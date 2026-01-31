import 'package:maplibre/maplibre.dart';

class District {
  final int id;
  final String name;
  final List<List<Geographic>> polygons; // MultiPolygon support

  District({
    required this.id,
    required this.name,
    required this.polygons,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    final geom = json['geom']; // GeoJSON from Supabase

    return District(
      id: json['id'],
      name: json['name'],
      polygons: (geom['coordinates'] as List)
          .map((poly) => (poly[0] as List)
              .map((c) => Geographic(lat:c[1], lon:c[0])) // GeoJSON = [lng, lat]
              .toList())
          .toList(),
    );
  }
}
