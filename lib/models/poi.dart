import 'package:maplibre_gl/maplibre_gl.dart';

class PointOfInterest {
  final String name;        // from OSM
  final LatLng location;    // from OSM
  final String tags;        // from OSM

  final List<String> categories; // <-- NEU: mehrere Kategorien
  final String? photoUrl;        // own data
  final String? history;         // own data

  PointOfInterest({
    required this.name,
    required this.location,
    required this.tags,
    required this.categories,
    this.photoUrl,
    this.history,
  });

  factory PointOfInterest.fromSupabase(Map<String, dynamic> row) {
    return PointOfInterest(
      name: row['name'] ?? '',
      location: LatLng(
        (row['lat'] as num).toDouble(),
        (row['lon'] as num).toDouble(),
      ),
      tags: row['tags'] ?? '',
      categories: List<String>.from(row['categories'] ?? const []),
      photoUrl: row['photo_url'],
      history: row['history'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'lat': location.latitude,
      'lon': location.longitude,
      'tags': tags,
      'categories': categories,
      'photo_url': photoUrl,
      'history': history,
    };
  }
}
