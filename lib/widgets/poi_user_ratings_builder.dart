import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/poi_rating__dto.dart';
import 'package:stadtschreiber/provider/poi_ratings_provider.dart';

class PoiUserRatingBuilder extends ConsumerWidget {
  final String poiId;
  final Widget Function(Map<String, PoiRatingDto>) builder;

  const PoiUserRatingBuilder({
    super.key,
    required this.poiId,
    required this.builder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(poiUserRatingsProvider(poiId));

    return stats.when(
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text("Fehler: $e"),
      data: (map) => builder(map),
    );
  }
}
