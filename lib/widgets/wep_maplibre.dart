/* import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as gl;
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/services/map_controller.dart';

class WebMapLibreWidget extends StatefulWidget {
  final void Function(StadtschreiberMapController) onMapReady;

  const WebMapLibreWidget({super.key, required this.onMapReady});

  @override
  State<WebMapLibreWidget> createState() => _WebMapLibreWidgetState();
}

class _WebMapLibreWidgetState extends State<WebMapLibreWidget>
    implements StadtschreiberMapController {
  gl.MapLibreMapController? _controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: gl.MapLibreMap(
        styleString: 'https://demotiles.maplibre.org/style.json',
        initialCameraPosition: const gl.CameraPosition(
          target: gl.LatLng(47.5596, 7.5886),
          zoom: 14,
        ),
        onMapCreated: (c) {
          _controller = c;
          widget.onMapReady(this);
        },
      ),
    );
  }

  // --- StadtschreiberMapController Implementierung ---

  @override
  Future<void> moveTo({
    required double lat,
    required double lon,
    double? zoom,
  }) async {
    if (_controller == null) return;
    await _controller!.animateCamera(
      gl.CameraUpdate.newCameraPosition(
        gl.CameraPosition(
          target: gl.LatLng(lat, lon),
          zoom: zoom ?? _controller!.cameraPosition!.zoom,
        ),
      ),
    );
  }

  @override
  Future<void> setZoom(double zoom) async {
    if (_controller == null) return;
    await _controller!.animateCamera(
      gl.CameraUpdate.newCameraPosition(
        gl.CameraPosition(
          target: _controller!.cameraPosition!.target,
          zoom: zoom,
        ),
      ),
    );
  }

  @override
  Future<void> addPoiMarker(PointOfInterest poi) async {
    if (_controller == null) return;
    await _controller!.addSymbol(
      gl.SymbolOptions(
        geometry: gl.LatLng(poi.location.lat, poi.location.lon),
        iconImage: 'marker-15', // oder eigener Sprite
        textField: poi.name,
        textOffset: const Offset(0, 1.2),
      ),
    );
  }

  @override
  Future<void> clearMarkers() async {
    if (_controller == null) return;
    final symbols = _controller!.symbols;
    for (final s in symbols) {
      await _controller!.removeSymbol(s);
    }
  }
}
 */