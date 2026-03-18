class UserProfile {
  final String id;
  final String username;
  final bool isAdmin;

  UserProfile({
    required this.id,
    required this.username,
    required this.isAdmin,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      isAdmin: json['is_admin'] as bool,
    );
  }
}
