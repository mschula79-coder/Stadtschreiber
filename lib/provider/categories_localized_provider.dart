import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/category.dart';
import 'package:stadtschreiber/models/category_node_localized.dart';
import 'package:stadtschreiber/provider/categories_provider.dart';
import 'package:stadtschreiber/provider/locale_provider.dart';

final localizedCategoriesProvider = Provider<List<LocalizedCategoryNode>>((
  ref,
) {
  final categories = ref.watch(
    categoriesProvider.select((state) => state.categories),
  );

  final locale = ref.watch(localeProvider);

  final localeCode = switch ((locale.languageCode, locale.countryCode)) {
    ('de', 'CH') => 'de-CH',
    ('en', _) => 'en-US',
    ('fr', _) => 'fr-FR',
    _ => 'de-DE',
  };

  String normalizedLabel(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ç', 'c')
        .replaceAll('ô', 'o')
        .replaceAll('î', 'i');
  }

  int compareNodes(LocalizedCategoryNode a, LocalizedCategoryNode b) {
    final sortOrderComparison = a.sortOrder.compareTo(b.sortOrder);

    if (sortOrderComparison != 0) {
      return sortOrderComparison;
    }

    return normalizedLabel(a.label).compareTo(normalizedLabel(b.label));
  }

  LocalizedCategoryNode localizeNode(CategoryNode node) {
    final localizedChildren = node.children.map(localizeNode).toList()
      ..sort(compareNodes);

    return LocalizedCategoryNode(
      id: node.id,
      slug: node.slug,
      label: node.labelFor(localeCode),
      sortOrder: node.sortOrder,
      labels: node.labels,
      children: localizedChildren,
      hasParents: node.hasParents,
    );
  }

  final localizedRoots = categories.map(localizeNode).toList()
    ..sort(compareNodes);

  return localizedRoots;
});

final categoryLabelBySlugProvider = Provider.family<String?, String>((
  ref,
  slug,
) {
  final categories = ref.watch(localizedCategoriesProvider);

  String? search(List<LocalizedCategoryNode> nodes) {
    for (final node in nodes) {
      if (node.slug == slug) {
        return node.label;
      }

      final result = search(node.children);

      if (result != null) {
        return result;
      }
    }

    return null;
  }

  return search(categories);
});
