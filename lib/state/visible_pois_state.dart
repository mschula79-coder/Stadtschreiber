import 'package:stadtschreiber/models/poi.dart';

class VisiblePoisStateData {
  final List<PointOfInterest> visible;

  const VisiblePoisStateData({required this.visible});

  VisiblePoisStateData copyWith({List<PointOfInterest>? visible}) {
    return VisiblePoisStateData(visible: visible ?? this.visible);
  }

  static const initial = VisiblePoisStateData(visible: []);
}
