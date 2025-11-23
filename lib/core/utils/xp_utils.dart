/// XP calculation utilities
/// 
/// Provides helper functions for XP and level calculations
/// used across the application.
class XPUtils {
  /// Calculate next level XP based on current XP
  /// 
  /// Formula: Next level at every 1000 XP milestone
  /// - If currentXP < 1000: returns 1000
  /// - Otherwise: returns next 1000 milestone
  /// 
  /// Example:
  /// - currentXP = 500 → returns 1000
  /// - currentXP = 1500 → returns 2000
  /// - currentXP = 2500 → returns 3000
  static int calculateNextLevelXP(int currentXP) {
    if (currentXP < 1000) return 1000;
    final nextMilestone = ((currentXP / 1000).ceil() + 1) * 1000;
    return nextMilestone;
  }

  /// Calculate remaining XP needed to reach next level
  /// 
  /// Returns the difference between next level XP and current XP
  static int calculateRemainingXP(int currentXP) {
    final nextLevelXP = calculateNextLevelXP(currentXP);
    return (nextLevelXP - currentXP).clamp(0, nextLevelXP);
  }
}

