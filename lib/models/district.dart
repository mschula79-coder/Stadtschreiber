import 'package:maplibre/maplibre.dart';
import 'package:polylabel/polylabel.dart';
import 'dart:math' as math;
import '../utils/geometry_utils.dart';

class District {
  final int id;
  final String name;
  final List<List<Geographic>> polygons;

  District({required this.id, required this.name, required this.polygons});

  factory District.fromJson(Map<String, dynamic> json) {
    final geom = json['geom'];

    final polygons = <List<Geographic>>[];

    for (final polygon in geom['coordinates']) {
      for (final ring in polygon) {
        polygons.add(
          (ring as List)
              .map<Geographic>((c) => Geographic(lat: c[1], lon: c[0]))
              .toList(),
        );
      }
    }

    return District(id: json['id'], name: json['name'], polygons: polygons);
  }

  factory District.fromSupabase(Map<String, dynamic> row) {
    final geom = row['geom'];

    final polygons = <List<Geographic>>[];

    for (final polygon in geom['coordinates']) {
      for (final ring in polygon) {
        polygons.add(
          (ring as List)
              .map<Geographic>((c) => Geographic(lat: c[1], lon: c[0]))
              .toList(),
        );
      }
    }

    return District(id: row['id'], name: row['name'], polygons: polygons);
  }

  
  Feature<Polygon> toFeature() {
    final rings = <PositionSeries>[];

    for (final ring in polygons) {
      rings.add(_convertRing(ring));
    }

    return Feature<Polygon>(
      geometry: Polygon(rings),
      properties: {"id": id, "name": name},
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

  Geographic computeDistrictCenter(List<List<Geographic>> polygons) {
    Geographic? best;
    double bestDistance = -1;

    for (final ringCoords in polygons) {
      final closed = closeRing(ringCoords);
      final ccw = ensureCCW(closed);

      final ring = ccw.map((p) => math.Point<num>(p.lon, p.lat)).toList();

      final result = polylabel([ring], precision: 1.0);

      if (result.distance > bestDistance) {
        bestDistance = result.distance.toDouble();
        best = Geographic(
          lat: result.point.y.toDouble(),
          lon: result.point.x.toDouble(),
        );
      }
    }

    if (bestDistance <= 0 || best == null) {
      // Use the same ring we used for polylabel
      final ring = polygons.first; // this is List<Geographic>
      return guaranteedInside(ring);
    }

    return best;
  }

  List<math.Point<num>> toRing(List<double> flat) {
    final ring = <math.Point<num>>[];
    for (int i = 0; i < flat.length; i += 2) {
      ring.add(math.Point<num>(flat[i], flat[i + 1]));
    }
    return ring;
  }

  bool isClockwise(List<Geographic> ring) {
    double sum = 0;
    for (int i = 0; i < ring.length - 1; i++) {
      sum += (ring[i + 1].lon - ring[i].lon) * (ring[i + 1].lat + ring[i].lat);
    }
    return sum > 0;
  }

  List<Geographic> ensureCCW(List<Geographic> ring) {
    return isClockwise(ring) ? ring.reversed.toList() : ring;
  }

  List<Geographic> closeRing(List<Geographic> ring) {
    if (ring.first.lon != ring.last.lon || ring.first.lat != ring.last.lat) {
      return [...ring, ring.first];
    }
    return ring;
  }

  bool pointInRing(Geographic p, List<Geographic> ring) {
    var inside = false;
    for (int i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final xi = ring[i].lon, yi = ring[i].lat;
      final xj = ring[j].lon, yj = ring[j].lat;

      final intersect =
          ((yi > p.lat) != (yj > p.lat)) &&
          (p.lon < (xj - xi) * (p.lat - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  Geographic projectInside(Geographic centroid, List<Geographic> ring) {
    double bestDist = double.infinity;
    Geographic? bestPoint;

    for (int i = 0; i < ring.length - 1; i++) {
      final a = ring[i];
      final b = ring[i + 1];

      final proj = projectPointOnSegment(centroid, a, b);
      final d = distance(centroid, proj);

      if (d < bestDist) {
        bestDist = d;
        bestPoint = proj;
      }
    }

    return nudgeInside(bestPoint!, centroid);
  }

  Geographic guaranteedInside(List<Geographic> ring) {
    final c = centroidOfRing(ring); // c is List<double> = [lat, lon]

    final centroid = Geographic(lat: c[0], lon: c[1]);

    if (pointInRing(centroid, ring)) {
      return centroid;
    }

    return projectInside(centroid, ring);
  }

  Geographic projectPointOnSegment(Geographic p, Geographic a, Geographic b) {
    final ax = a.lon;
    final ay = a.lat;
    final bx = b.lon;
    final by = b.lat;
    final px = p.lon;
    final py = p.lat;

    final abx = bx - ax;
    final aby = by - ay;

    final abLen2 = abx * abx + aby * aby;
    if (abLen2 == 0) return a; // segment is a point

    final t = ((px - ax) * abx + (py - ay) * aby) / abLen2;

    if (t <= 0) return a;
    if (t >= 1) return b;

    return Geographic(lon: ax + t * abx, lat: ay + t * aby);
  }

  double distance(Geographic a, Geographic b) {
    final dx = a.lon - b.lon;
    final dy = a.lat - b.lat;
    return math.sqrt(dx * dx + dy * dy);
  }

  Geographic nudgeInside(Geographic boundaryPoint, Geographic centroid) {
    // Move 1 meter inward (approx 1e-5 degrees)
    const double step = 0.00001;

    final dx = centroid.lon - boundaryPoint.lon;
    final dy = centroid.lat - boundaryPoint.lat;

    final len = math.sqrt(dx * dx + dy * dy);
    if (len == 0) return boundaryPoint;

    return Geographic(
      lon: boundaryPoint.lon + (dx / len) * step,
      lat: boundaryPoint.lat + (dy / len) * step,
    );
  }
}
