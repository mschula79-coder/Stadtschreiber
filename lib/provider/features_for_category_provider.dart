import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/localized_feature_node.dart';
import 'package:stadtschreiber/provider/category_repository_provider.dart';
import 'package:stadtschreiber/provider/locale_provider.dart';

final featuresForCategoryProvider = FutureProvider.autoDispose
    .family<List<LocalizedFeatureNode>, String>(
  (ref, categorySlug) async {
    final normalizedSlug = categorySlug.trim();

    if (normalizedSlug.isEmpty) {
      return const <LocalizedFeatureNode>[];
    }

    final locale = ref.watch(localeProvider);

    final repository = ref.read(
      categoriesRepositoryProvider,
    );

    return repository.loadFeaturesForCategory(
      categorySlug: normalizedSlug,
      languageCode: locale.languageCode,
      countryCode: locale.countryCode,
    );
  },
);