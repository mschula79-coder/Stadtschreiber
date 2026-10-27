import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/category.dart';
import 'package:stadtschreiber/models/category_dto.dart';
import 'package:stadtschreiber/models/rating_criterion.dart';
import 'package:stadtschreiber/provider/category_repository_provider.dart';
import 'package:stadtschreiber/state/categories_state.dart';

final categoriesProvider =
    NotifierProvider<CategoriesNotifier, CategoriesStateData>(
      CategoriesNotifier.new,
      name: 'categoriesProvider',
    );

class CategoriesNotifier extends Notifier<CategoriesStateData> {
  @override
  CategoriesStateData build() {
    return CategoriesStateData.initial;
  }

  Future<void> loadCategoryTree() async {
    final repo = ref.read(categoriesRepositoryProvider);

    final list = await repo.loadCategoryTree();

    final slugToId = <String, String>{};

    void collect(CategoryNode node) {
      slugToId[node.slug] = node.id;

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

final categoryIdBySlugProvider = Provider.family<String?, String>((ref, slug) {
  return ref.watch(categoriesProvider.select((state) => state.slugToId[slug]));
});

final criteriaForCategoryProvider =
    FutureProvider.family<List<RatingCriterionDTO>, String>((
      ref,
      categoryId,
    ) async {
      final repository = ref.read(categoriesRepositoryProvider);

      return repository.criteriaForCategory(categoryId);
    });

final categorySlugsForCriterionProvider =
    FutureProvider.family<List<String>, String>((ref, criterionId) {
      final repository = ref.read(categoriesRepositoryProvider);

      return repository.categorySlugsForCriterion(criterionId);
    });

final categoriesListProvider = FutureProvider<List<CategoryDto>>((ref) {
  final repository = ref.read(categoriesRepositoryProvider);

  return repository.categoriesList();
});

final childrenProvider = FutureProvider.family<List<CategoryDto>, String>((
  ref,
  parentId,
) {
  final repository = ref.read(categoriesRepositoryProvider);

  return repository.childrenForParentId(parentId);
});

final globalCriteriaProvider = FutureProvider<List<RatingCriterionDTO>>((ref) {
  final repository = ref.read(categoriesRepositoryProvider);

  return repository.criteriaListGlobal();
});

final poiCountForCategoryProvider = FutureProvider.autoDispose
    .family<int, String>((ref, categorySlug) async {
      final normalizedSlug = categorySlug.trim();

      if (normalizedSlug.isEmpty) {
        return 0;
      }

      final repository = ref.read(categoriesRepositoryProvider);

      return repository.poiCountForCategory(normalizedSlug);
    });
