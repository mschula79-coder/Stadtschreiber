import 'package:stadtschreiber/models/category_node_localized.dart';
import 'package:stadtschreiber/utils/category_localization_utils.dart';

class CategoryUtils {
  const CategoryUtils._();

  static List<LocalizedCategoryNode> collectLeafCategories(
    LocalizedCategoryNode node, {
    bool useSortOrder = false,
  }) {
    final result = <LocalizedCategoryNode>[];

    _collectLeaves(
      node,
      result,
    );

    return CategoryLocalizationUtils.sortLocalizedNodes(
      result,
      useSortOrder: useSortOrder,
    );
  }

  static List<LocalizedCategoryNode> collectAllLeafCategories(
    Iterable<LocalizedCategoryNode> roots, {
    bool useSortOrder = false,
  }) {
    final result = <LocalizedCategoryNode>[];

    for (final root in roots) {
      _collectLeaves(
        root,
        result,
      );
    }

    return CategoryLocalizationUtils.sortLocalizedNodes(
      result,
      useSortOrder: useSortOrder,
    );
  }

  static void _collectLeaves(
    LocalizedCategoryNode node,
    List<LocalizedCategoryNode> result,
  ) {
    if (node.children.isEmpty) {
      result.add(node);
      return;
    }

    for (final child in node.children) {
      _collectLeaves(
        child,
        result,
      );
    }
  }
}