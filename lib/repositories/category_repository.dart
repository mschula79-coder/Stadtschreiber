import 'package:stadtschreiber/models/rating_criterion.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category.dart';
import '../models/category_dto.dart';

class CategoryRepository {
  Future<List<CategoryNode>> loadCategoryTree() async {
    final supabase = Supabase.instance.client;

    final catListRaw = await supabase
        .from('categories')
        .select('id, slug, sort_order, labels')
        .eq('is_active', true);

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
    final roots = rootIds
        .map((id) => _buildNode(id, categories, childrenMap, allChildren))
        .toList();

    return roots;
  }

  Future<List<CategoryDto>> categoriesList() async {
    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('categories')
        .select('id, slug, sort_order, labels')
        .eq('is_active', true);

    return response
        .map<CategoryDto>((row) => CategoryDto.fromJson(row))
        .toList();
  }

  Future<CategoryDto> addCategory({
    required String slug,
    required Map<String, String> labels,
  }) async {
    final supabase = Supabase.instance.client;

    final normalizedSlug = slug.trim();

    if (normalizedSlug.isEmpty) {
      throw ArgumentError('Der Kategorie-Slug darf nicht leer sein.');
    }

    final germanLabel = labels['de-DE']?.trim();

    if (germanLabel == null || germanLabel.isEmpty) {
      throw ArgumentError('Das deutsche Label darf nicht leer sein.');
    }

    final newCategoryRaw = await supabase
        .from('categories')
        .insert({
          'name': germanLabel,
          'slug': normalizedSlug,
          'labels': labels,
          'is_active': true,
        })
        .select('id, slug, sort_order, labels')
        .single();

    return CategoryDto.fromJson(newCategoryRaw);
  }

  Future<CategoryDto> updateCategory({
    required String id,
    required String slug,
    required Map<String, String> labels,
  }) async {
    final supabase = Supabase.instance.client;

    final normalizedSlug = slug.trim();

    if (normalizedSlug.isEmpty) {
      throw ArgumentError('Der Kategorie-Slug darf nicht leer sein.');
    }

    final germanLabel = labels['de-DE']?.trim();

    if (germanLabel == null || germanLabel.isEmpty) {
      throw ArgumentError('Das deutsche Label darf nicht leer sein.');
    }

    final updatedRaw = await supabase
        .from('categories')
        .update({'name': germanLabel, 'slug': normalizedSlug, 'labels': labels})
        .eq('id', id)
        .select('id, slug, sort_order, labels')
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

    final response = await supabase
        .from('category_relations')
        .select('''
        child_id,
        categories!category_relations_child_id_fkey(
          id,
          slug,
          sort_order,
          labels
        )
        ''')
        .eq('parent_id', parentId);

    return response.map<CategoryDto>((row) {
      final categoryData = row['categories'];

      if (categoryData is! Map) {
        throw FormatException('Das erwartete Kategorieobjekt fehlt: $row');
      }

      return CategoryDto.fromJson(Map<String, dynamic>.from(categoryData));
    }).toList();
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
    Set<String> allChildren,
  ) {
    final dto = categories[id]!;
    final childIds = childrenMap[id] ?? const <String>[];

    final children = childIds
        .where(categories.containsKey)
        .map(
          (childId) =>
              _buildNode(childId, categories, childrenMap, allChildren),
        )
        .toList();

    return CategoryNode(
      id: dto.id,
      slug: dto.slug,
      sortOrder: dto.sortOrder,
      labels: dto.labels,
      children: children,
      hasParents: allChildren.contains(id),
    );
  }

  Future<int> poiCountForCategory(String categorySlug) async {
    final supabase = Supabase.instance.client;
    final normalizedSlug = categorySlug.trim();

    if (normalizedSlug.isEmpty) {
      return 0;
    }

    final count = await supabase.from('pois').count(CountOption.exact).contains(
      'categories',
      [normalizedSlug],
    );

    return count;
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
        .select('''
        categories!category_rating_criteria_relations_category_id_fkey(
          slug
        )
        ''')
        .eq('criterion_id', criterionId);

    return response.map<String>((row) {
      final categoryData = row['categories'];

      if (categoryData is! Map) {
        throw FormatException('Das erwartete Kategorieobjekt fehlt: $row');
      }

      final slug = categoryData['slug'];

      if (slug is! String || slug.trim().isEmpty) {
        throw FormatException('Ungültiger Kategorie-Slug: $row');
      }

      return slug;
    }).toList();
  }

  Future<RatingCriterionDTO> newCriterion(RatingCriterionDTO criterion) async {
    final supabase = Supabase.instance.client;

    final newCriterionRaw = await supabase
        .from('global_rating_criteria')
        .insert({'name': criterion.name, 'description': criterion.description})
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
        .update({'name': criterion.name, 'description': criterion.description})
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
