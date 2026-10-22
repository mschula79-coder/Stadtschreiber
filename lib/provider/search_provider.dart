import 'package:maplibre/maplibre.dart';
import 'package:stadtschreiber/provider/address_lookup_queue_provider.dart';
import 'package:stadtschreiber/provider/camera_provider.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';
import 'package:stadtschreiber/provider/poi_service_provider.dart';
import 'package:stadtschreiber/services/geo_service.dart';

import '../models/poi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef SearchResultsParams = ({String query, bool searchActive});

final rawSearchResultsProvider = FutureProvider.autoDispose
    .family<List<PointOfInterest>, SearchResultsParams>((ref, params) async {
      if (!params.searchActive) {
        return const [];
      }

      final query = params.query.trim();

      if (query.isEmpty) {
        return const [];
      }

      final repository = ref.read(poiRepositoryProvider);
      final camera = ref.read(cameraProvider);

      final pois = await repository.searchPois(query, camera.lat, camera.lon);

      if (!query.toLowerCase().startsWith('osm')) {
        return List<PointOfInterest>.unmodifiable(pois);
      }

      final poiService = ref.read(poiServiceProvider);
      final addressLookupQueue = ref.read(addressLookupQueueProvider.notifier);

      final processed = await Future.wait(
        pois.map((poi) async {
          final checked = await poiService.checkForDuplicates(poi);

          if (checked.address?.displayAddress() == null) {
            addressLookupQueue.enqueue(checked);
          }

          return checked;
        }),
      );

      return List<PointOfInterest>.unmodifiable(processed);
    });

final searchResultsProvider = Provider.autoDispose
    .family<AsyncValue<List<PointOfInterest>>, SearchResultsParams>((
      ref,
      params,
    ) {
      final searchResults = ref.watch(rawSearchResultsProvider(params));

      final correctedCamera = ref.watch(cameraPositionPanelCorrectedProvider);

      return searchResults.whenData((pois) {
        if (pois.length < 2) {
          return pois;
        }

        final distances = <PointOfInterest, double>{};

        for (final poi in pois) {
          distances[poi] = geoDistanceMeters(
            Geographic(lon: poi.location.lon, lat: poi.location.lat),
            correctedCamera,
          );
        }

        final sortedPois = List<PointOfInterest>.from(pois);

        sortedPois.sort((a, b) {
          final distanceA = distances[a] ?? double.infinity;

          final distanceB = distances[b] ?? double.infinity;

          return distanceA.compareTo(distanceB);
        });

        return List<PointOfInterest>.unmodifiable(sortedPois);
      });
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

  void setAll(List<PointOfInterest> pois) {
    state = pois;
  }
}
