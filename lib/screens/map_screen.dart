import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:maplibre/maplibre.dart' as maplibre;
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Consumer;
import '../controllers/poi_thumbnails_controller.dart';
import '../controllers/poi_controller.dart';
import '../controllers/category_controller.dart';
import '../models/poi.dart';
import '../provider/camera_provider.dart';
import '../provider/selected_poi_provider.dart';
import '../repositories/poi_repository.dart';
import '../repositories/districts_repository.dart';
import '../state/app_state.dart';
import '../state/poi_panel_state.dart';
import '../state/pois_thumbnails_state.dart';
import '../state/categories_menu_state.dart';
import '../services/geo_json_service.dart';
import '../services/debug_service.dart';
import '../widgets/_confirm_box.dart';
import '../widgets/poi_thumbnails_layer.dart';
import '../widgets/map_actions.dart';
import '../widgets/poi_panel.dart';

enum MapUpdateType { pointerMove, cameraIdle, animationFinished, styleLoaded }

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends ConsumerState<MapScreen> {
  maplibre.MapController? mapController;

  bool _styleLoaded = false;
  bool _isChangingStyle = false;

  final poiRepository = PoiRepository();

  Offset? userMarkerOffset;
  geo.Position? _lastUserPosition;
  MapUpdateType? _pendingUpdate;
  maplibre.StyleController? mapStyle;

  late VoidCallback _editModeListener;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CategoryController>().loadCategories();
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _addPoisforSelectedCategories();
    });
    geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      updateUserLocationOnMap(pos);
    });

    _editModeListener = () {
      final poi = ref.read(selectedPoiProvider);
      if (poi == null) return;

      if (context.read<AppState>().isPoiEditMode) {
        addPoiPointsLayer(poi);
      } else {
        removePoiPointsLayer();
      }
    };

    context.read<AppState>().addListener(_editModeListener);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
    _poiSub.close();
    context.read<AppState>().removeListener(_editModeListener);
  }

  Future<void> reloadPois() => _addPoisforSelectedCategories();

  bool _poiListenerRegistered = false;

  @override
  Widget build(BuildContext context) {
    /*print("Screen size: ${MediaQuery.of(context).size}");*/
    DebugService.log('Build MapScreen');

    if (!_poiListenerRegistered) {
      _poiListenerRegistered = true;
      _registerSelectedPoiListener();
    }

    final selectedPoi = ref.watch(selectedPoiProvider);
    if (selectedPoi != null) {
      DebugService.log('SelectedPoi: $selectedPoi.name');
    }
    context.watch<PoiThumbnailsState>();
    final appState = context.watch<AppState>();
    final poiPanelState = context.read<PoiPanelState>();

    return Stack(
      children: [
        // MapLibreMap
        Listener(
          behavior: HitTestBehavior.opaque,
          onPointerMove: _onPointerMove,
          child: maplibre.MapLibreMap(
            options: maplibre.MapOptions(
              initCenter: maplibre.Geographic(lon: 7.59253, lat: 47.55634),
              initZoom: 13.67,
              gestures: maplibre.MapGestures(
                rotate: false,
                pan: true,
                zoom: true,
                pitch: false,
              ),
              initStyle:
                  'https://stadtschreiber.duckdns.org/styles/basel-vintage/style.json',
            ),
            onMapCreated: (controller) async {
              mapController = controller;
            },
            onEvent: (event) async {
              DebugService.log('Event: $event.runtimeType');

              final thumbnailsController = context
                  .read<PoiThumbnailsController>();
              final poiController = context.read<PoiController>();

              switch (event) {
                case maplibre.MapEventDoubleClick():
                  poiPanelState.closePanel();
                  context.read<AppState>().setPoiEditMode(false);
                  ref.read(selectedPoiProvider.notifier).clear();

                case maplibre.MapEventStyleLoaded():
                  _styleLoaded = true;
                  _requestUpdateScreenpositions(MapUpdateType.styleLoaded);
                  mapStyle = event.style;

                // Create new poi, add or start dragging point of existing poi
                case maplibre.MapEventLongClick(
                  point: maplibre.Geographic(),
                  screenPoint: Offset(),
                ):
                  // Long press on map without poi edit mode -> create new poi
                  if (!appState.isPoiEditMode) {
                    if (appState.isAdmin) {
                      final newPoi = await poiRepository.newPoi(event.point);
                      _addPoiToMapScreen(newPoi);

                      DebugService.log(
                        'MapEventLongClick: Created new POI at ${event.point}, id: ${newPoi.id}, opening panel and enabling edit mode',
                      );
                    }
                    // start dragging / add new point
                  } else {
                    List<maplibre.Geographic> points =
                        selectedPoi!.getPoints() ?? [];

                    final pointIndex = await poiController
                        .findPoiPointIndexAtGeoPosition(
                          points,
                          event.point,
                          mapController!,
                        );

                    // Punkt wurde getroffen → Drag starten, Geometrie wird erst beim Loslassen aktualisiert
                    if (pointIndex != null) {
                      DebugService.log(
                        'MapEventLongClick: Long press on POI point, index $pointIndex, starting drag',
                      );
                      poiController.setDraggingPoiPoint(
                        selectedPoi,
                        pointIndex,
                      );
                      poiPanelState.closePanel();
                    }
                    // no point hit -> add new point and update geometry immediately, no dragging
                    else {
                      final newPoi = selectedPoi.cloneWithNewValues();

                      DebugService.log(
                        'MapEventLongClick: Long press on POI point, adding new point',
                      );
                      if (newPoi.geometryType == "Polygon") {
                        newPoi.insertPointIntoPolygon(points, event.point);
                      } else {
                        points.add(event.point);
                      }

                      newPoi.setPoints(points);
                      newPoi.closePolygonIfNeeded();

                      if (newPoi.isGeometryValid()) {
                        await poiRepository.updatePoiGeomInSupabase(newPoi);
                      }

                      ref.read(selectedPoiProvider.notifier).setPoi(newPoi);
                    }
                  }
                // Ende MapEventLongClick()

                case maplibre.MapEventMoveCamera(camera: maplibre.MapCamera()):
                  if (poiController.isDraggingPoiPoint) {
                    maplibre.MapGestures.none();

                    final poi = poiController.dragPoiPoint!;
                    final index = poiController.dragPoiPointIndex!;

                    final points = poi.getPoints()!;
                    points[index] = event.camera.center;

                    poi.setPoints(points);
                    ref
                        .read(selectedPoiProvider.notifier)
                        .setPoi(poi.cloneWithNewValues());
                  }
                  if (poiController.isDraggingPoi) {
                    maplibre.MapGestures.none();

                    final poi = poiController.dragPoi!;

                    final point = event.camera.center;
                    poi.location = point;
                    ref
                        .read(selectedPoiProvider.notifier)
                        .setPoi(poi.cloneWithNewValues());
                  }

                case maplibre.MapEventCameraIdle():
                  if (mapController == null) return;
                  // Refresh poi geometry
                  if (poiController.isDraggingPoiPoint) {
                    final poi = poiController.dragPoiPoint!;

                    poi.closePolygonIfNeeded();
                    if (poi.isGeometryValid()) {
                      await poiRepository.updatePoiGeomInSupabase(poi);
                    }

                    ref
                        .read(selectedPoiProvider.notifier)
                        .setPoi(poi.cloneWithNewValues());

                    poiController.unsetDraggingPoiPoint();
                    poiPanelState.openPanel();
                    maplibre.MapGestures.all();
                  }
                  // Refresh poi location
                  if (poiController.isDraggingPoi) {
                    final poi = poiController.dragPoi!;
                    await poiRepository.updatePoiGeomInSupabase(poi);
                    poiController.unsetDraggingPoi();
                    maplibre.MapGestures.all();
                  }

                  thumbnailsController.setZoom(mapController!.camera!.zoom);
                  final pos = mapController!.camera!;
                  ref
                      .read(cameraProvider.notifier)
                      .update(pos.center.lat, pos.center.lon, pos.zoom);
                  _requestUpdateScreenpositions(MapUpdateType.cameraIdle);

                default:
              }
            },
          ),
        ),

        Consumer2<PoiThumbnailsController, PoiThumbnailsState>(
          builder: (context, controller, visibleState, _) {
            return PoiThumbnailsLayer(
              controller: controller,
              visiblePOIs: visibleState.visible,
              zoom: controller.currentZoom,

              // onTapPoi
              onTapPoi: (poi) {
                DebugService.log('Poi selected from screen');
                _selectPoiAndOpenPanel(poi);
              },
              onLongPressPoi: (poi) {
                DebugService.log('onLongPressPoi');
                appState.setPoiEditMode(true);
                final poiController = context.read<PoiController>();
                poiController.setDraggingPoi(poi);
              },
            );
          },
        ),
        MapActions(
          onChangeStyle: changeStyle,
          onTapSearchedPoi: _addPoiToMapScreen,
          onLocateMe: _locateMe,
          onRemoveThumbnails: _removeAllThumbnails,
          onToggleAdminView: () {
            appState.setAdminViewEnabled(!appState.isAdminViewEnabled);
          },
          isAdmin: appState.isAdmin,
          isAdminViewEnabled: appState.isAdminViewEnabled,
        ),
        // PoiPanel
        Selector<PoiPanelState, bool>(
          selector: (_, panel) => (panel.isPanelOpen),
          builder: (_, isPanelOpen, _) {
            return isPanelOpen
                ? Align(alignment: Alignment.bottomCenter, child: PoiPanel())
                : const SizedBox.shrink();
          },
        ),

        // My Location Blue Dot
        if (userMarkerOffset != null)
          Positioned(
            left: userMarkerOffset!.dx - 8,
            top: userMarkerOffset!.dy - 8,
            child: Opacity(
              opacity: 0.5,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        // PoiEdits TODO Drag Hinweis und Status und Poi Name anzeigen
        Consumer<PoiController>(
          builder: (_, controller, _) {
            return controller.isDraggingPoi
                ? Positioned(
                    top: 20,
                    left: 0,
                    right: 0,

                    child: Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          final appState = context.read<AppState>();
                          final confirmed = await confirmBox(
                            context,
                            'Willst du den Point of Interest wirklich löschen?',
                            'Achtung',
                          );

                          if (confirmed) {
                            controller.deletePoi(selectedPoi!);
                            appState.setPoiEditMode(false);
                            ref.read(selectedPoiProvider.notifier).clear();

                            controller.unsetDraggingPoi();
                          }
                        },
                        child: Icon(
                          Icons.delete,
                          color: Colors.black,
                          size: 32,
                        ),
                      ),
                    ),
                  )
                : controller.isDraggingPoiPoint
                // Show trash button when dragging a point
                ? Stack(
                    children: [
                      Positioned(
                        top: 20,
                        left: 0,
                        right: 0,

                        child: Center(
                          child: ElevatedButton(
                            onPressed: () async {
                              final confirmed = await confirmBox(
                                context,
                                'Willst du den Punkt wirklich löschen?',
                                'Achtung',
                              );
                              if (confirmed) {
                                final index = controller.dragPoiPointIndex!;
                                final pts = List<maplibre.Geographic>.from(
                                  selectedPoi!.getPoints()!,
                                );
                                pts.removeAt(index);

                                final newPoi = selectedPoi.cloneWithNewValues();
                                newPoi.setPoints(pts);

                                newPoi.closePolygonIfNeeded();

                                DebugService.log(
                                  'Deleting point at index $index, new points: ${newPoi.getPoints()}',
                                );

                                ref
                                    .read(selectedPoiProvider.notifier)
                                    .setPoi(newPoi);

                                if (newPoi.isGeometryValid()) {
                                  await poiRepository.updatePoiGeomInSupabase(
                                    newPoi,
                                  );
                                }

                                controller.unsetDraggingPoiPoint();

                                maplibre.MapGestures.all();
                              }
                            },
                            child: Icon(
                              Icons.delete,
                              color: Colors.black,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            'Bewege die Karte, um den Punkt neu zu positionieren. Beim loslassen wird die Änderung gespeichert.',
                            style: TextStyle(color: Colors.black, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  late ProviderSubscription<PointOfInterest?> _poiSub;

  void _registerSelectedPoiListener() {
    _poiSub = ref.listenManual<PointOfInterest?>(selectedPoiProvider, (
      prev,
      next,
    ) async {
      if (next == null) {
        removePoiGeometrieLayer();
        removePoiPointsLayer();
        context.read<AppState>().setPoiEditMode(false);
        return;
      }

      // 1. Geometry type changed?
      if (prev?.geometryType != next.geometryType) {
        addPoiGeometrieLayer(next);
      }

      // 2. Geometry data changed?
      DebugService.log(
        '_registerSelectedPoiListener: Selected POI changed, checking geometry changes. Prev: ${prev?.getGeoJsonGeometry()}, Next: ${next.getGeoJsonGeometry()}, comparison result: ${prev?.getGeoJsonGeometry() == next.getGeoJsonGeometry()}',
      );
      if (prev?.getGeoJsonGeometry() != next.getGeoJsonGeometry()) {
        updatePoiGeometrieData(next);
        updatePoiPointsData(next);
      }

      // 4. Update thumbnails
      if (mapController != null) {
        final thumbnailsController = context.read<PoiThumbnailsController>();
        final visiblePOIs = context.read<PoiThumbnailsState>().visible;

        await thumbnailsController.updatePoiScreenPositions(
          controller: mapController!,
          visiblePOIs: visiblePOIs,
        );
      }
    });
  }

  Future<String> loadStyleJson(String path) async {
    return await rootBundle.loadString(path);
  }

  Future<geo.Position?> getCurrentPosition() async {
    final ok = context.read<AppState>().locationPermission;
    if (!ok) return null;

    return await geo.Geolocator.getCurrentPosition(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
      ),
    );
  }

  int styleCounter = 1;
  void changeStyle() async {
    if (_isChangingStyle) return;
    if (mapController == null) return;
    _isChangingStyle = true;
    _styleLoaded = false;

    styleCounter = styleCounter == 4 ? 1 : styleCounter + 1;
    final styleString = switch (styleCounter) {
      1 => "https://stadtschreiber.duckdns.org/styles/basel-vintage/style.json",
      2 => "https://stadtschreiber.duckdns.org/styles/basel-green/style.json",
      3 => "https://stadtschreiber.duckdns.org/styles/basel-osm/style.json",
      4 => "https://stadtschreiber.duckdns.org/styles/basel-blue/style.json",
      _ => throw Exception("Invalid styleCounter"),
    };

    mapController!.setStyle(styleString);
    _isChangingStyle = false;
  }

  Future<void> addDistrictsLayer() async {
    DebugService.log('MapScreen addDistrictsLayer');

    final districts = await DistrictsRepository().loadDistricts();

    mapStyle!.addSource(
      maplibre.GeoJsonSource(
        id: 'districts-source',
        data: getGeoJSONStringFromDistricts(districts),
      ),
    );

    final fillstyle = maplibre.FillStyleLayer(
      id: 'districts-fill',
      sourceId: 'districts-source',
      paint: {
        'fill-color': 'rgba(180, 180, 180, 0.3)',
        'fill-outline-color': 'rgba(0, 0, 0, 0)',
      },
    );
    mapStyle!.addLayer(fillstyle);
    /* belowLayerId: 'railway' */
    mapStyle!.addLayer(
      maplibre.LineStyleLayer(
        id: 'districts-outline',
        sourceId: 'districts-source',
        paint: {'line-color': 'rgba(50, 50, 50, 0.3)', 'line-width': 2.0},
      ),
    );
    /*     final c = Color.fromRGBO(0, 153, 255, 0);
 */
  }

  Future<void> removeDistrictsLayer() async {
    DebugService.log('MapScreen removeDistrictsLayer');
    try {
      mapStyle!.removeLayer('districts-outline');
      mapStyle!.removeLayer('districts-fill');
    } catch (e) {
      DebugService.log("Layer not found, skipping removal.");
    }
  }

  /* 
NEWPOI
- define geometry type in poi -> add dummy source and add layer depending on geometry type (point, line, polygon)
- edit points -> update source data -> geometry on map updates
 */

  Future<void> addPoiGeometrieLayer(PointOfInterest poi) async {
    DebugService.log('MapScreen addPoiGeometrieLayer');
    try {
      mapStyle!.removeLayer('poi-geom-fill');
      mapStyle!.removeLayer('poi-geom-fill-outline');
      mapStyle!.removeLayer('poi-geom-line');
      mapStyle!.removeSource('poi-geom-source');
    } catch (_) {}

    final geojson = poi.getGeoJsonGeometry();
    mapStyle!.addSource(
      maplibre.GeoJsonSource(id: 'poi-geom-source', data: geojson),
    );

    final type = poi.geometryType.toLowerCase();
    if (type == "multipolygon" || type == "polygon") {
      mapStyle!.addLayer(
        maplibre.FillStyleLayer(
          id: 'poi-geom-fill',
          sourceId: 'poi-geom-source',
          paint: {'fill-color': 'rgba(180, 180, 180, 0.3)'},
        ),
      );
      mapStyle!.addLayer(
        maplibre.LineStyleLayer(
          id: 'poi-geom-fill-outline',
          sourceId: 'poi-geom-source',
          paint: {'line-color': 'rgba(50, 50, 50, 0.3)', 'line-width': 5.0},
        ),
      );
    }

    if (type == "linestring") {
      mapStyle!.addLayer(
        maplibre.LineStyleLayer(
          id: 'poi-geom-line',
          sourceId: 'poi-geom-source',
          paint: {'line-color': 'rgba(255, 0, 0, 0.3)', 'line-width': 2.0},
        ),
      );
    }
  }

  Future<void> updatePoiGeometrieData(PointOfInterest selectedPoi) async {
    final newGeoJson = selectedPoi.getGeoJsonGeometry();

    mapStyle!.updateGeoJsonSource(id: 'poi-geom-source', data: newGeoJson);

    DebugService.log('MapScreen updatePoiGeometrieData, Data: $newGeoJson');
  }

  Future<void> removePoiGeometrieLayer() async {
    DebugService.log('MapScreen removePoiGeometrieLayer');
    try {
      mapStyle!.removeLayer('poi-geom-fill');
      mapStyle!.removeLayer('poi-geom-fill-outline');
      mapStyle!.removeLayer('poi-geom-line');
      mapStyle!.removeSource('poi-geom-source');
    } catch (e) {
      DebugService.log("Layer not found, skipping removal.");
    }
    mapController!.moveCamera(
      center: mapController!.camera!.center,
      zoom: mapController!.camera!.zoom + 0.00000001,
    );
  }

  Future<void> addPoiPointsLayer(PointOfInterest poi) async {
    try {
      mapStyle!.removeLayer('poi-points');
      mapStyle!.removeSource('poi-points-source');
    } catch (_) {}

    final points = poi.getPoints();
    if (points == null || points.isEmpty) return;

    final geojson = poi.getPointsGeoJson();

    mapStyle!.addSource(
      maplibre.GeoJsonSource(id: 'poi-points-source', data: geojson!),
    );
    DebugService.log('MapScreen addPoiPointsLayer, Data: $geojson');

    if (poi.geometryType == "polygon" ||
        poi.geometryType == "multipolygon" ||
        poi.geometryType == "linestring") {
      mapStyle!.addLayer(
        maplibre.CircleStyleLayer(
          id: 'poi-points-fill',
          sourceId: 'poi-points-source',
          paint: {
            'circle-radius': 6.0,
            'circle-color': '#ff0000',
            'circle-stroke-width': 2.0,
            'circle-stroke-color': '#ffffff',
          },
        ),
      );
    }
  }

  /// Update the geometry of the poi in the database and on the map after editing points
  Future<void> updatePoiPointsData(PointOfInterest poi) async {
    DebugService.log('MapScreen updatePoiPointsData');

    final newGeoJson = poi.getPointsGeoJson()!;
    mapStyle!.updateGeoJsonSource(id: 'poi-points-source', data: newGeoJson);
  }

  Future<void> removePoiPointsLayer() async {
    DebugService.log('MapScreen removePoiPointsLayer');
    try {
      mapStyle!.removeLayer('poi-points-fill');
      mapStyle!.removeSource('poi-points-source');
    } catch (e) {
      DebugService.log("Layer not found, skipping removal.");
    }

    mapController!.moveCamera(
      center: mapController!.camera!.center,
      zoom: mapController!.camera!.zoom + 0.00000001,
    );
  }

  /// sets selectedPoi in PoiController and opens the panel in PoiPanelState and adds the geometry layer for the selected poi (if poi has geometry)
  void _selectPoiAndOpenPanel(PointOfInterest poi) {
    DebugService.log('MapScreen run _selectPoiAndOpenPanel(poi)');

    final panel = context.read<PoiPanelState>();

    ref.read(selectedPoiProvider.notifier).setPoi(poi);

    panel.openPanel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerSelectedPoiConsideringPanel(poi);
    });
    addPoiGeometrieLayer(poi);
  }

  /// completes poi data, adds poi to visible pois in PoiThumbnailsState, updates screen positions and opens the panel for the poi
  Future<void> _addPoiToMapScreen(PointOfInterest poi) async {
    DebugService.log('MapScreen run _addPoiToMapScreen(poi)');
    final visiblePoiState = context.read<PoiThumbnailsState>();
    final thumbnailsController = context.read<PoiThumbnailsController>();
    final poiController = context.read<PoiController>();
    final completedPoi = await poiController.completePoi(poi);
    visiblePoiState.add(completedPoi);

    if (mapController != null) {
      await thumbnailsController.updatePoiScreenPositions(
        controller: mapController!,
        visiblePOIs: visiblePoiState.visible,
      );
    }
    _selectPoiAndOpenPanel(completedPoi);
  }

  Future<void> _addPoisforSelectedCategories() async {
    if (!mounted) return;
    final categoriesMenuState = context.read<CategoriesMenuState>();
    final poiThumbnailsState = context.read<PoiThumbnailsState>();
    final thumbnailsController = context.read<PoiThumbnailsController>();

    final pois = await poiRepository.loadPoisforSelectedCategories(
      categoriesMenuState.selectedValues.toList(),
    );
    List<PointOfInterest> allPois = List.from(pois);

    poiThumbnailsState.setAll(allPois);

    if (mapController != null) {
      await thumbnailsController.updatePoiScreenPositions(
        controller: mapController!,
        visiblePOIs: poiThumbnailsState.visible,
      );

      if (categoriesMenuState.selectedValues.contains('districts')) {
        await addDistrictsLayer();
        mapController!.moveCamera(
          zoom: 12.5,
          center: maplibre.Geographic(lon: 7.59065, lat: 47.55731),
        );
      } else {
        await removeDistrictsLayer();
      }
    }
  }

  void _removeAllThumbnails() {
    final state = context.read<PoiThumbnailsState>();
    // TODO context.read<CategoriesMenuState>().setSelected();
    state.setAll([]);
    _requestUpdateScreenpositions(MapUpdateType.cameraIdle);
  }

  final panelHeight = 460;

  Future<void> _centerSelectedPoiConsideringPanel(PointOfInterest poi) async {
    if (mapController == null) return;

    final size = MediaQuery.of(context).size;
    final halfWidth = size.width / 2;

    final screenTop = mapController!.toLngLat(Offset(halfWidth, 0)).lat;
    final screenBottom = mapController!
        .toLngLat(Offset(halfWidth, size.height))
        .lat;
    final mapScreenBottom = mapController!
        .toLngLat(Offset(halfWidth, (size.height + panelHeight) / 2))
        .lat;

    final distanceMapCentertoScreenCenter =
        (screenTop - mapScreenBottom) / 2 - (screenTop - screenBottom) / 2;

    try {
      await mapController!.animateCamera(
        center: maplibre.Geographic(
          lat: poi.location.y + distanceMapCentertoScreenCenter,
          lon: poi.location.x,
        ),
        nativeDuration: const Duration(milliseconds: 200),
      );
    } catch (e) {
      DebugService.log(
        "_centerSelectedPoiConsideringPanel: ⚠️ Camera animation cancelled: $e",
      );
    }

    _requestUpdateScreenpositions(MapUpdateType.animationFinished);
  }

  Future<void> _updateAllScreenPositions() async {
    if (!mounted || mapController == null) return;

    // capture everything BEFORE async
    final thumbnailsController = context.read<PoiThumbnailsController>();
    final visiblePOIs = context.read<PoiThumbnailsState>().visible;
    final lastUserPos = _lastUserPosition;

    await _waitForMapToSettle();

    if (visiblePOIs.isNotEmpty) {
      await thumbnailsController.updatePoiScreenPositions(
        controller: mapController!,
        visiblePOIs: visiblePOIs,
      );
    }

    if (lastUserPos != null) {
      updateUserLocationOnMap(lastUserPos);
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_styleLoaded || mapController == null) return;
    _requestUpdateScreenpositions(MapUpdateType.pointerMove);
    if (context.read<PoiPanelState>().isPanelOpen) {}
  }

  void _requestUpdateScreenpositions(MapUpdateType type) {
    _pendingUpdate = type;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // collapse multiple requests into one
      if (_pendingUpdate == null) return;
      await _updateAllScreenPositions();
      _pendingUpdate = null;
    });
  }

  void updateUserLocationOnMap(geo.Position pos) {
    _lastUserPosition = pos;
    if (mapController == null) return;

    final screen = mapController!.toScreenLocation(
      maplibre.Geographic(lat: pos.latitude, lon: pos.longitude),
    );

    setState(() {
      userMarkerOffset = Offset(screen.dx, screen.dy);
    });
  }

  Future<void> _locateMe() async {
    final pos = await getCurrentPosition();
    if (pos == null) return;

    try {
      await mapController!.animateCamera(
        center: maplibre.Geographic(lat: pos.latitude, lon: pos.longitude),
        nativeDuration: const Duration(milliseconds: 300),
      );
    } catch (e, stack) {
      DebugService.log("MapScreen._locateMe: ❌ animateCamera failed: $e");
      DebugService.log("MapScreen._locateMe: 📌 Stack trace: $stack");
    }

    updateUserLocationOnMap(pos);
    _requestUpdateScreenpositions(MapUpdateType.animationFinished);
  }

  Future<void> _waitForMapToSettle() async {
    await Future.delayed(Duration.zero); // microtask
    await Future.delayed(const Duration(milliseconds: 16)); // next frame
  }
}
