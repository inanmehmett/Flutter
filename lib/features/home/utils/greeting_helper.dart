/// Helper class for generating time-based greetings.
/// 
/// Provides consistent greeting logic across the app with enhanced time ranges.
class GreetingHelper {
  /// Returns a time-appropriate greeting in Turkish.
  /// 
  /// Enhanced time ranges (6 zones for natural flow):
  /// - 00:00 - 03:59: İyi geceler 🌙 (Late night)
  /// - 04:00 - 05:59: Günaydın 🌅 (Early morning)
  /// - 06:00 - 11:59: Günaydın ☀️ (Morning)
  /// - 12:00 - 16:59: İyi günler ☀️ (Afternoon)
  /// - 17:00 - 20:59: İyi akşamlar 🌆 (Evening)
  /// - 21:00 - 23:59: İyi geceler 🌙 (Night)
  static String getGreeting() {
    final hour = DateTime.now().hour;
    
    if (hour < 4) {
      return 'İyi geceler';
    } else if (hour < 6) {
      return 'Günaydın'; // Early bird
    } else if (hour < 12) {
      return 'Günaydın';
    } else if (hour < 17) {
      return 'İyi günler';
    } else if (hour < 21) {
      return 'İyi akşamlar';
    } else {
      return 'İyi geceler';
    }
  }

  /// Returns a personalized greeting with the user's name.
  /// 
  /// Example: "Günaydın, Mehmet!"
  static String getPersonalizedGreeting(String userName) {
    return '${getGreeting()}, $userName!';
  }

  /// Returns a greeting with emoji for visual appeal.
  /// 
  /// Example: "☀️ Günaydın, Mehmet!"
  static String getGreetingWithEmoji(String userName) {
    return '${getTimeEmoji()} ${getGreeting()}, $userName!';
  }

  /// Get emoji for current time
  static String getTimeEmoji() {
    final hour = DateTime.now().hour;
    
    if (hour < 4) return '🌙';      // Late night
    if (hour < 6) return '🌅';      // Dawn
    if (hour < 12) return '☀️';     // Morning
    if (hour < 17) return '☀️';     // Afternoon
    if (hour < 21) return '🌆';     // Evening
    return '🌙';                     // Night
  }
}
