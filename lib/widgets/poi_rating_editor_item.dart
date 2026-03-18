import 'package:flutter/material.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/models/rating_criterion.dart';
import 'package:stadtschreiber/widgets/poi_user_ratings_builder.dart';

class MyRatingListItem extends StatefulWidget {
  final RatingCriterionDTO criterion;
  final void Function(String criterionId, String myComment)? onCommentChanged;
  final PointOfInterest poi;
  final Future<String?> Function(int newScore)? onScoreChanged;

  const MyRatingListItem({
    super.key,
    required this.poi,
    required this.criterion,
    this.onCommentChanged,
    this.onScoreChanged,
  });

  @override
  State<MyRatingListItem> createState() => _MyRatingListItemState();
}

class _MyRatingListItemState extends State<MyRatingListItem> {
  int? selectedScore;
  late final TextEditingController commentController = TextEditingController();
  String? myComment;

  @override
  void dispose() {
    commentController.dispose();
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
    return PoiUserRatingBuilder(
      poiId: widget.poi.id,
      builder: (statsMap) {
        final myRating = statsMap[criterion.id];

        final myScore = selectedScore ?? myRating?.ratingScore ?? 0;

        myComment ??= myRating?.comment ?? "";

        if (commentController.text != myComment) {
          commentController.text = myComment!;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text Criterion Name
            Text(criterionName, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),

            // Criterion description
            Text(criterionDescription),
            const SizedBox(height: 8),

            // List of Rating Stars
            Row(
              children: [
                ...List.generate(5, (i) {
                  final starsValue = i + 1;
                  final isScored = myScore >= starsValue;
                  return
                  // Rating Stars, read only
                  GestureDetector(
                    onTap: () async {
                      final result = await widget.onScoreChanged?.call(
                        starsValue,
                      );
                      if (result == null) {
                        setState(() {
                          selectedScore = starsValue;
                        });
                      }
                    },
                    child: Icon(
                      Icons.star,
                      size: 32,
                      color: isScored ? Colors.amber : Colors.grey.shade400,
                    ),
                  );
                }),
              ],
            ),

            const SizedBox(height: 8),
/*             Text(scoreDescriptions[myScore] ?? ""),
 */
            TextField(
              controller: commentController,
              decoration: InputDecoration(
                labelText: 'Kommentar, max. 140 Zeichen (${commentController.text.length})',
                border: const OutlineInputBorder(),
              ),
              onChanged: (newValue) {
                setState(() {
                  myComment = newValue;
                  widget.onCommentChanged?.call(criterion.id, newValue);
                });
              },
            ),
          ],
        );
        // End Row 2
      },
    );
  }
}
