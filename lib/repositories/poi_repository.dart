import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/poi.dart';
import '../models/district.dart';
import '../models/article_entry.dart';

class PoiRepository {
  final supabase = Supabase.instance.client;

  Future<List<PointOfInterest>> loadPoisforSelectedCategories(
    List<String> selectedCategories,
  ) async {
    final supabase = Supabase.instance.client;

    if (selectedCategories.isEmpty) return [];

    var query = supabase
        .from('pois')
        .select(
          'id, name, lat, lon, categories, featured_image_url, history, articles',
        )
        .overlaps('categories', selectedCategories)
        .order('name');

    final response = await query;
    return response
        .map<PointOfInterest>((row) => PointOfInterest.fromSupabase(row))
        .toList();
  }

  Future<List<PointOfInterest>> loadDistrictPois() async {
    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('districts')
        .select('id, name, geom, featured_image_url, history, articles')
        .order('name');

    return response.map<PointOfInterest>((row) {
      // Build District
      final district = District.fromSupabase(row);

      // Convert District → POI
      return district.toPoi(
        featuredImageUrl: row['featured_image_url'],
        history: row['history'],
        articles: row['articles'] == null
            ? null
            : (row['articles'] as List)
                  .map((e) => ArticleEntry.fromJson(e))
                  .toList(),
      );
    }).toList();
  }

  Future<void> savePoi(PointOfInterest poi) async {
    poi.categories.contains('districts')
        ? await supabase.from('districts').insert(poi.toMap())
        : await supabase.from('pois').insert(poi.toMap());
  }

  Future<void> updatePoiCategories({
    required int poiId,
    required List<String> categories,
  }) async {
    await supabase
        .from('pois')
        .update({'categories': categories})
        .eq('id', poiId);
  }

  static Future<void> updatePoi(
    int id,
    String? history,
    String? featuredImageUrl,
  ) async {
    final supabase = Supabase.instance.client;

    await supabase
        .from('pois')
        .update({'history': history, 'featured_image_url': featuredImageUrl})
        .eq('id', id);
    await supabase
        .from('districts')
        .update({'history': history, 'featured_image_url': featuredImageUrl})
        .eq('id', id);
  }

  static Future<void> updatePoiArticles(
    int id,
    List<ArticleEntry> articles,
  ) async {
    final supabase = Supabase.instance.client;

    await supabase
        .from('pois')
        .update({'articles': articles.map((e) => e.toJson()).toList()})
        .eq('id', id);

    await supabase
        .from('districts')
        .update({'articles': articles.map((e) => e.toJson()).toList()})
        .eq('id', id);
  }

  Future<PointOfInterest?> loadPoiById(int id, List<String>? categories) async {
    if (categories == null || categories.contains('districts')) {
      final result2 = await supabase
          .from('districts')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (result2 != null) {
        return PointOfInterest.fromSupabase(result2);
      } else {
        return null;
      }
    }

    final result = await supabase
        .from('pois')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (result == null) return null;
    return PointOfInterest.fromSupabase(result);
  }

  Future<List<PointOfInterest>> searchPois(String query) async {
    final supabase = Supabase.instance.client;

    final q = query.toLowerCase();

    final result = await supabase
        .from('pois')
        .select()
        .or('name.ilike.%$q%, categories.cs.{$q}');

    return result
        .map<PointOfInterest>((row) => PointOfInterest.fromSupabase(row))
        .toList();
  }
}
