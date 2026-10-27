import 'package:flutter/material.dart';
import 'package:stadtschreiber/models/category_dto.dart';
import 'package:stadtschreiber/models/category_node_localized.dart';

class CategoryLocalizationUtils {
  const CategoryLocalizationUtils._();

  static String localeKey(Locale locale) {
    final languageCode = locale.languageCode.toLowerCase();
    final countryCode = locale.countryCode?.toUpperCase();

    if (languageCode == 'de' && countryCode == 'CH') {
      return 'de-CH';
    }

    switch (languageCode) {
      case 'en':
        return 'en-US';
      case 'fr':
        return 'fr-FR';
      case 'de':
      default:
        return 'de-DE';
    }
  }

  static String labelFromMap(
    Map<String, String> labels,
    String localeKey, {
    String fallback = '',
  }) {
    final localizedLabel = labels[localeKey]?.trim();

    if (localizedLabel != null && localizedLabel.isNotEmpty) {
      return localizedLabel;
    }

    final germanLabel = labels['de-DE']?.trim();

    if (germanLabel != null && germanLabel.isNotEmpty) {
      return germanLabel;
    }

    for (final label in labels.values) {
      final trimmedLabel = label.trim();

      if (trimmedLabel.isNotEmpty) {
        return trimmedLabel;
      }
    }

    return fallback;
  }

  static String labelForDto(
    CategoryDto category,
    String localeKey,
  ) {
    return labelFromMap(
      category.labels,
      localeKey,
      fallback: category.slug,
    );
  }

  static int compareLabels(
    String first,
    String second,
  ) {
    final normalizedFirst = normalizeLabel(first);
    final normalizedSecond = normalizeLabel(second);

    final normalizedComparison = normalizedFirst.compareTo(
      normalizedSecond,
    );

    if (normalizedComparison != 0) {
      return normalizedComparison;
    }

    return first.compareTo(second);
  }

  static int compareDtos(
    CategoryDto first,
    CategoryDto second,
    String localeKey,
  ) {
    final labelComparison = compareLabels(
      labelForDto(first, localeKey),
      labelForDto(second, localeKey),
    );

    if (labelComparison != 0) {
      return labelComparison;
    }

    return first.slug.compareTo(second.slug);
  }

  static int compareDtosBySortOrder(
    CategoryDto first,
    CategoryDto second,
    String localeKey,
  ) {
    final sortOrderComparison = first.sortOrder.compareTo(
      second.sortOrder,
    );

    if (sortOrderComparison != 0) {
      return sortOrderComparison;
    }

    return compareDtos(
      first,
      second,
      localeKey,
    );
  }

  static int compareLocalizedNodes(
    LocalizedCategoryNode first,
    LocalizedCategoryNode second,
  ) {
    final labelComparison = compareLabels(
      first.label,
      second.label,
    );

    if (labelComparison != 0) {
      return labelComparison;
    }

    return first.slug.compareTo(second.slug);
  }

  static int compareLocalizedNodesBySortOrder(
    LocalizedCategoryNode first,
    LocalizedCategoryNode second,
  ) {
    final sortOrderComparison = first.sortOrder.compareTo(
      second.sortOrder,
    );

    if (sortOrderComparison != 0) {
      return sortOrderComparison;
    }

    return compareLocalizedNodes(
      first,
      second,
    );
  }

  static List<CategoryDto> sortDtos(
    Iterable<CategoryDto> categories,
    String localeKey, {
    bool useSortOrder = false,
  }) {
    final sortedCategories = List<CategoryDto>.from(
      categories,
    );

    if (useSortOrder) {
      sortedCategories.sort(
        (first, second) => compareDtosBySortOrder(
          first,
          second,
          localeKey,
        ),
      );
    } else {
      sortedCategories.sort(
        (first, second) => compareDtos(
          first,
          second,
          localeKey,
        ),
      );
    }

    return sortedCategories;
  }

  static List<LocalizedCategoryNode> sortLocalizedNodes(
    Iterable<LocalizedCategoryNode> categories, {
    bool useSortOrder = false,
  }) {
    final sortedCategories = List<LocalizedCategoryNode>.from(
      categories,
    );

    if (useSortOrder) {
      sortedCategories.sort(
        compareLocalizedNodesBySortOrder,
      );
    } else {
      sortedCategories.sort(
        compareLocalizedNodes,
      );
    }

    return sortedCategories;
  }

  static String normalizeLabel(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss')
        .replaceAll('à', 'a')
        .replaceAll('á', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('å', 'a')
        .replaceAll('æ', 'ae')
        .replaceAll('ç', 'c')
        .replaceAll('è', 'e')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('ì', 'i')
        .replaceAll('í', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ñ', 'n')
        .replaceAll('ò', 'o')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('œ', 'oe')
        .replaceAll('ù', 'u')
        .replaceAll('ú', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ÿ', 'y');
  }
}