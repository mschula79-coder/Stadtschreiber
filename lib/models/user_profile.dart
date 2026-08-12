class UserProfile {
  final String id;
  final String username;
  final String email;
  final bool isAdmin;
  final bool isAuthor;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.isAdmin,
    required this.isAuthor,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      isAdmin: json['is_admin'] ?? false,
      isAuthor: json['is_author'] ?? false,
    );
  }
}
