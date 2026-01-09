import 'dart:math';
import '../services/debug_service.dart';


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
      [lon, lat]
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
