import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:stadtschreiber/models/address.dart';
import '../services/debug_service.dart';

Future<Address?> fetchStructuredAddressFromOSM(double lat, double lon) async {
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

  return Address(
    street: addr['road'] as String?,
    houseNumber: addr['house_number'] as String?,
    postcode: addr['postcode'] as String?,
    city: city as String?,
    district: addr['suburb'] as String?,
    country: addr['country'] as String?,
  );
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

Future<List<dynamic>> searchNearbyOverpassTag({
  required double lat,
  required double lon,
  required String cleanedQuery,
}) async {
  final overpassQuery = buildOverpassQueryForTag(
    lat: lat,
    lon: lon,
    query: cleanedQuery,
  );

  final servers = [
    "https://overpass.kumi.systems/api/interpreter",
    "https://overpass-api.de/api/interpreter",
  ];

  print(overpassQuery);

  for (final s in servers) {
    final url = Uri.parse(s);

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "User-Agent": "StadtschreiberApp/1.0 (Basel)",
        },
        body: {"data": overpassQuery},
      );

      print("Server: $s");
      print(response.body);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final json = jsonDecode(response.body);
        return json["elements"] ?? [];
      }
    } catch (_) {
      // try next server
    }
  }

  throw Exception("Overpass error: all servers failed");
}

Future<List<dynamic>> searchNearbyOverpassName({
  required double lat,
  required double lon,
  required String searchTerm,
}) async {
  final bbox = createViewbox(lat, lon, 500);

  final south = bbox['bottom'];
  final west = bbox['left'];
  final north = bbox['top'];
  final east = bbox['right'];

  final overpassQuery =
      '''
[out:json][timeout:5];
(
  node["name"~"$searchTerm",i]($south,$west,$north,$east);
  way["name"~"$searchTerm",i]($south,$west,$north,$east);
  relation["name"~"$searchTerm",i]($south,$west,$north,$east);
);
out center;
''';

  print(overpassQuery);

  final url = Uri.parse("https://overpass-api.de/api/interpreter");

/*   final url = Uri.parse("https://overpass.kumi.systems/api/interpreter");
 */
  final response = await http.post(
    url,
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      "User-Agent": "StadtschreiberApp/1.0 (Basel)",
    },
    body: {"data": overpassQuery},
  );

  print(response.statusCode);
  print(response.body);

  if (response.statusCode == 200 && response.body.isNotEmpty) {
    final json = jsonDecode(response.body);
    return json["elements"] ?? [];
  }
  return [];
}

String buildOverpassQueryForTag({
  required double lat,
  required double lon,
  required String query, // cleanedQuery
}) {
  final box = createViewbox(lat, lon, 500);

  final south = box['bottom'];
  final west = box['left'];
  final north = box['top'];
  final east = box['right'];

  // Zerlegen: key=value suchbegriff
  String key;
  String? value;
  String? searchTerm;

  // 1. key=value suchbegriff
  if (query.contains('=')) {
    final parts = query.split(' ');
    final keyValue = parts.first; // amenity=restaurant
    final kv = keyValue.split('=');

    key = kv[0].trim();
    value = kv[1].trim();

    if (parts.length > 1) {
      searchTerm = parts.sublist(1).join(' ').trim();
    }
  }
  // 2. key suchbegriff
  else {
    final parts = query.split(' ');
    key = parts.first.trim();

    if (parts.length > 1) {
      searchTerm = parts.sublist(1).join(' ').trim();
    }
  }

  // Query für key=value + optional suchbegriff
  if (value != null) {
    if (searchTerm != null && searchTerm.isNotEmpty) {
      return """
[out:json][timeout:5];
(
  node["$key"="$value"]["name"~"$searchTerm",i]($south,$west,$north,$east);
  way["$key"="$value"]["name"~"$searchTerm",i]($south,$west,$north,$east);
  relation["$key"="$value"]["name"~"$searchTerm",i]($south,$west,$north,$east);
);
out center;
""";
    }

    return """
[out:json][timeout:5];
(
  node["$key"="$value"]($south,$west,$north,$east);
  way["$key"="$value"]($south,$west,$north,$east);
  relation["$key"="$value"]($south,$west,$north,$east);
);
out center;
""";
  }

  // Query für nur key + optional suchbegriff
  if (searchTerm != null && searchTerm.isNotEmpty) {
    return """
[out:json][timeout:5];
(
  node["$key"]["name"~"$searchTerm",i]($south,$west,$north,$east);
  way["$key"]["name"~"$searchTerm",i]($south,$west,$north,$east);
  relation["$key"]["name"~"$searchTerm",i]($south,$west,$north,$east);
);
out center;
""";
  }

  return """
[out:json][timeout:5];
(
  node["$key"]($south,$west,$north,$east);
  way["$key"]($south,$west,$north,$east);
  relation["$key"]($south,$west,$north,$east);
);
out center;
""";
}

Future<List<dynamic>> searchNearbyOverpassBuildings({
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
      [out:json][timeout:5];
      (
        way["building"]($south,$west,$north,$east);
        relation["building"]($south,$west,$north,$east);
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
