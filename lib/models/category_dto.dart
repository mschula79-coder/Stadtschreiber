class CategoryDto {
  final String id;
  final String slug;
  final String name;
  final int sortOrder;

  CategoryDto({
    required this.id,
    required this.slug,
    required this.name,
    required this.sortOrder,
  });

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    return CategoryDto(
      id: json['id'],
      slug: json['slug'],
      name: json['name'],
      sortOrder: json['sort_order'] ?? 9999,
    );
  }
}
