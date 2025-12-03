import 'dart:async';
import 'package:injectable/injectable.dart';
import '../cache/cache_manager.dart';

/// Service to manage XP state locally for fast UI updates
/// XP changes are immediately reflected in UI without waiting for API calls
@singleton
class XPStateService {
  final CacheManager _cacheManager;
  
  // Stream controllers for reactive updates
  final _totalXPController = StreamController<int>.broadcast();
  final _dailyXPController = StreamController<int>.broadcast();
  final _streakController = StreamController<int>.broadcast();
  
  // Cache keys - using game/ prefix for compatibility with GameService
  static const String _totalXPKey = 'xp_state/total_xp';
  static const String _dailyXPKey = 'game/daily_xp';  // ✅ Same as GameService
  static const String _streakKey = 'xp_state/streak';
  static const String _lastUpdateKey = 'xp_state/last_update';
  
  XPStateService(this._cacheManager);
  
  /// Stream of total XP changes
  Stream<int> get totalXPStream => _totalXPController.stream;
  
  /// Stream of daily XP changes
  Stream<int> get dailyXPStream => _dailyXPController.stream;
  
  /// Stream of streak changes
  Stream<int> get streakStream => _streakController.stream;
  
  /// Get cached total XP (returns immediately)
  Future<int> getTotalXP() async {
    final cached = await _cacheManager.getData<int>(_totalXPKey);
    return cached ?? 0;
  }
  
  /// Get cached daily XP (returns immediately)
  Future<int> getDailyXP() async {
    final cached = await _cacheManager.getData<int>(_dailyXPKey);
    return cached ?? 0;
  }
  
  /// Get cached streak (returns immediately)
  Future<int> getStreak() async {
    final cached = await _cacheManager.getData<int>(_streakKey);
    return cached ?? 0;
  }
  
  /// Update total XP (called when XP is earned via SignalR)
  Future<void> updateTotalXP(int newTotalXP) async {
    await _cacheManager.setData(_totalXPKey, newTotalXP, timeout: const Duration(days: 30));
    await _cacheManager.setData(_lastUpdateKey, DateTime.now().toIso8601String(), timeout: const Duration(days: 30));
    _totalXPController.add(newTotalXP);
  }
  
  /// Increment total XP by delta (optimistic update)
  Future<void> incrementTotalXP(int deltaXP) async {
    final currentXP = await getTotalXP();
    final newTotalXP = currentXP + deltaXP;
    await updateTotalXP(newTotalXP);
  }
  
  /// Update daily XP (called when daily XP changes)
  Future<void> updateDailyXP(int dailyXP) async {
    print('🎯 [XPStateService] Updating daily XP: $dailyXP');
    // Use shorter timeout to match GameService (2 minutes)
    await _cacheManager.setData(_dailyXPKey, dailyXP, timeout: const Duration(minutes: 2));
    print('🎯 [XPStateService] Broadcasting daily XP to stream: $dailyXP');
    _dailyXPController.add(dailyXP);
    print('🎯 [XPStateService] Daily XP broadcast complete');
  }
  
  /// Increment daily XP by delta (optimistic update)
  Future<void> incrementDailyXP(int deltaXP) async {
    print('🎯 [XPStateService] Incrementing daily XP by: +$deltaXP');
    final currentDailyXP = await getDailyXP();
    print('🎯 [XPStateService] Current daily XP: $currentDailyXP');
    final newDailyXP = currentDailyXP + deltaXP;
    print('🎯 [XPStateService] New daily XP: $newDailyXP');
    await updateDailyXP(newDailyXP);
  }
  
  /// Update streak (called when streak changes)
  Future<void> updateStreak(int streak) async {
    await _cacheManager.setData(_streakKey, streak, timeout: const Duration(days: 30));
    _streakController.add(streak);
  }
  
  /// Initialize from API data (called on app start or refresh)
  Future<void> initializeFromAPI({
    int? totalXP,
    int? dailyXP,
    int? streak,
  }) async {
    if (totalXP != null) {
      await updateTotalXP(totalXP);
    }
    if (dailyXP != null) {
      await updateDailyXP(dailyXP);
    }
    if (streak != null) {
      await updateStreak(streak);
    }
  }
  
  /// Clear all cached XP data
  Future<void> clear() async {
    await _cacheManager.removeData(_totalXPKey);
    await _cacheManager.removeData(_dailyXPKey);
    await _cacheManager.removeData(_streakKey);
    await _cacheManager.removeData(_lastUpdateKey);
  }
  
  void dispose() {
    _totalXPController.close();
    _dailyXPController.close();
    _streakController.close();
  }
}

