import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../controllers/map_overlay_controller.dart';
import '../widgets/map_overlay_layer.dart';
import '../models/park.dart';
import '../repositories/poi_repository.dart';
import '../widgets/map_popup.dart';
import '../services/map_style_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapLibreMapController? mapController;
  final Completer<MapLibreMapController> _controllerCompleter = Completer();
  final MapOverlayController _overlayController = MapOverlayController();
  final mapStyleService = MapStyleService();
  bool _isUpdating = false;
  bool _styleLoaded = false;
  final poiRepository = PoiRepository();
  List<Park> parks = [];

  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      parks = await poiRepository.loadParks();
      setState(() {});
      _initialOverlayUpdate();
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
            styleString:
                "http://192.168.1.6:8080/styles/maptiler-basic/style.json?v=2",
            initialCameraPosition: const CameraPosition(
              target: LatLng(47.571922, 7.60092),
              zoom: 15.67,
            ),
            onMapCreated: (controller) async {
              mapController = controller;
              _controllerCompleter.complete(controller);
            },
            onStyleLoadedCallback: () async {
              _styleLoaded = true;
              await Future.delayed(const Duration(milliseconds: 300));
              await _setupMap(mapController!);
              _initialOverlayUpdate();
            },
            onCameraIdle: _initialOverlayUpdate,
            onMapClick: _onMapClick,
          ),
        ),
        MapOverlayLayer(
          controller: _overlayController,
          parks: parks,
          onTapPark: (park) {
            MapPopup.show(
              context: context,
              name: park.name,
              history: "No history available",
              leisure: "park",
              coords: park.location,
            );
          },
        ),
      ],
    );
  }

  Future<void> _setupMap(MapLibreMapController controller) async {
    final parkBytes = await rootBundle.load('assets/icon_nature_people.png');
    await controller.addImage('park-icon', parkBytes.buffer.asUint8List());

    final playgroundBytes = await rootBundle.load('assets/icon_playground.png');
    await controller.addImage(
      'playground-icon',
      playgroundBytes.buffer.asUint8List(),
    );

    final forestBytes = await rootBundle.load('assets/icon_forest.png');
    await controller.addImage('forest-icon', forestBytes.buffer.asUint8List());
  }

  Future<void> _initialOverlayUpdate() async {
    if (!_styleLoaded || mapController == null || parks.isEmpty) return;

    await _overlayController.updatePositions(
      controller: mapController!,
      parks: parks,
    );

    if (mounted) setState(() {});
  }

  void _onMapClick(Point<double> point, LatLng coordinates) async {
    if (mapController == null) return;

    final features = await mapController!.queryRenderedFeatures(
      point,
      ['baselparks-names'],
      ['all'],
    );

    if (features.isEmpty) return;
  }

  void _onPointerMove(PointerMoveEvent event) async {
    if (!_styleLoaded || mapController == null || parks.isEmpty) return;
    if (_isUpdating) return;

    _isUpdating = true;

    await Future.delayed(const Duration(milliseconds: 16)); // ~60fps

    if (!mounted) return;

    await _overlayController.updatePositions(
      controller: mapController!,
      parks: parks,
    );

    if (mounted) setState(() {});

    _isUpdating = false;
  }
}
