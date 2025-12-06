import 'package:json_annotation/json_annotation.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/utils/url_normalizer.dart';

part 'user_profile.g.dart';

@JsonSerializable()
class UserProfile {
  final String id;
  final String userName;
  final String email;
  final String? displayName;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String? bio;
  final int? level;
  final String? levelName;
  final String? levelDisplay;
  final int? experiencePoints;
  final int? totalReadBooks;
  final int? totalQuizScore;
  final int? currentStreak;
  final int? longestStreak;

  UserProfile({
    required this.id,
    required this.userName,
    required this.email,
    this.displayName,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    this.bio,
    this.level,
    this.levelName,
    this.levelDisplay,
    this.experiencePoints,
    this.totalReadBooks,
    this.totalQuizScore,
    this.currentStreak,
    this.longestStreak,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Profile image URL'yi normalize et (merkezi utility kullan)
    String? processProfileImageUrl(String? profileImageUrl) {
      return UrlNormalizer.normalizeImageUrl(profileImageUrl);
    }

    return UserProfile(
      id: json['id'] as String,
      userName: json['userName'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      profileImageUrl: processProfileImageUrl(json['profileImageUrl'] as String?),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isActive: json['isActive'] as bool,
      bio: json['bio'] as String?,
      level: (json['level'] as num?)?.toInt(),
      levelName: json['levelName'] as String?,
      levelDisplay: json['levelDisplay'] as String?,
      experiencePoints: (json['experiencePoints'] as num?)?.toInt(),
      totalReadBooks: (json['totalReadBooks'] as num?)?.toInt(),
      totalQuizScore: (json['totalQuizScore'] as num?)?.toInt(),
      currentStreak: (json['currentStreak'] as num?)?.toInt(),
      longestStreak: (json['longestStreak'] as num?)?.toInt(),
    );
  }
  
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  UserProfile copyWith({
    String? id,
    String? userName,
    String? email,
    String? displayName,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? bio,
    int? level,
    String? levelName,
    String? levelDisplay,
    int? experiencePoints,
    int? totalReadBooks,
    int? totalQuizScore,
    int? currentStreak,
    int? longestStreak,
  }) {
    return UserProfile(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      bio: bio ?? this.bio,
      level: level ?? this.level,
      levelName: levelName ?? this.levelName,
      levelDisplay: levelDisplay ?? this.levelDisplay,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      totalReadBooks: totalReadBooks ?? this.totalReadBooks,
      totalQuizScore: totalQuizScore ?? this.totalQuizScore,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
    );
  }

  String get displayNameOrUserName {
    return displayName?.isNotEmpty == true ? displayName! : userName;
  }
}
