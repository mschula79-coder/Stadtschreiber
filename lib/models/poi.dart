import 'package:maplibre/maplibre.dart';
import '../models/article_entry.dart';
import '../models/poi_metadata.dart';

class PointOfInterest {
  final String name; // from OSM
  final Geographic location; // from OSM
  final int id;
  final List<String> categories; // <-- NEU: mehrere Kategorien
  final String? featuredImageUrl; // own data
  final String? history; // own data
  final List<ArticleEntry> articles;
  final PoiMetadata metadata;
  final double? distance;
  final String? street;
  final String? houseNumber;
  final String? postcode;
  final String? city;
  final String? district;
  final String? country;
  final String? displayAddress;
  final String? description;

  PointOfInterest({
    required this.id,
    required this.name,
    required this.location,
    required this.categories,
    this.featuredImageUrl,
    this.history,
    required this.articles,
    required this.metadata,
    this.distance,
    this.street,
    this.houseNumber,
    this.postcode,
    this.city,
    this.district,
    this.country,
    this.displayAddress,
    this.description,
  });

  factory PointOfInterest.fromSupabase(Map<String, dynamic> row) {
    return PointOfInterest(
      id: row['id'],
      name: row['name'] ?? '',
      location: Geographic(
        lat: (row['lat'] as num).toDouble(),
        lon: (row['lon'] as num).toDouble(),
      ),
      categories: List<String>.from(row['categories'] ?? const []),
      featuredImageUrl: row['featured_image_url'],
      history: row['history'],
      articles: (row['articles'] as List<dynamic>)
          .map((e) => ArticleEntry.fromJson(e))
          .toList(),
      metadata: PoiMetadata(
        links: row['metadata']['links'] != null
            ? Map<String, String>.from(row['metadata']['links'])
            : null,
        features: row['metadata']['features'] != null
            ? Map<String, bool>.from(row['metadata']['features'])
            : null,
        attributes: row['metadata']['attributes'] != null
            ? Map<String, dynamic>.from(row['metadata']['attributes'])
            : null,
        tags: row['metadata']['tags'] != null
            ? List<String>.from(row['metadata']['tags'])
            : null,
      ),
      distance: (() {
        final raw = row['distance'];
        return (raw is num)
            ? raw.toDouble()
            : double.tryParse(raw.toString()) ?? 0.0;
      })(),
      street: row['street'] as String?,
      houseNumber: row['house_number'] as String?,
      postcode: row['postcode'] as String?,
      city: row['city'] as String?,
      district: row['district'] as String?,
      country: row['country'] as String?,
      displayAddress: row['display_address'] as String?,
      description: row['description']
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
      'articles': articles.map((e) => e.toJson()).toList(),
      'distance': distance,
      'street': street,
      'house_number': houseNumber,
      'postcode': postcode,
      'city': city,
      'district': district,
      'country': country,
      'display_address': displayAddress,
      'description': description
    };
  }

  @override
  String toString() {
    return 'POI(id: $id, name: $name, lat: $location, distance: $distance)';
  }
}
