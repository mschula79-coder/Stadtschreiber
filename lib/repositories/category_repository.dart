import 'package:stadtschreiber/models/rating_criterion.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category.dart';
import '../models/category_dto.dart';

class CategoryRepository {
  Future<List<CategoryNode>> loadCategories() async {
    final supabase = Supabase.instance.client;

    final catListRaw = await supabase
        .from('categories')
        .select('id, slug, name, sort_order, icon_source, icon_name')
        .eq('is_active', true)
        .order('name', ascending: true);

    final Map<String, CategoryDto> categories = {
      for (var c in catListRaw) c['id'] as String: CategoryDto.fromJson(c),
    };

    final parentChildRelationsRaw = await supabase
        .from('category_relations')
        .select('parent_id, child_id');

    final Map<String, List<String>> childrenMap = {};

    for (var r in parentChildRelationsRaw) {
      final parent = r['parent_id'];
      final child = r['child_id'];

      childrenMap.putIfAbsent(parent, () => []);
      childrenMap[parent]!.add(child);
    }

    final allChildren = parentChildRelationsRaw
        .map((r) => r['child_id'])
        .toSet();
    final rootIds = categories.keys.where((id) => !allChildren.contains(id));

    final roots =
        rootIds.map((id) => _buildNode(id, categories, childrenMap)).toList()
          ..sort((a, b) {
            final dtoA = categories[a.id]!;
            final dtoB = categories[b.id]!;
            return dtoA.sortOrder.compareTo(dtoB.sortOrder);
          });

    return roots;
  }

  CategoryNode _buildNode(
    String id,
    Map<String, CategoryDto> categories,
    Map<String, List<String>> childrenMap,
  ) {
    final dto = categories[id]!;

    final childIds = childrenMap[id] ?? [];
    final children =
        childIds
            .map((childId) => _buildNode(childId, categories, childrenMap))
            .toList()
          ..sort((a, b) => a.label.compareTo(b.label));

    return CategoryNode(
      id: dto.id,
      label: dto.name,
      value: dto.slug,
      children: children,
    );
  }

  Future<List<RatingCriterionDTO>> criteriaForCategory(
    String categoryId,
  ) async {
    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('category_rating_criteria_relations')
        .select('global_rating_criteria(*)')
        .eq('category_id', categoryId)
        .order('position');
    return response
        .map(
          (row) =>
              RatingCriterionDTO.fromJson(row['global_rating_criteria'] ?? ''),
        )
        .toList();
  }

  Future<List<RatingCriterionDTO>> criteriaListGlobal() async {
    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('global_rating_criteria')
        .select('*')
        .order('name',ascending: true);

    return response.map<RatingCriterionDTO>((row) {
      return RatingCriterionDTO.fromJson(row);
    }).toList();
  }

  Future<List<String>> categorySlugsForCriterion(String criterionId) async {
    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('category_rating_criteria_relations')
        .select('categories(*)')
        .eq('criterion_id', criterionId)
        .order('categories.name');

    return response.map((row) {
      final data = row['categories'];
      final slug = data['slug'];
      if (slug is String) return slug;
      throw Exception("Invalid row format: $row");
    }).toList();
  }

  Future<RatingCriterionDTO> newCriterion(RatingCriterionDTO criterion) async {
    final supabase = Supabase.instance.client;

    final newCriterionRaw = await supabase
        .from('global_rating_criteria')
        .insert({
          'name': criterion.name,
          'description': criterion.description,
          'score_descriptions': criterion.scoreDescriptions,
        })
        .select()
        .single();
    return RatingCriterionDTO.fromJson(newCriterionRaw);
  }

  Future<void> updateCriterionCategoryRelation({
    required String criterionId,
    required String categoryId,
    required bool enabled,
  }) async {
    final supabase = Supabase.instance.client;

    if (enabled) {
      await supabase.from('category_rating_criteria_relations').insert({
        'criterion_id': criterionId,
        'category_id': categoryId,
      });
    } else {
      await supabase
          .from('category_rating_criteria_relations')
          .delete()
          .eq('criterion_id', criterionId)
          .eq('category_id', categoryId);
    }
  }

  Future<void> updateCriterion(RatingCriterionDTO criterion) async {
    final supabase = Supabase.instance.client;

    await supabase
        .from('global_rating_criteria')
        .update({
          'name': criterion.name,
          'description': criterion.description,
          'score_descriptions': criterion.scoreDescriptions,
        })
        .eq('id', criterion.id);
  }

  Future<void> deleteCriterion(RatingCriterionDTO criterion) async {
    final supabase = Supabase.instance.client;

    await supabase
        .from('global_rating_criteria')
        .delete()
        .eq('id', criterion.id);
  }
}
