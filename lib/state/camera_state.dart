import 'package:maplibre/maplibre.dart';

class CameraState {
  final double lat;
  final double lon;
  final double zoom;

  const CameraState({
    required this.lat,
    required this.lon,
    required this.zoom,
  });

  Geographic getLocation () {
    return Geographic(lat: lat, lon:lon);  
  }
}
