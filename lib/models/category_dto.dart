class CategoryDto {
  final String id;
  final String slug;
  final String name;
  final int sortOrder;
  final String? iconSource;
  final String? iconName;

  CategoryDto({
    required this.id,
    required this.slug,
    required this.name,
    required this.sortOrder,
    this.iconSource,
    this.iconName,
  });

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    return CategoryDto(
      id: json['id'],
      slug: json['slug'],
      name: json['name'],
      sortOrder: json['sort_order'] ?? 0,
      iconSource: json['icon_source'],
      iconName: json['icon_name'],
    );
  }
}
