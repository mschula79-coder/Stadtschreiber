import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart';
import '../models/poi.dart';

class PoiThumbnailsController extends ChangeNotifier {
  final Map<int, Offset> screenPositions = {};

  Timer? _throttle;
  bool _updating = false;

  Future<void> updatePositions({
    required MapController controller,
    required List<PointOfInterest> visiblePOIs,
  }) async {
    if (_updating) return;
    _updating = true;

    final newPositions = <int, Offset>{};

    for (final poi in visiblePOIs) {
      final coords = controller.toScreenLocation(poi.location);
      newPositions[poi.id] = Offset(coords.dx, coords.dy);
    }
    screenPositions
      ..clear()
      ..addAll(newPositions);

    _updating = false;
    notifyListeners();
  }

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

  @override
  void dispose() {
    _throttle?.cancel();
    super.dispose();
  }
}
