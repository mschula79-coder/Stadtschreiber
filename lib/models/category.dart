class CategoryNode {
  final String id;
  final String slug;
  final int sortOrder;
  final Map<String, String> labels;
  final List<CategoryNode> children;
  final bool hasParents;

  const CategoryNode({
    required this.id,
    required this.slug,
    required this.sortOrder,
    required this.labels,
    required this.children,
    required this.hasParents,
  });

  bool get isLeaf => children.isEmpty;

  String labelFor(String localeCode) {
    return labels[localeCode] ??
        labels['de-DE'] ??
        labels.values.firstOrNull ??
        slug;
  }
}