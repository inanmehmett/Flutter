import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettings {
  final bool emailNotifications;
  final bool pushNotificationsEnabled;
  final bool progressNotifications;
  final bool badgeNotifications;
  final bool streakReminders;
  final bool dailyGoalReminders;
  final bool quizResultNotifications;
  final int? dailyReminderHour;
  final int? dailyReminderMinute;

  const NotificationSettings({
    this.emailNotifications = true,
    this.pushNotificationsEnabled = true,
    this.progressNotifications = true,
    this.badgeNotifications = true,
    this.streakReminders = true,
    this.dailyGoalReminders = true,
    this.quizResultNotifications = true,
    this.dailyReminderHour = 9,
    this.dailyReminderMinute = 0,
  });

  NotificationSettings copyWith({
    bool? emailNotifications,
    bool? pushNotificationsEnabled,
    bool? progressNotifications,
    bool? badgeNotifications,
    bool? streakReminders,
    bool? dailyGoalReminders,
    bool? quizResultNotifications,
    int? dailyReminderHour,
    int? dailyReminderMinute,
  }) {
    return NotificationSettings(
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      progressNotifications: progressNotifications ?? this.progressNotifications,
      badgeNotifications: badgeNotifications ?? this.badgeNotifications,
      streakReminders: streakReminders ?? this.streakReminders,
      dailyGoalReminders: dailyGoalReminders ?? this.dailyGoalReminders,
      quizResultNotifications: quizResultNotifications ?? this.quizResultNotifications,
      dailyReminderHour: dailyReminderHour ?? this.dailyReminderHour,
      dailyReminderMinute: dailyReminderMinute ?? this.dailyReminderMinute,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emailNotifications': emailNotifications,
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'progressNotifications': progressNotifications,
      'badgeNotifications': badgeNotifications,
      'streakReminders': streakReminders,
      'dailyGoalReminders': dailyGoalReminders,
      'quizResultNotifications': quizResultNotifications,
      'dailyReminderHour': dailyReminderHour,
      'dailyReminderMinute': dailyReminderMinute,
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      emailNotifications: json['emailNotifications'] as bool? ?? true,
      pushNotificationsEnabled: json['pushNotificationsEnabled'] as bool? ?? true,
      progressNotifications: json['progressNotifications'] as bool? ?? true,
      badgeNotifications: json['badgeNotifications'] as bool? ?? true,
      streakReminders: json['streakReminders'] as bool? ?? true,
      dailyGoalReminders: json['dailyGoalReminders'] as bool? ?? true,
      quizResultNotifications: json['quizResultNotifications'] as bool? ?? true,
      dailyReminderHour: json['dailyReminderHour'] as int? ?? 9,
      dailyReminderMinute: json['dailyReminderMinute'] as int? ?? 0,
    );
  }

  static const String _prefsKey = 'notification_settings';

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(toJson()));
  }

  static Future<NotificationSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_prefsKey);
    if (jsonString == null) {
      return const NotificationSettings();
    }
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return NotificationSettings.fromJson(json);
    } catch (e) {
      return const NotificationSettings();
    }
  }
}

