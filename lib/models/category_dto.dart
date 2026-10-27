class CategoryDto {
  final String id;
  final String slug;
  final int sortOrder;
  final Map<String, String> labels;

  const CategoryDto({
    required this.id,
    required this.slug,
    required this.sortOrder,
    required this.labels,
  });

  factory CategoryDto.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawLabels = json['labels'];

    return CategoryDto(
      id: json['id'] as String,
      slug: json['slug'] as String,
      sortOrder: json['sort_order'] as int? ?? 0,
      labels: rawLabels is Map
          ? rawLabels.map<String, String>(
              (key, value) => MapEntry(
                key.toString(),
                value.toString(),
              ),
            )
          : const <String, String>{},
    );
  }
}