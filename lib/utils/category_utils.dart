import 'package:stadtschreiber/models/category.dart';

class CategoryUtils {
  static List<CategoryNode> collectLeafCategories(CategoryNode node) {
    final result = <CategoryNode>[];

    void traverse(CategoryNode n) {
      if (n.children.isEmpty) {
        result.add(n);
      } else {
        for (final child in n.children) {
          traverse(child);
        }
      }
    }

    traverse(node);

    // ⭐ alphabetisch sortieren
    result.sort((a, b) => a.label.compareTo(b.label));

    return result;
  }

  static List<CategoryNode> collectAllLeafCategories(List<CategoryNode> roots) {
    final result = <CategoryNode>[];

    void traverse(CategoryNode n) {
      if (n.children.isEmpty) {
        result.add(n);
      } else {
        for (final child in n.children) {
          traverse(child);
        }
      }
    }

    for (final root in roots) {
      traverse(root);
    }

    result.sort((a, b) => a.label.compareTo(b.label));
    return result;
  }
}
