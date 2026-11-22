import 'package:flutter/material.dart';
import 'package:stadtschreiber/widgets/modal_photo_gallery.dart';

class AboutModal {
  static void open(
    BuildContext context, {
    required String baseUrl,
    required int imageCount,
    int initialIndex = 0,
    String filePrefix = 'Folie',
    String fileExtension = 'JPG',
  }) {
    final normalizedBaseUrl = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');

    if (normalizedBaseUrl.isEmpty || imageCount <= 0) {
      return;
    }

    final imageUrls = List<String>.generate(imageCount, (index) {
      final number = index + 1;

      return '$normalizedBaseUrl/'
          '$filePrefix$number.$fileExtension';
    }, growable: false);

    final safeInitialIndex = initialIndex.clamp(0, imageUrls.length - 1);

    PhotoGalleryModal.open(
      context,
      imageUrls: imageUrls,
      initialUrl: imageUrls[safeInitialIndex],
    );
  }
}
