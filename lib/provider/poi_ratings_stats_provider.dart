import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/poi_rating_stats_dto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final poiRatingStatsProvider =
    FutureProvider.family<List<PoiRatingStatsDto>, String>((ref, poiId) async {
  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('poi_rating_stats')
      .select('poi_id, criterion_id, avg_rating, rating_count, comment_count')
      .eq('poi_id', poiId);

  final list = response as List<dynamic>;

  return list
      .map((row) => PoiRatingStatsDto.fromJson(row as Map<String, dynamic>))
      .toList();
});
