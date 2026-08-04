class PoiRatingWithStats {
  final String criterionId;
  final String criterionName;

  // User-spezifische Bewertung (optional)
  final double? userRating;
  final String? userComment;

  // Aggregierte Werte
  final double avgRating;
  final int ratingCount;
  final int commentCount;

  // Optional: Bayesian Score
  final double bayesianScore;

  PoiRatingWithStats({
    required this.criterionId,
    required this.criterionName,
    required this.avgRating,
    required this.ratingCount,
    required this.commentCount,
    this.userRating,
    this.userComment,
    required this.bayesianScore,
  });

  factory PoiRatingWithStats.fromJson(Map<String, dynamic> json) {
    return PoiRatingWithStats(
      criterionId: json['criterion_id'] as String,
      criterionName: json['criterion_name'] as String,
      avgRating: (json['avg_rating'] as num).toDouble(),
      ratingCount: json['rating_count'] as int,
      commentCount: json['comment_count'] as int,
      userRating: json['user_rating'] != null
          ? (json['user_rating'] as num).toDouble()
          : null,
      userComment: json['user_comment'] as String?,
      bayesianScore: (json['bayesian_score'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'criterion_id': criterionId,
      'criterion_name': criterionName,
      'avg_rating': avgRating,
      'rating_count': ratingCount,
      'comment_count': commentCount,
      'user_rating': userRating,
      'user_comment': userComment,
      'bayesian_score': bayesianScore,
    };
  }
}
