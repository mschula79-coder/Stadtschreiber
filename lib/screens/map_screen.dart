import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre/maplibre.dart';
import 'package:provider/provider.dart';
import '../controllers/poi_thumbnails_controller.dart';
import '../controllers/poi_controller.dart';
import '../controllers/category_controller.dart';
import '../models/poi.dart';
import '../repositories/poi_repository.dart';
import '../state/app_state.dart';
import '../state/poi_panel_state.dart';
import '../state/pois_thumbnails_state.dart';
import '../state/categories_menu_state.dart';
import '../widgets/poi_thumbnails_layer.dart';
import '../widgets/map_actions.dart';
import '../widgets/poi_panel_persistent.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  MapController? mapController;
  final Completer<MapController> _controllerCompleter = Completer();
  // TODO umstellen auf Completer

  Future<void> reloadPois() => _loadPois();
  bool _isUpdating = false;
  bool _styleLoaded = false;
  bool _isCentering = false;
  Position? _lastCenteredPoi;
  bool _isChangingStyle = false;

  final poiRepository = PoiRepository();

  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CategoryController>().loadCategories();
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _loadPois();
    });
  }

  Future<void> _loadPois() async {
    final categoriesMenuState = context.read<CategoriesMenuState>();
    final poiThumbnailsState = context.read<PoiThumbnailsState>();
    final thumbnailsController = context.read<PoiThumbnailsController>();

    final pois = await poiRepository.loadPois(
      categoriesMenuState.selectedValues.toList(),
    );

    poiThumbnailsState.setAll(pois);

    if (mapController != null) {
      await thumbnailsController.updatePositions(
        controller: mapController!,
        visiblePOIs: poiThumbnailsState.visible,
      );
    }
  }

  Future<void> selectPoi(PointOfInterest poi) async {
    final poiController = context.read<PoiController>();
    final visiblePoiState = context.read<PoiThumbnailsState>();
    final thumbnailsController = context.read<PoiThumbnailsController>();
    final poiPanelState = context.read<PoiPanelState>();

    final fresh = await poiController.poiRepo.loadPoiById(poi.id);
    final realPoi = fresh ?? poi;

    visiblePoiState.add(realPoi);

    if (mapController != null) {
      await thumbnailsController.updatePositions(
        controller: mapController!,
        visiblePOIs: visiblePoiState.visible,
      );
    }
    poiPanelState.selectPoi(poi);
    /*     poiController.selectPoi(poi);
 */
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _idleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /*print("Screen size: ${MediaQuery.of(context).size}");*/
    context.watch<PoiThumbnailsState>();

    return Stack(
      children: [
        // MapLibreMap
        Listener(
          behavior: HitTestBehavior.opaque,
          onPointerMove: _onPointerMove,
          child: MapLibreMap(
            options: MapOptions(
              initCenter: Geographic(lon: 7.60132, lat: 47.57118),
              initZoom: 14,
              initStyle:
                  'https://stadtschreiber.duckdns.org/styles/basel-vintage/style.json',
            ),
            onMapCreated: (controller) async {
              mapController = controller;
              _controllerCompleter.complete(controller);
            },
            onEvent: (event) async {
              /* print("📡 MapEvent: ${event.runtimeType}");*/
              final visiblePOIs = context.read<PoiThumbnailsState>().visible;
              final thumbnailsController = context
                  .read<PoiThumbnailsController>();

              if (event case MapEventStyleLoaded()) {
                _styleLoaded = true;

                if (visiblePOIs.isNotEmpty) {
                  await thumbnailsController.updatePositions(
                    controller: mapController!,
                    visiblePOIs: visiblePOIs,
                  );
                }
              }
              if (event case MapEventCameraIdle()) {
                /* print(
                  "🧭 Camera center lat: ${mapController!.camera!.center.lat}, lon: ${mapController!.camera!.center.lon}",
                ); */

                if (!_isCentering) {
                  if (visiblePOIs.isNotEmpty) {
                    await thumbnailsController.updatePositions(
                      controller: mapController!,
                      visiblePOIs: visiblePOIs,
                    );
                  }
                }
                final zoom = mapController!.camera!.zoom;
                thumbnailsController.setZoom(zoom);
              }
            },
            /* children: const [
              MapControlButtons(showTrackLocation: true),
              MapScalebar(),
              SourceAttribution(),
            ], */
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
              },
            );
          },
        ),

        MapActions(onChangeStyle: changeStyle, onSelectPoi: selectPoi),
        // TODO Fix Thumbnail Centering after ontap and after selecting a searched poi; Fix PinMarker positioning
        Selector<PoiPanelState, (bool, PointOfInterest?)>(
          selector: (_, state) => (state.isPanelOpen, state.selected),
          builder: (_, tuple, _) {
            final (isPanelOpen, selectedPoi) = tuple;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (isPanelOpen && selectedPoi != null) {
                _centerPoiConsideringPanel();
              }
            });

            return isPanelOpen
                ? Align(
                    alignment: Alignment.bottomCenter,
                    child: PersistentPoiPanel(
                      isAdmin: context.read<AppState>().isAdmin,
                    ),
                  )
                : const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Future<String> loadStyleJson(String path) async {
    return await rootBundle.loadString(path);
  }

  Future<void> _centerPoiConsideringPanel() async {
    if (_isCentering) return;
    final poi = context.read<PoiPanelState>().selected;
    if (poi == null) return;
    if (_lastCenteredPoi == poi.location) return;
    _lastCenteredPoi = poi.location;
    _isCentering = true;

    /*     final panelHeight = MediaQuery.of(context).size.height * 0.35;
 */
    final panelHeight = 350;

    final double screenTop = mapController!
        .toLngLat(Offset(MediaQuery.of(context).size.width / 2, 0))
        .lat;
    final double screenBottom = mapController!
        .toLngLat(
          Offset(
            MediaQuery.of(context).size.width / 2,
            MediaQuery.of(context).size.height,
          ),
        )
        .lat;
    final double mapScreenBottom = mapController!
        .toLngLat(
          Offset(
            MediaQuery.of(context).size.width / 2,
            (MediaQuery.of(context).size.height + panelHeight) / 2,
          ),
        )
        .lat;
    final double distanceMapCentertoScreenCenter =
        (screenTop - mapScreenBottom) / 2 - (screenTop - screenBottom) / 2;

    await mapController!.animateCamera(
      center: Geographic(
        lat: poi.location.y + distanceMapCentertoScreenCenter,
        lon: poi.location.x,
      ),
      nativeDuration: const Duration(milliseconds: 200),
    );

    _isCentering = false;
  }

  void _onPointerMove(PointerMoveEvent event) async {
    final visiblePOIs = context.read<PoiThumbnailsState>().visible;
    final thumbnailsController = context.read<PoiThumbnailsController>();

    if (!_styleLoaded || mapController == null || visiblePOIs.isEmpty) return;
    if (_isUpdating) return;

    _isUpdating = true;

    await Future.delayed(const Duration(milliseconds: 16)); // ~60fps

    if (!mounted) return;

    await thumbnailsController.updatePositions(
      controller: mapController!,
      visiblePOIs: visiblePOIs,
    );

    _isUpdating = false;
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
  //TODO Fix searchresults by cutting of trailing spaces
  List<PointOfInterest> searchPois(String query) {
    final q = query.toLowerCase();
    final visiblePOIs = context.read<PoiThumbnailsState>().visible;

    return visiblePOIs.where((poi) {
      final nameMatch = poi.name.toLowerCase().contains(q);

      final categoryMatch = poi.categories.any(
        (c) => c.toLowerCase().contains(q),
      );

      return nameMatch || categoryMatch;
    }).toList();
  }
}
