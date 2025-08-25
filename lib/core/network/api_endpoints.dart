class ApiEndpoints {
  // Base API URLs
  static const String base = '/api';
  
  // Auth endpoints
  static const String auth = '$base/auth';
  static const String login = '$auth/login';
  static const String googleLogin = '$auth/google-login';
  static const String logout = '$auth/logout';
  static const String refreshToken = '$auth/refresh-token';
  
  // User endpoints
  static const String user = '$base/user';
  static const String userProfile = '$user/profile';
  static const String userActivities = '$user/activities';
  
  // Reading texts endpoints
  static const String readingTexts = '$base/reading-texts';
  
  // Reading quiz endpoints
  static const String readingQuiz = '$base/reading-quiz';
  
  // Vocabulary quiz endpoints
  static const String vocabularyQuiz = '$base/quiz';
  
  // Mobile quiz endpoints
  static const String mobileQuiz = '$base/mobile/quiz';
  
  // Gamification endpoints
  static const String gamification = '$base/gamification';
  static const String level = '$gamification/level';
  static const String dailyTasks = '$gamification/daily-tasks';
  static const String claimTask = '$gamification/tasks/complete';
  static const String earnXP = '$gamification/xp/earn';
  static const String badges = '$gamification/badges';
  static const String achievements = '$gamification/achievements';
  static const String leaderboard = '$gamification/leaderboard';
  
  // Translation endpoints
  static const String translation = '$base/translation';
  
  // File upload endpoints
  static const String upload = '$base/upload';
}
