import 'package:stadtschreiber/models/poi.dart';

class PoiDragState {
  final PointOfInterest? dragPoi;
  final PointOfInterest? dragPointPoi;
  final int? dragPointIndex;

  const PoiDragState({
    this.dragPoi,
    this.dragPointPoi,
    this.dragPointIndex,
  });

  PoiDragState copyWith({
    required PointOfInterest? dragPoi,
    required PointOfInterest? dragPointPoi,
    required int? dragPointIndex,
  }) {
    return PoiDragState(
      dragPoi: dragPoi,
      dragPointPoi: dragPointPoi,
      dragPointIndex: dragPointIndex,
    );
  }
}
