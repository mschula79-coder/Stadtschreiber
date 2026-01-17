// TODO: OSM-ID Check
// TODO: POI‑Editor
// TODO: Supabase Import umbauen: siehe Chat: 1. Du importierst OSM‑Daten NICHT per „truncate + insert“

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/poi.dart';

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
        .from('export_pois')
        .select('id, name, lat, lon, categories, featured_image_url, history')
        .overlaps('categories', selectedCategories)
        .order('name');

    final response = await query;
    return response
        .map<PointOfInterest>((row) => PointOfInterest.fromSupabase(row))
        .toList();
  }

  Future<void> savePoi(PointOfInterest poi) async {
    await supabase.from('export_pois').insert(poi.toMap());
  }

  Future<void> updatePoiCategories(int poiId, List<String> categories) async {
    await supabase
        .from('export_pois')
        .update({'categories': categories})
        .eq('id', poiId);
  }

  static Future<void> updatePoi(
    int id, 
    String history, 
    String featuredImageUrl
  ) async {
    final supabase = Supabase.instance.client;

    await supabase
        .from('export_pois')
        .update({
          'history': history,
          'featured_image_url': featuredImageUrl
          })
        
        .eq('id', id);
  }
}
