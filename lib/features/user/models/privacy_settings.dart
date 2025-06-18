enum PrivacyLevel {
  public_,
  friends,
  private_,
}

class PrivacySettings {
  final PrivacyLevel profileVisibility;
  final bool showReadingStats;
  final bool showAchievements;
  final bool allowFriendRequests;
  final bool shareReadingActivity;

  const PrivacySettings({
    this.profileVisibility = PrivacyLevel.public_,
    this.showReadingStats = true,
    this.showAchievements = true,
    this.allowFriendRequests = true,
    this.shareReadingActivity = true,
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      profileVisibility: PrivacyLevel.values[json['profileVisibility'] as int],
      showReadingStats: json['showReadingStats'] as bool,
      showAchievements: json['showAchievements'] as bool,
      allowFriendRequests: json['allowFriendRequests'] as bool,
      shareReadingActivity: json['shareReadingActivity'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profileVisibility': profileVisibility.index,
      'showReadingStats': showReadingStats,
      'showAchievements': showAchievements,
      'allowFriendRequests': allowFriendRequests,
      'shareReadingActivity': shareReadingActivity,
    };
  }

  PrivacySettings copyWith({
    PrivacyLevel? profileVisibility,
    bool? showReadingStats,
    bool? showAchievements,
    bool? allowFriendRequests,
    bool? shareReadingActivity,
  }) {
    return PrivacySettings(
      profileVisibility: profileVisibility ?? this.profileVisibility,
      showReadingStats: showReadingStats ?? this.showReadingStats,
      showAchievements: showAchievements ?? this.showAchievements,
      allowFriendRequests: allowFriendRequests ?? this.allowFriendRequests,
      shareReadingActivity: shareReadingActivity ?? this.shareReadingActivity,
    );
  }
}
