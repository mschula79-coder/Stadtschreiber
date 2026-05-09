import 'dart:async';

import 'package:flutter/material.dart';

Future<Size> getImageSize(String url) async {
  final completer = Completer<Size>();
  final img = Image.network(url);
  img.image.resolve(const ImageConfiguration()).addListener(
    ImageStreamListener((info, _) {
      completer.complete(Size(
        info.image.width.toDouble(),
        info.image.height.toDouble(),
      ));
    }),
  );
  return completer.future;
}