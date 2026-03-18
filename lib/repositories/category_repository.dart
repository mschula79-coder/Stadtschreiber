import 'package:flutter/material.dart';
import 'package:stadtschreiber/models/rating_criterion.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category.dart';
import '../models/category_dto.dart';
import '../services/debug_service.dart';

class CategoryRepository {
  Future<List<CategoryNode>> loadCategories() async {
    final supabase = Supabase.instance.client;

    final catListRaw = await supabase
        .from('categories')
        .select('id, slug, name, sort_order, icon_source, icon_name')
        .eq('is_active', true)
        .order('sort_order', ascending: true);

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

    final roots = rootIds
        .map((id) => _buildNode(id, categories, childrenMap))
        .toList();
    return roots;
  }

  CategoryNode _buildNode(
    String id,
    Map<String, CategoryDto> categories,
    Map<String, List<String>> childrenMap,
  ) {
    final dto = categories[id]!;

    final icon = (dto.iconSource != null && dto.iconName != null)
        ? CategoryIcon(type: dto.iconSource!, value: dto.iconName!)
        : null;

    final childIds = childrenMap[id] ?? [];

    return CategoryNode(
      id: dto.id,
      label: dto.name,
      value: dto.slug,
      icon: icon,
      children: childIds
          .map((childId) => _buildNode(childId, categories, childrenMap))
          .toList(),
      ratingCriteria: [],
    );
  }

  Future<List<RatingCriterionDTO>> loadCriteriaForCategory(
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
          (row) => RatingCriterionDTO.fromJson(row['global_rating_criteria']),
        )
        .toList();
  }
}

class CategoryState extends ChangeNotifier {
  List<CategoryNode> categories = [];

  void setCategories(List<CategoryNode> list) {
    categories = list;
    DebugService.log('CategoryState.setCategories - notifyListeners');
    notifyListeners();
  }
}
