import 'package:http/http.dart' as http;


bool isValidUrl(String url) {
  final uri = Uri.tryParse(url);
  return uri != null && uri.hasScheme && (uri.isScheme("http") || uri.isScheme("https"));
}

Future<bool> urlExists(String url) async {
  try {
    final uri = Uri.parse(url);
    final response = await http.head(uri).timeout(const Duration(seconds: 3));
    return response.statusCode >= 200 && response.statusCode < 400;
  } catch (_) {
    return false;
  }
}
