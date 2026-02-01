import 'dart:convert';
import '../models/district.dart';

String getGeoJSONStringFromDistricts(List<District> districts) {
  final geoJsonMap = _buildDistrictGeoJson(districts);
  
  return jsonEncode(geoJsonMap);
}

Map<String, dynamic> _buildDistrictGeoJson(List<District> districts) {
  return {
    "type": "FeatureCollection",
    "features": districts.map((d) {
      return {
        "type": "Feature",
        "properties": {"id": d.id, "name": d.name},
        "geometry": {
          "type": "MultiPolygon",
          "coordinates": d.polygons.map((poly) {
            return [
              poly.map((p) => [p.lon, p.lat]).toList(),
            ];
          }).toList(),
        },
      };
    }).toList(),
  };
}
