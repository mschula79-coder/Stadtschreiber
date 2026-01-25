class CategoryIcon {
  final String type; // flutter, iconify, url
  final String value;

  CategoryIcon({required this.type, required this.value});

  factory CategoryIcon.fromJson(Map<String, dynamic> json) {
    return CategoryIcon(type: json['type'], value: json['value']);
  }
}

class CategoryNode {
  final String label;
  final String? value;
  final CategoryIcon? icon;
  final List<CategoryNode> children;

  CategoryNode({
    required this.label,
    this.value,
    this.icon,
    this.children = const [],
  });

  factory CategoryNode.fromJson(Map<String, dynamic> json) {
    return CategoryNode(
      label: json['label'],
      value: json['value'],
      icon: json['icon'] != null ? CategoryIcon.fromJson(json['icon']) : null,
      children: json['children'] != null
          ? (json['children'] as List)
                .map((c) => CategoryNode.fromJson(c))
                .toList()
          : [],
    );
  }
  bool get isLeaf => children.isEmpty;
}
