import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/poi_display_modes.dart';

class PoiDisplayModeNotifier extends Notifier<PoiDisplayMode> {
  @override
  PoiDisplayMode build() {
    return PoiDisplayMode.categories; // initial state
  }

  void setMode(PoiDisplayMode mode) {
    state = mode;
  }
}
