import '../../game/models/experience_stats.dart';
import '../../game/models/social_stats.dart';
import '../../game/models/game_settings.dart';
import 'privacy_settings.dart';

class ReadingGoals {
  final int dailyReadingMinutes;
  final int dailyNewWords;
  final int weeklyBookTarget;
  final int monthlyReadingHours;
  final int yearlyBookTarget;
  final int streakTarget;

  const ReadingGoals({
    this.dailyReadingMinutes = 30,
    this.dailyNewWords = 10,
    this.weeklyBookTarget = 1,
    this.monthlyReadingHours = 20,
    this.yearlyBookTarget = 12,
    this.streakTarget = 30,
  });

  factory ReadingGoals.fromJson(Map<String, dynamic> json) {
    return ReadingGoals(
      dailyReadingMinutes: json['dailyReadingMinutes'] as int,
      dailyNewWords: json['dailyNewWords'] as int,
      weeklyBookTarget: json['weeklyBookTarget'] as int,
      monthlyReadingHours: json['monthlyReadingHours'] as int,
      yearlyBookTarget: json['yearlyBookTarget'] as int,
      streakTarget: json['streakTarget'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyReadingMinutes': dailyReadingMinutes,
      'dailyNewWords': dailyNewWords,
      'weeklyBookTarget': weeklyBookTarget,
      'monthlyReadingHours': monthlyReadingHours,
      'yearlyBookTarget': yearlyBookTarget,
      'streakTarget': streakTarget,
    };
  }
}

class UserPreferences {
  final int? lastReadBookId;
  final Map<int, List<int>> bookmarks;
  final Map<int, double> readingProgress;
  final Set<String> vocabulary;
  final int wordsLearned;
  final int dailyStreak;
  final DateTime? lastReadDate;
  final ReadingGoals readingGoals;
  final Map<String, dynamic> achievements;
  final ExperienceStats gameStats;
  final SocialStats social;
  final GameSettings settings;
  final PrivacySettings privacySettings;

  UserPreferences({
    this.lastReadBookId,
    this.bookmarks = const {},
    this.readingProgress = const {},
    Set<String>? vocabulary,
    this.wordsLearned = 0,
    this.dailyStreak = 0,
    this.lastReadDate,
    ReadingGoals? readingGoals,
    Map<String, dynamic>? achievements,
    ExperienceStats? gameStats,
    SocialStats? social,
    GameSettings? settings,
    PrivacySettings? privacySettings,
  })  : readingGoals = readingGoals ?? ReadingGoals(),
        vocabulary = vocabulary ?? <String>{},
        achievements = achievements ?? {},
        gameStats = gameStats ?? ExperienceStats(),
        social = social ?? SocialStats(),
        settings = settings ?? GameSettings(),
        privacySettings = privacySettings ?? PrivacySettings();

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      lastReadBookId: json['lastReadBookId'] as int?,
      bookmarks: (json['bookmarks'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(int.parse(k), List<int>.from(v as List))) ??
          {},
      readingProgress: (json['readingProgress'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(int.parse(k), v as double)) ??
          {},
      vocabulary: Set<String>.from(json['vocabulary'] as List? ?? []),
      wordsLearned: json['wordsLearned'] as int? ?? 0,
      dailyStreak: json['dailyStreak'] as int? ?? 0,
      lastReadDate: json['lastReadDate'] != null
          ? DateTime.parse(json['lastReadDate'] as String)
          : null,
      readingGoals: json['readingGoals'] != null
          ? ReadingGoals.fromJson(json['readingGoals'] as Map<String, dynamic>)
          : const ReadingGoals(),
      achievements: json['achievements'] as Map<String, dynamic>? ?? {},
      gameStats: json['gameStats'] != null
          ? ExperienceStats.fromJson(json['gameStats'] as Map<String, dynamic>)
          : const ExperienceStats(),
      social: json['social'] != null
          ? SocialStats.fromJson(json['social'] as Map<String, dynamic>)
          : const SocialStats(),
      settings: json['settings'] != null
          ? GameSettings.fromJson(json['settings'] as Map<String, dynamic>)
          : GameSettings(),
      privacySettings: json['privacySettings'] != null
          ? PrivacySettings.fromJson(
              json['privacySettings'] as Map<String, dynamic>)
          : PrivacySettings(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lastReadBookId': lastReadBookId,
      'bookmarks': bookmarks.map((k, v) => MapEntry(k.toString(), v)),
      'readingProgress':
          readingProgress.map((k, v) => MapEntry(k.toString(), v)),
      'vocabulary': vocabulary.toList(),
      'wordsLearned': wordsLearned,
      'dailyStreak': dailyStreak,
      'lastReadDate': lastReadDate?.toIso8601String(),
      'readingGoals': readingGoals.toJson(),
      'achievements': achievements,
      'gameStats': gameStats.toJson(),
      'social': social.toJson(),
      'settings': settings.toJson(),
      'privacySettings': privacySettings.toJson(),
    };
  }
}
