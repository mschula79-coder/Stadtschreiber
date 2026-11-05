import 'package:maplibre/maplibre.dart';
import 'package:stadtschreiber/models/address.dart';
import 'package:stadtschreiber/models/history_entry.dart';
import 'package:stadtschreiber/models/image_entry.dart';
import 'dart:convert';
import '../models/article_entry.dart';
import '../models/poi_metadata.dart';

class PointOfInterest {
  final String name;
  Geographic location;
  String id;
  final List<String>? categories;
  final String? featuredImageUrl;
  final List<HistoryEntry> historyEntries;
  final List<ArticleEntry> articles;
  final PoiMetadata metadata;
  final double? distance;
  final Address? address;
  final String? description;
  Map<String, dynamic>? geomArea;
  String geometryType; // 'point' | 'linestring' | 'polygon' | 'multipolygon',
  final int? osmId;
  final String? osmKey;
  final String? osmValue;

  bool newPoi = false;
  final List<ImageEntry> images;

  PointOfInterest({
    required this.id,
    required this.name,
    required this.location,
    required this.categories,
    this.featuredImageUrl,
    required this.historyEntries,
    required this.articles,
    required this.metadata,
    this.distance,
    this.address,
    this.description,
    this.geomArea,
    this.geometryType = 'point',
    this.osmId,
    this.osmKey,
    this.osmValue,
    required newPoi,
    required this.images,
  });

  factory PointOfInterest.fromSupabase(Map<String, dynamic> row) {
    final id = row['id']?.toString();

    if (id == null || id.isEmpty) {
      throw const FormatException('Der POI besitzt keine gültige ID.');
    }

    final latitude = row['lat'] as num?;
    final longitude = row['lon'] as num?;

    if (latitude == null || longitude == null) {
      throw FormatException('Der POI $id besitzt keine gültigen Koordinaten.');
    }

    final historyRaw = row['history'];
    final articlesRaw = row['articles'];
    final metadataRaw = row['metadata'];
    final imagesRaw = row['images'];
    final geomAreaRaw = row['geom_area'];

    final historyEntries = historyRaw is List
        ? historyRaw
              .whereType<Map>()
              .map(
                (entry) =>
                    HistoryEntry.fromJson(Map<String, dynamic>.from(entry)),
              )
              .toList()
        : <HistoryEntry>[];

    historyEntries.sort((first, second) {
      return first.start.compareTo(second.start);
    });

    final articles = articlesRaw is List
        ? articlesRaw
              .whereType<Map>()
              .map(
                (entry) =>
                    ArticleEntry.fromJson(Map<String, dynamic>.from(entry)),
              )
              .toList()
        : <ArticleEntry>[];

    final metadata = metadataRaw is Map
        ? Map<String, dynamic>.from(metadataRaw)
        : <String, dynamic>{};

    final linksRaw = metadata['links'];
    final featuresRaw = metadata['features'];
    final attributesRaw = metadata['attributes'];
    final tagsRaw = metadata['tags'];

    final geomArea = geomAreaRaw is Map
        ? Map<String, dynamic>.from(geomAreaRaw)
        : null;

    final images = imagesRaw is List
        ? imagesRaw
              .whereType<Map>()
              .map(
                (entry) =>
                    ImageEntry.fromJson(Map<String, dynamic>.from(entry)),
              )
              .toList()
        : <ImageEntry>[];

    final distanceRaw = row['distance'];

    final distance = distanceRaw is num
        ? distanceRaw.toDouble()
        : double.tryParse(distanceRaw?.toString() ?? '') ?? 0.0;

    final osmIdRaw = row['osm_id'];

    return PointOfInterest(
      id: id,
      name: row['name']?.toString() ?? '',
      location: Geographic(lon: longitude.toDouble(), lat: latitude.toDouble()),
      categories: List<String>.from(
        row['categories'] as List? ?? const <dynamic>[],
      ),
      featuredImageUrl: row['featured_image_url']?.toString() ?? '',
      historyEntries: historyEntries,
      articles: articles,
      metadata: PoiMetadata(
        links: linksRaw is Map ? Map<String, String>.from(linksRaw) : null,
        features: featuresRaw is Map
            ? Map<String, bool>.from(featuresRaw)
            : null,
        attributes: attributesRaw is Map
            ? Map<String, dynamic>.from(attributesRaw)
            : null,
        tags: tagsRaw is List ? List<String>.from(tagsRaw) : null,
      ),
      distance: distance,
      address: Address(
        street: row['street']?.toString(),
        houseNumber: row['house_number']?.toString(),
        postcode: row['postcode']?.toString(),
        city: row['city']?.toString(),
        district: row['district']?.toString(),
        country: row['country']?.toString(),
      ),
      description: row['description']?.toString(),
      geomArea: geomArea,
      geometryType:
          row['geom_type']?.toString().toLowerCase() ??
          geomArea?['type']?.toString().toLowerCase() ??
          'point',
      osmId: osmIdRaw is num
          ? osmIdRaw.toInt()
          : int.tryParse(osmIdRaw?.toString() ?? ''),
      osmKey: row['osm_key']?.toString(),
      osmValue: row['osm_value']?.toString(),
      newPoi: false,
      images: images,
    );
  }

  PointOfInterest copyWith({
    String? id,
    String? name,
    Geographic? location,
    List<String>? categories,
    String? featuredImageUrl,
    bool? clearFeaturedImage,
    List<HistoryEntry>? historyEntries,
    List<ArticleEntry>? articles,
    PoiMetadata? metadata,
    Address? address,
    double? distance,
    String? description,
    Map<String, dynamic>? geomArea,
    String? geometryType,
    int? osmId,
    bool? newPoi,
    bool? hasUnsavedChanges,
    List<ImageEntry>? images,
  }) {
    if (geometryType == 'polygon') {
      closePolygonIfNeeded();
    }

    // DEBUG NEW ADDRESS CODE

    final newAddress = Address(
      street: address?.street ?? this.address?.street,
      houseNumber: address?.houseNumber ?? this.address?.houseNumber,
      postcode: address?.postcode ?? this.address?.postcode,
      city: address?.city ?? this.address?.city,
      district: address?.district ?? this.address?.district,
      country: address?.country ?? this.address?.country,
    );

    final newFeatured = clearFeaturedImage == true
        ? null
        : (featuredImageUrl ?? this.featuredImageUrl);

    final sortedHistory = (historyEntries ?? this.historyEntries).toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    return PointOfInterest(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      categories:
          categories ??
          (this.categories != null ? List.from(this.categories!) : null),
      featuredImageUrl: newFeatured,
      historyEntries: sortedHistory,
      articles: articles ?? List<ArticleEntry>.from(this.articles),
      metadata: metadata ?? this.metadata,
      distance: distance ?? this.distance,
      address: newAddress,
      description: description ?? this.description,
      geomArea:
          geomArea ??
          (this.geomArea != null
              ? Map<String, dynamic>.from(this.geomArea!)
              : null),
      geometryType: geometryType ?? this.geometryType,
      osmId: osmId ?? this.osmId,
      osmKey: osmKey,
      osmValue: osmValue,
      newPoi: newPoi ?? this.newPoi,
      images: images ?? this.images,
    );
  }

  /// Creates map from POI values
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'lat': location.lat,
      'lon': location.lon,
      'categories': categories,
      'featured_image_url': featuredImageUrl,
      'history': historyEntries.map((e) => e.toJson()).toList(),
      'articles': articles.map((e) => e.toJson()).toList(),
      'street': address?.street,
      'house_number': address?.houseNumber,
      'postcode': address?.postcode,
      'city': address?.city,
      'district': address?.district,
      'country': address?.country,
      'description': description,
      'geom_area': geomArea,
      'osm_id': osmId,
      'osm_key': osmKey,
      'osm_value': osmValue,
      'images': images.map((e) => e.toJson()).toList(),
    };
  }

  Map<String, dynamic> toMapNewPoi() {
    final insertMap = toMap()..remove('id');
    return insertMap;
  }

  List<Geographic>? getPoints() {
    if (geomArea == null) return null;
    final type = (geomArea!['type'] as String).toLowerCase();
    final coords = geomArea!['coordinates'];

    switch (type) {
      case 'point':
        return [
          Geographic(lat: coords[1].toDouble(), lon: coords[0].toDouble()),
        ];

      case 'linestring':
        return (coords as List)
            .map((c) => Geographic(lat: c[1].toDouble(), lon: c[0].toDouble()))
            .toList();

      case 'polygon':
        final ring = coords[0] as List;
        return ring
            .map((c) => Geographic(lat: c[1].toDouble(), lon: c[0].toDouble()))
            .toList();

      case 'multipolygon':
        return (coords as List)
            .expand(
              (poly) => (poly[0] as List).map(
                (c) => Geographic(lat: c[1].toDouble(), lon: c[0].toDouble()),
              ),
            )
            .toList();

      default:
        return null;
    }
  }

  void setPoints(List<Geographic> points) {
    //if (geomArea == null) {
    //  throw Exception("Cannot set points because geomArea is null.");
    //}

    switch (geometryType) {
      case 'point':
        geomArea = {
          "type": "Point",
          "coordinates": [points.first.lon, points.first.lat],
        };
        break;

      case 'linestring':
        geomArea = {
          "type": "LineString",
          "coordinates": points.map((p) => [p.lon, p.lat]).toList(),
        };
        break;

      case 'polygon':
        geomArea = {
          "type": "Polygon",
          "coordinates": [
            points.map((p) => [p.lon, p.lat]).toList(),
          ],
        };
        break;

      case 'multipolygon':
        geomArea = {
          "type": "MultiPolygon",
          "coordinates": [
            [
              points.map((p) => [p.lon, p.lat]).toList(),
            ],
          ],
        };
        break;

      default:
        throw Exception("Unsupported geometry type: $geometryType");
    }
  }

  void addPoint(Geographic p) {
    final pts = getPoints();
    if (pts == null) return;

    pts.add(p);
    setPoints(pts);
  }

  void removePointAt(int index) {
    final pts = getPoints();
    if (pts == null) return;
    if (index < 0 || index >= pts.length) return;
    pts.removeAt(index);
    setPoints(pts);
  }

  @override
  String toString() {
    return 'POI(id: $id, name: $name, location: $location, category: $categories)';
  }

  String getGeoJsonGeometry() {
    final points = getPoints();

    if (points == null || points.isEmpty) {
      return '{"type":"FeatureCollection","features":[]}';
    }

    if (!isGeometryValid()) {
      return '{"type":"FeatureCollection","features":[]}';
    }

    return jsonEncode({"type": "Feature", "geometry": geomArea});
  }

  String? getPointsGeoJson() {
    final points = getPoints();
    if (points == null) return null;
    return jsonEncode({
      "type": "FeatureCollection",
      "features": points.map((p) {
        return {
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [p.lon, p.lat],
          },
        };
      }).toList(),
    });
  }

  void insertPointIntoPolygon(List<Geographic> pts, Geographic newPoint) {
    if (pts.length < 2) {
      pts.add(newPoint);
      return;
    }

    // Falls geschlossen → letzten Punkt entfernen
    if (pts.first.lat == pts.last.lat && pts.first.lon == pts.last.lon) {
      pts.removeLast();
    }

    int bestIndex = 0;
    double bestDistance = double.infinity;

    for (int i = 0; i < pts.length; i++) {
      final a = pts[i];
      final b = pts[(i + 1) % pts.length];

      final dist = _distancePointToSegment(newPoint, a, b);
      if (dist < bestDistance) {
        bestDistance = dist;
        bestIndex = i + 1;
      }
    }

    pts.insert(bestIndex, newPoint);

    // Polygon wieder schließen
    pts.add(pts.first);
  }

  double _distancePointToSegment(Geographic p, Geographic a, Geographic b) {
    final px = p.lon;
    final py = p.lat;
    final ax = a.lon;
    final ay = a.lat;
    final bx = b.lon;
    final by = b.lat;

    final dx = bx - ax;
    final dy = by - ay;

    if (dx == 0 && dy == 0) {
      return ((px - ax) * (px - ax) + (py - ay) * (py - ay)).abs();
    }

    final t = ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy);

    if (t < 0) {
      return ((px - ax) * (px - ax) + (py - ay) * (py - ay)).abs();
    } else if (t > 1) {
      return ((px - bx) * (px - bx) + (py - by) * (py - by)).abs();
    }

    final projX = ax + t * dx;
    final projY = ay + t * dy;

    return ((px - projX) * (px - projX) + (py - projY) * (py - projY)).abs();
  }

  factory PointOfInterest.fromOSM(Map<String, dynamic> json) {
    final tags = json['tags'] ?? {};

    // Koordinaten:
    // - Nodes haben lat/lon direkt
    // - Ways/Relations haben center.lat / center.lon
    final lat = json['lat'] ?? json['center']?['lat'];
    final lon = json['lon'] ?? json['center']?['lon'];

    return PointOfInterest(
      id: '-1',
      name: tags['name'] ?? 'Unbenannt',
      featuredImageUrl: '',
      location: Geographic(lat: lat?.toDouble(), lon: lon?.toDouble()),

      // Kategorien aus OSM-Tags ableiten
      categories: [
        tags['amenity'],
        tags['shop'],
        tags['tourism'],
        tags['historic'],
        tags['leisure'],
        tags['building'],
        tags['place'],
        tags['highway'],
      ].whereType<String>().toList(),
      historyEntries: [],
      articles: [],
      metadata: PoiMetadata(attributes: json),

      // Adressfelder (falls vorhanden)
      address: Address(
        street: tags['addr:street'],
        houseNumber: tags['addr:housenumber'],
        postcode: tags['addr:postcode'],
        city: tags['addr:city'],
        district: tags['addr:suburb'],
        country: tags['addr:country'],
      ),
      osmId: json['id'],
      newPoi: true,
      images: [],
    );
  }
}

extension PoiGeometryValidation on PointOfInterest {
  bool isGeometryValid() {
    final points = getPoints();
    if (points == null) return false;

    switch (geometryType.toLowerCase()) {
      case 'point':
        return points.length == 1;

      case 'linestring':
        return points.length >= 2;

      case 'polygon':
        return points.length >= 3;

      case 'multipolygon':
        // Minimal: ein Polygon mit >= 3 Punkten
        return points.length >= 3;

      default:
        return false;
    }
  }
}

extension PoiGeometryTools on PointOfInterest {
  void closePolygonIfNeeded() {
    if (geometryType != 'Polygon') return;

    final points = getPoints();
    if (points == null || points.length < 3) return;

    final first = points.first;
    final last = points.last;

    // Wenn nicht geschlossen → schließen
    if (first.lat != last.lat || first.lon != last.lon) {
      points.add(Geographic(lat: first.lat, lon: first.lon));
      setPoints(points);
    }
  }
}
