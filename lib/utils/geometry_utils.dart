import 'dart:math';
import '../services/debug_service.dart';
import 'package:maplibre/maplibre.dart';
import '../models/district.dart';

List<List<double>> extractPolygonCoords(Map<String, dynamic> feature) {
  final geometry = feature['geometry'];
  final type = geometry['type'];
  final coords = geometry['coordinates'];

  // Handle Point geometry
  if (type == 'Point') {
    final lon = (coords[0] as num).toDouble();
    final lat = (coords[1] as num).toDouble();

    DebugService.log("Using Point geometry as center: $lon, $lat");

    // Return a single coordinate pair
    return [
      [lon, lat],
    ];
  }

  // Handle Polygon and MultiPolygon
  List<dynamic> ring;

  if (type == 'Polygon') {
    ring = coords[0];
  } else if (type == 'MultiPolygon') {
    ring = coords[0][0];
  } else {
    DebugService.log("Skipping unsupported geometry type: $type");
    return [];
  }

  return ring
      .map<List<double>>(
        (c) => [(c[0] as num).toDouble(), (c[1] as num).toDouble()],
      )
      .toList();
}

List<double> geoCentroid(List<List<double>> coords) {
  double x = 0, y = 0, z = 0;

  for (var c in coords) {
    double lon = c[0] * pi / 180;
    double lat = c[1] * pi / 180;

    x += cos(lat) * cos(lon);
    y += cos(lat) * sin(lon);
    z += sin(lat);
  }

  int total = coords.length;
  x /= total;
  y /= total;
  z /= total;

  double lon = atan2(y, x);
  double hyp = sqrt(x * x + y * y);
  double lat = atan2(z, hyp);

  return [lat * 180 / pi, lon * 180 / pi];
}

List<Feature<Polygon>> convertDistrictsToFeatures(List<District> districts) {
  return districts.map((d) => d.toFeature()).toList();
}

List<double> centroidOfRing(List<Geographic> ring) {
  double area = 0;
  double cx = 0;
  double cy = 0;

  for (int i = 0; i < ring.length - 1; i++) {
    final x0 = ring[i].lon;
    final y0 = ring[i].lat;
    final x1 = ring[i + 1].lon;
    final y1 = ring[i + 1].lat;

    final a = x0 * y1 - x1 * y0;
    area += a;
    cx += (x0 + x1) * a;
    cy += (y0 + y1) * a;
  }

  area *= 0.5;

  if (area == 0) {
    // fallback: average of points
    final avgLon = ring.map((p) => p.lon).reduce((a, b) => a + b) / ring.length;
    final avgLat = ring.map((p) => p.lat).reduce((a, b) => a + b) / ring.length;
    return [avgLat, avgLon];
  }

  cx /= (6 * area);
  cy /= (6 * area);

  return [cy, cx]; // [lat, lon]
}
List<double> centroidOfDistrict(District d) {
  final centroids = <List<double>>[];
  final areas = <double>[];

  for (final ring in d.polygons) {
    final c = centroidOfRing(ring);

    // Fläche berechnen (für Gewichtung)
    double area = 0;
    for (int i = 0; i < ring.length - 1; i++) {
      final x0 = ring[i].lon;
      final y0 = ring[i].lat;
      final x1 = ring[i + 1].lon;
      final y1 = ring[i + 1].lat;
      area += (x0 * y1 - x1 * y0);
    }
    area = area.abs() / 2;

    centroids.add(c);
    areas.add(area);
  }

  // Flächengewichteter Schwerpunkt
  double totalArea = areas.reduce((a, b) => a + b);

  double lat = 0;
  double lon = 0;

  for (int i = 0; i < centroids.length; i++) {
    lat += centroids[i][0] * areas[i];
    lon += centroids[i][1] * areas[i];
  }

  return [lat / totalArea, lon / totalArea];
}

