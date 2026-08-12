import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/poi_rating__dto.dart';
import 'package:stadtschreiber/models/poi_ratings_with_stats.dart';
import 'package:stadtschreiber/provider/poi_ratings_stats_provider.dart';
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

final ratingCriteriaProvider =
    FutureProvider.family<Map<String, String>, String>((ref, poiId) async {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('global_rating_criteria')
          .select('id, name');

      return {
        for (final row in response) row['id'] as String: row['name'] as String,
      };
    });

final poiRatingsWithStatsProvider =
    FutureProvider.family<List<PoiRatingWithStats>, String>((ref, poiId) async {
      final stats = await ref.watch(poiRatingStatsProvider(poiId).future);

      if (stats.isEmpty) {
        return [];
      }

      final supabase = Supabase.instance.client;
      final criteriaRaw = await supabase
          .from('global_rating_criteria')
          .select();

      final criteriaNames = {
        for (final row in criteriaRaw as List<dynamic>)
          row['id'] as String: row['name'] as String,
      };

      // Nur Stats behalten, deren Kriterien existieren
      final filteredStats = stats
          .where((s) => criteriaNames.containsKey(s.criterionId))
          .toList();

      if (filteredStats.isEmpty) {
        return [];
      }

      // Durchschnitt für Bayesian Score
      final C =
          filteredStats.map((s) => s.avgRating).reduce((a, b) => a + b) /
          filteredStats.length;

      final result = <PoiRatingWithStats>[];

      for (final entry in filteredStats) {
        final criterionId = entry.criterionId;

        final m = 5.0;
        final R = entry.avgRating;
        final v = entry.ratingCount.toDouble();

        final bayes = (v / (v + m)) * R + (m / (v + m)) * C;

        result.add(
          PoiRatingWithStats(
            criterionId: criterionId,
            criterionName: criteriaNames[criterionId]!,
            avgRating: entry.avgRating,
            ratingCount: entry.ratingCount,
            commentCount: entry.commentsCount,
            userRating: null, // ⭐ entfernt
            userComment: null, // ⭐ entfernt
            bayesianScore: bayes,
          ),
        );
      }

      return result;
    });
