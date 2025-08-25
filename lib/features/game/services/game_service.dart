import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class UserProfileSummary {
  final int xp;
  final int currentStreak;
  final String? currentLevelLabel;
  final double progress; // 0..1

  const UserProfileSummary({
    required this.xp,
    required this.currentStreak,
    required this.progress,
    this.currentLevelLabel,
  });

  factory UserProfileSummary.fromLevelAndStreak({
    required Map<String, dynamic> levelJson,
    required Map<String, dynamic> streakJson,
  }) {
    final levelData = (levelJson['data'] ?? levelJson) as Map<String, dynamic>;
    final streakData = (streakJson['data'] ?? streakJson) as Map<String, dynamic>;

    final int currentXP = ((levelData['currentXP'] ?? levelData['CurrentXP'] ?? levelData['totalXP'] ?? levelData['TotalXP']) as num? ?? 0).toInt();
    final double progressPercent = (levelData['progressPercentage'] ?? levelData['ProgressPercentage'] as num?)?.toDouble() ?? 0.0;
    final double progress = progressPercent > 1 ? (progressPercent / 100.0) : progressPercent;
    final int streak = ((streakData['currentStreak'] ?? streakData['CurrentStreak']) as num? ?? 0).toInt();
    final String? levelLabel = (levelData['currentLevelEnglish'] ?? levelData['CurrentLevelEnglish'] ?? levelData['currentLevel'] ?? levelData['CurrentLevel'])?.toString();

    return UserProfileSummary(
      xp: currentXP,
      currentStreak: streak,
      progress: progress.clamp(0.0, 1.0),
      currentLevelLabel: levelLabel,
    );
  }
}

class GameService {
  final ApiClient _apiClient;

  GameService(this._apiClient);

  Future<UserProfileSummary> getProfileSummary() async {
    final Response levelResp = await _apiClient.get(ApiEndpoints.level);
    final Response streakResp = await _apiClient.get('/api/ApiProgressStats/streak');
    final levelData = levelResp.data is Map<String, dynamic> ? levelResp.data as Map<String, dynamic> : <String, dynamic>{};
    final streakData = streakResp.data is Map<String, dynamic> ? streakResp.data as Map<String, dynamic> : <String, dynamic>{};
    return UserProfileSummary.fromLevelAndStreak(levelJson: levelData, streakJson: streakData);
  }

  Future<List<dynamic>> getBadges() async {
    final Response response = await _apiClient.get(ApiEndpoints.badges);
    final data = response.data;
    return (data is Map<String, dynamic> && data['data'] is List) ? data['data'] as List<dynamic> : [];
  }

  Future<List<dynamic>> getLeaderboard() async {
    final Response response = await _apiClient.get(ApiEndpoints.leaderboard);
    final data = response.data;
    return (data is Map<String, dynamic> && data['data'] is List) ? data['data'] as List<dynamic> : [];
  }
}


