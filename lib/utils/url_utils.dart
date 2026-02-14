import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/_message_box.dart';

bool isValidUrl(String url) {
  final uri = Uri.tryParse(url);
  return uri != null &&
      uri.hasScheme &&
      (uri.isScheme("http") || uri.isScheme("https"));
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

Future<void> openLink(BuildContext context, String url) async {
  void showMsg() {
    messageBox(context, 'Adresse nicht erreichbar', '');
  }

  try {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    showMsg();
    return;
  }
}
