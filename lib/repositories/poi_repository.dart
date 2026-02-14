import 'package:stadtschreiber/models/poi_metadata.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/poi.dart';
import '../models/article_entry.dart';

class PoiRepository {
  final supabase = Supabase.instance.client;

  // ------------------------------------------------------------
  // 1. POIs nach Kategorien laden
  // ------------------------------------------------------------
  Future<List<PointOfInterest>> loadPoisforSelectedCategories(
    List<String> selectedCategories,
  ) async {
    if (selectedCategories.isEmpty) return [];

    final response = await supabase
        .from('pois')
        .select(
          'id, name, lat, lon, geom, categories, featured_image_url, history, articles, metadata, street, house_number, postcode, city, district, country, display_address',
        )
        .overlaps('categories', selectedCategories)
        .order('name');

    return response
        .map<PointOfInterest>((row) => PointOfInterest.fromSupabase(row))
        .toList();
  }

  // ------------------------------------------------------------
  // 2. Neuen POI speichern
  // ------------------------------------------------------------
  Future<void> saveNewPoiToSupabase(PointOfInterest poi) async {
    await supabase.from('pois').insert(poi.toMap());
  }

  // ------------------------------------------------------------
  // 3. Kategorien eines POIs aktualisieren
  // ------------------------------------------------------------
  Future<void> updatePoiCategories({
    required int poiId,
    required List<String> categories,
  }) async {
    await supabase
        .from('pois')
        .update({'categories': categories})
        .eq('id', poiId);
  }

  // ------------------------------------------------------------
  // 4. POI-Daten aktualisieren (History, Image, Articles, Metadata)
  // ------------------------------------------------------------
  static Future<void> updatePoiDataInSupabase(
    int id,
    String? history,
    String? featuredImageUrl,
    List<ArticleEntry> articles,
    PoiMetadata metadata,
  ) async {
    final supabase = Supabase.instance.client;

    await supabase
        .from('pois')
        .update({
          'history': history,
          'featured_image_url': featuredImageUrl,
          'articles': articles.map((e) => e.toJson()).toList(),
          'metadata': metadata.toJson(),
        })
        .eq('id', id);
  }

  // ------------------------------------------------------------
  // 5. POI nach ID laden
  // ------------------------------------------------------------
  Future<PointOfInterest?> loadPoiById(int id) async {
    final result = await supabase
        .from('pois')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (result == null) return null;
    return PointOfInterest.fromSupabase(result);
  }

  Future<List<PointOfInterest>> searchPois(
    String query,
    double lat,
    double lon,
  ) async {
    /*print("🟢 searchPois() CALLED");

    final result = await supabase.rpc(
      'pois_search_with_distance_and_address',
      params: {'q': 'erle', 'lat_input': 47.55634, 'lon_input': 7.59253},
    );
    print("TEST RPC RESULT:");
    print(result); */

    final response = await supabase.rpc(
      'pois_search_with_distance_and_address',
      params: {'q': query, 'lat_input': lat, 'lon_input': lon},
    );

    final pois = response.map<PointOfInterest>((row) {
      final poi = PointOfInterest.fromSupabase(row);
      return poi;
    }).toList();

    

    /*final PointOfInterest firstpoi = list.first;
     print("FIRST POI: ${firstpoi.toString()}"); */

    return pois;
  }

  Future<void> updatePoiAddressInSupabase(
    int id,
    Map<String, String?> address,
  ) async {
    await supabase
        .from('pois')
        .update({
          'street': address['street'],
          'house_number': address['house_number'],
          'postcode': address['postcode'],
          'city': address['city'],
          'district': address['district'],
          'country': address['country'],
          'display_address': address['display_address'],
        })
        .eq('id', id);
  }
}
