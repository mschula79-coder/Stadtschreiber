import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import '../controllers/map_overlay_controller.dart';
import '../controllers/poi_controller.dart';

import '../models/poi.dart';
import '../repositories/poi_repository.dart';
import '../services/map_style_service.dart';
import '../services/debug_service.dart';
import '../state/app_state.dart';
import '../state/poi_state.dart';
import '../state/filter_state.dart';
// TODO Check if necessary: import '../widgets/map_popup.dart';
// TODO Center map when opening poi panel
import '../widgets/map_overlay_layer.dart';
import '../widgets/map_actions.dart';
import '../widgets/poi_panel_persistent.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  MapLibreMapController? mapController;
  final Completer<MapLibreMapController> _controllerCompleter = Completer();
  // TODO umstellen auf Completer
  final MapOverlayController _overlayController = MapOverlayController();
  final mapStyleService = MapStyleService();
  bool _isUpdating = false;
  bool _styleLoaded = false;
  bool _isReloadingPois = false;

  final poiRepository = PoiRepository();
  List<PointOfInterest> visiblePOIs = [];

  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _loadPois();
      setState(() {});
      _initialOverlayUpdate();
    });
  }

  Future<void> _loadPois() async {
    _isReloadingPois = true;

    final filterState = context.read<FilterState>();
    final pois = await poiRepository.loadPois(
      filterState.selectedValues.toList(),
    );

    setState(() {
      visiblePOIs = pois;
    });

    _isReloadingPois = false;

    if (_styleLoaded && mapController != null) {
      await _initialOverlayUpdate();
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
    return Stack(
      children: [
        // MapLibreMap
        Listener(
          behavior: HitTestBehavior.opaque,
          onPointerMove: _onPointerMove,
          child: MapLibreMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(47.571922, 7.60092),
              zoom: 14.67,
            ),
            onMapCreated: (controller) async {
              mapController = controller; // keep this if you need it later
              _controllerCompleter.complete(controller);
              await mapController!.setStyle(
                "http://192.168.1.6:9000/style.json",
              );
            },
            onStyleLoadedCallback: () async {
              _styleLoaded = true;
              DebugService.log("Map style loaded.");
              await Future.delayed(const Duration(milliseconds: 300));
              _initialOverlayUpdate();
            },
            onCameraIdle: _initialOverlayUpdate,
          ),
        ),
        MapOverlayLayer(
          controller: _overlayController,
          visiblePOIs: visiblePOIs,
          onTapPoi: (poi) {
            context.read<PoiController>().selectPoi(poi);
            context.read<PoiState>().selectPoi(poi);
          },
        ),
        const MapActions(),

        Consumer<PoiState>(
          builder: (_, state, _) {
            return state.isPanelOpen
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

  Future<void> _initialOverlayUpdate() async {
    if (_isReloadingPois) return; // <-- block early calls
    if (!_styleLoaded || mapController == null || visiblePOIs.isEmpty) return;

    await _overlayController.updatePositions(
      controller: mapController!,
      visiblePOIs: visiblePOIs,
    );

    if (mounted) setState(() {});
  }

  /* void _onMapClick(Point<double> point, LatLng coordinates) async {
    if (mapController == null) return;

    final features = await mapController!.queryRenderedFeatures(
      point,
      ['baselparks-names'],
      ['all'],
    );

    if (features.isEmpty) return;
  } */

  void _onPointerMove(PointerMoveEvent event) async {
    if (!_styleLoaded || mapController == null || visiblePOIs.isEmpty) return;
    if (_isUpdating) return;

    _isUpdating = true;

    await Future.delayed(const Duration(milliseconds: 16)); // ~60fps

    if (!mounted) return;

    await _overlayController.updatePositions(
      controller: mapController!,
      visiblePOIs: visiblePOIs,
    );

    if (mounted) setState(() {});

    _isUpdating = false;
  }
}
