import 'package:flutter/foundation.dart';

class FilterState extends ChangeNotifier {
  final Set<String> selectedValues = {};

  bool isSelected(String value) => selectedValues.contains(value);

  void setSelected(String value, bool selected) {
    if (selected) {
      selectedValues.add(value);
    } else {
      selectedValues.remove(value);
    }
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
    notifyListeners();
  }

  void clear() {
    selectedValues.clear();
    notifyListeners();
  }
}
