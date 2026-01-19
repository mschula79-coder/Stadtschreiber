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

  /* void selectPoi(PointOfInterest poi) {
    selectedPoi = poi;
    notifyListeners();
  }
 */
  Future<void> selectPoi(PointOfInterest poi) async {
    final fresh = await repo.loadPoiById(poi.id);
    selectedPoi = fresh ?? poi;
    notifyListeners();
  }

  void clearSelection() {
    selectedPoi = null;
    notifyListeners();
  }

  Future<void> reloadSelectedPoi() async {
    if (selectedPoi == null) return;

    final freshPoi = await repo.loadPoiById(selectedPoi!.id);

    if (freshPoi != null) {
      selectedPoi = freshPoi;
      notifyListeners();
    }
  }
}
