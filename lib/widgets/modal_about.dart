import 'package:flutter/material.dart';
import 'package:stadtschreiber/widgets/modal_photo_gallery.dart';

class AboutModal {
  static const String _baseUrl =
      'https://pub-f79c7b584e8a408282353176df4c42e6.r2.dev';

  static const int _imageCount = 14;

  static List<String> get imageUrls {
    return List<String>.generate(
      _imageCount,
      (index) {
        final number = (index + 1).toString();

        return '$_baseUrl/Folie$number.JPG';
      },
      growable: false,
    );
  }

  static void open(
    BuildContext context, {
    int initialIndex = 0,
  }) {
    final urls = imageUrls;

    if (urls.isEmpty) {
      return;
    }

    final safeInitialIndex = initialIndex.clamp(
      0,
      urls.length - 1,
    );

    PhotoGalleryModal.open(
      context,
      imageUrls: urls,
      initialUrl: urls[safeInitialIndex],
    );
  }
}