class CategoriesMenuState {
  final List<String> selectedValues;

  const CategoriesMenuState({required this.selectedValues});

  bool isSelected(String value) => selectedValues.contains(value);

  CategoriesMenuState copyWith({
    List<String>? selectedValues,
  }) {
    return CategoriesMenuState(
      selectedValues: selectedValues ?? this.selectedValues,
    );
  }

  static const initial = CategoriesMenuState(selectedValues: []);
}
