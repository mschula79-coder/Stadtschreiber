import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/poi_feature_node.dart';
import 'package:stadtschreiber/provider/locale_provider.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';

final poiFeaturesProvider = FutureProvider.autoDispose
    .family<List<PoiFeatureNode>, String>(
  (ref, poiId) async {
    final locale = ref.watch(localeProvider);

    final repository = ref.read(
      poiRepositoryProvider,
    );

    return repository.loadFeaturesForPoi(
      poiId: poiId,
      languageCode: locale.languageCode,
      countryCode: locale.countryCode,
    );
  },
);