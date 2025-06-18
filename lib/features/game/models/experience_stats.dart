class ExperienceStats {
  final int currentLevel;
  final int totalXP;
  final int currentLevelXP;
  final int nextLevelXP;

  const ExperienceStats({
    this.currentLevel = 1,
    this.totalXP = 0,
    this.currentLevelXP = 0,
    this.nextLevelXP = 1000,
  });

  factory ExperienceStats.fromJson(Map<String, dynamic> json) {
    return ExperienceStats(
      currentLevel: json['currentLevel'] as int,
      totalXP: json['totalXP'] as int,
      currentLevelXP: json['currentLevelXP'] as int,
      nextLevelXP: json['nextLevelXP'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentLevel': currentLevel,
      'totalXP': totalXP,
      'currentLevelXP': currentLevelXP,
      'nextLevelXP': nextLevelXP,
    };
  }

  ExperienceStats copyWith({
    int? currentLevel,
    int? totalXP,
    int? currentLevelXP,
    int? nextLevelXP,
  }) {
    return ExperienceStats(
      currentLevel: currentLevel ?? this.currentLevel,
      totalXP: totalXP ?? this.totalXP,
      currentLevelXP: currentLevelXP ?? this.currentLevelXP,
      nextLevelXP: nextLevelXP ?? this.nextLevelXP,
    );
  }
}
