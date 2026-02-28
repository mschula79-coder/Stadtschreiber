import 'package:flutter/material.dart';
import '../services/debug_service.dart';

class PoiPanelState extends ChangeNotifier {
  bool isPanelOpen = false;
  
  void openPanel() {
    isPanelOpen = true;
    DebugService.log('PoiPanelAndSelectionState.openPanel - notifyListeners');

    notifyListeners();
  }

  /// Closes the POI panel and notifies listeners to update the UI accordingly.
  void closePanel() {
    isPanelOpen = false;
    DebugService.log('PoiPanelAndSelectionState.closePanel - notifyListeners');

    notifyListeners();
  }
}
