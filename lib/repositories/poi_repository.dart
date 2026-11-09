import 'package:maplibre/maplibre.dart';
import 'package:stadtschreiber/models/address.dart';
import 'package:stadtschreiber/models/article_entry.dart';
import 'package:stadtschreiber/models/history_entry.dart';
import 'package:stadtschreiber/models/image_entry.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/models/poi_feature_node.dart';
import 'package:stadtschreiber/models/poi_metadata.dart';
import 'package:stadtschreiber/models/search_progress.dart';
import 'package:stadtschreiber/services/debug_service.dart';
import 'package:stadtschreiber/utils/osm_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PoiRepository {
  final SupabaseClient supabase = Supabase.instance.client;

  int _lastRequestId = 0;

  Future<List<PointOfInterest>> loadPoisforSelectedCategories(
    List<String> selectedCategories,
  ) async {
    if (selectedCategories.isEmpty) {
      return const <PointOfInterest>[];
    }

    final response = await supabase
        .from('pois')
        .select(
          'id, name, lat, lon, categories, featured_image_url, history, articles, metadata, street, house_number, postcode, city, district, country, description, geom_area, osm_id, images',
        )
        .overlaps('categories', selectedCategories)
        .order('name');

    return response
        .map<PointOfInterest>(PointOfInterest.fromSupabase)
        .toList(growable: false);
  }

  Future<List<PointOfInterest>> loadTopNPois({
    required String categoryId,
    required String criterionId,
    required double limit,
  }) async {
    final rows = await supabase
        .from('poi_ratings_bayesian')
        .select()
        .eq('criterion_id', criterionId);

    if (rows.isEmpty) {
      return const <PointOfInterest>[];
    }

    final data = await supabase
        .from('categories')
        .select('slug')
        .eq('id', categoryId)
        .single();

    final categoryName = data['slug'] as String;

    final poiIds = rows
        .map((row) => row['poi_id'] as String)
        .toList(growable: false);

    final poisRaw = await supabase
        .from('pois')
        .select('*')
        .inFilter('id', poiIds);

    final pois = poisRaw
        .map<PointOfInterest>(PointOfInterest.fromSupabase)
        .toList();

    final filtered = pois.where((poi) {
      return poi.categories?.contains(categoryName) ?? false;
    }).toList();

    double bayesScore(Map<String, dynamic> row) {
      final averageRating = (row['avg_rating'] as num).toDouble();

      final ratingCount = (row['rating_count'] as num).toDouble();

      final globalAverage = (row['global_avg'] as num).toDouble();

      final minimumCount = (row['m'] as num).toDouble();

      return (ratingCount / (ratingCount + minimumCount)) * averageRating +
          (minimumCount / (ratingCount + minimumCount)) * globalAverage;
    }

    filtered.sort((first, second) {
      final firstRow = rows.firstWhere((row) => row['poi_id'] == first.id);

      final secondRow = rows.firstWhere((row) => row['poi_id'] == second.id);

      return bayesScore(secondRow).compareTo(bayesScore(firstRow));
    });

    if (limit.isInfinite) {
      return List<PointOfInterest>.unmodifiable(filtered);
    }

    return filtered.take(limit.toInt()).toList(growable: false);
  }

  Future<PointOfInterest> saveOSMPoiToSupabase(PointOfInterest poi) async {
    poi.newPoi = true;
    poi.id = '-1';

    final map = poi.toMap();

    map.remove('id');

    final result = await supabase.from('pois').insert(map).select().single();

    poi.id = result['id'] as String;

    DebugService.log('Neuer POI gespeichert: $result');

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
    final newCategories = <String>[...?poi.categories];

    if (enabled) {
      if (!newCategories.contains(category)) {
        newCategories.add(category);
      }
    } else {
      newCategories.remove(category);
    }

    await supabase
        .from('pois')
        .update({'categories': newCategories})
        .eq('id', poi.id);

    return poi.copyWith(categories: newCategories);
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
    final updateData = <String, dynamic>{};

    if (name != null) {
      updateData['name'] = name;
    }

    if (history != null) {
      updateData['history'] = history;
    }

    if (clearFeaturedImage) {
      updateData['featured_image_url'] = null;
    } else if (featuredImageUrl != null) {
      updateData['featured_image_url'] = featuredImageUrl;
    }

    if (articles != null) {
      updateData['articles'] = articles
          .map((article) => article.toJson())
          .toList(growable: false);
    }

    if (historyEntries != null) {
      updateData['history'] = historyEntries
          .map((entry) => entry.toJson())
          .toList(growable: false);
    }

    if (metadata != null) {
      updateData['metadata'] = metadata.toJson();
    }

    if (description != null) {
      updateData['description'] = description;
    }

    if (images != null) {
      updateData['images'] = images
          .map((image) => image.toJson())
          .toList(growable: false);
    }

    if (updateData.isEmpty) {
      return;
    }

    await supabase.from('pois').update(updateData).eq('id', id);
  }

  Future<void> updatePoiGeomInSupabase(PointOfInterest poi) async {
    await supabase
        .from('pois')
        .update({
          'geom_area': poi.geomArea,
          'lat': poi.location.lat,
          'lon': poi.location.lon,
        })
        .eq('id', poi.id);

    DebugService.log(
      'updatePoiGeomInSupabase name: ${poi.name} geom_area: ${poi.geomArea} label_location: ${poi.location}',
    );
  }

  Future<PointOfInterest?> loadPoiById(String id) async {
    final result = await supabase
        .from('pois')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (result == null) {
      return null;
    }

    return PointOfInterest.fromSupabase(result);
  }

  Future<List<PointOfInterest>> searchPois(
    String query,
    double lat,
    double lon,
  ) async {
    if (query.trim().isEmpty) {
      return const <PointOfInterest>[];
    }

    const debounceDuration = Duration(milliseconds: 500);

    final currentRequestId = ++_lastRequestId;

    await Future<void>.delayed(debounceDuration);

    if (currentRequestId != _lastRequestId) {
      return const <PointOfInterest>[];
    }

    final safeQuery = query.trim();

    if (safeQuery.startsWith('osm')) {
      final overpassPois = await searchPoisOverpass(safeQuery, lat, lon);

      if (currentRequestId != _lastRequestId) {
        return const <PointOfInterest>[];
      }

      return overpassPois;
    }

    List<Map<String, dynamic>> response;

    if (safeQuery.startsWith('tag')) {
      final cleanedQuery = safeQuery.substring('tag'.length).trim();

      response = await supabase
          .from('pois')
          .select('*')
          .ilike('osm_value', '%$cleanedQuery%')
          .order('name');
    } else {
      response = await supabase
          .from('pois')
          .select('*')
          .ilike('name', '%$safeQuery%')
          .order('name');
    }

    if (currentRequestId != _lastRequestId) {
      return const <PointOfInterest>[];
    }

    return response
        .map<PointOfInterest>(PointOfInterest.fromSupabase)
        .toList(growable: false);
  }

  Future<List<PointOfInterest>> searchPoisByAddress(
  String query,
  double latitude,
  double longitude, {
  void Function(SearchProgress progress)?
      onProgressChanged,
}) async {
  final normalizedQuery = query.trim();

  if (normalizedQuery.isEmpty) {
    return const <PointOfInterest>[];
  }

  final currentRequestId = ++_lastRequestId;

  onProgressChanged?.call(
    SearchProgress.stadtschreiber,
  );

  final supabasePois =
      await _searchPoisByAddressInSupabase(
    normalizedQuery,
  );

  if (currentRequestId != _lastRequestId) {
    return const <PointOfInterest>[];
  }

  if (supabasePois.isNotEmpty) {
    return List<PointOfInterest>.unmodifiable(
      supabasePois,
    );
  }

  onProgressChanged?.call(
    SearchProgress.openStreetMap,
  );

  final overpassPois =
      await _searchPoisByAddressInOverpass(
    query: normalizedQuery,
    latitude: latitude,
    longitude: longitude,
  );

  if (currentRequestId != _lastRequestId) {
    return const <PointOfInterest>[];
  }

  return List<PointOfInterest>.unmodifiable(
    overpassPois,
  );
}

  Future<List<PointOfInterest>> _searchPoisByAddressInSupabase(
    String query,
  ) async {
    final addressParts = _parseAddressQuery(query);

    List<Map<String, dynamic>> response;

    if (addressParts.houseNumber != null) {
      response = await supabase
          .from('pois')
          .select('*')
          .ilike('street', '%${addressParts.street}%')
          .ilike('house_number', '%${addressParts.houseNumber}%')
          .order('name');
    } else {
      final escapedQuery = _escapePostgrestFilterValue(query);

      final pattern = '*$escapedQuery*';

      response = await supabase
          .from('pois')
          .select('*')
          .or(
            'street.ilike.$pattern,'
            'house_number.ilike.$pattern,'
            'postcode.ilike.$pattern,'
            'city.ilike.$pattern,'
            'district.ilike.$pattern,'
            'country.ilike.$pattern',
          )
          .order('name');
    }

    return response
        .map<PointOfInterest>(
          (row) => PointOfInterest.fromSupabase(Map<String, dynamic>.from(row)),
        )
        .toList(growable: false);
  }

  ({String street, String? houseNumber}) _parseAddressQuery(String query) {
    final normalizedQuery = query.trim().replaceAll(RegExp(r'\s+'), ' ');

    final match = RegExp(
      r'^(.*?)[,\s]+(\d+[a-zA-Z]?(?:[-/]\d+[a-zA-Z]?)?)$',
    ).firstMatch(normalizedQuery);

    if (match == null) {
      return (street: normalizedQuery, houseNumber: null);
    }

    final street = match.group(1)?.trim() ?? '';

    final houseNumber = match.group(2)?.trim();

    if (street.isEmpty || houseNumber == null || houseNumber.isEmpty) {
      return (street: normalizedQuery, houseNumber: null);
    }

    return (street: street, houseNumber: houseNumber);
  }

  String _escapePostgrestFilterValue(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll(',', '\\,')
        .replaceAll('(', '\\(')
        .replaceAll(')', '\\)');
  }

  Future<List<PointOfInterest>> _searchPoisByAddressInOverpass({
    required String query,
    required double latitude,
    required double longitude,
  }) async {
    final addressParts = _parseAddressQuery(query);

    final street = addressParts.street.trim();

    final houseNumber = addressParts.houseNumber?.trim();

    if (street.length < 3) {
      return const <PointOfInterest>[];
    }

    final osmResult = await searchNearbyStreetBuildings(
      searchTerm: street,
      houseNumber: houseNumber,
      lat: latitude,
      lon: longitude,
    );

    return (osmResult as Iterable<dynamic>)
        .whereType<Map>()
        .map<PointOfInterest>(
          (row) => PointOfInterest.fromOSM(Map<String, dynamic>.from(row)),
        )
        .toList(growable: false);
  }

  Future<void> updatePoiAddressInSupabase(String id, Address address) async {
    await supabase
        .from('pois')
        .update({
          'street': address.street,
          'house_number': address.houseNumber,
          'postcode': address.postcode,
          'city': address.city,
          'district': address.district,
          'country': address.country,
        })
        .eq('id', id);
  }

  Future<List<PointOfInterest>> searchPoisOverpass(
    String query,
    double lat,
    double lon,
  ) async {
    final normalizedQuery = query.trim();

    if (normalizedQuery.startsWith('osm tag')) {
      final cleanedQuery = normalizedQuery.substring('osm tag'.length).trim();

      if (cleanedQuery.isEmpty) {
        return const <PointOfInterest>[];
      }

      final osmResult = await searchNearbyOverpassTag(
        lat: lat,
        lon: lon,
        cleanedQuery: cleanedQuery,
      );

      return (osmResult as Iterable<dynamic>)
          .map<PointOfInterest>(
            (row) =>
                PointOfInterest.fromOSM(Map<String, dynamic>.from(row as Map)),
          )
          .toList(growable: false);
    }

    if (normalizedQuery.startsWith('osmn')) {
      final cleanedQuery = normalizedQuery.substring('osmn'.length).trim();

      if (cleanedQuery.isEmpty) {
        return const <PointOfInterest>[];
      }

      final osmResult = await searchNearbyOverpassName(
        lat: lat,
        lon: lon,
        searchTerm: cleanedQuery,
      );

      return (osmResult as Iterable<dynamic>)
          .map<PointOfInterest>(
            (row) =>
                PointOfInterest.fromOSM(Map<String, dynamic>.from(row as Map)),
          )
          .toList(growable: false);
    }

    if (normalizedQuery.startsWith('osmb')) {
      final cleanedQuery = normalizedQuery.substring('osmb'.length).trim();

      if (cleanedQuery.length < 3) {
        return const <PointOfInterest>[];
      }

      final osmResult = await searchNearbyStreetBuildings(
        searchTerm: cleanedQuery,
        lat: lat,
        lon: lon,
      );

      return (osmResult as Iterable<dynamic>)
          .map<PointOfInterest>(
            (row) =>
                PointOfInterest.fromOSM(Map<String, dynamic>.from(row as Map)),
          )
          .toList(growable: false);
    }

    final response = await supabase.rpc(
      'pois_search_with_distance_and_address',
      params: {'q': normalizedQuery, 'lat_input': lat, 'lon_input': lon},
    );

    return (response as Iterable<dynamic>)
        .map<PointOfInterest>(
          (row) => PointOfInterest.fromSupabase(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList(growable: false);
  }

  Future<PointOfInterest> newPoi(Geographic location) async {
    final result = await supabase
        .from('pois')
        .insert({
          'name': 'newPOI',
          'lat': location.lat,
          'lon': location.lon,
          'featured_image_url': '',
        })
        .select()
        .single();

    final newId = result['id'] as String;

    return PointOfInterest(
      id: newId,
      name: 'newPOI',
      location: location,
      categories: const [],
      articles: const [],
      historyEntries: const [],
      metadata: PoiMetadata(),
      geometryType: 'point',
      newPoi: true,
      images: const [],
      featuredImageUrl: '',
    );
  }

  Future<PointOfInterest?> loadPoiByOSMId(int osmId) async {
    final result = await supabase
        .from('pois')
        .select()
        .eq('osm_id', osmId)
        .maybeSingle();

    if (result == null) {
      return null;
    }

    return PointOfInterest.fromSupabase(result);
  }

  Future<List<PointOfInterest>> loadPoisWithinRadius({
    required double lat,
    required double lon,
    required double radiusKm,
    required Set<String> categorySlugs,
    required Set<String> featureSlugs,
  }) async {
    if (categorySlugs.isEmpty) {
      return const <PointOfInterest>[];
    }

    final normalizedCategorySlugs = categorySlugs
        .map((slug) => slug.trim())
        .where((slug) => slug.isNotEmpty)
        .toSet();

    final normalizedFeatureSlugs = featureSlugs
        .map((slug) => slug.trim())
        .where((slug) => slug.isNotEmpty)
        .toSet();

    if (normalizedCategorySlugs.isEmpty) {
      return const <PointOfInterest>[];
    }

    final response = await supabase.rpc(
      'search_pois_by_radius',
      params: {
        'p_lat': lat,
        'p_lon': lon,
        'p_radius_meters': radiusKm * 1000,
        'p_category_slugs': normalizedCategorySlugs.toList(),
        'p_feature_slugs': normalizedFeatureSlugs.toList(),
      },
    );

    return (response as List)
        .map<PointOfInterest>(
          (row) => PointOfInterest.fromSupabase(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList(growable: false);
  }

  Future<List<PoiFeatureNode>> loadFeaturesForPoi({
    required String poiId,
    required String languageCode,
    required String? countryCode,
  }) async {
    final normalizedPoiId = poiId.trim();

    if (normalizedPoiId.isEmpty) {
      return const <PoiFeatureNode>[];
    }

    final response = await supabase.rpc(
      'features_for_poi',
      params: {'p_poi_id': normalizedPoiId},
    );

    final rows = List<Map<String, dynamic>>.from(
      (response as List).map((row) => Map<String, dynamic>.from(row as Map)),
    );

    final nodes = rows
        .map((row) {
          final featureLabels = Map<String, dynamic>.from(
            row['labels'] as Map? ?? const {},
          );

          final sourceCategoryLabels = Map<String, dynamic>.from(
            row['source_category_labels'] as Map? ?? const {},
          );

          final featureLabel = _localizedValue(
            labels: featureLabels,
            languageCode: languageCode,
            countryCode: countryCode,
            fallback:
                row['name']?.toString().trim() ??
                row['slug']?.toString().trim() ??
                '',
          );

          final sourceCategoryLabel = _localizedValue(
            labels: sourceCategoryLabels,
            languageCode: languageCode,
            countryCode: countryCode,
            fallback:
                row['source_category_name']?.toString().trim() ??
                row['source_category_slug']?.toString().trim() ??
                '',
          );

          final slug = row['slug']?.toString().trim() ?? '';

          return PoiFeatureNode(
            id: row['id']?.toString() ?? '',
            slug: slug,
            label: featureLabel,
            definition: row['definition']?.toString().trim(),
            parentSlug: row['parent_slug']?.toString().trim(),
            rootFeatureSlug:
                row['root_feature_slug']?.toString().trim() ?? slug,
            sourceCategoryId:
                row['source_category_id']?.toString().trim() ?? '',
            sourceCategorySlug:
                row['source_category_slug']?.toString().trim() ?? '',
            sourceCategoryLabel: sourceCategoryLabel,
            sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
            isSelected: row['is_selected'] == true,
            children: const [],
          );
        })
        .where((node) {
          return node.slug.isNotEmpty;
        })
        .toList(growable: false);

    return _buildPoiFeatureTree(nodes);
  }

  String _localizedValue({
    required Map<String, dynamic> labels,
    required String languageCode,
    required String? countryCode,
    required String fallback,
  }) {
    final normalizedLanguageCode = languageCode.trim().toLowerCase();

    final normalizedCountryCode = countryCode?.trim().toUpperCase();

    final localeKey =
        normalizedCountryCode == null || normalizedCountryCode.isEmpty
        ? normalizedLanguageCode
        : '$normalizedLanguageCode-$normalizedCountryCode';

    final languageFallbackKey = switch (normalizedLanguageCode) {
      'de' => 'de-DE',
      'fr' => 'fr-FR',
      'en' => 'en-US',
      _ => 'de-DE',
    };

    final candidates = <String?>[
      labels[localeKey]?.toString(),
      labels[languageFallbackKey]?.toString(),
      labels['de-DE']?.toString(),
      labels['de-CH']?.toString(),
      labels['en-US']?.toString(),
      labels['fr-FR']?.toString(),
      fallback,
    ];

    for (final candidate in candidates) {
      final normalizedCandidate = candidate?.trim();

      if (normalizedCandidate != null && normalizedCandidate.isNotEmpty) {
        return normalizedCandidate;
      }
    }

    return '';
  }

  List<PoiFeatureNode> _buildPoiFeatureTree(List<PoiFeatureNode> nodes) {
    final nodesByKey = <String, PoiFeatureNode>{};

    for (final node in nodes) {
      nodesByKey[_featureNodeKey(node)] = node;
    }

    final childrenByParentKey = <String, List<PoiFeatureNode>>{};

    final roots = <PoiFeatureNode>[];

    for (final node in nodes) {
      final parentSlug = node.parentSlug?.trim();

      if (parentSlug == null || parentSlug.isEmpty) {
        roots.add(node);
        continue;
      }

      final parentKey = _featureNodeKeyForValues(
        sourceCategorySlug: node.sourceCategorySlug,
        rootFeatureSlug: node.rootFeatureSlug,
        featureSlug: parentSlug,
      );

      if (!nodesByKey.containsKey(parentKey)) {
        roots.add(node);
        continue;
      }

      childrenByParentKey
          .putIfAbsent(parentKey, () => <PoiFeatureNode>[])
          .add(node);
    }

    PoiFeatureNode buildNode(PoiFeatureNode node) {
      final nodeKey = _featureNodeKey(node);

      final children = List<PoiFeatureNode>.from(
        childrenByParentKey[nodeKey] ?? const <PoiFeatureNode>[],
      );

      children.sort(_compareFeatureNodes);

      return node.copyWith(
        children: children.map(buildNode).toList(growable: false),
      );
    }

    roots.sort(_compareFeatureNodes);

    return roots.map(buildNode).toList(growable: false);
  }

  String _featureNodeKey(PoiFeatureNode node) {
    return _featureNodeKeyForValues(
      sourceCategorySlug: node.sourceCategorySlug,
      rootFeatureSlug: node.rootFeatureSlug,
      featureSlug: node.slug,
    );
  }

  String _featureNodeKeyForValues({
    required String sourceCategorySlug,
    required String rootFeatureSlug,
    required String featureSlug,
  }) {
    return '$sourceCategorySlug::$rootFeatureSlug::$featureSlug';
  }

  int _compareFeatureNodes(PoiFeatureNode first, PoiFeatureNode second) {
    final firstCategory = _normalizeSortLabel(first.sourceCategoryLabel);

    final secondCategory = _normalizeSortLabel(second.sourceCategoryLabel);

    final categoryComparison = firstCategory.compareTo(secondCategory);

    if (categoryComparison != 0) {
      return categoryComparison;
    }

    final firstLabel = _normalizeSortLabel(first.label);

    final secondLabel = _normalizeSortLabel(second.label);

    final labelComparison = firstLabel.compareTo(secondLabel);

    if (labelComparison != 0) {
      return labelComparison;
    }

    return first.slug.compareTo(second.slug);
  }

  String _normalizeSortLabel(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss')
        .replaceAll('à', 'a')
        .replaceAll('á', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('å', 'a')
        .replaceAll('æ', 'ae')
        .replaceAll('ç', 'c')
        .replaceAll('è', 'e')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('ì', 'i')
        .replaceAll('í', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ñ', 'n')
        .replaceAll('ò', 'o')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('œ', 'oe')
        .replaceAll('ù', 'u')
        .replaceAll('ú', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ÿ', 'y');
  }

  Future<void> replacePoiFeatures({
    required String poiId,
    required Set<String> featureSlugs,
  }) async {
    final normalizedPoiId = poiId.trim();

    if (normalizedPoiId.isEmpty) {
      throw ArgumentError.value(poiId, 'poiId');
    }

    final normalizedFeatureSlugs = featureSlugs
        .map((slug) => slug.trim())
        .where((slug) => slug.isNotEmpty)
        .toSet();

    await supabase.rpc(
      'replace_poi_features',
      params: {
        'p_poi_id': normalizedPoiId,
        'p_feature_slugs': normalizedFeatureSlugs.toList(),
      },
    );
  }

  Future<Map<String, int>> loadPoiCountsByCategory({
    required double lat,
    required double lon,
    required double radiusKm,
    required Set<String> featureSlugs,
  }) async {
    final normalizedFeatureSlugs = featureSlugs
        .map((slug) => slug.trim())
        .where((slug) => slug.isNotEmpty)
        .toSet();

    final response = await supabase.rpc(
      'poi_counts_by_category',
      params: {
        'p_lat': lat,
        'p_lon': lon,
        'p_radius_meters': radiusKm * 1000,
        'p_feature_slugs': normalizedFeatureSlugs.toList(),
      },
    );

    if (response is! List) {
      throw const FormatException(
        'Die POI-Counts haben keine Liste zurückgegeben.',
      );
    }

    final rows = response
        .map<Map<String, dynamic>>(
          (row) => Map<String, dynamic>.from(row as Map),
        )
        .toList(growable: false);

    return <String, int>{
      for (final row in rows)
        row['category_slug'].toString():
            (row['poi_count'] as num?)?.toInt() ?? 0,
    };
  }
}
