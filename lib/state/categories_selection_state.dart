class CategoriesSelectionState {
  final List<String> selectedValues;

  const CategoriesSelectionState({required this.selectedValues});

  bool isSelected(String value) => selectedValues.contains(value);

  CategoriesSelectionState copyWith({List<String>? selectedValues}) {
    return CategoriesSelectionState(
      selectedValues: selectedValues ?? this.selectedValues,
    );
  }

  static const initial = CategoriesSelectionState(selectedValues: []);

  @override
  String toString() {
    final buffer = StringBuffer('CategoriesSelectionState:\n');

    if (selectedValues.isEmpty) {
      buffer.writeln('  (keine Kategorien ausgewählt)');
    } else {
      for (final value in selectedValues) {
        buffer.writeln('  • $value');
      }
    }

    return buffer.toString();
  }
}
