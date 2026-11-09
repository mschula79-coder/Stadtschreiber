import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/models/rating_criterion.dart';
import 'package:stadtschreiber/provider/categories_localized_provider.dart';
import 'package:stadtschreiber/provider/categories_provider.dart';
import 'package:stadtschreiber/provider/poi_ratings_provider.dart';
import 'package:stadtschreiber/provider/poi_ratings_stats_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';
import 'package:stadtschreiber/widgets/poi_rating_editor_dialog.dart';
import 'package:stadtschreiber/widgets/poi_rating_list.dart';

class CategoryRatingsSection extends ConsumerWidget {
  const CategoryRatingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poi = ref.watch(selectedPoiProvider);

    if (poi == null) {
      return const SizedBox.shrink();
    }

    final categorySlugs =
        (poi.categories ?? const <String>[])
            .map((slug) => slug.trim())
            .where((slug) => slug.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    if (categorySlugs.isEmpty) {
      return const SizedBox.shrink();
    }

    final categorySlugsKey = categorySlugs.join('\u001f');

    final categoryCriteriaAsync = ref.watch(
      categoryCriteriaForSlugsProvider(categorySlugsKey),
    );

    return categoryCriteriaAsync.when(
      data: (categoryEntries) {
        final uniqueEntriesByCategoryId = <String, CategoryCriteriaEntry>{};

        for (final entry in categoryEntries) {
          if (entry.criteria.isEmpty) {
            continue;
          }

          final existingEntry = uniqueEntriesByCategoryId[entry.categoryId];

          if (existingEntry == null) {
            uniqueEntriesByCategoryId[entry.categoryId] = entry;

            continue;
          }

          final uniqueCriteriaById = <String, RatingCriterionDTO>{
            for (final criterion in existingEntry.criteria)
              criterion.id: criterion,
            for (final criterion in entry.criteria) criterion.id: criterion,
          };

          uniqueEntriesByCategoryId[entry.categoryId] = (
            categoryId: existingEntry.categoryId,
            categorySlug: existingEntry.categorySlug,
            criteria: List<RatingCriterionDTO>.unmodifiable(
              uniqueCriteriaById.values,
            ),
          );
        }

        final uniqueEntries = uniqueEntriesByCategoryId.values.toList();

        if (uniqueEntries.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: uniqueEntries
              .map((entry) {
                return _CategoryRatingEntry(
                  key: ValueKey<String>('${poi.id}-${entry.categoryId}'),
                  categorySlug: entry.categorySlug,
                  criteria: entry.criteria,
                  poi: poi,
                  onTap: () {
                    _openRatingEditor(poi, entry.criteria, ref, context);
                  },
                );
              })
              .toList(growable: false),
        );
      },
      loading: () {
        return const Center(child: LinearProgressIndicator(minHeight: 2));
      },
      error: (error, stackTrace) {
        return Text('Fehler: $error');
      },
    );
  }

  void _openRatingEditor(
    PointOfInterest poi,
    List<RatingCriterionDTO> criteria,
    WidgetRef ref,
    BuildContext context,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return PoiRatingEditorDialog(
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
        );
      },
    );
  }
}

class _CategoryRatingEntry extends ConsumerWidget {
  final String categorySlug;
  final List<RatingCriterionDTO> criteria;
  final PointOfInterest poi;
  final VoidCallback onTap;

  const _CategoryRatingEntry({
    super.key,
    required this.categorySlug,
    required this.criteria,
    required this.poi,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryName = ref.watch(categoryLabelBySlugProvider(categorySlug));

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            categoryName ?? categorySlug,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          PoiRatingList(criteria: criteria, poi: poi, onTap: onTap),
        ],
      ),
    );
  }
}
