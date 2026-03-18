import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/provider/categories_menu_provider.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';
import 'package:stadtschreiber/state/visible_pois_state.dart';

final visiblePoisProvider =
    NotifierProvider<VisiblePoisNotifier, VisiblePoisStateData>(
      VisiblePoisNotifier.new,
      name: 'visiblePoisProvider',
    );

class VisiblePoisNotifier extends Notifier<VisiblePoisStateData> {
  @override
  VisiblePoisStateData build() => VisiblePoisStateData.initial;

  void add(PointOfInterest poi) {
    final updated = [...state.visible]
      ..removeWhere((p) => p.id == poi.id)
      ..add(poi);

    state = state.copyWith(visible: updated);
  }

  void removePoi(PointOfInterest poi) {
    final updated = [...state.visible]..removeWhere((p) => p.id == poi.id);

    state = state.copyWith(visible: updated);
  }

  void setAll(List<PointOfInterest> pois) {
    state = state.copyWith(visible: [...pois]);
  }

  void removeAll() {
    state = state.copyWith(visible: []);
  }

  void replaceInVisiblePois(PointOfInterest updated) {
    final list = [...state.visible];
    final index = list.indexWhere((p) => p.id == updated.id);

    if (index != -1) {
      list[index] = updated;
      state = VisiblePoisStateData(visible: list);
    }
  }

}

final poisForSelectedCategoriesProvider = FutureProvider<List<PointOfInterest>>(
  (ref) async {
    final repo = ref.read(poiRepositoryProvider);
    final selected = ref.watch(categoriesMenuProvider).selectedValues.toList();

    return repo.loadPoisforSelectedCategories(selected);
  },
);
