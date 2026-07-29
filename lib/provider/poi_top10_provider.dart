import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/category.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/models/rating_criterion.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';

class Top10State {
  final double listLength;
  final CategoryNode? category;
  final RatingCriterionDTO? criterion;

  const Top10State({
    required this.listLength,
    this.category,
    this.criterion,
  });

  Top10State copyWith({
    double? listLength,
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

  void setListLength(double n) => state = state.copyWith(listLength: n);
  void setCategory(CategoryNode? c) => state = state.copyWith(category: c);
  void setCriterion(RatingCriterionDTO? c) => state = state.copyWith(criterion: c);
}


final top10PoisProvider = FutureProvider<List<PointOfInterest>>((ref) async {
  final repo = ref.watch(poiRepositoryProvider);

  final state = ref.watch(top10StateProvider);

  if (state.category == null || state.criterion == null) {
    return [];
  }

  return repo.loadTopNPois(
    categoryId: state.category!.id,
    criterionId: state.criterion!.id,
    limit: state.listLength,
  );
});
