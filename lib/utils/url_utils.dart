import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/modal_message_box.dart';

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

String? convertGoogleDriveToDirectImageUrl(String url) {
  if (url.isEmpty) return null;

  final RegExp idPattern = RegExp(
    r'(?:file/d/|open\?id=|uc\?id=|id=)([a-zA-Z0-9_-]+)',
  );

  final match = idPattern.firstMatch(url);
  if (match == null) return null;

  final fileId = match.group(1);
  if (fileId == null || fileId.isEmpty) return null;

  return "https://drive.google.com/uc?export=view&id=$fileId";
}

bool isGoogleDriveLink(String url) {
  return url.contains("drive.google.com");
}

