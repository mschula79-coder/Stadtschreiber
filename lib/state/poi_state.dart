import 'package:flutter/material.dart';
import '../models/poi.dart';

class PoiState extends ChangeNotifier {
  PointOfInterest? selected;
  bool isPanelOpen = false;

  void selectPoi(PointOfInterest poi) {
    selected = poi;
    isPanelOpen = true;
    notifyListeners();
  }

  void clear() {
    selected = null;
    isPanelOpen = false;
    notifyListeners();
  }

  void openPanel() {
    isPanelOpen = true;
    notifyListeners();
  }

  void closePanel() {
    isPanelOpen = false;
    notifyListeners();
  }
}
