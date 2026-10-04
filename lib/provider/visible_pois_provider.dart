import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre/maplibre.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/provider/camera_provider.dart';
import 'package:stadtschreiber/services/geo_service.dart';

final visiblePoisProvider =
    NotifierProvider<VisiblePoisNotifier, List<PointOfInterest>>(
      VisiblePoisNotifier.new,
    );

class VisiblePoisNotifier extends Notifier<List<PointOfInterest>> {
  @override
  List<PointOfInterest> build() => [];

  void setAllPois(List<PointOfInterest> pois) {
    state = pois;
  }

  void addPois(List<PointOfInterest> pois) {
    final existingIds = state.map((p) => p.id).toSet();

    final newPois = pois.where((p) => !existingIds.contains(p.id));

    state = [...state, ...newPois];
  }

  void removePois(List<String> ids) {
    state = state.where((p) => !ids.contains(p.id)).toList();
  }

  void clear() {
    state = [];
  }
}

final sortedVisiblePoisProvider = Provider<List<PointOfInterest>>((ref) {
  final pois = ref.watch(
    visiblePoisProvider,
  ); // ⭐ direktes List<PointOfInterest>
  final correctedCamera = ref.watch(cameraPositionPanelCorrectedProvider);

  final sorted = [...pois];

  sorted.sort((a, b) {
    final da = geoDistanceMeters(
      Geographic(lon: a.location.lon, lat: a.location.lat),
      correctedCamera,
    );

    final db = geoDistanceMeters(
      Geographic(lon: b.location.lon, lat: b.location.lat),
      correctedCamera,
    );

    return da.compareTo(db);
  });

  return sorted;
});
