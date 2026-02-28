import 'package:maplibre/maplibre.dart' as maplibre;
import 'package:flutter/material.dart';

import '../models/poi.dart';
import '../repositories/poi_repository.dart';
import '../utils/osm_utils.dart';
import '../services/debug_service.dart';
import '../services/geo_service.dart';

class PoiController with ChangeNotifier {
  final PoiRepository poiRepo;
  bool _isProcessingQueue = false;
  final List<PointOfInterest> _queue = [];

  PoiController(this.poiRepo);

  List<PointOfInterest> pois = [];
  //PointOfInterest? selectedPoi;

  // --- Dragging state ---
  PointOfInterest? _dragPoiPoint;
  PointOfInterest? _dragPoi;
  int? _dragPoiPointIndex;

  /// Returns true if dragPoiPointIndex is not null
  bool get isDraggingPoiPoint => _dragPoiPointIndex != null;
  bool get isDraggingPoi => _dragPoi != null;
  PointOfInterest? get dragPoiPoint => _dragPoiPoint;
  PointOfInterest? get dragPoi => _dragPoi;
  int? get dragPoiPointIndex => _dragPoiPointIndex;

  /// Creates a copy of the given POI with the new point added, and sets the index of the dragged point.
  void setDraggingPoiPoint(PointOfInterest poi, int index) {
    _dragPoiPoint = poi;
    _dragPoiPointIndex = index;
    DebugService.log(
      'PoiController.setDraggingPoiPoint - notifyListeners, dragPoi: $poi.name',
    );
    notifyListeners();
  }

  void unsetDraggingPoiPoint() {
    _dragPoiPoint = null;
    _dragPoiPointIndex = null;
    DebugService.log('PoiController.unsetDraggingPoiPoint - notifyListeners');
    notifyListeners();
  }

  void setDraggingPoi(PointOfInterest poi) {
    // TODO showTrash and dragging info = true;
    // isOverTrash = false;

    _dragPoi = poi;
    DebugService.log(
      '📌 PoiController.setDraggingPoi - notifyListeners, dragPoi: $poi.name',
    );
    notifyListeners();
  }

  void unsetDraggingPoi() {
    _dragPoi = null;
    DebugService.log('PoiController.unsetDraggingPoi - notifyListeners');
    notifyListeners();
  }

  // TODO clearSelection, clearfrom loaded poi
  void deletePoi(PointOfInterest poi) {
    poiRepo.deletePoi(poi.id!);
    DebugService.log('PoiController.deletePoi $poi.name - notifyListeners');

    notifyListeners();
  }

  void queueAddressLookup(PointOfInterest poi) {
    _queue.add(poi);
    _processQueue();
  }

  Future<PointOfInterest> completePoi(PointOfInterest poi) async {
    // -1 => from OSM Overpass query
    if (poi.id == -1 || poi.id == null) {
      // Load existing OSM Poi from Supabase or save it if it doesn't exist
      final freshExisting = await poiRepo.loadPoiByOSMId(poi.osmId!);
      if (freshExisting == null) {
        final freshNew = await poiRepo.saveOSMPoiToSupabase(poi);
        // TODO handling of visiblePois
        pois.add(freshNew);
        return freshNew;
      } else {
        pois.add(freshExisting);
        return freshExisting;
      }
    }
    // Exists in Supabase
    else {
      await ensurePoiHasAddress(poi);
      final fresh = await poiRepo.loadPoiById(poi.id!);
      final index = pois.indexWhere((p) => p.id == poi.id);
      if (index != -1) {
        pois[index] = fresh!;
      }
      return fresh!;
    }
  }

  PointOfInterest setGeometryType(PointOfInterest selPoi, String type) {
    selPoi.geometryType = type;

    // Wenn der POI schon Punkte hat → neu interpretieren
    final pts = selPoi.getPoints();
    selPoi.geomArea = null; // Reset

    if (pts != null || pts!.isNotEmpty) {
      selPoi.setPoints(pts);
    }

    DebugService.log(
      'PoiController.setGeometryType, selectedPoi: $selPoi.name, type: $type',
    );

    return selPoi.cloneWithNewValues();
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
    DebugService.log(
      'PoiController.loadPoisforSelectedCategories - notifyListeners',
    );
    notifyListeners();
  }

  Future<PointOfInterest> toggleCategory({
    required PointOfInterest selPoi,
    required String categorySlug,
    required bool enabled,
  }) async {
    // 1. Update local list
    final updatedCategories = [...selPoi.categories!];

    if (enabled) {
      if (!updatedCategories.contains(categorySlug)) {
        updatedCategories.add(categorySlug);
      }
    } else {
      updatedCategories.remove(categorySlug);
    }

    await poiRepo.updatePoiCategories(
      poiId: selPoi.id!,
      categories: updatedCategories,
    );

    DebugService.log(
      'PoiController.toggleCategory - selectedPoi: $selPoi.name',
    );

    return selPoi.cloneWithNewValues(categories: updatedCategories);
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
    // TODO check and add house number
    final address = await fetchStructuredAddressFromOSM(
      poi.location.lat,
      poi.location.lon,
    );
    if (address == null) {
      DebugService.log('🔴 Konnte keine Adresse von OSM holen.');
      return;
    }

    /* print('🟢 Adresse von OSM: ${address['display_address']}'); */
    // DEBUG house number
    await poiRepo.updatePoiAddressInSupabase(poi.id!, address);
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

  Future<int?> findPoiPointIndexAtGeoPosition(
    List<maplibre.Geographic> points,
    maplibre.Geographic tapGeo,
    maplibre.MapController controller,
  ) async {
    final zoom = controller.camera!.zoom;
    final lat = tapGeo.lat;

    final hitRadiusMeters = geoHitRadiusMeters(
      lat: lat,
      zoom: zoom,
      pixelRadius: 12.0,
    );

    DebugService.log(
      'PoiController.findPoiPointIndexAtGeoPosition - tapGeo: $tapGeo, zoom: $zoom, hitRadiusMeters: $hitRadiusMeters',
    );


    for (int i = 0; i < points.length; i++) {
      
      final d = geoDistanceMeters(points[i], tapGeo);
      
      DebugService.log(
        'Checking point index $i at ${points[i]} - distance to tap: $d meters',
      );

      if (d <= hitRadiusMeters) {
        return i;
      }
    }

    return null;
  }
}
