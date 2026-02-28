import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../services/debug_service.dart';

Future<Map<String, String?>?> fetchStructuredAddressFromOSM(
  double lat,
  double lon,
) async {
  final url = Uri.parse(
    'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=jsonv2&addressdetails=1&zoom=30',
  );

  final response = await http.get(
    url,
    headers: {'User-Agent': 'Stadtschreiber/1.0 (mschula@gmail.com)'},
  );

  if (response.statusCode != 200) {
    DebugService.log('OSM ERROR: ${response.statusCode} ${response.body}');
    return null;
  }

  final data = jsonDecode(response.body);
  final addr = data['address'] as Map<String, dynamic>?;

  if (addr == null) return null;

  final city = addr['city'] ?? addr['town'] ?? addr['village'];

  return {
    'street': addr['road'] as String?,
    'house_number': addr['house_number'] as String?,
    'postcode': addr['postcode'] as String?,
    'city': city as String?,
    'district': addr['suburb'] as String?,
    'country': addr['country'] as String?,
    'display_address': data['display_name'] as String?,
  };
}

Map<String, double> createViewbox(double lat, double lon, int meters) {
  // Breitengrad: 1° ≈ 110.540 km
  final dLat = meters / 110540.0;

  // Längengrad: 1° ≈ 111.320 km * cos(lat)
  final dLon = meters / (111320.0 * cos(lat * pi / 180));

  return {
    "left": lon - dLon,
    "right": lon + dLon,
    "top": lat + dLat,
    "bottom": lat - dLat,
  };
}

Future<List<dynamic>> searchNearbyOverpass({
  required double lat,
  required double lon,
  required String query,
}) async {

  final box = createViewbox(lat, lon, 100);

  final south = box['bottom'];
  final west = box['left'];
  final north = box['top'];
  final east = box['right'];

  // Overpass Query
  final overpassQuery =
      """
      [out:json][timeout:25];
      (
        way["building"]["name"]($south,$west,$north,$east);
        relation["building"]["name"]($south,$west,$north,$east);

        way["highway"]["name"]($south,$west,$north,$east);
        relation["highway"]["name"]($south,$west,$north,$east);

        node["place"]["name"]($south,$west,$north,$east);
        way["place"]["name"]($south,$west,$north,$east);
        relation["place"]["name"]($south,$west,$north,$east);
      );
      out center;
      """;

  final url = Uri.parse("https://overpass-api.de/api/interpreter");

  final response = await http.post(
    url,
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      "User-Agent": "StadtschreiberApp/1.0 (Basel)",
    },
    body: {"data": overpassQuery},
  );

  if (response.statusCode != 200) {
    throw Exception("Overpass error: ${response.statusCode}");
  }

  final json = jsonDecode(response.body);

  return json["elements"] ?? [];
}
