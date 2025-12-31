/* import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print("BUILD CALLED");
    return MaterialApp(
      title: 'Stadtschreiber',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SimpleMapPage(),
    );
  }
}

class SimpleMapPage extends StatefulWidget {
  const SimpleMapPage({super.key});

  @override
  State<SimpleMapPage> createState() => _SimpleMapPageState();
}

class _SimpleMapPageState extends State<SimpleMapPage> {
  final Completer<MapLibreMapController> _controllerCompleter = Completer();

  bool _styleLoaded = false;

  List<Park> parks = [];

  
  late MapLibreMapController mapController;
  static const _initial = CameraPosition(target: LatLng(0, 0), zoom: 2);
  Timer? _idleTimer;
  Timer? _throttle;

  bool _updating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) { 
      loadParks(); 
    });
  }

  Future<void> loadParks() async {
    parks = await Future.wait([
      Park.create(
        "Schützenmattpark",
        "https://images.unsplash.com/photo-1501785888041-af3ef285b470",
      ),
      Park.create(
        "Kannenfeldpark",
        "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee",
      ),
      Park.create(
        "Erlenmattpark",
        "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee",
      ),
    ]);
    setState(() {});
  }

  final Map<String, Offset> _screenPositions = {};

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size; 
    final dpr = MediaQuery.of(context).devicePixelRatio;
    print("SCREEN WIDTH = ${size.width}, HEIGHT = ${size.height}");
    print("SCREEN: $size, DPR: $dpr");
    return Scaffold(
      appBar: AppBar(title: const Text('THIS IS BASEL')),
      body: Stack(
        children: [
          Positioned.fill(
            child:Listener(
              onPointerMove: (_) {
                _updateMarkerPositionsThrottled();
              },
              child: Offstage(
                offstage: false,
                child: MapLibreMap(
                  styleString:
                      "http://192.168.1.6:8080/styles/maptiler-basic/style.json",
                  initialCameraPosition: CameraPosition(
                    target: LatLng(47.571922, 7.60092),
                    zoom: 15.67,
                  ),
                  onMapCreated: (controller) async {
                    mapController = controller;
                    _controllerCompleter.complete(controller);
                    /* mapController.addListener(() {
                      _updateMarkerPositionsThrottled(); 
                    }); */
                  },
                  onStyleLoadedCallback: () async {
                    _styleLoaded = true;
                    await Future.delayed(const Duration(milliseconds: 300));
                    await _setupMap(mapController);
                  },
                  /* onCameraMove: (position) { 
                    _updateMarkerPositionsThrottled(); 
                  }, */
                  onMapIdle: () async { 
                    if (!_styleLoaded || parks.isEmpty) return; 
                    //final camera = await mapController.cameraPosition; 
                    //print("CAMERA TARGET = ${camera?.target.latitude}, ${camera?.target.longitude}");
                    _idleTimer?.cancel(); 
                    _idleTimer = Timer(const Duration(milliseconds: 300), () async { 
                    await Future.delayed(const Duration(milliseconds: 16));
                    if (!mounted) return; 
                    if (!_styleLoaded) return;
                    _updateMarkerPositions(); 
                    }); 
                  },  
                  onMapClick: _onMapClick,
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _toggleVisibility,
              child: Icon(Icons.visibility),
            ),
          ),
          ...parks.map((park) {
            final pos = _screenPositions[park.name];
            if (pos == null) return const SizedBox.shrink(); 
            const double thumbSize = 50; 
            return Positioned( 
              left: pos.dx - thumbSize/2, 
              top: pos.dy - thumbSize/2, 
/*               width: thumbSize, 
              height: thumbSize, 
 */              child: _buildThumbnail(park), 
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildThumbnail(Park park) {
    return GestureDetector(
      onTap: () {
        print("Tapped ${park.name}");
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height:50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              image: DecorationImage(
                image: NetworkImage(park.photoUrl),
                fit: BoxFit.cover,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxWidth: 120),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              park.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

 
  

  Future<void> _goHome() async {
    final c = await _controllerCompleter.future;
    await c.animateCamera(CameraUpdate.newCameraPosition(_initial));
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

  void _onMapClick(Point<double> point, LatLng coordinates) async {
    final features = await mapController.queryRenderedFeatures(
      point,
      ['baselparks-names'],
      ['all'],
    );

    if (features.isEmpty) return;

    final feature = features.first;

    // Extract properties from your GeoJSON

    final name = feature['properties']['name'] ?? 'Unknown';
    final history = feature['properties']['history'] ?? 'No history available';
    final leisure = feature['properties']['leisure'] ?? 'unknown';

    // Show popup
    _showPopup(name, history, leisure, coordinates);
  }

  void _showPopup(String name, String history, String leisure, LatLng coords) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text("Type: $leisure"),
              const SizedBox(height: 8),
              Text(history),
              const SizedBox(height: 16),
              Text(
                "Location: ${coords.latitude}, ${coords.longitude}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _visible = true;
  void _toggleVisibility() async {
    _visible = !_visible;
    await mapController.setLayerVisibility('baselparks-area', _visible);
  }

 
  Future<void> _updateMarkerPositions() async {
    if (_updating) return;
    _updating = true;
    try {
      final dpr = MediaQuery.of(context).devicePixelRatio; 
      final newPositions = <String, Offset>{};
 
      for (final park in parks) {
        final raw = await mapController.toScreenLocation(park.location);
        if (raw != null) { 
          final logical = Offset(raw.x / dpr, raw.y / dpr); 
          newPositions[park.name] = logical; 
        }
        print ("NewPositions §for ${park.name} = $newPositions");
        print("UPDATED POSITIONS: $_screenPositions");

      }

      setState(() {
        _screenPositions
          ..clear()
          ..addAll(newPositions);
      });
    } 
    catch (e, st) {
      print("ERROR in _updateMarkerPositions: $e");
      print(st);
    } 
    finally {
      _updating = false;
    }
  }

  void _updateMarkerPositionsThrottled() {
    if (_throttle?.isActive ?? false) return;

    _throttle = Timer(const Duration(milliseconds: 0), () {
      _updateMarkerPositions();
    });
}



}



 */ 