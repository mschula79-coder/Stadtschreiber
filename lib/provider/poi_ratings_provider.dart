import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/poi_rating__dto.dart';
import 'package:stadtschreiber/provider/supabase_user_state_provider.dart';
import 'package:stadtschreiber/repositories/poi_rating_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lazy loads a list of all ratings for one poiId to use in a PoiRatingStatsBuilder
final poiRatingsProvider = FutureProvider.family<List<PoiRatingDto>, String>((
  ref,
  poiId,
) async {
  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('poi_ratings')
      .select('''
        id,
        user_id,
        criterion_id,
        rating,
        comment,
        created_at,
        updated_at,
        profiles ( username )
      ''')
      .eq('poi_id', poiId);

  return response
      .map<PoiRatingDto>((row) => PoiRatingDto.fromJson(row))
      .toList();
});

/// Return all ratings of current user for a poiId
final poiUserRatingsProvider =
    FutureProvider.family<Map<String, PoiRatingDto>, String>((
      ref,
      poiId,
    ) async {
      final supabase = Supabase.instance.client;
      final userId = ref.read(supabaseUserStateProvider).userid;

      final response = await supabase
          .from('poi_ratings')
          .select('''
        id,
        criterion_id,
        rating,
        comment,
        created_at,
        updated_at,
        profiles ( username )
      ''')
          .eq('poi_id', poiId)
          .eq('user_id', userId);

      return {
        for (final row in response)
          row['criterion_id'] as String: PoiRatingDto.fromJson(row),
      };
    });

final poiRatingRepositoryProvider = Provider((ref) {
  return PoiRatingRepository();
});
