import '../models/poi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/poi_repository.dart';
import '../state/camera_state.dart';

final searchResultsProvider = FutureProvider.autoDispose
    .family<
      List<PointOfInterest>,
      ({
        String query,
        bool searchActive,
        PoiRepository repo,
        CameraState camera,
      })
    >((ref, params) async {
      if (!params.searchActive) {
        return [];
      }

      final pois = await params.repo.searchPois(
        params.query.trimRight(),
        params.camera.lat,
        params.camera.lon,
      );

      return pois;
    });

final searchSelectionProvider =
    NotifierProvider<SearchSelectionNotifier, List<PointOfInterest>>(
      SearchSelectionNotifier.new,
      name: 'searchSelectionProvider',
    );

class SearchSelectionNotifier extends Notifier<List<PointOfInterest>> {
  @override
  List<PointOfInterest> build() => [];

  void add(PointOfInterest poi) {
    if (!state.any((p) => p.id == poi.id)) {
      state = [...state, poi];
    }
  }

  void remove(PointOfInterest poi) {
    state = state.where((p) => p.id != poi.id).toList();
  }

  void replace(PointOfInterest poi) {
    state = [
      for (final p in state)
        if (p.id == poi.id) poi else p,
    ];
  }

  void clear() {
    state = [];
  }
}
