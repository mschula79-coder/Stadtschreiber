class UserProfile {
  final String id;
  final String username;
  final String email;
  final bool isAdmin;
  final bool isEditor;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.isAdmin,
    required this.isEditor,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      isAdmin: json['is_admin'] ?? false,
      isEditor: json['is_editor'] ?? false,
    );
  }
}
