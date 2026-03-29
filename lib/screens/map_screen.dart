import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:maplibre/maplibre.dart' as maplibre;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/provider/address_lookup_queue_provider.dart';
import 'package:stadtschreiber/provider/app_state_provider.dart';
import 'package:stadtschreiber/provider/categories_menu_provider.dart';
import 'package:stadtschreiber/provider/categories_provider.dart';
import 'package:stadtschreiber/provider/map_controller_provider.dart';
import 'package:stadtschreiber/provider/poi_drag_provider.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';
import 'package:stadtschreiber/provider/poi_service_provider.dart';
import 'package:stadtschreiber/provider/search_provider.dart';
import 'package:stadtschreiber/provider/supabase_user_state_provider.dart';
import 'package:stadtschreiber/provider/visible_pois_provider.dart';
import 'package:stadtschreiber/provider/camera_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';
import 'package:stadtschreiber/repositories/districts_repository.dart';
import 'package:stadtschreiber/services/geo_json_service.dart';
import 'package:stadtschreiber/services/debug_service.dart';
import 'package:stadtschreiber/state/app_state.dart';
import 'package:stadtschreiber/widgets/modal_confirm_box.dart';
import 'package:stadtschreiber/widgets/poi_thumbnails_layer.dart';
import 'package:stadtschreiber/widgets/map_actions.dart';
import 'package:stadtschreiber/widgets/poi_panel.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends ConsumerState<MapScreen> {
  maplibre.MapController? mapController;

  bool _isChangingStyle = false;
  List<PointOfInterest> _lastVisiblePois = const [];

  late ProviderSubscription<AsyncValue<List<PointOfInterest>>> _visiblePoisSub;

  late ProviderSubscription<PointOfInterest?> _selectedPoiSub;

  // TODO userMarkerOffset reaktiv machen
  Offset? userMarkerOffset;
  maplibre.StyleController? mapStyle;
  double? lastKnownUserLat;
  double? lastKnownUserLon;

  @override
  void initState() {
    super.initState();
    _registerSelectedPoiListener();
    _registerVisiblePoisListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(categoriesProvider.notifier).loadCategories();
    });

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      updateUserLocationOnMap(pos);
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
    _selectedPoiSub.close();
    _visiblePoisSub.close();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final poiRepository = ref.read(poiRepositoryProvider);
    final dragPoiNotifier = ref.read(dragPoiProvider.notifier);
    final user = ref.watch(supabaseUserStateProvider);

    final isPoiEditMode = appState.isPoiEditMode;
    final isAdminViewEnabled = appState.isAdminViewEnabled;

    final selectedPoi = ref.watch(selectedPoiProvider);
    final hasSelectedPoi = selectedPoi != null;
    final bool isDraggingPoi = dragPoiNotifier.isDraggingPoi();
    final bool isDraggingPoiPoint = dragPoiNotifier.isDraggingPoiPoint();

    final bool showPoiPanel =
        hasSelectedPoi && !isPoiEditMode && !isDraggingPoi;

    final camera = ref.watch(cameraProvider);
    ref.watch(cameraProvider);

    DebugService.log(
      'Build MapScreen Screen size: ${MediaQuery.of(context).size}\n isPoiEditMode: $isPoiEditMode\nisAdminViewEnabled: $isAdminViewEnabled\nhasSelectedPoi: $hasSelectedPoi\nshowPoiPanel: $showPoiPanel\nisDraggingPoi: $isDraggingPoi\nisDraggingPoiPoint: $isDraggingPoiPoint',
    );

    /*     if (!_selectedPoiListenerRegistered) {
      _selectedPoiListenerRegistered = true;
      _registerSelectedPoiListener();
    }

    if (!_visiblePoisListenerRegistered) {
      _visiblePoisListenerRegistered = true;
      _registerVisiblePoisListener();
    } */

    // isPoiEditmode => add points layer
    if (selectedPoi != null) {
      DebugService.log('SelectedPoi: $selectedPoi.name');

      ref.listen<AppStateData>(appStateProvider, (previous, next) {
        debugPrint('AppStateData changed: $previous → $next');

        if (next.isPoiEditMode &&
            (previous == null || !previous.isPoiEditMode)) {
          addPoiPointsLayer(selectedPoi);
        }
        if (!next.isPoiEditMode &&
            previous != null &&
            !previous.isPoiEditMode) {
          removePoiPointsLayer();
        }
      });
    }
    if (userMarkerOffset != null) {
      final screen = mapController?.toScreenLocation(
        maplibre.Geographic(lat: lastKnownUserLat!, lon: lastKnownUserLon!),
      );

      if (screen != null) {
        userMarkerOffset = Offset(screen.dx, screen.dy);
      }
    }

    if (user.loading) {
      return Center(child: CircularProgressIndicator());
    } else {
      return Stack(
        children: [
          // MapLibreMap
          Listener(
            behavior: HitTestBehavior.opaque,
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

                if (_lastVisiblePois.isNotEmpty) {
                  /* final newPositions = calculatePoiMarkerPositions(
                    visiblePois: _lastVisiblePois,
                    controller: controller,
                  );
                  ref
                      .read(poiMarkerPositionsProvider.notifier)
                      .setPositions(newPositions); */
                }
              },

              onEvent: (event) async {
                DebugService.log('Event: $event.runtimeType');
                // check for double events and add break if necessary
                switch (event) {
                  // TODO double click funktioniert nicht??
                  case maplibre.MapEventDoubleClick():
                    ref.read(selectedPoiProvider.notifier).clear();
                    break;
                  case maplibre.MapEventStyleLoaded():
                    ref.read(mapControllerProvider.notifier).state =
                        mapController;
                    mapStyle = event.style;

                    // Wenn ein POI ausgewählt ist → Geometrie-Layer neu aufbauen
                    final selectedPoi = ref.read(selectedPoiProvider);
                    if (selectedPoi != null) {
                      addPoiGeometrieLayer(selectedPoi);
                      updatePoiPointsData(selectedPoi);
                    }
                    break;
                  // Create new poi, add or start dragging point of existing poi
                  // TODO Ask to create new poi
                  case maplibre.MapEventLongClick(
                    point: maplibre.Geographic(),
                    screenPoint: Offset(),
                  ):
                    // Long press on map without poi edit mode -> create new poi
                    if (isPoiEditMode) {
                      // start dragging / add new point
                      List<maplibre.Geographic> points =
                          selectedPoi!.getPoints() ?? [];

                      final pointIndex = await ref
                          .read(poiServiceProvider)
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
                        dragPoiNotifier.startDraggingPoiPoint(
                          selectedPoi,
                          pointIndex,
                        );
                        mapController!.moveCamera(center: event.point);
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
                    break;
                  // Ende MapEventLongClick()
                  case maplibre.MapEventMoveCamera(
                    camera: maplibre.MapCamera(),
                  ):
                    final cam = event.camera;

                    DebugService.log(
                      'MapEventMoveCamera: ${cam.center.lat}, ${cam.center.lon}, zoom: ${cam.zoom}',
                    );

                    // ------------------------------------------------------------
                    // 1. Kamera-Status aktualisieren (leichtgewichtige Updates)
                    // ------------------------------------------------------------
                    ref
                        .read(cameraProvider.notifier)
                        .update(cam.center.lat, cam.center.lon, cam.zoom);

                    // ------------------------------------------------------------
                    // 2. User-Marker aktualisieren (falls vorhanden)
                    // ------------------------------------------------------------
                    if (lastKnownUserLat != null && lastKnownUserLon != null) {
                      final screen = mapController?.toScreenLocation(
                        maplibre.Geographic(
                          lat: lastKnownUserLat!,
                          lon: lastKnownUserLon!,
                        ),
                      );

                      if (screen != null) {
                        setState(() {
                          userMarkerOffset = Offset(screen.dx, screen.dy);
                        });
                      }
                    }

                    // ------------------------------------------------------------
                    // 3. Dragging eines Polygon-Punktes
                    // ------------------------------------------------------------
                    if (isDraggingPoiPoint) {
                      maplibre.MapGestures.none();

                      final dragPoi = dragPoiNotifier.dragPoi();
                      final index = ref
                          .read(dragPoiProvider)
                          .dragPoiPointIndex!;
                      final points = dragPoi!.getPoints()!;

                      points[index] = cam.center;
                      dragPoi.setPoints(points);

                      ref
                          .read(selectedPoiProvider.notifier)
                          .setPoi(dragPoi.cloneWithNewValues());
                    }

                    // ------------------------------------------------------------
                    // 4. Dragging eines ganzen POIs
                    // ------------------------------------------------------------
                    if (isDraggingPoi) {
                      maplibre.MapGestures.none();

                      final poi = dragPoiNotifier.dragPoi();
                      poi!.location = cam.center;

                      ref
                          .read(selectedPoiProvider.notifier)
                          .setPoi(poi.cloneWithNewValues());
                    }

                    break;

                  case maplibre.MapEventCameraIdle():
                    if (mapController == null) return;

                    // ------------------------------------------------------------
                    // 1. Dragging-Updates (wie bisher)
                    // ------------------------------------------------------------
                    if (isDraggingPoiPoint) {
                      final poi = dragPoiNotifier.dragPoi()!;

                      poi.closePolygonIfNeeded();
                      if (poi.isGeometryValid()) {
                        await poiRepository.updatePoiGeomInSupabase(poi);
                      }

                      dragPoiNotifier.stopDraggingPoiPoint();
                      ref
                          .read(selectedPoiProvider.notifier)
                          .setPoi(poi.cloneWithNewValues());

                      maplibre.MapGestures.all();
                    }

                    if (isDraggingPoi) {
                      final poi = dragPoiNotifier.dragPoi();
                      await poiRepository.updatePoiGeomInSupabase(poi!);
                      dragPoiNotifier.stopDraggingPoi();
                      maplibre.MapGestures.all();
                    }
                    break;

                  case maplibre.MapEventIdle():
                    break;

                  default:
                }
              },
              children: [
                maplibre.SourceAttribution(
                  showMapLibre: true,
                  alignment: Alignment.bottomLeft,
                ),
              ],
            ),
          ),
          isPoiEditMode
              // Button Edit Mode beenden anzeigen
              ? Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        ref
                            .read(appStateProvider.notifier)
                            .setPoiEditMode(false);
                        final poi = ref
                            .read(selectedPoiProvider)!
                            .cloneWithNewValues();
                        ref.read(selectedPoiProvider.notifier).setPoi(poi);

                        ref.read(selectedPoiProvider.notifier).clear();
                      },
                      child: Text('Edit Mode beenden'),
                    ),
                  ),
                )
              // !poiEditMode: Icon anzeigen
              : PoiThumbnailsLayer(
                  // onTapPoi
                  onTapPoi: (poi) {
                    DebugService.log('Poi selected from screen');
                    _selectPoi(poi);
                  },
                ),

          MapActions(
            onChangeStyle: changeStyle,
            onLocateMe: _locateMe,
            onAddPoi: () async {
              final newPoi = await poiRepository.newPoi(camera.getLocation());

              DebugService.log(
                'MapEventLongClick: Created new POI at ${camera.getLocation()}, id: ${newPoi.id}, opening panel and enabling edit mode',
              );
            },
            onRemoveThumbnails: () {
              ref.read(categoriesSelectionProvider.notifier).clear();
              ref.read(searchSelectionProvider.notifier).clear();
            },

            isAdmin: user.isAdmin,
            isAdminViewEnabled: isAdminViewEnabled,
          ),

          // PoiPanel anzeigen, wenn hasSelectedPoi !& isPoiEditMode
          showPoiPanel
              ? Align(
                  alignment: Alignment.bottomCenter,
                  child: PoiPanel(
                    selectedPoi: selectedPoi,
                    onToggleAdminView: () {
                      ref
                          .read(appStateProvider.notifier)
                          .setAdminViewEnabled(!isAdminViewEnabled);
                    },
                    onStartDraggingPoi: () {
                      dragPoiNotifier.startDraggingPoi(selectedPoi);
                      mapController!.moveCamera(center: selectedPoi.location);
                    },
                  ),
                )
              : const SizedBox.shrink(),

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
          if (isDraggingPoi)
            // Papierkorb
            Positioned(
              top: 20,
              left: 0,
              right: 0,

              child: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    final confirmed = await confirmBox(
                      context,
                      'Willst du den Point of Interest wirklich löschen?',
                      'Achtung',
                    );

                    if (confirmed) {
                      ref
                          .read(searchSelectionProvider.notifier)
                          .remove(selectedPoi!);
                      poiRepository.deletePoi(selectedPoi.id);
                      ref.read(appStateProvider.notifier).setPoiEditMode(false);
                      ref.read(selectedPoiProvider.notifier).clear();
                      dragPoiNotifier.stopDraggingPoi();
                    }
                  },
                  child: Icon(Icons.delete, color: Colors.black, size: 32),
                ),
              ),
            ),
          if (isDraggingPoiPoint)
            // Show trash button when dragging a point
            Stack(
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
                          final index = ref
                              .read(dragPoiProvider)
                              .dragPoiPointIndex;
                          final pts = List<maplibre.Geographic>.from(
                            selectedPoi!.getPoints()!,
                          );
                          pts.removeAt(index!);

                          final newPoi = selectedPoi.cloneWithNewValues();
                          newPoi.setPoints(pts);

                          newPoi.closePolygonIfNeeded();

                          DebugService.log(
                            'Deleting point at index $index, new points: ${newPoi.getPoints()}',
                          );

                          ref.read(selectedPoiProvider.notifier).setPoi(newPoi);

                          if (newPoi.isGeometryValid()) {
                            await poiRepository.updatePoiGeomInSupabase(newPoi);
                          }

                          dragPoiNotifier.stopDraggingPoiPoint();

                          maplibre.MapGestures.all();
                        }
                      },
                      child: Icon(Icons.delete, color: Colors.black, size: 32),
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
            ),
        ],
      );
    }
  }

  void _registerVisiblePoisListener() {
    _visiblePoisSub = ref.listenManual<AsyncValue<List<PointOfInterest>>>(
      visiblePoisProvider,
      (prev, next) {
        next.whenData((pois) {
          _lastVisiblePois = pois;

          final controller = mapController;
          if (controller == null) {
            // Controller kommt später → wir holen das nach, sobald er gesetzt ist
            return;
          }

          final lookupQueue = ref.read(addressLookupQueueProvider.notifier);
          for (final poi in pois) {
            if (poi.displayAddress == null || poi.displayAddress!.isEmpty) {
              lookupQueue.enqueue(poi);
            }
          }
        });
      },
    );
  }

  void _registerSelectedPoiListener() {
    _selectedPoiSub = ref.listenManual<PointOfInterest?>(selectedPoiProvider, (
      prev,
      next,
    ) async {
      // Poi de-selected
      if (next == null) {
        removePoiGeometrieLayer();
        // TODO move this to UI
        ref.read(appStateProvider.notifier).setPoiEditMode(false);
        return;
      }

      final prevGeom = prev?.getGeoJsonGeometry();
      final nextGeom = next.getGeoJsonGeometry();

      if (prevGeom != nextGeom) {
        if (prev?.geometryType != next.geometryType) {
          addPoiGeometrieLayer(next);
        } else {
          updateMapGeometrieData(next);
        }

        updatePoiPointsData(next);
      }

      DebugService.log(
        '_registerSelectedPoiListener: Selected POI changed, checking geometry changes. Prev: ${prev?.getGeoJsonGeometry()}, Next: ${next.getGeoJsonGeometry()}, comparison result: ${prev?.getGeoJsonGeometry() == next.getGeoJsonGeometry()}',
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        centerSelectedPoiConsideringPanel();
      });
    });
  }

  Future<String> loadStyleJson(String path) async {
    return await rootBundle.loadString(path);
  }

  Future<geo.Position?> getCurrentPosition() async {
    final ok = ref.read(appStateProvider).locationPermission;
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

    _safeRemoveLayer('poi-geom-fill');
    _safeRemoveLayer('poi-geom-fill-outline');
    _safeRemoveLayer('poi-geom-line');
    _safeRemoveSource('poi-geom-source');

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

  Future<void> updateMapGeometrieData(PointOfInterest selectedPoi) async {
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
    _safeRemoveLayer('poi-points');
    _safeRemoveSource('poi-points-source');

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

    final newGeoJson = poi.getPointsGeoJson();
    if (newGeoJson != null) {
      mapStyle!.updateGeoJsonSource(id: 'poi-points-source', data: newGeoJson);
    }
  }

  Future<void> removePoiPointsLayer() async {
    DebugService.log('MapScreen removePoiPointsLayer');

    _safeRemoveLayer('poi-points-fill');
    _safeRemoveSource('poi-points-source');

    mapController!.moveCamera(
      center: mapController!.camera!.center,
      zoom: mapController!.camera!.zoom + 0.00000001,
    );
  }

  /// sets selectedPoi in dragPoiNotifier and opens the panel in PoiPanelState and adds the geometry layer for the selected poi (if poi has geometry)
  void _selectPoi(PointOfInterest poi) {
    DebugService.log('MapScreen run _selectPoi(poi)');

    ref.read(selectedPoiProvider.notifier).setPoi(poi);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      centerSelectedPoiConsideringPanel();
    });
    addPoiGeometrieLayer(poi);
  }

  final panelHeight = 460;

  Future<void> centerSelectedPoiConsideringPanel() async {
    if (mapController == null) return;
    final poi = ref.read(selectedPoiProvider);
    if (poi == null) return;
    final screenSize = MediaQuery.of(context).size;
    final halfWidth = screenSize.width / 2;

    final screenTop = mapController!.toLngLat(Offset(halfWidth, 0)).lat;
    final screenBottom = mapController!
        .toLngLat(Offset(halfWidth, screenSize.height))
        .lat;
    final mapScreenBottom = mapController!
        .toLngLat(Offset(halfWidth, (screenSize.height - panelHeight)))
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
      DebugService.log(
        "centerSelectedPoiConsideringPanel: Camera animated considering panel height: $panelHeight, screen: $screenSize, distanceMapCentertoScreenCenter: $distanceMapCentertoScreenCenter",
      );
    } catch (e) {
      DebugService.log(
        "centerSelectedPoiConsideringPanel: ⚠️ Camera animation cancelled: $e",
      );
    }
  }

  void updateUserLocationOnMap(geo.Position pos) {
    lastKnownUserLat = pos.latitude;
    lastKnownUserLon = pos.longitude;

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
  }

  void _safeRemoveLayer(String id) {
    try {
      mapStyle?.removeLayer(id);
      DebugService.log("Removed layer: $id");
    } catch (e) {
      DebugService.log("ERROR removing layer '$id': $e");
    }
  }

  void _safeRemoveSource(String id) {
    try {
      mapStyle?.removeSource(id);
      DebugService.log("Removed source: $id");
    } catch (e) {
      DebugService.log("ERROR removing source '$id': $e");
    }
  }
}
