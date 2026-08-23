import 'package:stadtschreiber/models/poi_selection_modes.dart';

class VisiblePoisMenuStateData {
  final Map<String, bool> expandedTiles; // ⭐ neu
  final PoiSelectionMode poiSelectionMode;

  const VisiblePoisMenuStateData({
    required this.expandedTiles,
    required this.poiSelectionMode,
  });

  VisiblePoisMenuStateData copyWith({
    Map<String, bool>? expandedTiles,
    PoiSelectionMode? poiSelectionMode,
  }) {
    return VisiblePoisMenuStateData(
      expandedTiles: expandedTiles ?? this.expandedTiles,
      poiSelectionMode: poiSelectionMode ?? this.poiSelectionMode,
    );
  }

  static const initial = VisiblePoisMenuStateData(
    expandedTiles: {},
    poiSelectionMode: PoiSelectionMode.single,
  );
}
