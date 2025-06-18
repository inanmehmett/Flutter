import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

@JsonSerializable()
class UserProfile {
  final String id;
  final String userName;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String? bio;
  final int? level;
  final int? experiencePoints;
  final int? totalReadBooks;
  final int? totalQuizScore;

  UserProfile({
    required this.id,
    required this.userName,
    required this.email,
    this.firstName,
    this.lastName,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    this.bio,
    this.level,
    this.experiencePoints,
    this.totalReadBooks,
    this.totalQuizScore,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  UserProfile copyWith({
    String? id,
    String? userName,
    String? email,
    String? firstName,
    String? lastName,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? bio,
    int? level,
    int? experiencePoints,
    int? totalReadBooks,
    int? totalQuizScore,
  }) {
    return UserProfile(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      bio: bio ?? this.bio,
      level: level ?? this.level,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      totalReadBooks: totalReadBooks ?? this.totalReadBooks,
      totalQuizScore: totalQuizScore ?? this.totalQuizScore,
    );
  }

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    }
    return userName;
  }

  String get displayName {
    return fullName.isNotEmpty ? fullName : userName;
  }
}
