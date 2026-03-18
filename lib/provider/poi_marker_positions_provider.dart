import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre/maplibre.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/services/debug_service.dart';
import 'package:stadtschreiber/state/poi_marker_position_state.dart';

final poiMarkerPositionProvider =
    NotifierProvider<PoiMarkerPositionNotifier, PoiMarkerPositionStateData>(
  PoiMarkerPositionNotifier.new,
  name: 'poiMarkerPositionProvider'
);

class PoiMarkerPositionNotifier extends Notifier<PoiMarkerPositionStateData> {
  bool _updating = false;

  @override
  PoiMarkerPositionStateData build() => PoiMarkerPositionStateData.initial;

  Future<void> updatePositions({
    required MapController controller,
    required List<PointOfInterest> visiblePois,
  }) 
  async {
    DebugService.log('updatePositions');
    
    if (_updating) return;
    _updating = true;

    final newPositions = <String, Offset>{};

    for (final poi in visiblePois) {
      final coords = controller.toScreenLocation(poi.location);
      newPositions[poi.id] = Offset(coords.dx, coords.dy);
    }

    state = state.copyWith(positions: newPositions);
    _updating = false;
  }

  void setZoom(double zoom) {
    if (state.zoom != zoom) {
      state = state.copyWith(zoom: zoom);
    }
  }
}
