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
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/debug_service.dart';

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
  Map<String, dynamic>? _baselParksGeojson;
  List<Park> parks = [];

  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _loadData();
      setState(() {});
      _initialOverlayUpdate();
    });
  }

  Future<void> _loadData() async {
    _baselParksGeojson = await loadGeoJson();
    parks = await poiRepository.loadParksFromGeojson(_baselParksGeojson!);
  }

  Future<Map<String, dynamic>> loadGeoJson() async {
    final response = await http.get(
      Uri.parse('http://192.168.1.6:9000/baselparks.geojson'),
    );
    return jsonDecode(response.body);
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

  Future<String> loadStyleJson(String path) async {
    return await rootBundle.loadString(path);
  }

  Future<void> _setupMap(MapLibreMapController controller) async {
    final parkBytes = await rootBundle.load(
      'assets/icons/icon_nature_people.png',
    );
    await controller.addImage('park-icon', parkBytes.buffer.asUint8List());

    final playgroundBytes = await rootBundle.load(
      'assets/icons/icon_playground.png',
    );
    await controller.addImage(
      'playground-icon',
      playgroundBytes.buffer.asUint8List(),
    );

    final forestBytes = await rootBundle.load('assets/icons/icon_forest.png');
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
