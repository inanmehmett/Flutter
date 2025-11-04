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

  Future<int> getDailyXP({bool forceRefresh = false}) async {
    const cacheKey = 'game/daily_xp';
    
    if (!forceRefresh) {
      final cached = await _cacheManager.getData<int>(cacheKey);
      if (cached != null) return cached;
    }
    
    try {
      final Response response = await _apiClient.get('/api/gamification/daily-xp');
      final data = response.data;
      
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        final dailyData = data['data'] as Map<String, dynamic>;
        final dailyXP = (dailyData['dailyXP'] as num?)?.toInt() ?? 0;
        
        // Cache for 2 minutes (short cache for real-time feel)
        try {
          await _cacheManager.setData(cacheKey, dailyXP, timeout: const Duration(minutes: 2));
        } catch (_) {}
        
        return dailyXP;
      }
      
      return 0;
    } catch (e) {
      // Return cached value or 0 on error
      final cached = await _cacheManager.getData<int>(cacheKey);
      return cached ?? 0;
    }
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

  Future<LeaderboardPageResponse> getLeaderboardPage({
    String range = 'allTime',
    int offset = 0,
    int limit = 50,
    int surrounding = 2,
  }) async {
    try {
      final Response response = await _apiClient.get(
        '${ApiEndpoints.leaderboard}/paged',
        queryParameters: {
          'range': range,
          'offset': offset,
          'limit': limit,
          'surrounding': surrounding,
        },
      );

      final data = response.data;
      final payload = (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>)
          ? data['data'] as Map<String, dynamic>
          : <String, dynamic>{};

      return LeaderboardPageResponse.fromJson(payload);
    } catch (e) {
      // Fallback to old endpoint if paged endpoint not available
      print('⚠️ Paged leaderboard failed, falling back to old endpoint: $e');
      final Response response = await _apiClient.get(ApiEndpoints.leaderboard);
      final data = response.data;
      final list = (data is Map<String, dynamic> && data['data'] is List) 
          ? data['data'] as List<dynamic> 
          : [];
      
      final items = list
          .whereType<Map<String, dynamic>>()
          .take(limit)
          .toList()
          .asMap()
          .entries
          .map((entry) => _legacyEntryToApi(entry.value, entry.key))
          .toList();
      
      return LeaderboardPageResponse(
        items: items,
        totalCount: items.length,
        nextOffset: null,
        currentUser: null,
        surrounding: [],
      );
    }
  }

  LeaderboardApiEntry _legacyEntryToApi(Map<String, dynamic> m, int index) {
    String? levelLabel;
    if (m['currentLevel'] != null) {
      final level = m['currentLevel'] as Map<String, dynamic>;
      levelLabel = level['fullDisplayName'] ?? level['displayName'] ?? level['turkishName'];
    }
    
    return LeaderboardApiEntry(
      rank: (m['rank'] as num?)?.toInt() ?? (index + 1),
      userId: (m['userId'] ?? '').toString(),
      userName: (m['userName'] ?? 'Kullanıcı').toString(),
      totalXP: (m['totalXP'] as num?)?.toInt() ?? 0,
      weeklyXP: (m['weeklyXP'] as num?)?.toInt() ?? 0,
      monthlyXP: (m['monthlyXP'] as num?)?.toInt() ?? 0,
      currentStreak: (m['currentStreak'] as num?)?.toInt() ?? 0,
      levelLabel: levelLabel,
      profilePictureUrl: m['profilePictureUrl']?.toString() ?? m['profileImageUrl']?.toString(),
      isCurrentUser: false,
    );
  }

  Future<List<LeaderboardApiEntry>> getLeaderboard({
    String range = 'allTime',
    int limit = 50,
  }) async {
    final page = await getLeaderboardPage(range: range, limit: limit, surrounding: 0);
    return page.items;
  }
}

class LeaderboardPageResponse {
  final List<LeaderboardApiEntry> items;
  final int totalCount;
  final int? nextOffset;
  final LeaderboardApiEntry? currentUser;
  final List<LeaderboardApiEntry> surrounding;

  LeaderboardPageResponse({
    required this.items,
    required this.totalCount,
    required this.nextOffset,
    required this.currentUser,
    required this.surrounding,
  });

  factory LeaderboardPageResponse.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    final surroundingJson = json['surrounding'];

    return LeaderboardPageResponse(
      items: itemsJson is List
          ? itemsJson
              .whereType<Map<String, dynamic>>()
              .map(LeaderboardApiEntry.fromJson)
              .toList()
          : <LeaderboardApiEntry>[],
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      nextOffset: json['nextOffset'] is num ? (json['nextOffset'] as num).toInt() : null,
      currentUser: json['currentUser'] is Map<String, dynamic>
          ? LeaderboardApiEntry.fromJson(json['currentUser'] as Map<String, dynamic>)
          : null,
      surrounding: surroundingJson is List
          ? surroundingJson
              .whereType<Map<String, dynamic>>()
              .map(LeaderboardApiEntry.fromJson)
              .toList()
          : <LeaderboardApiEntry>[],
    );
  }
}

class LeaderboardApiEntry {
  final int rank;
  final String userId;
  final String userName;
  final int totalXP;
  final int weeklyXP;
  final int monthlyXP;
  final int currentStreak;
  final String? levelLabel;
  final String? profilePictureUrl;
  final bool isCurrentUser;

  LeaderboardApiEntry({
    required this.rank,
    required this.userId,
    required this.userName,
    required this.totalXP,
    required this.weeklyXP,
    required this.monthlyXP,
    required this.currentStreak,
    this.levelLabel,
    this.profilePictureUrl,
    this.isCurrentUser = false,
  });

  factory LeaderboardApiEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardApiEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] ?? '').toString(),
      userName: (json['userName'] ?? 'Kullanıcı').toString(),
      totalXP: (json['totalXP'] as num?)?.toInt() ?? 0,
      weeklyXP: (json['weeklyXP'] as num?)?.toInt() ?? 0,
      monthlyXP: (json['monthlyXP'] as num?)?.toInt() ?? 0,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      levelLabel: json['levelLabel']?.toString(),
      profilePictureUrl: json['profilePictureUrl']?.toString(),
      isCurrentUser: json['isCurrentUser'] == true,
    );
  }
}


