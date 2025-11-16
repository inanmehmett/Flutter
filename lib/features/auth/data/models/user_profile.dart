import 'package:json_annotation/json_annotation.dart';
import '../../../../core/config/app_config.dart';

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
    this.firstName,
    this.lastName,
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
    // Profile image URL'yi tam URL'ye çevir
    String? processProfileImageUrl(String? profileImageUrl) {
      if (profileImageUrl == null || profileImageUrl.isEmpty) return null;
      
      // localhost içeren URL'leri AppConfig.apiBaseUrl ile değiştir
      if (profileImageUrl.contains('localhost') || profileImageUrl.contains('127.0.0.1')) {
        final uri = Uri.parse(profileImageUrl);
        final path = uri.path;
        return '${AppConfig.apiBaseUrl}$path${uri.query.isNotEmpty ? '?${uri.query}' : ''}';
      }
      
      if (profileImageUrl.startsWith('http://') || profileImageUrl.startsWith('https://')) {
        return profileImageUrl;
      }
      if (profileImageUrl.startsWith('file://')) {
        return profileImageUrl.replaceFirst('file://', AppConfig.apiBaseUrl);
      }
      if (profileImageUrl.startsWith('/')) {
        return '${AppConfig.apiBaseUrl}$profileImageUrl';
      }
      return '${AppConfig.apiBaseUrl}/$profileImageUrl';
    }

    return UserProfile(
      id: json['id'] as String,
      userName: json['userName'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
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
    String? firstName,
    String? lastName,
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
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
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
