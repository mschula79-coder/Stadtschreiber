import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart';
import '../models/poi.dart';

class MapPoiOverlayController {
  final Map<int, Offset> screenPositions = {};

  Timer? _throttle;
  bool _updating = false;

  Future<void> updatePositions({
    required MapController controller,
    required List<PointOfInterest> visiblePOIs,
  }) async {
    if (_updating) return;
    _updating = true;

    try {
      final newPositions = <int, Offset>{};

      for (final poi in visiblePOIs) {
        final coords = controller.toScreenLocation(poi.location);
        newPositions[poi.id] = Offset(coords.dx, coords.dy);
/*         print("📍 POI '${poi.name}' at screen ${newPositions[poi.id]} lon: ${poi.location.lon}, lat: ${poi.location.lat}",
        ); */
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
    required MapController controller,
    required List<PointOfInterest> visiblePOIs,
  }) {
    if (_throttle?.isActive ?? false) return;

    _throttle = Timer(const Duration(milliseconds: 0), () {
      updatePositions(controller: controller, visiblePOIs: visiblePOIs);
    });
  }

  void dispose() {
    _throttle?.cancel();
  }
}
