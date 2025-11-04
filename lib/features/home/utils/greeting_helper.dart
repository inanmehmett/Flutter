/// Helper class for generating time-based greetings.
/// 
/// Provides consistent greeting logic across the app.
class GreetingHelper {
  /// Returns a time-appropriate greeting in Turkish.
  /// 
  /// Time ranges:
  /// - 00:00 - 04:59: İyi geceler
  /// - 05:00 - 11:59: Günaydın
  /// - 12:00 - 17:59: İyi günler
  /// - 18:00 - 23:59: İyi akşamlar
  static String getGreeting() {
    final hour = DateTime.now().hour;
    
    if (hour < 5) {
      return 'İyi geceler';
    } else if (hour < 12) {
      return 'Günaydın';
    } else if (hour < 18) {
      return 'İyi günler';
    } else {
      return 'İyi akşamlar';
    }
  }

  /// Returns a personalized greeting with the user's name.
  /// 
  /// Example: "Günaydın, Mehmet!"
  static String getPersonalizedGreeting(String userName) {
    return '${getGreeting()}, $userName!';
  }
}

