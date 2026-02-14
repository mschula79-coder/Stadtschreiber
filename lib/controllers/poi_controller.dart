import 'package:flutter/foundation.dart';
import '../models/poi.dart';
import '../repositories/poi_repository.dart';
import '../utils/osm_utils.dart';
import '../services/debug_service.dart';

class PoiController with ChangeNotifier {
  final PoiRepository poiRepo;

  bool _isProcessingQueue = false;
  final List<PointOfInterest> _queue = [];

  PoiController(this.poiRepo);

  List<PointOfInterest> pois = [];
  PointOfInterest? selectedPoi;

  void queueAddressLookup(PointOfInterest poi) {
    _queue.add(poi);
    _processQueue();
  }

  PointOfInterest? getSelectedPoi() {
    return selectedPoi;
  }

  Future<void> _processQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;
    while (_queue.isNotEmpty) {
      final poi = _queue.removeAt(0);
      await ensurePoiHasAddress(poi);
      await Future.delayed(const Duration(seconds: 1));
    }
    _isProcessingQueue = false;
  }

  Future<void> loadPoisforSelectedCategories(List<String> categories) async {
    pois = await poiRepo.loadPoisforSelectedCategories(categories);
    notifyListeners();
  }

  Future<void> loadAndSelectPoiById(PointOfInterest poi) async {
    await ensurePoiHasAddress(poi);
    final fresh = await poiRepo.loadPoiById(poi.id);
    selectedPoi = fresh ?? poi;
    notifyListeners();
  }

  void clearSelection() {
    selectedPoi = null;
    notifyListeners();
  }

  Future<void> reloadSelectedPoi() async {
    if (selectedPoi == null) return;

    final freshPoi = await poiRepo.loadPoiById(
      selectedPoi!.id,
    );

    if (freshPoi != null) {
      selectedPoi = freshPoi;
      notifyListeners();
    }
  }

  void selectPoi(PointOfInterest poi) async {
    await ensurePoiHasAddress(poi);
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
      metadata: poi.metadata,
    );

    notifyListeners();
  }

  void clearQueue() {
    _queue.clear();
  }

  Future<void> ensurePoiHasAddress(PointOfInterest poi) async {
    final hasAddress =
        (poi.displayAddress != null && poi.displayAddress!.isNotEmpty) ||
        (poi.street != null && poi.street!.isNotEmpty);

    if (hasAddress) {
      return;
    }

    DebugService.log('🟡 Hole Adresse für POI ${poi.id} (${poi.name})…');

    final address = await fetchStructuredAddressFromOSM(
      poi.location.lat,
      poi.location.lon,
    );
    if (address == null) {
      DebugService.log('🔴 Konnte keine Adresse von OSM holen.');
      return;
    }

    /* print('🟢 Adresse von OSM: ${address['display_address']}'); */
    await poiRepo.updatePoiAddressInSupabase(poi.id, address);
    /*     print('🟢 Adresse in Supabase gespeichert.'); */
  }

  /* Future<List<PointOfInterest>> searchRemote(
    String query,
    double lat,
    double lon,
  ) async {
    print("🟣 searchRemote() CALLED with query='$query'");
    if (query.isEmpty) return [];
    return await poiRepo.searchPois(query.trimRight(), lat, lon);
  } */
}
