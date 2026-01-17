import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../models/poi.dart';

class MapOverlayController {
  final Map<String, Offset> screenPositions = {};

  Timer? _throttle;
  bool _updating = false;

  Future<void> updatePositions({
    required MapLibreMapController controller,
    required List<PointOfInterest> visiblePOIs,
  }) async {
    if (_updating) return;
    _updating = true;

    try {
      final dpr = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
      final newPositions = <String, Offset>{};

      for (final poi in visiblePOIs) {
        final raw = await controller.toScreenLocation(poi.location);
        newPositions[poi.name] = Offset(raw.x / dpr, raw.y / dpr);
        
      }

      screenPositions
        ..clear()
        ..addAll(newPositions);

    } catch (e, st) {
      debugPrint("ERROR in MapOverlayController.updatePositions: $e");
      debugPrint("$st");
    } finally {
      _updating = false;
    }
  }

  /// Throttled version to avoid spamming updates during camera movement.
  void updatePositionsThrottled({
    required BuildContext context,
    required MapLibreMapController controller,
    required List<PointOfInterest> visiblePOIs,
  }) {
    if (_throttle?.isActive ?? false) return;

    _throttle = Timer(const Duration(milliseconds: 0), () {
      updatePositions(
        controller: controller,
        visiblePOIs: visiblePOIs,
      );
    });
  }

  void dispose() {
    _throttle?.cancel();
  }
}
