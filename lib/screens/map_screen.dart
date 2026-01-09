import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import '../controllers/map_overlay_controller.dart';
import '../models/poi.dart';
import '../repositories/poi_repository.dart';
import '../services/map_style_service.dart';
import '../services/debug_service.dart';
import '../state/filter_state.dart';
import '../widgets/map_popup.dart';
import '../widgets/map_overlay_layer.dart';



class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapLibreMapController? mapController;
  final Completer<MapLibreMapController> _controllerCompleter = Completer();
  // TODO umstellen auf Completer
  final MapOverlayController _overlayController = MapOverlayController();
  final mapStyleService = MapStyleService();
  bool _isUpdating = false;
  bool _styleLoaded = false;
  final poiRepository = PoiRepository();
  Map<String, dynamic>? _baselParksGeojson;
  List<PointOfInterest> poiSelected = [];

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
    final filterState = context.read<FilterState>(); 
    final pois = await poiRepository.loadPois( 
      filterState.selectedValues.toList(), 
    );
    setState(() { 
      poiSelected = pois; 
    }); 
  }

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
              final geojson = _baselParksGeojson!;
              await mapController!.addSource(
                "baselparks",
                GeojsonSourceProperties(data: geojson),
              );
              await mapController!.addLayer(
                "baselparks",
                "baselparks-layer",
                LineLayerProperties(lineColor: "#00AA00", lineWidth: 2.0),
              );
              DebugService.log("Map style loaded.");
              await Future.delayed(const Duration(milliseconds: 300));
              _initialOverlayUpdate();
            },
            onCameraIdle: _initialOverlayUpdate,
/*             onMapClick: _onMapClick, */
          ),
        ),
        MapOverlayLayer(
          controller: _overlayController,
          poiSelected: poiSelected,
          onTapPoi: (poi) {
            MapPopup.show(
              context: context,
              name: poi.name,
              history: "No history available",
              leisure: "park",
              coords: poi.location,
            );
          },
        ),
      ],
    );
  }

  Future<String> loadStyleJson(String path) async {
    return await rootBundle.loadString(path);
  }

  Future<void> _initialOverlayUpdate() async {
    if (!_styleLoaded || mapController == null || poiSelected.isEmpty) return;

    await _overlayController.updatePositions(
      controller: mapController!,
      poiSelected: poiSelected,
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
    if (!_styleLoaded || mapController == null || poiSelected.isEmpty) return;
    if (_isUpdating) return;

    _isUpdating = true;

    await Future.delayed(const Duration(milliseconds: 16)); // ~60fps

    if (!mounted) return;

    await _overlayController.updatePositions(
      controller: mapController!,
      poiSelected: poiSelected,
    );

    if (mounted) setState(() {});

    _isUpdating = false;
  }
}
