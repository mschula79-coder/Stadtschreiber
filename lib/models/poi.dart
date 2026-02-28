import 'package:maplibre/maplibre.dart';
import 'package:stadtschreiber/services/debug_service.dart';
import 'dart:convert';
import '../models/article_entry.dart';
import '../models/poi_metadata.dart';

class PointOfInterest {
  final String name;
  Geographic location;
  int? id;
  final List<String>? categories;
  final String featuredImageUrl;
  final String? history;
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
  Map<String, dynamic>? geomArea;
  String geometryType; // 'point' | 'linestring' | 'polygon' | 'multipolygon',
  final int? osmId;
  bool newPoi = false;
  // TODO implement hasUnsavedChanges
  bool hasUnsavedChanges = false;

  PointOfInterest({
    required this.id,
    required this.name,
    required this.location,
    required this.categories,
    required this.featuredImageUrl,
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
    this.geomArea,
    this.geometryType = 'point',
    this.osmId,
    required newPoi,
  });

  factory PointOfInterest.fromSupabase(Map<String, dynamic> row) {
    return PointOfInterest(
      id: row['id'],
      name: row['name'] ?? '',
      location: Geographic(lon: row['lon'], lat: row['lat']),
      categories: List<String>.from(row['categories'] ?? const []),
      featuredImageUrl: row['featured_image_url'] is String
          ? row['featured_image_url']
          : '',

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
      description: row['description'] as String?,
      geomArea: row['geom_area'] as Map<String, dynamic>?,
      geometryType:
          (row['geom_area']?['type'] as String?)?.toLowerCase() ?? 'point',
      osmId: row['osm_id'] as int?,
      newPoi: false,
    );
  }

  PointOfInterest cloneWithNewValues({
    int? id,
    String? name,
    Geographic? location,
    List<String>? categories,
    String? featuredImageUrl,
    String? history,
    List<ArticleEntry>? articles,
    PoiMetadata? metadata,
    double? distance,
    String? street,
    String? houseNumber,
    String? postcode,
    String? city,
    String? district,
    String? country,
    String? displayAddress,
    String? description,
    Map<String, dynamic>? geomArea,
    String? geometryType,
    int? osmId,
    bool? newPoi,
    bool? hasUnsavedChanges,
  }) {
    DebugService.log("Cloning POI with new values: id=$id, name=$name");

    if (geometryType == 'polygon') {
      closePolygonIfNeeded();
    }

    

    return PointOfInterest(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      categories:
          categories ??
          (this.categories != null ? List.from(this.categories!) : null),
      featuredImageUrl: featuredImageUrl ?? this.featuredImageUrl,
      history: history ?? this.history,
      articles: articles ?? List<ArticleEntry>.from(this.articles),
      metadata: metadata ?? this.metadata,
      distance: distance ?? this.distance,
      street: street ?? this.street,
      houseNumber: houseNumber ?? this.houseNumber,
      postcode: postcode ?? this.postcode,
      city: city ?? this.city,
      district: district ?? this.district,
      country: country ?? this.country,
      displayAddress: displayAddress ?? this.displayAddress,
      description: description ?? this.description,
      geomArea:
          geomArea ??
          (this.geomArea != null
              ? Map<String, dynamic>.from(this.geomArea!)
              : null),
      geometryType: geometryType ?? this.geometryType,
      osmId: osmId ?? this.osmId,
      newPoi: newPoi ?? this.newPoi,
    )..hasUnsavedChanges = hasUnsavedChanges ?? this.hasUnsavedChanges;
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
      'history': history,
      'articles': articles.map((e) => e.toJson()).toList(),
      'street': street,
      'house_number': houseNumber,
      'postcode': postcode,
      'city': city,
      'district': district,
      'country': country,
      'display_address': displayAddress,
      'description': description,
      'geom_area': geomArea,
      'osm_id': osmId,
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
    return 'POI(id: $id, name: $name, lat: $location, distance: $distance)';
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

  factory PointOfInterest.fromOverpass(Map<String, dynamic> json) {
    final tags = json['tags'] ?? {};

    // Koordinaten:
    // - Nodes haben lat/lon direkt
    // - Ways/Relations haben center.lat / center.lon
    final lat = json['lat'] ?? json['center']?['lat'];
    final lon = json['lon'] ?? json['center']?['lon'];

    return PointOfInterest(
      id: -1,
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

      articles: [],
      metadata: PoiMetadata(attributes: json),

      // Adressfelder (falls vorhanden)
      street: tags['addr:street'],
      houseNumber: tags['addr:housenumber'],
      postcode: tags['addr:postcode'],
      city: tags['addr:city'],
      district: tags['addr:suburb'],
      country: tags['addr:country'],

      // Display Address
      displayAddress: [
        tags['addr:street'],
        tags['addr:housenumber'],
        tags['addr:postcode'],
        tags['addr:city'],
      ].whereType<String>().join(' '),

      osmId: json['id'],
      newPoi: true,
    );
  }
}

// TODO add messages for invalid geometry
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
