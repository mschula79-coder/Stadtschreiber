import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/models/rating_criterion.dart';
import 'package:stadtschreiber/provider/categories_provider.dart';
import 'package:stadtschreiber/provider/poi_ratings_provider.dart';
import 'package:stadtschreiber/provider/poi_ratings_stats_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';
import 'package:stadtschreiber/services/debug_service.dart';
import 'package:stadtschreiber/widgets/poi_rating_editor_dialog.dart';
import 'package:stadtschreiber/widgets/poi_rating_list.dart';

class PoiPanelRatingsTab extends ConsumerWidget {
  const PoiPanelRatingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    DebugService.log('build PoiPanelInfoTab $this.key $this.hashcode');
    final selectedPoi = ref.watch(selectedPoiProvider);
    if (selectedPoi == null ||
        selectedPoi.categories!.isEmpty ||
        selectedPoi.categories![0].isEmpty) {
      return SizedBox.shrink();
    } else {
      final categoryId = ref.watch(
        categoryIdBySlugProvider(selectedPoi.categories![0]),
      );
      if (categoryId != null) {
        final criteria = ref.watch(criteriaForCategoryProvider(categoryId));
        // Überschrift mit PoiRatingList
        return criteria.when(
          data: (list) => Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Bewertung',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(width: 4),
                    GestureDetector(
                      onTap: () =>
                          _openRatingEditor(selectedPoi, list, ref, context),
                      child: Icon(
                        Icons.rate_review,
                        color: Color.fromARGB(255, 42, 23, 86),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: PoiRatingList(criteria: list, poi: selectedPoi),
                ),
              ],
            ),
          ),
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text("Fehler: $e"),
        );
      }
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Keine Kategorie gefunden'),
      );
    }
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

          // UI aktualisieren
          ref.invalidate(poiRatingsProvider(poi.id));
          ref.invalidate(poiUserRatingsProvider(poi.id));
          ref.invalidate(poiRatingStatsProvider(poi.id));
        },
      ),
    );
  }
}
