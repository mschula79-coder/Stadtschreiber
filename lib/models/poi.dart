import 'package:maplibre/maplibre.dart';
import '../models/article_entry.dart';

class PointOfInterest {
  final String name; // from OSM
  final Geographic location; // from OSM
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
      location: Geographic(
        lat: (row['lat'] as num).toDouble(),
        lon:(row['lon'] as num).toDouble(),
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
      'lat': location.lat,
      'lon': location.lon,
      'categories': categories,
      'featured_image_url': featuredImageUrl,
      'history': history,
      'articles': articles?.map((e) => e.toJson()).toList(),
    };
  }
}
