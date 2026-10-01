
class CategoryNode {
  final String id;
  final String label;
  final String? value;
  final List<CategoryNode> children;
  final bool hasParents;

  CategoryNode({
    required this.id,
    required this.label,
    this.value,
    this.children = const [],
    required this.hasParents
  });

  bool get isLeaf => children.isEmpty;
}
