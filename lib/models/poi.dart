import 'package:maplibre_gl/maplibre_gl.dart';
import '../models/article_entry.dart';

class PointOfInterest {
  final String name; // from OSM
  final LatLng location; // from OSM
  final int id;
  final List<String> categories; // <-- NEU: mehrere Kategorien
  final String? featuredImageUrl; // own data
  final String? history; // own data
  final List<ArticleEntry>? articles;

  PointOfInterest({
    required this.id,
    required this.name,
    required this.location,
    required this.categories,
    this.featuredImageUrl,
    this.history,
    this.articles,
  });

  factory PointOfInterest.fromSupabase(Map<String, dynamic> row) {
    return PointOfInterest(
      id: row['id'],
      name: row['name'] ?? '',
      location: LatLng(
        (row['lat'] as num).toDouble(),
        (row['lon'] as num).toDouble(),
      ),
      categories: List<String>.from(row['categories'] ?? const []),
      featuredImageUrl: row['featured_image_url'],
      history: row['history'],
      articles: row['articles'] == null
          ? null
          : (row['articles'] as List<dynamic>)
                .map((e) => ArticleEntry.fromJson(e))
                .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'lat': location.latitude,
      'lon': location.longitude,
      'categories': categories,
      'featured_image_url': featuredImageUrl,
      'history': history,
      'articles': articles?.map((e) => e.toJson()).toList(),
    };
  }
}
