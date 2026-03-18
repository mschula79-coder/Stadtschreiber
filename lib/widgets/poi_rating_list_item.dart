import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/rating_criterion.dart';
import 'package:stadtschreiber/provider/poi_ratings_provider.dart';
import 'package:stadtschreiber/widgets/poi_ratings_stats_builder.dart';
import '../utils/date_time_utils.dart';

class RatingListItem extends ConsumerStatefulWidget {
  final RatingCriterionDTO criterion;
  final String poiId;

  const RatingListItem({
    super.key,
    required this.criterion,
    required this.poiId,
  });

  @override
  ConsumerState<RatingListItem> createState() => _RatingListItemState();
}

class _RatingListItemState extends ConsumerState<RatingListItem> {
  bool showComments = false;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // General properties of a criterion, no ratings inside
    final criterion = widget.criterion;
    final String criterionName = criterion.name;
    final String criterionDescription = criterion.description;
    /*     final Map<int, String> scoreDescriptions = criterion.scoreDescriptions;
 */
    // Use this with a PoiRatingStatsBuilder
    final commentsAsync = ref.watch(poiRatingsProvider(widget.poiId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text Criterion Name + Comment show/hide button + rate button
        Text(criterionName, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),

        // Criterion description
        Text(criterionDescription),
        const SizedBox(height: 8),

        // List of Rating Stars, average score and no. of ratings
        PoiRatingStatsBuilder(
          poiId: widget.poiId,
          builder: (statsMap) {
            final stat = statsMap[criterion.id];
            final exactScore = stat?.avgRating ?? 0;
            final String? scoreRoundedOneDigit;
            final int? scoreRoundedZeroDigits;
            scoreRoundedOneDigit = exactScore.toStringAsFixed(1);
            scoreRoundedZeroDigits = int.parse(exactScore.toStringAsFixed(0));
            final ratingsCount = stat?.ratingCount ?? 0;
            final commentsCount = stat?.commentsCount ?? 0;

            return Column(
              children: [
                Row(
                  children: [
                    // Sterne links
                    Padding(
                      padding: EdgeInsets.only(right: 30),
                      child: Row(
                        children: List.generate(5, (i) {
                          final starsCount = i + 1;
                          final isScored =
                              scoreRoundedZeroDigits! >= starsCount;
                          return Icon(
                            Icons.star,
                            color: isScored
                                ? Colors.amber
                                : Colors.grey.shade400,
                          );
                        }),
                      ),
                    ),

                    Spacer(),

                    // Score rechts
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(scoreRoundedOneDigit),
                        Text('($ratingsCount)'),
                      ],
                    ),
                    SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 4),
                        GestureDetector(
                          onTap: () =>
                              setState(() => showComments = !showComments),
                          child: Icon(
                            showComments
                                ? Icons.comments_disabled
                                : Icons.comment,
                            color: Color.fromARGB(255, 42, 23, 86),
                            size: 16,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text('($commentsCount)'),
                      ],
                    ),
                  ],
                ),

                /* ratingsCount > 0
                    ? Column(
                        children: [
                          Text(scoreDescriptions[scoreRoundedZeroDigits]!),
                          SizedBox(height: 8),
                        ],
                      )
                    : SizedBox.shrink(), */
              ],
            );
            // End Row 2
          },
        ),

        const SizedBox(height: 8),
        // Row 3: Text Score Description

        // Row 4 + X: Comments
        showComments
            ? commentsAsync.when(
                loading: () => CircularProgressIndicator(),
                error: (e, _) => Text("Fehler: $e"),
                data: (ratings) {
                  final ratingsForCriterion = ratings.where(
                    (r) => r.criterionId == criterion.id,
                  );

                  final comments = ratingsForCriterion
                      .where((r) => (r.comment ?? '').trim().isNotEmpty)
                      .toList();

                  final hasComments = comments.isNotEmpty;

                  return hasComments
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Kommentare: ${comments.length}",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ...comments.map(
                              (r) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.comment!,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '${r.username} • ${formatDate(r.createdAt)}',
                                      style: TextStyle(
                                        fontSize: 8,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : SizedBox.shrink();
                },
              )
            : SizedBox.shrink(),
      ],
    );
  }
}
