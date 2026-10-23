
class CategoryNode {
  final String id;
  final String label;
  final String? slug;
  final List<CategoryNode> children;
  final bool hasParents;

  CategoryNode({
    required this.id,
    required this.label,
    this.slug,
    this.children = const [],
    required this.hasParents
  });

  bool get isLeaf => children.isEmpty;
}
