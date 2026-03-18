class PoiRatingStatsDto {
  final String poiId;
  final String criterionId;
  final double avgRating;
  final int ratingCount;
  final int commentsCount;

  PoiRatingStatsDto({
    required this.poiId,
    required this.criterionId,
    required this.avgRating,
    required this.ratingCount,
    required this.commentsCount
  });

  factory PoiRatingStatsDto.fromJson(Map<String, dynamic> json) {
    return PoiRatingStatsDto(
      poiId: json['poi_id'] as String,
      criterionId: json['criterion_id'] as String,
      avgRating: (json['avg_rating'] as num).toDouble(),
      ratingCount: json['rating_count'] as int,
      commentsCount: json['comment_count'] as int,
    );
  }
}
