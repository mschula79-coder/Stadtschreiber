import 'package:maplibre/maplibre.dart';

class District {
  final int id;
  final String name;
  final List<List<Geographic>> polygons; // MultiPolygon support

  District({required this.id, required this.name, required this.polygons});

  factory District.fromJson(Map<String, dynamic> json) {
    final geom = json['geom']; // GeoJSON from Supabase

    return District(
      id: json['id'],
      name: json['name'],
      polygons: (geom['coordinates'] as List)
          .map<List<Geographic>>(
            (poly) => (poly[0] as List)
                .map<Geographic>((c) => Geographic(lat: c[1], lon: c[0]))
                .toList(),
          )
          .toList(),
    );
  }

Feature<Polygon> toFeature() {
  final rings = <PositionSeries>[];

  for (final ring in polygons) {
    rings.add(_convertRing(ring));
  }

  return Feature<Polygon>(
    geometry: Polygon(rings),
    properties: {
      "id": id,
      "name": name,
    },
  );
}

  /// Convert a single ring into PositionSeries
  PositionSeries _convertRing(List<Geographic> ring) {
    final flat = <double>[];

    for (final p in ring) {
      flat.add(p.lon); // x
      flat.add(p.lat); // y
    }

    // Ensure polygon is closed
    if (ring.first.lat != ring.last.lat || ring.first.lon != ring.last.lon) {
      flat.add(ring.first.lon);
      flat.add(ring.first.lat);
    }

    return flat.positions(Coords.xy);
  }

  
}
