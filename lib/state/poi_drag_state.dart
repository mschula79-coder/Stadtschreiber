import 'package:stadtschreiber/models/poi.dart';

class PoiDragState {
  final PointOfInterest? dragPoi;
  final PointOfInterest? dragPoiPoint;
  final int? dragPoiPointIndex;

  const PoiDragState({
    this.dragPoi,
    this.dragPoiPoint,
    this.dragPoiPointIndex,
  });

  PoiDragState copyWith({
    PointOfInterest? dragPoi,
    PointOfInterest? dragPoiPoint,
    int? dragPoiPointIndex,
  }) {
    return PoiDragState(
      dragPoi: dragPoi ?? this.dragPoi,
      dragPoiPoint: dragPoiPoint ?? this.dragPoiPoint,
      dragPoiPointIndex: dragPoiPointIndex ?? this.dragPoiPointIndex,
    );
  }
}
