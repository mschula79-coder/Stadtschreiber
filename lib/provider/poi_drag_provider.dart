import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/state/poi_drag_state.dart';

class PoiDragNotifier extends Notifier<PoiDragState> {
  @override
  PoiDragState build() => const PoiDragState();

  /// Sets state to poi
  void startDraggingPoi(PointOfInterest poi) {
    state = state.copyWith(dragPoi: poi);
  }

  /// Sets state to null
  void stopDraggingPoi() {
    state = state.copyWith(dragPoi: null);
  }

  void startDraggingPoiPoint(PointOfInterest poi, int index) {
    state = state.copyWith(dragPoiPoint: poi, dragPoiPointIndex: index);
  }

  void stopDraggingPoiPoint() {
    state = state.copyWith(dragPoiPoint: null, dragPoiPointIndex: null);
  }

  bool isDraggingPoiPoint() {
    return state.dragPoiPoint != null;
  }

  bool isDraggingPoi() {
    return state.dragPoi != null;
  }

  PointOfInterest? dragPoi() {
    return state.dragPoi;
  }

  PointOfInterest? dragPoiPoint() {
    return state.dragPoiPoint;
  }
}

final dragPoiProvider = NotifierProvider<PoiDragNotifier, PoiDragState>(
  PoiDragNotifier.new,
  name: 'dragPoiProvider'
);
