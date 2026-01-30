// TODO: OSM-ID Check
// TODO: Supabase Import umbauen: siehe Chat: 1. Du importierst OSM‑Daten NICHT per „truncate + insert“

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/poi.dart';
import '../models/article_entry.dart';

/* import '../services/debug_service.dart';
 */
class PoiRepository {
  final supabase = Supabase.instance.client;

  Future<List<PointOfInterest>> loadPois(
    List<String> selectedCategories,
  ) async {
    final supabase = Supabase.instance.client;

    if (selectedCategories.isEmpty) return [];

    var query = supabase
        .from('pois')
        .select('id, name, lat, lon, categories, featured_image_url, history')
        .overlaps('categories', selectedCategories)
        .order('name');

    final response = await query;
    return response
        .map<PointOfInterest>((row) => PointOfInterest.fromSupabase(row))
        .toList();
  }

  Future<void> savePoi(PointOfInterest poi) async {
    await supabase.from('pois').insert(poi.toMap());
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
    String history,
    String featuredImageUrl,
  ) async {
    final supabase = Supabase.instance.client;

    await supabase
        .from('pois')
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
  }

  Future<PointOfInterest?> loadPoiById(int id) async {
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
