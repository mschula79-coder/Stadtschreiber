import 'package:flutter/foundation.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/repositories/poi_repository.dart';

class PoiController with ChangeNotifier {
  final PoiRepository repo = PoiRepository();

  List<PointOfInterest> pois = [];
  PointOfInterest? selectedPoi;

  Future<void> loadPois(List<String> categories) async {
    pois = await repo.loadPois(categories);
    notifyListeners();
  }

  void selectPoi(PointOfInterest poi) {
    selectedPoi = poi;
    notifyListeners();
  }

  void clearSelection() {
    selectedPoi = null;
    notifyListeners();
  }

  Future<void> reloadSelectedPoi() async {
    if (selectedPoi == null) return;

    // Reload POIs using the same categories the user has selected
    // (you probably store this in FilterState)
    final categories = selectedPoi!.categories;

    final freshPois = await repo.loadPois(categories);

    // Replace selected POI with the fresh version
    selectedPoi = freshPois.firstWhere(
      (p) => p.id == selectedPoi!.id,
      orElse: () => selectedPoi!,
    );

    notifyListeners();
  }
}
