
import 'package:maplibre/maplibre.dart';

class PolygonEditorState {
  List<Geographic> points = [];
  bool isClosed = false;

  void addPoint(Geographic p) => points.add(p);
  void movePoint(int index, Geographic p) => points[index] = p;
  void removePoint(int index) => points.removeAt(index);

  Map<String, dynamic>? toGeoJson() {
    if (points.length < 3) return null;

    return {
      "type": "Polygon",
      "coordinates": [
        points.map((p) => [p.lon, p.lat]).toList()
      ]
    };
  }
}
