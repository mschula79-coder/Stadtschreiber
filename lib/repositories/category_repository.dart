import 'package:stadtschreiber/models/rating_criterion.dart';
import 'package:stadtschreiber/utils/language_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category.dart';
import '../models/category_dto.dart';

// TODO ln

class CategoryRepository {
  Future<List<CategoryNode>> loadCategoryTree() async {
    final supabase = Supabase.instance.client;

    final catListRaw = await supabase
        .from('categories')
        .select('id, slug, name, sort_order')
        .eq('is_active', true)
        .order('name', ascending: true);

    final Map<String, CategoryDto> categories = {
      for (var c in catListRaw) c['id'] as String: CategoryDto.fromJson(c),
    };

    final parentChildRelationsRaw = await supabase
        .from('category_relations')
        .select('parent_id, child_id');

    final Map<String, List<String>> childrenMap = {};

    for (var rel in parentChildRelationsRaw) {
      final parent = rel['parent_id'];
      final child = rel['child_id'];

      childrenMap.putIfAbsent(parent, () => []);
      childrenMap[parent]!.add(child);
    }

    // **ADDED**: collect all child ids into a Set for parent detection
    final Set<String> allChildren = parentChildRelationsRaw
        .map((r) => r['child_id'] as String)
        .toSet();

    // **ADDED**: rootIds are those not present in allChildren
    final rootIds = categories.keys.where((id) => !allChildren.contains(id));

    // **ADDED**: pass allChildren into _buildNode so nodes know if they have parents
    final roots =
        rootIds
            .map((id) => _buildNode(id, categories, childrenMap, allChildren))
            .toList()
          ..sort((a, b) {
            final dtoA = categories[a.id]!;
            final dtoB = categories[b.id]!;

            final orderCompare = dtoA.sortOrder.compareTo(dtoB.sortOrder);
            if (orderCompare != 0) return orderCompare;

            return germanCompare(dtoA.name, dtoB.name);
          });

    return roots;
  }

  Future<List<CategoryDto>> categoriesList() async {
    final supabase = Supabase.instance.client;

    final catListRaw = await supabase
        .from('categories')
        .select('id, slug, name')
        .eq('is_active', true)
        .order('name', ascending: true);

    final List<CategoryDto> categories = (catListRaw as List)
        .map<CategoryDto>((c) => CategoryDto.fromJson(c))
        .toList();
    return categories;
  }

  Future<CategoryDto> addCategory({
    required String name,
    required String slug,
  }) async {
    final supabase = Supabase.instance.client;

    final newCategoryRaw = await supabase
        .from('categories')
        .insert({'name': name, 'slug': slug, 'is_active': true})
        .select()
        .single();

    return CategoryDto.fromJson(newCategoryRaw);
  }

  Future<CategoryDto> updateCategory({
    required String id,
    required String name,
    String? slug,
  }) async {
    final supabase = Supabase.instance.client;

    final updatedRaw = await supabase
        .from('categories')
        .update({'name': name, if (slug != null) 'slug': slug})
        .eq('id', id)
        .select()
        .single();

    return CategoryDto.fromJson(updatedRaw);
  }

  Future<void> deleteCategory(String slug) async {
    final supabase = Supabase.instance.client;

    final poisUsingCategory = await supabase
        .from('pois')
        .select('categories')
        .overlaps('categories', [slug])
        .limit(1);

    if ((poisUsingCategory as List).isNotEmpty) {
      throw Exception(
        'Es existieren POIs mit dieser Kategorie. Die Kategorie kann nicht gelöscht werden.',
      );
    }

    await supabase.from('categories').delete().eq('slug', slug);
  }

  Future<List<CategoryDto>> childrenForParentId(String parentId) async {
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase
          .from('category_relations')
          .select('child_id, categories!category_relations_child_id_fkey(*)')
          .eq('parent_id', parentId);

   /*    print('childrenForParentId response type=${response.runtimeType}');
      print('childrenForParentId raw=$response'); */

      final List<CategoryDto> children = (response as List).map((row) {
        final categoriesData = row['categories'];
        if (categoriesData == null) {
          throw Exception('Erwartetes "categories" Objekt fehlt in row: $row');
        }
        final Map<String, dynamic> map = Map<String, dynamic>.from(
          categoriesData as Map,
        );
        return CategoryDto.fromJson(map);
      }).toList();

      return children;
    } catch (e, st) {
/*       print('Fehler in childrenForParentId: $e');
      print('$st'); */
      rethrow;
    }
  }

  Future<void> addCategoryRelation({
    required String parentId,
    required String childId,
  }) async {
    final supabase = Supabase.instance.client;

    // Verhindere, dass eine Kategorie sich selbst als Kind bekommt
    if (parentId == childId) {
      throw Exception(
        'Eine Kategorie kann nicht mit sich selbst verknüpft werden.',
      );
    }

    final existing = await supabase
        .from('category_relations')
        .select('parent_id, child_id')
        .eq('parent_id', parentId)
        .eq('child_id', childId)
        .limit(1);

    if ((existing as List).isNotEmpty) {
      throw Exception('Die Relation existiert bereits.');
    }

    final parentExists = await supabase
        .from('categories')
        .select('id')
        .eq('id', parentId)
        .limit(1);
    if ((parentExists as List).isEmpty) {
      throw Exception('Elternkategorie nicht gefunden.');
    }

    final childExists = await supabase
        .from('categories')
        .select('id')
        .eq('id', childId)
        .limit(1);
    if ((childExists as List).isEmpty) {
      throw Exception('Kindkategorie nicht gefunden.');
    }

    // Einfügen der Relation
    await supabase.from('category_relations').insert({
      'parent_id': parentId,
      'child_id': childId,
    });
  }

  Future<void> deleteCategoryRelation({
    required String parentId,
    required String childId,
  }) async {
    final supabase = Supabase.instance.client;

    if (parentId == childId) {
      throw Exception(
        'Eine Kategorie kann nicht von sich selbst entfernt werden.',
      );
    }

    // Prüfen, ob die Relation existiert
    final existing = await supabase
        .from('category_relations')
        .select('parent_id, child_id')
        .eq('parent_id', parentId)
        .eq('child_id', childId)
        .limit(1);

    if ((existing as List).isEmpty) {
      throw Exception('Die Relation existiert nicht.');
    }

    // Löschen der Relation
    final response = await supabase
        .from('category_relations')
        .delete()
        .eq('parent_id', parentId)
        .eq('child_id', childId);

    // Optional: Fehlerbehandlung falls Supabase einen Fehler zurückgibt
    if (response == null) {
      throw Exception('Fehler beim Löschen der Relation.');
    }
  }

  CategoryNode _buildNode(
    String id,
    Map<String, CategoryDto> categories,
    Map<String, List<String>> childrenMap,
    // **ADDED**: receive allChildren to determine hasParents for each node
    Set<String> allChildren,
  ) {
    final dto = categories[id]!;

    final childIds = childrenMap[id] ?? [];
    final children =
        childIds
            .map(
              (childId) =>
                  _buildNode(childId, categories, childrenMap, allChildren),
            )
            .toList()
          ..sort((a, b) => a.label.compareTo(b.label));

    return CategoryNode(
      id: dto.id,
      label: dto.name,
      value: dto.slug,
      children: children,
      // **ADDED**: set hasParents based on whether this id appears as a child anywhere
      hasParents: allChildren.contains(id),
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
        .order('name', ascending: true);

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
