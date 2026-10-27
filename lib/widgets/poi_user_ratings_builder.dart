import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/poi_rating__dto.dart';
import 'package:stadtschreiber/provider/locale_provider.dart';
import 'package:stadtschreiber/provider/poi_ratings_provider.dart';
import 'package:stadtschreiber/utils/language_utils.dart';

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
    final languageCode = ref.watch(localeProvider).languageCode;
    final countryCode = ref.watch(localeProvider).countryCode;

    return stats.when(
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text("${getText('error', languageCode: languageCode, countryCode: countryCode)}: $e"),
      data: (map) => builder(map),
    );
  }
}
