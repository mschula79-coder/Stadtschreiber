import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/categories_selection_state.dart';
import '../services/debug_service.dart';


class CategoriesSelectionNotifier extends Notifier<CategoriesSelectionState> {
  @override
  CategoriesSelectionState build() => CategoriesSelectionState.initial;

  void setSelected(String value, bool selected) {
    final updated = [...state.selectedValues];

    if (selected) {
      if (!updated.contains(value)) updated.add(value);
    } else {
      updated.remove(value);
    }

    DebugService.log("CategoriesSelectionNotifier.setSelected: $value = $selected");

    state = state.copyWith(selectedValues: updated);
  }

  void setMany(Map<String, bool> updates) {
    final updated = [...state.selectedValues];

    updates.forEach((value, selected) {
      if (selected) {
        if (!updated.contains(value)) updated.add(value);
      } else {
        updated.remove(value);
      }
    });

    DebugService.log("CategoriesSelectionNotifier.setMany: $updates");

    state = state.copyWith(selectedValues: updated);
  }

  void clear() {
    DebugService.log("CategoriesSelectionNotifier.clear");
    state = state.copyWith(selectedValues: []);
  }
}

final categoriesSelectionProvider =
    NotifierProvider<CategoriesSelectionNotifier, CategoriesSelectionState>(
      CategoriesSelectionNotifier.new,
      name: 'categoriesSelectionProvider',
    );

final selectedCategoriesProvider = Provider<List<String>>((ref) {
  return ref.watch(categoriesSelectionProvider).selectedValues;
});
