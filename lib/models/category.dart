
import 'package:stadtschreiber/models/rating_criterion.dart';


class CategoryNode {
  final String id;
  final String label;
  final String? value;
  final CategoryIcon? icon;
  final List<CategoryNode> children;
  final List<RatingCriterionDTO> ratingCriteria;

  CategoryNode({
    required this.id,
    required this.label,
    this.value,
    this.icon,
    this.children = const [],
    required this.ratingCriteria,
  });

  bool get isLeaf => children.isEmpty;
}

class CategoryIcon {
  final String type; // flutter, iconify, url
  final String value;

  CategoryIcon({required this.type, required this.value});

  factory CategoryIcon.fromJson(Map<String, dynamic> json) {
    return CategoryIcon(type: json['type'], value: json['value']);
  }
}
