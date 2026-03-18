import 'package:stadtschreiber/models/category.dart';

class CategoriesStateData {
  final List<CategoryNode> categories;
    final Map<String, String> slugToId;

  const CategoriesStateData({
    required this.categories,
    required this.slugToId
    });

  CategoriesStateData copyWith({
    List<CategoryNode>? categories,
    Map<String, String>? slugToId
  }) {
    return CategoriesStateData(
      categories: categories ?? this.categories,
      slugToId: slugToId ?? this.slugToId
    );
  }

  static const initial = CategoriesStateData(categories: [], slugToId: {});
}
