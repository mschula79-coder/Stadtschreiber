import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/category.dart';
import 'package:stadtschreiber/models/rating_criterion.dart';

class Top10State {
  final int listLength;
  final CategoryNode? category;
  final RatingCriterionDTO? criterion;

  const Top10State({
    required this.listLength,
    this.category,
    this.criterion,
  });

  Top10State copyWith({
    int? listLength,
    CategoryNode? category,
    RatingCriterionDTO? criterion,
  }) {
    return Top10State(
      listLength: listLength ?? this.listLength,
      category: category ?? this.category,
      criterion: criterion ?? this.criterion,
    );
  }
}

final top10StateProvider =
    NotifierProvider<Top10StateNotifier, Top10State>(() {
  return Top10StateNotifier();
});

class Top10StateNotifier extends Notifier<Top10State> {
  @override
  Top10State build() => const Top10State(listLength: 10);

  void setListLength(int n) => state = state.copyWith(listLength: n);
  void setCategory(CategoryNode? c) => state = state.copyWith(category: c);
  void setCriterion(RatingCriterionDTO? c) => state = state.copyWith(criterion: c);
}
