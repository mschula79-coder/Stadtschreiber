// TODO: OSM-ID Check
// TODO: POI‑Editor
// TODO: Supabase Import umbauen: siehe Chat: 1. Du importierst OSM‑Daten NICHT per „truncate + insert“

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/poi.dart';
import '../services/debug_service.dart';

class PoiRepository {
  final supabase = Supabase.instance.client;

  Future<List<PointOfInterest>> loadPois(
    List<String> selectedCategories,
  ) async {
    final supabase = Supabase.instance.client;

    final query = supabase
        .from('export_pois')
        .select('id, name, lat, lon, tags, categories, photo_url, history')
        .not('name', 'is', null)
        .neq('name', '');

    // Hier kommt das Multi-Kategorien-Filtering rein:
    if (selectedCategories.isNotEmpty) {
      // POI wird geladen, wenn categories irgendeine der ausgewählten Kategorien enthält
      query.overlaps('categories', selectedCategories);
    }

    query.or(
      'tags.ilike.%addr:city=Basel%,'
      'and(lat.gte.47.532,lat.lte.47.590,lon.gte.7.560,lon.lte.7.645)',
    );

    query.order('name');

    final response = await query;

    return response
        .map<PointOfInterest>((row) => PointOfInterest.fromSupabase(row))
        .toList();
  }

  Future<void> savePoi(PointOfInterest poi) async {
    await supabase.from('export_pois').insert(poi.toMap());
  }

  Future<void> updatePoi(int id, PointOfInterest poi) async {
    await supabase.from('export_pois').update(poi.toMap()).eq('id', id);
  }

  Future<void> updatePoiCategories(int poiId, List<String> categories) async { 
    await supabase 
      .from('export_pois') 
      .update({'categories': categories}) 
      .eq('id', poiId); 
  }
}





/* class PoiRepository {
  final List<Map<String, String>> _parkMetadata = [
    {
      "name": "Schützenmattpark",
      "photoUrl":
          "https://images.unsplash.com/photo-1501785888041-af3ef285b470",
    },
    {
      "name": "Kannenfeldpark",
      "photoUrl":
          "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee",
    },
    {
      "name": "Erlenmattpark",
      "photoUrl":
          "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee",
    },
  ];
 */