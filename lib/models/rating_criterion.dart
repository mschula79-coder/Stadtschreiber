/// General description of the criteria. User ratings are provided seperately
class RatingCriterionDTO {
  final String id;
  final String name;
  final String description;
  final Map<int, String> scoreDescriptions;

  RatingCriterionDTO({
    required this.id,
    required this.name,
    required this.description,
    required this.scoreDescriptions,
  });

  factory RatingCriterionDTO.fromJson(Map<String, dynamic> json) {
    final raw = json['score_descriptions'] as Map<String, dynamic>;

    final converted = raw.map(
      (key, value) => MapEntry(int.parse(key), value as String),
    );

    return RatingCriterionDTO(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      scoreDescriptions: converted,
    );
  }
}
