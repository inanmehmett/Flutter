import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/cache/cache_manager.dart';

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
  final CacheManager _cacheManager;

  GameService(this._apiClient, this._cacheManager);

  Future<UserProfileSummary> getProfileSummary({bool forceRefresh = false}) async {
    const levelKey = 'game/level';
    const streakKey = 'game/streak';

    Map<String, dynamic>? levelData;
    Map<String, dynamic>? streakData;

    if (!forceRefresh) {
      levelData = await _cacheManager.getData<Map<String, dynamic>>(levelKey);
      streakData = await _cacheManager.getData<Map<String, dynamic>>(streakKey);
    }

    if (levelData == null || streakData == null) {
      final Response levelResp = await _apiClient.get(ApiEndpoints.level);
      final Response streakResp = await _apiClient.get('/api/ApiProgressStats/streak');
      levelData = levelResp.data is Map<String, dynamic> ? levelResp.data as Map<String, dynamic> : <String, dynamic>{};
      streakData = streakResp.data is Map<String, dynamic> ? streakResp.data as Map<String, dynamic> : <String, dynamic>{};
      try {
        await _cacheManager.setData(levelKey, levelData, timeout: const Duration(minutes: 3));
        await _cacheManager.setData(streakKey, streakData, timeout: const Duration(minutes: 3));
      } catch (_) {}
    }

    return UserProfileSummary.fromLevelAndStreak(levelJson: levelData!, streakJson: streakData!);
  }

  Future<List<dynamic>> getBadges({bool forceRefresh = false}) async {
    const cacheKey = 'game/badges';
    if (!forceRefresh) {
      final cached = await _cacheManager.getData<List<dynamic>>(cacheKey);
      if (cached != null && cached.isNotEmpty) return cached;
    }
    final Response response = await _apiClient.get(ApiEndpoints.badges);
    final data = response.data;
    final list = (data is Map<String, dynamic> && data['data'] is List) ? data['data'] as List<dynamic> : [];
    try { await _cacheManager.setData(cacheKey, list, timeout: const Duration(minutes: 10)); } catch (_) {}
    return list;
  }

  Future<List<dynamic>> getLeaderboard() async {
    final Response response = await _apiClient.get(ApiEndpoints.leaderboard);
    final data = response.data;
    return (data is Map<String, dynamic> && data['data'] is List) ? data['data'] as List<dynamic> : [];
  }
}


