import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/categories_menu_state.dart';
import '../services/debug_service.dart';

class CategoriesMenuNotifier extends Notifier<CategoriesMenuState> {
  @override
  CategoriesMenuState build() => CategoriesMenuState.initial;

  void setSelected(String value, bool selected) {
    final updated = [...state.selectedValues];

    if (selected) {
      if (!updated.contains(value)) updated.add(value);
    } else {
      updated.remove(value);
    }

    DebugService.log("CategoriesMenuNotifier.setSelected: $value = $selected");

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

    DebugService.log("CategoriesMenuNotifier.setMany: $updates");

    state = state.copyWith(selectedValues: updated);
  }

  void clear() {
    DebugService.log("CategoriesMenuNotifier.clear");
    state = state.copyWith(selectedValues: []);
  }
}

final categoriesMenuProvider =
    NotifierProvider<CategoriesMenuNotifier, CategoriesMenuState>(
      CategoriesMenuNotifier.new,
      name: 'categoriesMenuProvider'
    );
