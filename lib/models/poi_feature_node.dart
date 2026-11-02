class PoiFeatureNode {
  final String id;
  final String slug;
  final String label;
  final String? definition;
  final String? parentSlug;
  final String rootFeatureSlug;
  final String sourceCategoryId;
  final String sourceCategorySlug;
  final String sourceCategoryLabel;
  final int sortOrder;
  final bool isSelected;
  final List<PoiFeatureNode> children;

  const PoiFeatureNode({
    required this.id,
    required this.slug,
    required this.label,
    required this.rootFeatureSlug,
    required this.sourceCategoryId,
    required this.sourceCategorySlug,
    required this.sourceCategoryLabel,
    required this.sortOrder,
    required this.isSelected,
    required this.children,
    this.definition,
    this.parentSlug,
  });

  bool get isLeaf {
    return children.isEmpty;
  }

  PoiFeatureNode copyWith({
    List<PoiFeatureNode>? children,
  }) {
    return PoiFeatureNode(
      id: id,
      slug: slug,
      label: label,
      definition: definition,
      parentSlug: parentSlug,
      rootFeatureSlug: rootFeatureSlug,
      sourceCategoryId: sourceCategoryId,
      sourceCategorySlug: sourceCategorySlug,
      sourceCategoryLabel: sourceCategoryLabel,
      sortOrder: sortOrder,
      isSelected: isSelected,
      children: children ?? this.children,
    );
  }
}