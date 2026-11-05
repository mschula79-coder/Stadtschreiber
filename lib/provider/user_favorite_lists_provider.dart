import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/models/user_favorite_list_with_pois.dart';
import 'package:stadtschreiber/models/user_favorites_list_dto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final userFavoriteListsProvider = FutureProvider.autoDispose
    .family<List<UserFavoriteListWithPois>, String>((ref, userID) async {
      /*       print('userFavoriteListsProvider START: userID: $userID');
 */
      final stopwatch = Stopwatch()..start();

      final normalizedUserID = userID.trim();

      if (normalizedUserID.isEmpty) {
        return const <UserFavoriteListWithPois>[];
      }

      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('favorite_lists')
          .select('''
      id,
      user_id,
      name,
      created_at,
      favorites:favorites!favorites_list_id_fkey (
        poi_id,
        poi:pois!favorites_poi_id_fkey (
          id,
          name,
          lat,
          lon
        )
      )
    ''')
          .eq('user_id', normalizedUserID)
          .order('name');

      /*       print('Favoriten SQL/Netzwerk: ${stopwatch.elapsedMilliseconds} ms');
 */
      stopwatch.reset();

      return response
          .map<UserFavoriteListWithPois>((rawList) {
            final listRow = Map<String, dynamic>.from(rawList);

            final listDTO = UserFavoritesListDTO.fromJson(listRow);

            final favoritesRaw = listRow['favorites'] as List? ?? const [];

            final poisById = <String, PointOfInterest>{};

            for (final rawFavorite in favoritesRaw) {
              if (rawFavorite is! Map) {
                continue;
              }

              final favoriteRow = Map<String, dynamic>.from(rawFavorite);

              final rawPoi = favoriteRow['poi'];

              if (rawPoi is! Map) {
                continue;
              }

              final poi = PointOfInterest.fromSupabase(
                Map<String, dynamic>.from(rawPoi),
              );

              poisById[poi.id] = poi;
            }

            final pois = poisById.values.toList()
              ..sort((first, second) {
                return first.name.trim().toLowerCase().compareTo(
                  second.name.trim().toLowerCase(),
                );
              });
            /*             print('Favoriten Mapping: ${stopwatch.elapsedMilliseconds} ms');

            print('Listen: ${response.length}');
 */
            return UserFavoriteListWithPois(
              list: listDTO,
              pois: List<PointOfInterest>.unmodifiable(pois),
            );
          })
          .toList(growable: false);
    });

final createFavoriteListProvider = Provider((ref) {
  final supabase = Supabase.instance.client;

  return ({required String listName, required String userId}) async {
    final normalizedListName = listName.trim();
    final normalizedUserId = userId.trim();

    if (normalizedListName.isEmpty) {
      throw ArgumentError.value(listName, 'listName');
    }

    if (normalizedUserId.isEmpty) {
      throw ArgumentError.value(userId, 'userId');
    }

    await supabase.from('favorite_lists').insert({
      'user_id': normalizedUserId,
      'name': normalizedListName,
    });
  };
});

final toggleFavoriteProvider = Provider((ref) {
  final supabase = Supabase.instance.client;

  return ({
    required String poiId,
    required String listId,
    required bool add,
  }) async {
    final normalizedPoiId = poiId.trim();
    final normalizedListId = listId.trim();

    if (normalizedPoiId.isEmpty) {
      throw ArgumentError.value(poiId, 'poiId');
    }

    if (normalizedListId.isEmpty) {
      throw ArgumentError.value(listId, 'listId');
    }

    if (add) {
      await supabase.from('favorites').upsert({
        'poi_id': normalizedPoiId,
        'list_id': normalizedListId,
      }, onConflict: 'poi_id,list_id');

      return;
    }

    await supabase
        .from('favorites')
        .delete()
        .eq('poi_id', normalizedPoiId)
        .eq('list_id', normalizedListId);
  };
});

final deleteFavoriteListProvider = Provider((ref) {
  final supabase = Supabase.instance.client;

  return ({required String listId, required String userId}) async {
    final normalizedListId = listId.trim();
    final normalizedUserId = userId.trim();

    if (normalizedListId.isEmpty) {
      throw ArgumentError.value(listId, 'listId');
    }

    if (normalizedUserId.isEmpty) {
      throw ArgumentError.value(userId, 'userId');
    }

    await supabase
        .from('favorite_lists')
        .delete()
        .eq('id', normalizedListId)
        .eq('user_id', normalizedUserId);
  };
});

final userFavoriteListHeadersProvider =
    FutureProvider.family<List<UserFavoritesListDTO>, String>((
      ref,
      userId,
    ) async {
      final normalizedUserId = userId.trim();

      if (normalizedUserId.isEmpty) {
        return const <UserFavoritesListDTO>[];
      }

      final response = await Supabase.instance.client
          .from('favorite_lists')
          .select(
            'id, user_id, name, created_at',
          )
          .eq(
            'user_id',
            normalizedUserId,
          )
          .order('name');

      return response
          .map<UserFavoritesListDTO>(
            (row) => UserFavoritesListDTO.fromJson(
              Map<String, dynamic>.from(row),
            ),
          )
          .toList(growable: false);
    });

final favoritePoisForListProvider =
    FutureProvider.autoDispose.family<List<PointOfInterest>, String>((
      ref,
      listId,
    ) async {
      final normalizedListId = listId.trim();

      if (normalizedListId.isEmpty) {
        return const <PointOfInterest>[];
      }

      final supabase = Supabase.instance.client;

      final favoritesResponse = await supabase
          .from('favorites')
          .select('poi_id')
          .eq(
            'list_id',
            normalizedListId,
          );

      final poiIds = favoritesResponse
          .map(
            (row) => row['poi_id']?.toString().trim(),
          )
          .whereType<String>()
          .where(
            (poiId) => poiId.isNotEmpty,
          )
          .toSet();

      if (poiIds.isEmpty) {
        return const <PointOfInterest>[];
      }

      final poisResponse = await supabase
          .from('pois')
          .select('''
            id,
            name,
            lat,
            lon,
            categories,
            featured_image_url,
            street,
            house_number,
            postcode,
            city,
            district,
            country,
            description,
            geom_type,
            osm_id
          ''')
          .inFilter(
            'id',
            poiIds.toList(),
          );

      final poisById = <String, PointOfInterest>{};

      for (final rawPoi in poisResponse) {
        final poi = PointOfInterest.fromSupabase(
          Map<String, dynamic>.from(rawPoi),
        );

        poisById[poi.id] = poi;
      }

      final pois = poisById.values.toList()
        ..sort(
          (first, second) => first.name
              .trim()
              .toLowerCase()
              .compareTo(
                second.name.trim().toLowerCase(),
              ),
        );

      return List<PointOfInterest>.unmodifiable(
        pois,
      );
    });