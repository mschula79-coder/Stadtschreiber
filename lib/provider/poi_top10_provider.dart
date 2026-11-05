import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/category_node_localized.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/models/rating_criterion.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';

class Top10State {
  final double listLength;
  final LocalizedCategoryNode? category;
  final RatingCriterionDTO? criterion;

  const Top10State({
    required this.listLength,
    this.category,
    this.criterion,
  });
}

final top10StateProvider =
    NotifierProvider<Top10StateNotifier, Top10State>(
      Top10StateNotifier.new,
    );

class Top10StateNotifier extends Notifier<Top10State> {
  @override
  Top10State build() {
    return const Top10State(
      listLength: 10,
    );
  }

  void setListLength(double listLength) {
    state = Top10State(
      listLength: listLength,
      category: state.category,
      criterion: state.criterion,
    );
  }

  void setCategory(
    LocalizedCategoryNode? category,
  ) {
    state = Top10State(
      listLength: state.listLength,
      category: category,
      criterion: null,
    );
  }

  void setCriterion(
    RatingCriterionDTO? criterion,
  ) {
    state = Top10State(
      listLength: state.listLength,
      category: state.category,
      criterion: criterion,
    );
  }

  void clear() {
    state = const Top10State(
      listLength: 10,
    );
  }
}

final top10PoisProvider =
    FutureProvider<List<PointOfInterest>>((ref) async {
      final repository = ref.read(
        poiRepositoryProvider,
      );

      final state = ref.watch(
        top10StateProvider,
      );

      final category = state.category;
      final criterion = state.criterion;

      if (category == null || criterion == null) {
        return const <PointOfInterest>[];
      }

      return repository.loadTopNPois(
        categoryId: category.id,
        criterionId: criterion.id,
        limit: state.listLength,
      );
    });