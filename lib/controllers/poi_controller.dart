import 'package:flutter/foundation.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/repositories/poi_repository.dart';

class PoiController with ChangeNotifier {
  final PoiRepository poiRepo = PoiRepository();

  List<PointOfInterest> pois = [];
  PointOfInterest? selectedPoi;

  Future<void> loadPoisforSelectedCategories(List<String> categories) async {
    pois = await poiRepo.loadPoisforSelectedCategories(categories);
    notifyListeners();
  }
  Future<void> loadPoiById(PointOfInterest poi, List<String> categories) async {
    final fresh = await poiRepo.loadPoiById(poi.id, categories);
    selectedPoi = fresh ?? poi;
    notifyListeners();
  }

  void clearSelection() {
    selectedPoi = null;
    notifyListeners();
  }

  Future<void> reloadSelectedPoi() async {
    if (selectedPoi == null) return;

    final freshPoi = await poiRepo.loadPoiById(selectedPoi!.id, selectedPoi?.categories);

    if (freshPoi != null) {
      selectedPoi = freshPoi;
      notifyListeners();
    }
  }

  void selectPoi(PointOfInterest poi) {
    selectedPoi = poi;
  }

  Future<void> toggleCategory({
    required PointOfInterest poi,
    required String categorySlug,
    required bool enabled,
  }) async {
    // 1. Update local list
    final updatedCategories = [...poi.categories];

    if (enabled) {
      if (!updatedCategories.contains(categorySlug)) {
        updatedCategories.add(categorySlug);
      }
    } else {
      updatedCategories.remove(categorySlug);
    }

    await poiRepo.updatePoiCategories(
      poiId: poi.id,
      categories: updatedCategories,
    );

    selectedPoi = PointOfInterest(
      id: poi.id,
      name: poi.name,
      location: poi.location,
      categories: updatedCategories,
      featuredImageUrl: poi.featuredImageUrl,
      history: poi.history,
      articles: poi.articles,
    );

    notifyListeners();
  }

  Future<List<PointOfInterest>> searchRemote(String query) async {
    if (query.isEmpty) return [];
    return await poiRepo.searchPois(query.trimRight());
  }
}
