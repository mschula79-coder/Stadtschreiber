import 'dart:convert';
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
    headers: {
      'User-Agent': 'Stadtschreiber/1.0 (mschula@gmail.com)',
    },
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
