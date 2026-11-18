import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

class ArticleEmbedResult {
  final bool canEmbed;
  final String reason;
  final String? finalUrl;
  final int? statusCode;

  const ArticleEmbedResult({
    required this.canEmbed,
    required this.reason,
    this.finalUrl,
    this.statusCode,
  });
}

class ArticleEmbedService {
  final SupabaseClient supabase;

  const ArticleEmbedService(
    this.supabase,
  );

  Future<ArticleEmbedResult> checkUrl(
    String url,
  ) async {
    final session = supabase.auth.currentSession;

    if (session == null) {
      throw const AuthException(
        'Authentication required',
      );
    }

    final response = await supabase.functions.invoke(
      'check-article-embed',
      body: <String, dynamic>{
        'url': url.trim(),
      },
      headers: <String, String>{
        'Authorization':
            'Bearer ${session.accessToken}',
      },
    );

    if (
      response.status < 200 ||
      response.status >= 300
    ) {
      throw StateError(
        'Embed-Prüfung fehlgeschlagen. '
        'Statuscode: ${response.status}',
      );
    }

    final data = _parseResponseData(
      response.data,
    );

    final canEmbed = _parseBoolean(
      data['canEmbed'],
    );

    final reason =
        data['reason']?.toString().trim();

    final finalUrl =
        data['finalUrl']?.toString().trim();

    final statusCode = _parseInteger(
      data['statusCode'],
    );

    return ArticleEmbedResult(
      canEmbed: canEmbed,
      reason:
          reason == null || reason.isEmpty
          ? 'unknown'
          : reason,
      finalUrl:
          finalUrl == null || finalUrl.isEmpty
          ? null
          : finalUrl,
      statusCode: statusCode,
    );
  }

  Map<String, dynamic> _parseResponseData(
    dynamic responseData,
  ) {
    if (responseData is Map<String, dynamic>) {
      return responseData;
    }

    if (responseData is Map) {
      return responseData.map(
        (key, value) => MapEntry(
          key.toString(),
          value,
        ),
      );
    }

    if (responseData is String) {
      final decoded = jsonDecode(
        responseData,
      );

      if (decoded is Map) {
        return decoded.map(
          (key, value) => MapEntry(
            key.toString(),
            value,
          ),
        );
      }
    }

    throw const FormatException(
      'Ungültige Antwort der Embed-Prüfung.',
    );
  }

  bool _parseBoolean(
    dynamic value,
  ) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      final normalizedValue =
          value.trim().toLowerCase();

      if (
        normalizedValue == 'true' ||
        normalizedValue == '1'
      ) {
        return true;
      }

      if (
        normalizedValue == 'false' ||
        normalizedValue == '0'
      ) {
        return false;
      }
    }

    throw FormatException(
      'Ungültiger canEmbed-Wert: $value',
    );
  }

  int? _parseInteger(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(
        value.trim(),
      );
    }

    return null;
  }
}