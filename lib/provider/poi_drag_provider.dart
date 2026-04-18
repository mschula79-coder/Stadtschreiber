import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/state/poi_drag_state.dart';

class PoiDragNotifier extends Notifier<PoiDragState> {
  @override
  PoiDragState build() => const PoiDragState();

  /// Sets state to poi
  void startDraggingPoiMode(PointOfInterest poi) {
    state = state.copyWith(dragPoi: poi, dragPointIndex: null, dragPointPoi: null);
  }

  /// Sets state to null
  void stopDraggingPoiMode() {
    state = state.copyWith(dragPoi: null,dragPointIndex: null, dragPointPoi: null);
  }

  void startDraggingPointMode(PointOfInterest poi, int index) {
    state = state.copyWith(dragPointPoi: poi, dragPointIndex: index, dragPoi: null);
  }

  void stopDraggingPointMode() {
    state = state.copyWith(dragPointIndex: null, dragPointPoi: null, dragPoi: null);
  }

  bool isDraggingPointMode() {
    return state.dragPointPoi != null;
  }

  bool isDraggingPoiMode() {
    return state.dragPoi != null;
  }

  PointOfInterest? dragPoi() {
    return state.dragPoi;
  }

  PointOfInterest? dragPointPoi() {
    return state.dragPointPoi;
  }


  void setDragPoi(PointOfInterest poi) {
    state.copyWith(dragPoi: poi, dragPointPoi: null, dragPointIndex: null);
  }
}

final dragPoiProvider = NotifierProvider<PoiDragNotifier, PoiDragState>(
  PoiDragNotifier.new,
  name: 'dragPoiProvider'
);
