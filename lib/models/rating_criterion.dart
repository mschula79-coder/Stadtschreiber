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
    // score_descriptions kann fehlen, null sein oder kein Map sein
    final raw = json['score_descriptions'];

    final Map<int, String> converted = {};

    if (raw is Map) {
      raw.forEach((key, value) {
        // Key muss String sein und parsebar zu int
        final parsedKey = int.tryParse(key.toString());
        if (parsedKey != null && value is String) {
          converted[parsedKey] = value;
        }
      });
    }

    return RatingCriterionDTO(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      scoreDescriptions: converted,
    );
  }
}
