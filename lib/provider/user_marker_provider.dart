import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart' as maplibre;
import 'package:stadtschreiber/provider/map_controller_provider.dart';
import 'package:stadtschreiber/provider/user_location_state_provider.dart';

final userMarkerProvider = Provider<Offset?>((ref) {
  final pos = ref.watch(userLocationStateProvider);
  final controller = ref.watch(mapControllerProvider);

  if (pos == null || controller == null) return null;

  final screen = controller.toScreenLocation(
    maplibre.Geographic(
      lat: pos.latitude,
      lon: pos.longitude,
    ),
  );

  return Offset(screen.dx, screen.dy);
});
