import 'package:maplibre/maplibre.dart' as maplibre;
import '../services/geo_service.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/repositories/poi_repository.dart';
import 'package:stadtschreiber/services/debug_service.dart';
import 'package:stadtschreiber/utils/osm_utils.dart';

class PoiService {
  PoiService(this.repo);

  final PoiRepository repo;

  Future<PointOfInterest> checkForDuplicates(PointOfInterest poi) async {
    // -1 => from OSM Overpass query
    if (poi.id == '-1') {
      final existing = await repo.loadPoiByOSMId(poi.osmId!);
      // TODO CHECK OB OSM ID ABGLEICH FUNKTIONIERT, DA POIS UND NICHT POI IDS VERGLICHEN WERDEN
      final fresh = existing ?? await repo.saveOSMPoiToSupabase(poi);
      return fresh;
    }

    // POI existiert bereits → NICHT Adresse laden!
    // Adresse wird über die Queue geladen.
    final fresh = await repo.loadPoiById(poi.id);
    return fresh!;
  }

  Future<PointOfInterest> ensurePoiHasAddress(PointOfInterest poi) async {
    if (poi.houseNumber != null && poi.houseNumber!.isNotEmpty) {
      return poi;
    }

    DebugService.log('🟡 Hole Adresse für POI ${poi.id} (${poi.name})…');

    final address = await fetchStructuredAddressFromOSM(
      poi.location.lat,
      poi.location.lon,
    );

    if (address == null) {
      DebugService.log('🔴 Konnte keine Adresse von OSM holen.');
      return poi;
    }

    // TODO CHECK OB DOPPELT
    await repo.updatePoiAddressInSupabase(poi.id, address);

    return poi.cloneWithNewValues(address: address);
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

    await repo.updatePoiCategories(
      poiId: selPoi.id,
      categories: updatedCategories,
    );

    DebugService.log(
      'PoiController.toggleCategory - selectedPoi: $selPoi.name',
    );

    return selPoi.cloneWithNewValues(categories: updatedCategories);
  }

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
