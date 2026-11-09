import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre/maplibre.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/provider/address_lookup_queue_provider.dart';
import 'package:stadtschreiber/provider/camera_provider.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';
import 'package:stadtschreiber/provider/poi_service_provider.dart';
import 'package:stadtschreiber/services/geo_service.dart';

enum PoiSearchMode {
  name,
  address,
}

typedef SearchResultsParams = ({
  String query,
  bool searchActive,
  PoiSearchMode searchMode,
});

final rawSearchResultsProvider = FutureProvider.autoDispose.family<
    List<PointOfInterest>,
    SearchResultsParams>((ref, params) async {
  if (!params.searchActive) {
    return const <PointOfInterest>[];
  }

  final query = params.query.trim();

  if (query.isEmpty) {
    return const <PointOfInterest>[];
  }
  final repository = ref.read(
    poiRepositoryProvider,
  );

  final camera = ref.read(
    cameraProvider,
  );

  final List<PointOfInterest> pois;

  switch (params.searchMode) {
    case PoiSearchMode.name:
      pois = await repository.searchPois(
        query,
        camera.lat,
        camera.lon,
      );

    case PoiSearchMode.address:
      pois = await repository.searchPoisByAddress(
        query,
        camera.lat,
        camera.lon,
      );
  }

  final isOsmSearch =
      params.searchMode == PoiSearchMode.name &&
      query.toLowerCase().startsWith('osm');

  if (!isOsmSearch) {
    return List<PointOfInterest>.unmodifiable(
      pois,
    );
  }

  final poiService = ref.read(
    poiServiceProvider,
  );

  final addressLookupQueue = ref.read(
    addressLookupQueueProvider.notifier,
  );

  final processed = await Future.wait(
    pois.map((poi) async {
      final checked = await poiService
          .checkForDuplicates(poi);

      if (checked.address?.displayAddress() == null) {
        addressLookupQueue.enqueue(
          checked,
        );
      }

      return checked;
    }),
  );

  return List<PointOfInterest>.unmodifiable(
    processed,
  );
});

final searchResultsProvider = Provider.autoDispose.family<
    AsyncValue<List<PointOfInterest>>,
    SearchResultsParams>((ref, params) {
  final searchResults = ref.watch(
    rawSearchResultsProvider(params),
  );

  final correctedCamera = ref.watch(
    cameraPositionPanelCorrectedProvider,
  );

  return searchResults.whenData((pois) {
    if (pois.length < 2) {
      return pois;
    }

    final distances = <PointOfInterest, double>{};

    for (final poi in pois) {
      distances[poi] = geoDistanceMeters(
        Geographic(
          lon: poi.location.lon,
          lat: poi.location.lat,
        ),
        correctedCamera,
      );
    }

    final sortedPois = List<PointOfInterest>.from(
      pois,
    );

    sortedPois.sort((first, second) {
      final firstDistance =
          distances[first] ?? double.infinity;

      final secondDistance =
          distances[second] ?? double.infinity;

      return firstDistance.compareTo(
        secondDistance,
      );
    });

    return List<PointOfInterest>.unmodifiable(
      sortedPois,
    );
  });
});

final searchSelectionProvider =
    NotifierProvider<SearchSelectionNotifier, List<PointOfInterest>>(
      SearchSelectionNotifier.new,
      name: 'searchSelectionProvider',
    );

class SearchSelectionNotifier
    extends Notifier<List<PointOfInterest>> {
  @override
  List<PointOfInterest> build() {
    return const <PointOfInterest>[];
  }

  void add(PointOfInterest poi) {
    if (state.any((currentPoi) => currentPoi.id == poi.id)) {
      return;
    }

    state = <PointOfInterest>[
      ...state,
      poi,
    ];
  }

  void remove(PointOfInterest poi) {
    state = state
        .where(
          (currentPoi) => currentPoi.id != poi.id,
        )
        .toList(growable: false);
  }

  void replace(PointOfInterest poi) {
    state = <PointOfInterest>[
      for (final currentPoi in state)
        if (currentPoi.id == poi.id) poi else currentPoi,
    ];
  }

  void clear() {
    state = const <PointOfInterest>[];
  }

  void setAll(List<PointOfInterest> pois) {
    state = List<PointOfInterest>.unmodifiable(
      pois,
    );
  }

  
}

