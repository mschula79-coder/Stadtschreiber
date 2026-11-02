import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/provider/categories_menu_provider.dart';
import 'package:stadtschreiber/provider/feature_filter_provider.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';
import 'package:stadtschreiber/provider/poi_search_center_provider.dart';
import 'package:stadtschreiber/provider/search_radius_provider.dart';

final poisForCategoriesProvider =
    FutureProvider.autoDispose<List<PointOfInterest>>((ref) async {
      final selectedCategorySlugs = Set<String>.unmodifiable(
        ref
            .watch(
              categoriesSelectionProvider.select(
                (state) => state.selectedSlugs,
              ),
            )
            .map((slug) => slug.trim())
            .where((slug) => slug.isNotEmpty),
      );

      final selectedFeatureSlugs = Set<String>.unmodifiable(
        ref
            .watch(featureFilterProvider)
            .map((slug) => slug.trim())
            .where((slug) => slug.isNotEmpty),
      );

      final radiusKm = ref.watch(searchRadiusKmProvider);

      final searchCenter = ref.watch(poiSearchCenterProvider);

      if (selectedCategorySlugs.isEmpty || searchCenter == null) {
        return const <PointOfInterest>[];
      }

      final repository = ref.read(poiRepositoryProvider);

      return repository.loadPoisWithinRadius(
        lat: searchCenter.lat,
        lon: searchCenter.lon,
        radiusKm: radiusKm,
        categorySlugs: selectedCategorySlugs,
        featureSlugs: selectedFeatureSlugs,
      );
    });