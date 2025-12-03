// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
      id: json['id'] as String,
      userName: json['userName'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
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

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userName': instance.userName,
      'email': instance.email,
      'displayName': instance.displayName,
      'profileImageUrl': instance.profileImageUrl,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'isActive': instance.isActive,
      'bio': instance.bio,
      'level': instance.level,
      'levelName': instance.levelName,
      'levelDisplay': instance.levelDisplay,
      'experiencePoints': instance.experiencePoints,
      'totalReadBooks': instance.totalReadBooks,
      'totalQuizScore': instance.totalQuizScore,
      'currentStreak': instance.currentStreak,
      'longestStreak': instance.longestStreak,
    };
