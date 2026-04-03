import 'package:maplibre/maplibre.dart';
import 'dart:math' as math;

Geographic parseWktPoint(String wkt) {
  // Beispiel: "SRID=4326;POINT(7.59 47.56)"
  final pointPart = wkt.split(';').last; // "POINT(7.59 47.56)"
  final coords = pointPart
      .replaceAll('POINT(', '')
      .replaceAll(')', '')
      .split(' ');

  final lon = double.parse(coords[0]);
  final lat = double.parse(coords[1]);

  return Geographic(lon: lon, lat: lat);
}

double metersPerPixel(double lat, double zoom) {
  return 156543.03392 * math.cos(lat * math.pi / 180) / math.pow(2, zoom);
}

double geoHitRadiusMeters({
  required double lat,
  required double zoom,
  double pixelRadius = 12.0,
}) {
  return pixelRadius * metersPerPixel(lat, zoom);
}

double geoDistanceMeters(Geographic a, Geographic b) {
  const R = 6371000.0;
  final dLat = (b.lat - a.lat) * math.pi / 180;
  final dLon = (b.lon - a.lon) * math.pi / 180;

  final lat1 = a.lat * math.pi / 180;
  final lat2 = b.lat * math.pi / 180;

  final h =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);

  return 2 * R * math.asin(math.sqrt(h));
}

double haversineDistanceMeters(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const R = 6371000.0;
  final dLat = (lat2 - lat1) * math.pi / 180.0;
  final dLon = (lon2 - lon1) * math.pi / 180.0;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180.0) *
          math.cos(lat2 * math.pi / 180.0) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return R * c;
}

Map<String, double> createViewbox(double lat, double lon, int meters) {
  // Breitengrad: 1° ≈ 110.540 km
  final dLat = meters / 110540.0;

  // Längengrad: 1° ≈ 111.320 km * cos(lat)
  final dLon = meters / (111320.0 * math.cos(lat * math.pi / 180));

  return {
    "left": lon - dLon,
    "right": lon + dLon,
    "top": lat + dLat,
    "bottom": lat - dLat,
  };
}
