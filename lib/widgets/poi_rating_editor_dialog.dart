import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/models/rating_criterion.dart';
import 'package:stadtschreiber/provider/locale_provider.dart';
import 'package:stadtschreiber/utils/language_utils.dart';
import 'package:stadtschreiber/widgets/poi_rating_editor_item.dart';

class PoiRatingEditorDialog extends ConsumerStatefulWidget {
  final List<RatingCriterionDTO> criteria;
  final PointOfInterest poi;
  
  final void Function(
    Map<String, int> scores, 
    Map<String, String> comments
  ) onRatingChanged;

  const PoiRatingEditorDialog({
    super.key,
    required this.criteria,
    required this.poi,
    required this.onRatingChanged,
  });

  @override
  ConsumerState<PoiRatingEditorDialog> createState() => _PoiRatingEditorDialogState();
}

class _PoiRatingEditorDialogState extends ConsumerState<PoiRatingEditorDialog> {
  final Map<String, int> updatedScores = {};
  final Map<String, String> updatedComments = {};

  @override
  Widget build(BuildContext context) {
    final languageCode = ref.watch(localeProvider).languageCode;
    return AlertDialog(
      title: Text(getText('myRating', languageCode: languageCode)),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: ListView(
          children: widget.criteria.map((criterion) {
            return Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              child: MyRatingListItem(
                criterion: criterion,
                poi: widget.poi,

                // Score wurde geändert
                onScoreChanged: (newScore) async {
                  updatedScores[criterion.id] = newScore;
                  return null; // kein Fehler
                },

                // Kommentar wurde geändert
                onCommentChanged: (criterionId, newComment) {
                  updatedComments[criterionId] = newComment;
                },
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(getText("Abbrechen", languageCode: languageCode)),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onRatingChanged(updatedScores, updatedComments);
            Navigator.pop(context);
          },
          child: Text(getText("save", languageCode: languageCode)),
        ),
      ],
    );
  }
}
