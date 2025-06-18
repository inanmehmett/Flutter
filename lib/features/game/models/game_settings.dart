class GameSettings {
  final bool notificationsEnabled;
  final bool dailyReminders;
  final bool challengeNotifications;
  final bool achievementNotifications;
  final DateTime reminderTime;

  GameSettings({
    this.notificationsEnabled = true,
    this.dailyReminders = true,
    this.challengeNotifications = true,
    this.achievementNotifications = true,
    DateTime? reminderTime,
  }) : reminderTime = reminderTime ??
            DateTime(DateTime.now().year, DateTime.now().month,
                DateTime.now().day, 9, 0); // 09:00 default

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    return GameSettings(
      notificationsEnabled: json['notificationsEnabled'] as bool,
      dailyReminders: json['dailyReminders'] as bool,
      challengeNotifications: json['challengeNotifications'] as bool,
      achievementNotifications: json['achievementNotifications'] as bool,
      reminderTime: DateTime.parse(json['reminderTime'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'dailyReminders': dailyReminders,
      'challengeNotifications': challengeNotifications,
      'achievementNotifications': achievementNotifications,
      'reminderTime': reminderTime.toIso8601String(),
    };
  }

  GameSettings copyWith({
    bool? notificationsEnabled,
    bool? dailyReminders,
    bool? challengeNotifications,
    bool? achievementNotifications,
    DateTime? reminderTime,
  }) {
    return GameSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      dailyReminders: dailyReminders ?? this.dailyReminders,
      challengeNotifications:
          challengeNotifications ?? this.challengeNotifications,
      achievementNotifications:
          achievementNotifications ?? this.achievementNotifications,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }
}
