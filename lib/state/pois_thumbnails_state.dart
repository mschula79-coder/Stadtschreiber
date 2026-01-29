import '../models/poi.dart';  
import 'package:flutter/material.dart';

class PoiThumbnailsState extends ChangeNotifier {
  final List<PointOfInterest> visible = [];

  void add(PointOfInterest poi) {
    visible.removeWhere((p) => p.id == poi.id);
    visible.add(poi);
    notifyListeners();
  }

  void setAll(List<PointOfInterest> pois) {
    visible
      ..clear()
      ..addAll(pois);
    notifyListeners();
  }
}
