import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/models/rating_criterion.dart';
import 'package:stadtschreiber/widgets/poi_rating_list_item.dart';

class PoiRatingList extends ConsumerWidget {
  final List<RatingCriterionDTO> criteria;
  final PointOfInterest poi;

  const PoiRatingList({super.key, required this.criteria, required this.poi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: criteria.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final criterion = criteria[index];
        // Widget
        return RatingListItem(
          criterion: criterion,
          poiId: poi.id,
          
        );
      },
    );
  }
}
