import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/poi_selection_modes.dart';
import 'package:stadtschreiber/provider/poi_selection_provider.dart';
import 'package:stadtschreiber/state/visible_pois_menu_state.dart';

class VisiblePoisMenuStateNotifier extends Notifier<VisiblePoisMenuStateData> {
  @override
  VisiblePoisMenuStateData build() {
    return VisiblePoisMenuStateData.initial;
  }

  void setPoiSelectionMode(PoiSelectionMode value) {
    ref.read(poiSelectionProvider).clear();
    state = state.copyWith(poiSelectionMode: value);
  }

  void setTileExpanded(String tileId, bool expanded) {
    final updated = Map<String, bool>.from(state.expandedTiles);
    updated[tileId] = expanded;
    state = state.copyWith(expandedTiles: updated);
  }
}

final visiblePoisMenuStateProvider =
    NotifierProvider<VisiblePoisMenuStateNotifier, VisiblePoisMenuStateData>(
      VisiblePoisMenuStateNotifier.new,
      name: 'visiblePoisMenuStateProvider',
    );
