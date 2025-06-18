class UserProfile {
  final String userName;
  final String? profileImageUrl;
  final String? level;

  const UserProfile({
    required this.userName,
    this.profileImageUrl,
    this.level,
  });
}
