import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:maplibre/maplibre.dart' as maplibre;
import 'package:provider/provider.dart';
import '../controllers/poi_thumbnails_controller.dart';
import '../controllers/poi_controller.dart';
import '../controllers/category_controller.dart';
import '../models/poi.dart';
import '../repositories/poi_repository.dart';
import '../repositories/districts_repository.dart';
import '../state/app_state.dart';
import '../state/poi_panel_state.dart';
import '../state/pois_thumbnails_state.dart';
import '../state/categories_menu_state.dart';
import '../services/geo_json_service.dart';
import '../widgets/poi_thumbnails_layer.dart';
import '../widgets/map_actions.dart';
import '../widgets/poi_panel_persistent.dart';

enum MapUpdateType { pointerMove, cameraIdle, animationFinished, styleLoaded }

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  maplibre.MapController? mapController;

  Future<void> reloadPois() => _loadPoisforSelectedCategories();
  bool _styleLoaded = false;
  bool _isChangingStyle = false;

  final poiRepository = PoiRepository();

  Offset? userMarkerOffset;
  geo.Position? _lastUserPosition;
  MapUpdateType? _pendingUpdate;
  maplibre.StyleController? mapStyle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CategoryController>().loadCategories();
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _loadPoisforSelectedCategories();
    });
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
  Widget build(BuildContext context) {
    /*print("Screen size: ${MediaQuery.of(context).size}");*/

    context.watch<PoiThumbnailsState>();
    final appState = context.read<AppState>();

    return Stack(
      children: [
        // MapLibreMap
        Listener(
          behavior: HitTestBehavior.opaque,
          onPointerMove: _onPointerMove,
          child: maplibre.MapLibreMap(
            options: maplibre.MapOptions(
              initCenter: maplibre.Geographic(lon: 7.60132, lat: 47.57118),
              initZoom: 14,
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
              /*               print("📡 MapEvent: ${event.runtimeType}"); */
              final thumbnailsController = context
                  .read<PoiThumbnailsController>();

              if (event case maplibre.MapEventStyleLoaded()) {
                _styleLoaded = true;
                _requestUpdateScreenpositions(MapUpdateType.styleLoaded);
                mapStyle = event.style;
              }

              if (event case maplibre.MapEventCameraIdle()) {
                if (mapController == null) return;

                thumbnailsController.setZoom(mapController!.camera!.zoom);

                _requestUpdateScreenpositions(MapUpdateType.cameraIdle);
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
              onTapPoi: (poi) {
                final panel = context.read<PoiPanelState>();
                panel.selectPoi(poi);
                context.read<PoiController>().selectPoi(poi);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _centerSelectedPoiConsideringPanel();
                });
              },
            );
          },
        ),
        MapActions(
          onChangeStyle: changeStyle,
          onSelectPoi: selectPoi,
          onLocateMe: _locateMe,
          onRemoveThumbnails: removeAllThumbnails,
          onToggleAdminView: () {
            appState.setAdminViewEnabled(!appState.isAdminViewEnabled);
          },
          isAdmin: appState.isAdmin,
          isAdminViewEnabled: appState.isAdminViewEnabled,
        ),
        Selector<PoiPanelState, (bool, PointOfInterest?)>(
          selector: (_, state) => (state.isPanelOpen, state.selected),
          builder: (_, tuple, _) {
            final (isPanelOpen, selectedPoi) = tuple;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (isPanelOpen && selectedPoi != null) {
                _centerSelectedPoiConsideringPanel();
              }
            });

            return isPanelOpen
                ? Align(
                    alignment: Alignment.bottomCenter,
                    child: PersistentPoiPanel(
                      isAdminViewEnabled: context
                          .watch<AppState>()
                          .isAdminViewEnabled,
                    ),
                  )
                : const SizedBox.shrink();
          },
        ),
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
      ],
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
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

  Future<void> _loadPoisforSelectedCategories() async {
    final categoriesMenuState = context.read<CategoriesMenuState>();
    final poiThumbnailsState = context.read<PoiThumbnailsState>();
    final thumbnailsController = context.read<PoiThumbnailsController>();

    final pois = await poiRepository.loadPoisforSelectedCategories(
      categoriesMenuState.selectedValues.toList(),
    );
    List<PointOfInterest> allPois = List.from(pois);
    List<PointOfInterest> districtPois = [];

    if (categoriesMenuState.selectedValues.contains('districts')) {
      districtPois = await poiRepository.loadDistrictPois();
      allPois.addAll(districtPois);
    }
    
    poiThumbnailsState.setAll(allPois);

    if (mapController != null) {
      await thumbnailsController.updatePoiScreenPositions(
        controller: mapController!,
        visiblePOIs: poiThumbnailsState.visible,
      );

      if (categoriesMenuState.selectedValues.contains('districts')) {
        await addDistrictsLayer(mapController!);
        mapController!.moveCamera(zoom: 12.5,center: maplibre.Geographic(lon: 7.59065, lat: 47.55731) );
        
      } else {
        await removeDistrictsLayer(mapController!);
      }
    }
  }

  void removeAllThumbnails() {
    final state = context.read<PoiThumbnailsState>();
    state.setAll([]);
    _requestUpdateScreenpositions(MapUpdateType.cameraIdle);
  }

  Future<void> addDistrictsLayer(maplibre.MapController mapController) async {
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
 */  }

  Future<void> removeDistrictsLayer(
    maplibre.MapController mapController,
  ) async {
    mapStyle!.removeLayer('districts-outline');
    mapStyle!.removeLayer('districts-fill');
  }

  Future<void> selectPoi(PointOfInterest poi) async {
    final poiController = context.read<PoiController>();
    final visiblePoiState = context.read<PoiThumbnailsState>();
    final thumbnailsController = context.read<PoiThumbnailsController>();
    final poiPanelState = context.read<PoiPanelState>();
    final fresh = await poiController.poiRepo.loadPoiById(poi.id, poi.categories);
    final realPoi = fresh ?? poi;

    visiblePoiState.add(realPoi);

    if (mapController != null) {
      await thumbnailsController.updatePoiScreenPositions(
        controller: mapController!,
        visiblePOIs: visiblePoiState.visible,
      );
    }
    poiPanelState.selectPoi(poi);
    /*         poiController.loadPoiById(poi);
 */
  }

  List<PointOfInterest> searchPois(String query) {
    final q = query.trim().toLowerCase();
    final visiblePOIs = context.read<PoiThumbnailsState>().visible;

    return visiblePOIs.where((poi) {
      final nameMatch = poi.name.toLowerCase().contains(q);

      final categoryMatch = poi.categories.any(
        (c) => c.toLowerCase().contains(q),
      );

      return nameMatch || categoryMatch;
    }).toList();
  }

  Future<void> _centerSelectedPoiConsideringPanel() async {
    final poiState = context.read<PoiPanelState>();
    final poi = poiState.selected;
    if (poi == null || mapController == null) return;

    final size = MediaQuery.of(context).size;
    final panelHeight = 350;
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
      debugPrint("⚠️ Camera animation cancelled: $e");
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
    if (context.read<PoiPanelState>().isPanelOpen) {
      context.read<PoiPanelState>().closePanel();
    }
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
      debugPrint("❌ animateCamera failed: $e");
      debugPrint("📌 Stack trace: $stack");
    }

    updateUserLocationOnMap(pos);
    _requestUpdateScreenpositions(MapUpdateType.animationFinished);
  }

  Future<void> _waitForMapToSettle() async {
    await Future.delayed(Duration.zero); // microtask
    await Future.delayed(const Duration(milliseconds: 16)); // next frame
  }
}
