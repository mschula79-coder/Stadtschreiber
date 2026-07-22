import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

final localeProvider = StateProvider<Locale>((ref) {
  return const Locale("de", "DE");
});
