class LocalizedFeatureNode {
  final String id;
  final String slug;
  final String label;
  final String? definition;
  final int sortOrder;
  final String? parentSlug;
  final List<LocalizedFeatureNode> children;

  const LocalizedFeatureNode({
    required this.id,
    required this.slug,
    required this.label,
    required this.sortOrder,
    required this.children,
    this.definition,
    this.parentSlug,
  });

  bool get isLeaf {
    return children.isEmpty;
  }

  factory LocalizedFeatureNode.fromJson(
    Map<String, dynamic> json, {
    required String languageCode,
    String? countryCode,
  }) {
    final labels = Map<String, dynamic>.from(
      json['labels'] as Map? ?? const {},
    );

    final localeKey = countryCode == null
        ? languageCode
        : '$languageCode-$countryCode';

    final fallbackKey = switch (languageCode) {
      'de' => 'de-DE',
      'fr' => 'fr-FR',
      'en' => 'en-US',
      _ => 'de-DE',
    };

    final label =
        labels[localeKey]?.toString().trim() ??
        labels[fallbackKey]?.toString().trim() ??
        labels['de-DE']?.toString().trim() ??
        json['name']?.toString().trim() ??
        json['slug']?.toString().trim() ??
        '';

    return LocalizedFeatureNode(
      id: json['id'].toString(),
      slug: json['slug'].toString(),
      label: label,
      definition: json['definition']?.toString(),
      sortOrder:
          (json['sort_order'] as num?)?.toInt() ?? 0,
      parentSlug: json['parent_slug']?.toString(),
      children: const [],
    );
  }

  LocalizedFeatureNode copyWith({
    List<LocalizedFeatureNode>? children,
  }) {
    return LocalizedFeatureNode(
      id: id,
      slug: slug,
      label: label,
      sortOrder: sortOrder,
      definition: definition,
      parentSlug: parentSlug,
      children: children ?? this.children,
    );
  }
}