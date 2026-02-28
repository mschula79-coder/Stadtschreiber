import 'package:stadtschreiber/models/poi_metadata.dart';
import 'package:stadtschreiber/services/debug_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:maplibre/maplibre.dart';

import '../models/poi.dart';
import '../models/article_entry.dart';
import '../utils/osm_utils.dart';

class PoiRepository {
  final supabase = Supabase.instance.client;

  Future<List<PointOfInterest>> loadPoisforSelectedCategories(
    List<String> selectedCategories,
  ) async {
    if (selectedCategories.isEmpty) return [];

    final response = await supabase
        .from('pois')
        .select(
          'id, name, lat, lon, categories, featured_image_url, history, articles, metadata, street, house_number, postcode, city, district, country, display_address, description, geom_area, osm_id',
        )
        .overlaps('categories', selectedCategories)
        .order('name');

    return response
        .map<PointOfInterest>((row) => PointOfInterest.fromSupabase(row))
        .toList();
  }

  Future<PointOfInterest> saveOSMPoiToSupabase(PointOfInterest poi) async {
    poi.newPoi = true;
    poi.id = null;

    final map = poi.toMap(); 
    map.remove('id');

    final result = await supabase
        .from('pois')
        .insert(map)
        .select()
        .single();

    poi.id = result['id'] as int;
    DebugService.log('neuer POI gespeichert: $result');

    return poi;
  }

  Future<void> deletePoi(int id) async {
    await supabase.from('pois').delete().eq('id', id);
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

  static Future<void> updatePoiDataInSupabase(
    int id,
    String? name,
    String? history,
    String? featuredImageUrl,
    List<ArticleEntry> articles,
    PoiMetadata metadata,
    String? description,
  ) async {
    final supabase = Supabase.instance.client;

    await supabase
        .from('pois')
        .update({
          'name': name,
          'history': history,
          'featured_image_url': featuredImageUrl,
          'articles': articles.map((e) => e.toJson()).toList(),
          'metadata': metadata.toJson(),
          'description': description,
        })
        .eq('id', id);
  }

  Future<void> updatePoiGeomInSupabase(PointOfInterest poi) async {
    final supabase = Supabase.instance.client;
    await supabase
        .from('pois')
        .update({
          'geom_area': poi.geomArea,
          'lat': poi.location.lat,
          'lon': poi.location.lon,
        })
        .eq('id', poi.id!);

    DebugService.log(
      'updatePoiGeomInSupabase name: $poi.name geom_area: $poi.geomArea label_location: $poi.location',
    );
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

  // TODO !! show all button, do not save to db, flag customDataChanged, search for buildings
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
    if (query.startsWith('nearby')) {
      final cleanedQuery = query.substring('nearby'.length).trim();
      final osmResult = await searchNearbyOverpass(
        query: cleanedQuery,
        lat: lat,
        lon: lon,
      );
      return osmResult.map<PointOfInterest>((row) {
        return PointOfInterest.fromOverpass(row);
      }).toList();
    } else {
      final response = await supabase.rpc(
        'pois_search_with_distance_and_address',
        params: {'q': query, 'lat_input': lat, 'lon_input': lon},
      );
      final pois = response.map<PointOfInterest>((row) {
        final poi = PointOfInterest.fromSupabase(row);
        return poi;
      }).toList();
      return pois;
    }
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

  Future<PointOfInterest> newPoi(Geographic location) async {
    final supabase = Supabase.instance.client;

    final result = await supabase
        .from('pois')
        .insert({
          'name': 'newPOI',
          'lat': location.lat,
          'lon': location.lon,
        })
        .select()
        .single();
    final newId = result['id'];

    return PointOfInterest(
      id: newId,
      name: 'newPOI',
      location: location,
      featuredImageUrl: '',
      categories: [],
      articles: [],
      metadata: PoiMetadata(),
      geometryType: 'point',
      newPoi: true,
    );
  }

  /// Check if a POI with the given OSM ID already exists in the database and load it if it does.
  Future<PointOfInterest?> loadPoiByOSMId(int osmId) async {
    final result = await supabase
        .from('pois')
        .select()
        .eq('osm_id', osmId)
        .maybeSingle();

    if (result == null) return null;
    return PointOfInterest.fromSupabase(result);
  }
}
