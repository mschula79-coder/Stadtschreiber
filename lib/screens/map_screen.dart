// ignore_for_file: avoid_print
// TODO Hide Thumbnails when Zoomed Out

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre/maplibre.dart';
import 'package:provider/provider.dart';
import '../controllers/map_poi_overlay_controller.dart';
import '../controllers/poi_controller.dart';
import '../models/poi.dart';
import '../repositories/poi_repository.dart';
import '../state/app_state.dart';
import '../state/poi_state.dart';
import '../state/filter_state.dart';
import '../widgets/map_poi_overlay_layer.dart';
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
  final MapPoiOverlayController _poiOverlayController =
      MapPoiOverlayController();
  bool _isUpdating = false;
  bool _styleLoaded = false;
  bool _isCentering = false;
  Position? _lastCenteredPoi;
  bool _isChangingStyle = false;

  final poiRepository = PoiRepository();
  List<PointOfInterest> visiblePOIs = [];

  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _loadPois();
    });
  }

  Future<void> _loadPois() async {
    final filterState = context.read<FilterState>();
    final pois = await poiRepository.loadPois(
      filterState.selectedValues.toList(),
    );

    setState(() {
      visiblePOIs = pois;
    });

    if (_styleLoaded && mapController != null) {
      await _poiOverlayController.updatePositions(
        controller: mapController!,
        visiblePOIs: visiblePOIs,
      );
    }
  }

  Future<void> reloadPois() => _loadPois();

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _idleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
/*     print("Screen size: ${MediaQuery.of(context).size}");
 */
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
              /*               print("🟦 Map created, initStyle called");
 */
            },
            onEvent: (event) async {
/*               print("📡 MapEvent: ${event.runtimeType}");
 */
              if (event case MapEventStyleLoaded()) {
                _styleLoaded = true;

                if (visiblePOIs.isNotEmpty) {
                  await _poiOverlayController.updatePositions(
                    controller: mapController!,
                    visiblePOIs: visiblePOIs,
                  );
                  if (mounted) setState(() {});
                }
              }
              if (event case MapEventCameraIdle()) {
                print(
                  "🧭 Camera center lat: ${mapController!.camera!.center.lat}, lon: ${mapController!.camera!.center.lon}",
                );

                /*                 print("🟨 Camera idle");
 */
                if (!_isCentering) {
                  if (visiblePOIs.isNotEmpty) {
                    await _poiOverlayController.updatePositions(
                      controller: mapController!,
                      visiblePOIs: visiblePOIs,
                    );
                    if (mounted) setState(() {});
                  }
                }
              }
            },
            /* children: const [
              MapControlButtons(showTrackLocation: true),
              MapScalebar(),
              SourceAttribution(),
            ], */
          ),
        ),
        MapPoiOverlayLayer(
          controller: _poiOverlayController,
          visiblePOIs: visiblePOIs,
          onTapPoi: (poi) {
            final state = context.read<PoiState>();
            state.selectPoi(poi); 
            context.read<PoiController>().selectPoi(poi); 
          },
        ),
        MapActions(onChangeStyle: () => changeStyle()),
        // TODO Fix Thumbnail Centering 
        Selector<PoiState, (bool, PointOfInterest?)>(
          selector: (_, state) => (state.isPanelOpen, state.selected),
          builder: (_, tuple, _) {
            final (isPanelOpen, selectedPoi) = tuple;
            print("Panel open: $isPanelOpen, Selected POI: $selectedPoi");
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
    final poi = context.read<PoiState>().selected;
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
    if (!_styleLoaded || mapController == null || visiblePOIs.isEmpty) return;
    if (_isUpdating) return;

    _isUpdating = true;

    await Future.delayed(const Duration(milliseconds: 16)); // ~60fps

    if (!mounted) return;

    await _poiOverlayController.updatePositions(
      controller: mapController!,
      visiblePOIs: visiblePOIs,
    );

    if (mounted) setState(() {});

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

  List<PointOfInterest> searchPois(String query) {
    final q = query.toLowerCase();

    return visiblePOIs.where((poi) {
      final nameMatch = poi.name.toLowerCase().contains(q);

      final categoryMatch = poi.categories.any(
        (c) => c.toLowerCase().contains(q),
      );

      return nameMatch || categoryMatch;
    }).toList();
  }
}


// Suchfelder 

/* TextField(
  decoration: InputDecoration(
    hintText: "POI suchen…",
    prefixIcon: Icon(Icons.search),
  ),
  onChanged: (value) {
    final results = searchPois(value);
    setState(() => searchResults = results);
  },
)

ListView.builder(
  itemCount: searchResults.length,
  itemBuilder: (_, i) {
    final poi = searchResults[i];
    return ListTile(
      title: Text(poi.name),
      subtitle: Text(poi.category),
      onTap: () {
        context.read<PoiState>().selectPoi(poi);
        context.read<PoiController>().selectPoi(poi);

        // Panel öffnen
        context.read<PoiState>().openPanel();

        // Karte zentrieren
        _centerPoiConsideringPanel();
      },
    );
  },
)

Future<void> goToPoi(PointOfInterest poi) async {
  await mapController!.animateCamera(
    CameraUpdate.newLatLng(poi.location),
    duration: const Duration(milliseconds: 1200),
  );

  await mapController!.animateCamera(
    CameraUpdate.scrollBy(0, panelHeight),
    duration: const Duration(milliseconds: 1200),
  );
} */
