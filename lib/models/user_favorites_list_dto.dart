class UserFavoritesListDTO {
  final String id;
  final String userID;
  final String name;
  final String createdAt;

  UserFavoritesListDTO({
    required this.id,
    required this.userID,
    required this.name,
    required this.createdAt,
  });

  factory UserFavoritesListDTO.fromJson(Map<String, dynamic> json) {
    return UserFavoritesListDTO(
      id: json['id'] as String,
      userID: json['user_id'] as String,
      name: json['name'] as String,
      createdAt: json['created_at'] as String,
    );
  }
}
