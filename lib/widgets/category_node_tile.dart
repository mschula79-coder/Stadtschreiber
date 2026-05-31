import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/provider/categories_provider.dart';
import 'package:stadtschreiber/provider/category_repository_provider.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';

import '../models/category.dart';

class PoiCategoryNodeTile extends ConsumerWidget {
  final CategoryNode node;
  final bool? isCriterionMode;
  final String? criterionId;

  const PoiCategoryNodeTile({
    super.key,
    required this.node,
    this.isCriterionMode,
    this.criterionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poi = ref.watch(selectedPoiProvider);

    final hasChildren = node.children.isNotEmpty;

    if (hasChildren) {
      return ExpansionTile(
        title: Text(node.label),
        visualDensity: VisualDensity.compact,
        children: node.children
            .map(
              (child) => PoiCategoryNodeTile(
                node: child,
                isCriterionMode: isCriterionMode,
                criterionId: criterionId,
              ),
            )
            .toList(),
      );
    }

    final slug = node.value!;

    List<String> criterionCategories = [];

    if (criterionId != null) {
      final criterionCategoriesAsync = ref.watch(
        categorySlugsForCriterionProvider(criterionId!),
      );
      criterionCategories = criterionCategoriesAsync.asData?.value ?? [];
    }

    bool? isSelected;

    if (isCriterionMode == null || isCriterionMode == false) {
        isSelected = poi!.categories?.contains(slug);
    } else if (isCriterionMode!) {
      isSelected = criterionCategories.contains(slug);
    }

    return CheckboxListTile(
      title: Text(node.label),
      visualDensity: VisualDensity.compact,
      value: isSelected,
      onChanged: (checked) async {
        if (checked == null) return;
        if (isCriterionMode == null || !isCriterionMode!) {
          {
            final updatedPoi = await ref
                .read(poiRepositoryProvider)
                .updatePoiCategory(poi: poi!, category: slug, enabled: checked);
            ref.read(selectedPoiProvider.notifier).setPoi(updatedPoi);
          }
        } else {
          final categoryId = ref.read(categoryIdBySlugProvider(slug));
          if (categoryId != null) {
            ref
                .read(categoriesRepositoryProvider)
                .updateCriterionCategoryRelation(
                  criterionId: criterionId!,
                  categoryId: categoryId,
                  enabled: checked,
                );
          }
          return;
        }
      },
    );
  }
}
