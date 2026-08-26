import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/l10n/app_localizations.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/models/rating_criterion.dart';
import 'package:stadtschreiber/provider/categories_provider.dart';
import 'package:stadtschreiber/provider/poi_ratings_provider.dart';
import 'package:stadtschreiber/provider/poi_ratings_stats_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';
import 'package:stadtschreiber/widgets/poi_rating_editor_dialog.dart';
import 'package:stadtschreiber/widgets/poi_rating_list.dart';

class CategoryRatingsSection extends ConsumerWidget {
  final String slug;
  const CategoryRatingsSection({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryId = ref.watch(categoryIdBySlugProvider(slug));
    final categoryName = ref.watch(categoryLabelBySlugProvider(slug));
    final poi = ref.watch(selectedPoiProvider);

    if (categoryId == null || poi == null) {
      return const SizedBox.shrink();
    }

    final criteriaAsync = ref.watch(criteriaForCategoryProvider(categoryId));

    return criteriaAsync.when(
      data: (criteria) => Column(
        
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ⭐ HEADER (Titel + Rating‑Text + Icon)
          Row(
            children: [
              Text(
                '$categoryName',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _openRatingEditor(poi, criteria, ref, context),
                child: const Icon(
                  Icons.rate_review,
                  color: Color.fromARGB(255, 42, 23, 86),
                ),
              ),
            ],
          ),

          PoiRatingList(criteria: criteria, poi: poi),
        ],
      ),

      loading: () => const Center(child: CircularProgressIndicator()),

      error: (e, _) => Text("Fehler: $e"),
    );
  }

  void _openRatingEditor(
    PointOfInterest poi,
    List<RatingCriterionDTO> criteria,
    WidgetRef ref,
    BuildContext context,
  ) {
    showDialog(
      context: context,
      builder: (_) => PoiRatingEditorDialog(
        poi: poi,
        criteria: criteria,
        onRatingChanged: (scores, comments) async {
          await ref
              .read(poiRatingRepositoryProvider)
              .saveRatings(poiId: poi.id, scores: scores, comments: comments);

          ref.invalidate(poiRatingsProvider(poi.id));
          ref.invalidate(poiUserRatingsProvider(poi.id));
          ref.invalidate(poiRatingStatsProvider(poi.id));
        },
      ),
    );
  }
}
