import '../models/poi.dart';
import 'package:flutter/material.dart';
import '../services/debug_service.dart';

class PoiThumbnailsState extends ChangeNotifier {
  final List<PointOfInterest> visible = [];

  void add(PointOfInterest poi) {
    visible.removeWhere((p) => p.id == poi.id);
    visible.add(poi);
    DebugService.log('PoiThumbnailsState.add $poi.name - notifyListeners');

    notifyListeners();
  }

  void setAll(List<PointOfInterest> pois) {
    visible
      ..clear()
      ..addAll(pois);
    DebugService.log('PoiThumbnailsState.setAll: $pois.length - notifyListeners ');
    notifyListeners();
  }
}
