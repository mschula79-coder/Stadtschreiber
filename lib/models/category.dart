
import 'package:stadtschreiber/models/rating_criterion.dart';


class CategoryNode {
  final String id;
  final String label;
  final String? value;
  final List<CategoryNode> children;
  final List<RatingCriterionDTO> ratingCriteria;

  CategoryNode({
    required this.id,
    required this.label,
    this.value,
    this.children = const [],
    required this.ratingCriteria,
  });

  bool get isLeaf => children.isEmpty;
}
