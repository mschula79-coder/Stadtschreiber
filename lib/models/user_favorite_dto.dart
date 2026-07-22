class UserFavoriteDTO {
  final String id;
  final String poiID;
  final String listID;
  final String createdAt;

  UserFavoriteDTO({
    required this.id,
    required this.listID,
    required this.poiID,
    required this.createdAt,
  });

  factory UserFavoriteDTO.fromJson(Map<String, dynamic> json) {
    return UserFavoriteDTO(
      id: json['id'] as String,
      poiID: json['poi_id'] as String,
      listID: json['list_id'] as String,
      createdAt: json['created_at'] as String,
    );
  }
}
