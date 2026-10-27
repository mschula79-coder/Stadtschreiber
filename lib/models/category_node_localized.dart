class LocalizedCategoryNode {
  final String id;
  final String slug;
  final String label;
  final int sortOrder;
  final Map<String, String> labels;
  final List<LocalizedCategoryNode> children;
  final bool hasParents;

  const LocalizedCategoryNode({
    required this.id,
    required this.slug,
    required this.label,
    required this.sortOrder,
    required this.labels,
    required this.children,
    required this.hasParents,
  });

  bool get isLeaf => children.isEmpty;
}