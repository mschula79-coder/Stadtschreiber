import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:stadtschreiber/models/image_entry.dart';
import 'package:stadtschreiber/services/url_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageRepository {
  final SupabaseClient supabase;
  final http.Client httpClient;

  ImageRepository(this.supabase, {http.Client? httpClient})
    : httpClient = httpClient ?? http.Client();

  Future<ImageEntry?> pickProcessAndUploadImage() async {
    final currentUser = supabase.auth.currentUser;
    final currentSession = supabase.auth.currentSession;

    if (currentUser == null || currentSession == null) {
      throw const AuthException(
        'Für den Bildupload ist eine Anmeldung erforderlich.',
      );
    }

    final picker = ImagePicker();

    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) {
      return null;
    }

    final originalBytes = await picked.readAsBytes();

    final decodedImage = await decodeImageFromList(originalBytes);

    final originalWidth = decodedImage.width;
    final originalHeight = decodedImage.height;

    const maxSize = 1200;

    final longestSide = originalWidth > originalHeight
        ? originalWidth
        : originalHeight;

    final scale = longestSide > maxSize ? maxSize / longestSide : 1.0;

    final targetWidth = (originalWidth * scale).round();

    final targetHeight = (originalHeight * scale).round();

    final processedBytes = await FlutterImageCompress.compressWithList(
      originalBytes,
      autoCorrectionAngle: true,
      format: CompressFormat.webp,
      quality: 80,
      minWidth: targetWidth,
      minHeight: targetHeight,
    );

    if (processedBytes.isEmpty) {
      throw StateError('Das Bild konnte nicht verarbeitet werden.');
    }

    final originalName = picked.name.trim();

    final extensionIndex = originalName.lastIndexOf('.');

    final baseName = extensionIndex > 0
        ? originalName.substring(0, extensionIndex)
        : originalName;

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final cleanedFileName = sanitizeFilename('${baseName}_$timestamp.webp');

    final objectKey = 'processed/$cleanedFileName';

    final uploadTarget = await _createR2UploadTarget(
      objectKey: objectKey,
      contentType: 'image/webp',
      accessToken: currentSession.accessToken,
    );

    await _uploadImageToR2(
      uploadUrl: uploadTarget.uploadUrl,
      imageBytes: Uint8List.fromList(processedBytes),
      contentType: 'image/webp',
    );

    return ImageEntry(
      title: baseName,
      url: uploadTarget.publicUrl,
      enteredBy: currentUser.id,
    );
  }

  Future<_R2UploadTarget> _createR2UploadTarget({
    required String objectKey,
    required String contentType,
    required String accessToken,
  }) async {
    final response = await supabase.functions.invoke(
      'create-r2-upload-url',
      body: <String, dynamic>{
        'objectKey': objectKey,
        'contentType': contentType,
      },
      headers: <String, String>{'Authorization': 'Bearer $accessToken'},
    );

    if (response.status < 200 || response.status >= 300) {
      throw StateError(
        'Die Upload-Freigabe konnte nicht erstellt werden. '
        'Statuscode: ${response.status}',
      );
    }

    final data = _parseResponseData(response.data);

    final uploadUrl = data['uploadUrl']?.toString().trim();

    final publicUrl = data['publicUrl']?.toString().trim();

    final returnedObjectKey = data['objectKey']?.toString().trim();

    if (uploadUrl == null || uploadUrl.isEmpty) {
      throw const FormatException(
        'Die Edge Function hat keine Upload-URL zurückgegeben.',
      );
    }

    if (publicUrl == null || publicUrl.isEmpty) {
      throw const FormatException(
        'Die Edge Function hat keine öffentliche URL zurückgegeben.',
      );
    }

    if (returnedObjectKey == null || returnedObjectKey.isEmpty) {
      throw const FormatException(
        'Die Edge Function hat keinen Objektpfad zurückgegeben.',
      );
    }

    return _R2UploadTarget(
      uploadUrl: uploadUrl,
      publicUrl: publicUrl,
      objectKey: returnedObjectKey,
    );
  }

  Map<String, dynamic> _parseResponseData(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      return responseData;
    }

    if (responseData is Map) {
      return Map<String, dynamic>.from(responseData);
    }

    if (responseData is String) {
      final decodedData = jsonDecode(responseData);

      if (decodedData is Map) {
        return Map<String, dynamic>.from(decodedData);
      }
    }

    throw const FormatException(
      'Die Edge Function hat eine ungültige Antwort zurückgegeben.',
    );
  }

  Future<void> _uploadImageToR2({
    required String uploadUrl,
    required Uint8List imageBytes,
    required String contentType,
  }) async {
    final response = await httpClient
        .put(
          Uri.parse(uploadUrl),
          headers: <String, String>{'Content-Type': contentType},
          body: imageBytes,
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Der Bildupload zu Cloudflare R2 ist fehlgeschlagen. '
        'Statuscode: ${response.statusCode}. '
        '${response.body}',
      );
    }
  }
}

class _R2UploadTarget {
  final String uploadUrl;
  final String publicUrl;
  final String objectKey;

  const _R2UploadTarget({
    required this.uploadUrl,
    required this.publicUrl,
    required this.objectKey,
  });
}
