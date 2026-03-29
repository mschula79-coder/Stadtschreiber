import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:maplibre/maplibre.dart';

final mapControllerProvider = StateProvider<MapController?>((ref) => null);


extension MapControllerProjection on MapController {
  Offset project(Geographic geo) {
    final p = toScreenLocation(geo);
    return Offset(p.dx, p.dy);
  }
}
