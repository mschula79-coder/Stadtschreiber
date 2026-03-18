import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/category.dart';
import 'package:stadtschreiber/models/rating_criterion.dart';
import 'package:stadtschreiber/state/categories_state.dart';
import 'package:stadtschreiber/provider/category_repository_provider.dart';

final categoriesProvider =
    NotifierProvider<CategoriesNotifier, CategoriesStateData>(
      CategoriesNotifier.new,
      name: 'categoriesProvider',
    );

final criteriaForCategoryProvider =
    FutureProvider.family<List<RatingCriterionDTO>, String>((
      ref,
      categoryId,
    ) async {
      final repo = ref.read(categoriesRepositoryProvider);
      return repo.loadCriteriaForCategory(categoryId);
    });

final categoryIdBySlugProvider = Provider.family<String?, String>((ref, slug) {
  final categories = ref.watch(categoriesProvider).categories;

  String? search(List<CategoryNode> nodes) {
    for (final node in nodes) {
      if (node.value == slug) return node.id;

      final result = search(node.children);
      if (result != null) return result;
    }
    return null;
  }

  return search(categories);
});

class CategoriesNotifier extends Notifier<CategoriesStateData> {
  @override
  CategoriesStateData build() => CategoriesStateData.initial;

  Future<void> loadCategories() async {
    final repo = ref.read(categoriesRepositoryProvider);
    final list = await repo.loadCategories();

    // Map bauen: slug → id
    final slugToId = <String, String>{};

    void collect(CategoryNode node) {
      if (node.value != null) {
        slugToId[node.value!] = node.id;
      }
      for (final child in node.children) {
        collect(child);
      }
    }

    for (final root in list) {
      collect(root);
    }

    state = state.copyWith(categories: list, slugToId: slugToId);
  }
}
