import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart';
import '../models/poi.dart';
import '../services/debug_service.dart';

class PoiThumbnailsController extends ChangeNotifier {
  final Map<int, Offset> poiScreenPositions = {};
  double currentZoom =
      14.0; // Default zoom level that will be overwritten on map load with the actual zoom level

  Timer? _throttle;
  bool _updating = false;

  Future<void> updatePoiScreenPositions({
    required MapController controller,
    required List<PointOfInterest> visiblePOIs,
  }) async {
    if (_updating) return;
    _updating = true;

    final newPositions = <int, Offset>{};

    for (final poi in visiblePOIs) {
      final coords = controller.toScreenLocation(poi.location);
      newPositions[poi.id!] = Offset(coords.dx, coords.dy);
    }
    poiScreenPositions
      ..clear()
      ..addAll(newPositions);

    _updating = false;
    DebugService.log('PoiThumbnailsController.updatePoiScreenPositions - notifyListeners');
    notifyListeners();
  }

  void updatePositionsThrottled({
    required BuildContext context,
    required MapController controller,
    required List<PointOfInterest> visiblePOIs,
  }) {
    if (_throttle?.isActive ?? false) return;

    _throttle = Timer(const Duration(milliseconds: 0), () {
      updatePoiScreenPositions(
        controller: controller,
        visiblePOIs: visiblePOIs,
      );
    });
  }

  @override
  void dispose() {
    _throttle?.cancel();
    super.dispose();
  }

  void setZoom(double zoom) {
    if (currentZoom != zoom) {
      currentZoom = zoom;
      DebugService.log('PoiThumbnailsController.setZoom - notifyListeners');
      notifyListeners();
    }
  }
}
