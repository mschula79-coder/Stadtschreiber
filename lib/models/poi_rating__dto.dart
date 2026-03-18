/// one rating (score + optional comment + timestamp) for one poi, user and criterion
class PoiRatingDto {
  final String ratingId;
  final String? userId;
  final String? username;
  final String criterionId;
  final int ratingScore;
  final String? comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  PoiRatingDto({
    required this.ratingId,
    this.userId,
    this.username,
    required this.criterionId,
    required this.ratingScore,
    this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PoiRatingDto.fromJson(Map<String, dynamic> json) {
    return PoiRatingDto(
      ratingId: json['id'],
      userId: json['user_id'],
      username: json['profiles']?['username'] ?? 'anonym',
      criterionId: json['criterion_id'],
      ratingScore: json['rating'],
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
