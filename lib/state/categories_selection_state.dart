class CategoriesSelectionState {
  final List<String> selectedSlugs;

  const CategoriesSelectionState({required this.selectedSlugs});

  bool isSelected(String value) => selectedSlugs.contains(value);

  CategoriesSelectionState copyWith({List<String>? selectedSlugs}) {
    return CategoriesSelectionState(
      selectedSlugs: selectedSlugs ?? this.selectedSlugs,
    );
  }

  static const initial = CategoriesSelectionState(selectedSlugs: []);

  @override
  String toString() {
    final buffer = StringBuffer('CategoriesSelectionState:\n');

    if (selectedSlugs.isEmpty) {
      buffer.writeln('  (keine Kategorien ausgewählt)');
    } else {
      for (final value in selectedSlugs) {
        buffer.writeln('  • $value');
      }
    }

    return buffer.toString();
  }
}
