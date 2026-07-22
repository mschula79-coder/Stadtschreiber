import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/user_favorite_dto.dart';
import 'package:stadtschreiber/provider/supabase_user_state_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final userFavoritesProvider = FutureProvider<List<UserFavoriteDTO>>((ref) async {
  final supabase = Supabase.instance.client;
  final userID = ref.watch(supabaseUserStateProvider).userid;

  // 1) Listen des Users laden
  final lists = await supabase
      .from('favorite_lists')
      .select('id')
      .eq('user_id', userID);

  if (lists.isEmpty) return [];

  final listIds = lists.map((row) => row['id'] as String).toList();

  // 2) OR‑Filter bauen
  final filter = listIds.map((id) => 'list_id.eq.$id').join(',');

  // 3) Favoriten laden
  final favorites = await supabase
      .from('favorites')
      .select('*')
      .or(filter);


  return favorites
      .map<UserFavoriteDTO>((row) => UserFavoriteDTO.fromJson(row))
      .toList();
});






