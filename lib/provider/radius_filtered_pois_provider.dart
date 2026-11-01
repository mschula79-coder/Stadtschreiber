import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/provider/categories_menu_provider.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';
import 'package:stadtschreiber/provider/poi_search_center_provider.dart';
import 'package:stadtschreiber/provider/search_radius_provider.dart';

final radiusFilteredPoisProvider =
    FutureProvider.autoDispose<
      List<PointOfInterest>
    >((ref) async {
      final categorySlugs = ref.watch(
        categoriesSelectionProvider.select(
          (state) => state.selectedSlugs,
        ),
      );

      final radiusKm = ref.watch(
        searchRadiusKmProvider,
      );

      final searchCenter = ref.watch(
        poiSearchCenterProvider,
      );

      if (categorySlugs.isEmpty ||
          searchCenter == null) {
        return const <PointOfInterest>[];
      }

      final repository = ref.read(
        poiRepositoryProvider,
      );

      return repository.loadPoisWithinRadius(
        lat: searchCenter.lat,
        lon: searchCenter.lon,
        radiusKm: radiusKm,
        categorySlugs: categorySlugs,
      );
    });