  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:stadtschreiber/models/poi_rating_stats_dto.dart';
  import 'package:stadtschreiber/provider/poi_ratings_stats_provider.dart';

  class PoiRatingStatsBuilder extends ConsumerWidget {
  final String poiId;
  final Widget Function(Map<String, PoiRatingStatsDto>) builder;

  const PoiRatingStatsBuilder({
    super.key,
    required this.poiId,
    required this.builder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(poiRatingStatsProvider(poiId));

    return stats.when(
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text("Fehler: $e"),
      data: (list) {
        final map = {
          for (final s in list) s.criterionId: s,
        };
        return builder(map);
      },
    );
  }
  }
