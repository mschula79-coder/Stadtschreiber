import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/poi_selection_modes.dart';

class PoiSelectionModeNotifier extends Notifier<PoiSelectionMode> {
  @override
  PoiSelectionMode build() {
    return PoiSelectionMode.categories; // initial state
  }

  void setMode(PoiSelectionMode mode) {
    state = mode;
  }
}

final poiSelectionModeProvider =
    NotifierProvider<PoiSelectionModeNotifier, PoiSelectionMode>(
  PoiSelectionModeNotifier.new,
);

