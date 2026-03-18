import 'dart:async';
import 'package:flutter/material.dart';

Future<Size> getImageSize(String url) async {
  final completer = Completer<Size>();

  final image = Image.network(url);
  image.image.resolve(const ImageConfiguration()).addListener(
    ImageStreamListener((ImageInfo info, bool _) {
      final mySize = Size(
        info.image.width.toDouble(),
        info.image.height.toDouble(),
      );
      completer.complete(mySize);
    }),
  );

  return completer.future;
}
