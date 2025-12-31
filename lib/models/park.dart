import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';


class Park {
  final String name;
  final LatLng location;
  final String photoUrl;

  Park._(this.name, this.location, this.photoUrl);

  static Future<Park> create(String name, String photoUrl) async {
    final center = await _getParkCentroid(name);
    final location = LatLng(center[0], center[1]);
    return Park._(name, location, photoUrl);
  }

  static Future<List<double>> _getParkCentroid(String parkName) async {
    final geojson = await loadGeoJson();
    final features = geojson['features'];

    final feature = features.firstWhere(
      (f) => f['properties']['name'] == parkName,
    );

    final polygon = extractPolygonCoords(feature);
    return geoCentroid(polygon);
  }
}

Future<Map<String, dynamic>> loadGeoJson() async {
  final response = await http.get(
    Uri.parse(
      'https://raw.githubusercontent.com/mschula79-coder/Stadtschreiber/main/baselparks.geojson',
    ),
  );
  return jsonDecode(response.body);
}

List<List<double>> extractPolygonCoords(Map<String, dynamic> feature) {
  final coords = feature['geometry']['coordinates'][0];
  return coords
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