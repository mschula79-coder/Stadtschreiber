import 'package:stadtschreiber/models/history_entry.dart';
import 'package:stadtschreiber/models/image_entry.dart';
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
          'id, name, lat, lon, categories, featured_image_url, history, articles, metadata, street, house_number, postcode, city, district, country, display_address, description, geom_area, osm_id, images',
        )
        .overlaps('categories', selectedCategories)
        .order('name');

    return response
        .map<PointOfInterest>((row) => PointOfInterest.fromSupabase(row))
        .toList();
  }

  // TODO combine with New Poi
  Future<PointOfInterest> saveOSMPoiToSupabase(PointOfInterest poi) async {
    poi.newPoi = true;
    poi.id = '-1';

    final map = poi.toMap();
    map.remove('id');

    final result = await supabase.from('pois').insert(map).select().single();

    poi.id = result['id'] as String;
    DebugService.log('neuer POI gespeichert: $result');

    return poi;
  }

  Future<void> deletePoi(String id) async {
    await supabase.from('pois').delete().eq('id', id);
  }

  Future<void> updatePoiCategories({
    required String poiId,
    required List<String> categories,
  }) async {
    await supabase
        .from('pois')
        .update({'categories': categories})
        .eq('id', poiId);
  }

  Future<PointOfInterest> updatePoiCategory({
    required PointOfInterest poi,
    required String category,
    required bool enabled,
  }) async {
    // IMMER neue Liste erzeugen
    final newCategories = <String>[...(poi.categories ?? [])];

    if (enabled) {
      if (!newCategories.contains(category)) {
        newCategories.add(category);
      }
    } else {
      newCategories.remove(category);
    }

    // Supabase speichern
    await supabase
        .from('pois')
        .update({'categories': newCategories})
        .eq('id', poi.id);

    // neues POI-Objekt zurückgeben
    return poi.cloneWithNewValues(categories: newCategories);
  }

  Future<void> updatePoiDataInSupabase({
    required String id,
    String? name,
    String? history,
    String? featuredImageUrl,
    bool clearFeaturedImage = false,
    List<ArticleEntry>? articles,
    List<HistoryEntry>? historyEntries,
    PoiMetadata? metadata,
    String? description,
    List<ImageEntry>? images,
  }) async {
    final supabase = Supabase.instance.client;

    // Dynamische Update-Map
    final Map<String, dynamic> updateData = {};

    if (name != null) updateData['name'] = name;
    if (history != null) updateData['history'] = history;

    if (clearFeaturedImage) {
      updateData['featured_image_url'] = null; // explizit löschen
    } else if (featuredImageUrl != null) {
      updateData['featured_image_url'] = featuredImageUrl; // neuen Wert setzen
    }

    if (articles != null) {
      updateData['articles'] = articles.map((e) => e.toJson()).toList();
    }
    if (historyEntries != null) {
      updateData['history'] = historyEntries.map((e) => e.toJson()).toList();
    }
    if (metadata != null) updateData['metadata'] = metadata.toJson();
    if (description != null) updateData['description'] = description;
    if (images != null) {
      updateData['images'] = images.map((e) => e.toJson()).toList();
    }

    if (updateData.isEmpty) return; // nichts zu tun

    await supabase.from('pois').update(updateData).eq('id', id);
  }

  // TODO Combine with updateData
  Future<void> updatePoiGeomInSupabase(PointOfInterest poi) async {
    final supabase = Supabase.instance.client;
    await supabase
        .from('pois')
        .update({
          'geom_area': poi.geomArea,
          'lat': poi.location.lat,
          'lon': poi.location.lon,
        })
        .eq('id', poi.id);

    DebugService.log(
      'updatePoiGeomInSupabase name: $poi.name geom_area: $poi.geomArea label_location: $poi.location',
    );
  }

  Future<PointOfInterest?> loadPoiById(String id) async {
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
    if (query.startsWith('nearby')) {
      final cleanedQuery = query.substring('nearby'.length).trim();
      final osmResult = await searchNearbyOverpass(
        query: cleanedQuery,
        lat: lat,
        lon: lon,
      );
      final List<PointOfInterest> pois = osmResult.map<PointOfInterest>((row) {
        return PointOfInterest.fromOverpass(row);
      }).toList();
      return pois;
    }
    if (query.startsWith('nearby buildings')) {
      final cleanedQuery = query.substring('nearby buildings'.length).trim();
      final osmResult = await searchNearbyOverpassBuildings(
        query: cleanedQuery,
        lat: lat,
        lon: lon,
      );
      final List<PointOfInterest> pois = osmResult.map<PointOfInterest>((row) {
        return PointOfInterest.fromOverpass(row);
      }).toList();
      return pois;
    } else {
      final response = await supabase.rpc(
        'pois_search_with_distance_and_address',
        params: {'q': query, 'lat_input': lat, 'lon_input': lon},
      );
      final List<PointOfInterest> pois = response
          .map<PointOfInterest>((row) => PointOfInterest.fromSupabase(row))
          .toList();
      return pois;
    }
  }

  // TODO change to updateData
  Future<void> updatePoiAddressInSupabase(
    String id,
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

  // Combine with newOSMPoi, combine with check duplicate?
  Future<PointOfInterest> newPoi(Geographic location) async {
    final supabase = Supabase.instance.client;

    final result = await supabase
        .from('pois')
        .insert({'name': 'newPOI', 'lat': location.lat, 'lon': location.lon})
        .select()
        .single();
    final newId = result['id'];

    return PointOfInterest(
      id: newId,
      name: 'newPOI',
      location: location,
      categories: [],
      articles: [],
      historyEntries: [],
      metadata: PoiMetadata(),
      geometryType: 'point',
      newPoi: true,
      images: [],
    );
  }

  /// Check if a POI with the given OSM ID already exists in the database and load it if it does.
  // TODO Combine with loadPoiById
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
