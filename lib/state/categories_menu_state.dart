import 'package:flutter/foundation.dart';
import '../services/debug_service.dart';

class CategoriesMenuState extends ChangeNotifier {
  final List<String> selectedValues = [];

  bool isSelected(String value) => selectedValues.contains(value);

  void setSelected(String value, bool selected) {
    if (selected) {
      selectedValues.add(value);
    } else {
      selectedValues.remove(value);
    }
    DebugService.log(
      'CategoriesMenuState.setSelected: $value: $selected - notifyListeners',
    );
    notifyListeners();
  }

  void setMany(Map<String, bool> updates) {
    updates.forEach((value, selected) {
      if (selected) {
        selectedValues.add(value);
      } else {
        selectedValues.remove(value);
      }
    });
     DebugService.log(
      'CategoriesMenuState.setMany: $updates - notifyListeners',
    );
    notifyListeners();
  }

  void clear() {
    selectedValues.clear();
    DebugService.log(
      'CategoriesMenuState.clear - notifyListeners',
    );
    notifyListeners();
  }
}
