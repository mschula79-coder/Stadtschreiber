import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/provider/feature_filter_provider.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';
import 'package:stadtschreiber/provider/poi_search_center_provider.dart';
import 'package:stadtschreiber/provider/search_radius_provider.dart';

final poiCountsByCategoryProvider = FutureProvider<Map<String, int>>((
  ref,
) async {
  final searchCenter = ref.watch(poiSearchCenterProvider);

  final radiusKm = ref.watch(searchRadiusKmProvider);

  final featureSlugs = Set<String>.unmodifiable(
    ref
        .watch(featureFilterProvider)
        .map((slug) => slug.trim())
        .where((slug) => slug.isNotEmpty),
  );

  if (searchCenter == null) {
    return const <String, int>{};
  }

  final repository = ref.read(poiRepositoryProvider);

  return repository.loadPoiCountsByCategory(
    lat: searchCenter.lat,
    lon: searchCenter.lon,
    radiusKm: radiusKm,
    featureSlugs: featureSlugs,
  );
});
