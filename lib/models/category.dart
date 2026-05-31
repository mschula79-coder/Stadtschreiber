
class CategoryNode {
  final String id;
  final String label;
  final String? value;
  final List<CategoryNode> children;

  CategoryNode({
    required this.id,
    required this.label,
    this.value,
    this.children = const [],
  });

  bool get isLeaf => children.isEmpty;
}
