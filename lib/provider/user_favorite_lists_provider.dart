import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/user_favorite_dto.dart';
import 'package:stadtschreiber/models/user_favorites_list_dto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final userFavoriteListsProvider =
    FutureProvider.family<
      List<(UserFavoritesListDTO, List<UserFavoriteDTO>)>,
      String
    >((ref, userID) async {
      final supabase = Supabase.instance.client;

      // 1) Favoriten-Listen laden
      final responseFavoritesList = await supabase
          .from('favorite_lists')
          .select('*')
          .eq('user_id', userID);

      final lists = responseFavoritesList
          .map<UserFavoritesListDTO>(
            (row) => UserFavoritesListDTO.fromJson(row),
          )
          .toList();

      // 2) Favoriten pro Liste laden
      final result = <(UserFavoritesListDTO, List<UserFavoriteDTO>)>[];

      for (final list in lists) {
        final responseFavorites = await supabase
            .from('favorites')
            .select('*')
            .eq('list_id', list.id);

        final favorites = responseFavorites
            .map<UserFavoriteDTO>((row) => UserFavoriteDTO.fromJson(row))
            .toList();

        result.add((list, favorites));
      }

      return result;
    });

final toggleFavoriteProvider = Provider((ref) {
  final supabase = Supabase.instance.client;

  return (
    {
      required String poiId,
      required String listId,
      required bool add,
    }
  ) async {
    if (add) {
      await supabase.from('favorites').insert({
        'poi_id': poiId,
        'list_id': listId,
      });
    } else {
      await supabase
          .from('favorites')
          .delete()
          .eq('poi_id', poiId)
          .eq('list_id', listId);
    }
  };
});


final editFavoriteListsListProvider = Provider((ref) {
  final supabase = Supabase.instance.client;

  return (
    {
      required String listId,
      required String listname,
      required bool add,
      required String userID
    }
  ) async {



    if (add) {
      await supabase.from('favorite_lists').insert({
        'user_id': userID,
        'name': listname
      });
    } else {
      await supabase
          .from('favorite_lists')
          .delete()
          .eq('id', listId);
    }
  };
});
