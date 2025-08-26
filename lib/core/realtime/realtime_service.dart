import 'dart:async';
import 'package:flutter/services.dart';
import '../di/injection.dart';
import '../network/network_manager.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';

enum RealtimeEventType { xpChanged, levelUp, badgeEarned, streakUpdated }

class RealtimeEvent {
  final RealtimeEventType type;
  final Map<String, dynamic> payload;
  const RealtimeEvent(this.type, this.payload);
}

/// Lightweight polling-based realtime until SignalR is wired.
class RealtimeService {
  final ApiClient _apiClient;
  final NetworkManager _networkManager;

  Timer? _timer;
  final StreamController<RealtimeEvent> _controller = StreamController.broadcast();

  // Client-side last-knowns for diffing
  int? _lastXP;
  String? _lastLevelLabel;
  int? _lastStreak;
  Set<String> _earnedBadgeNames = <String>{};
  bool _badgesPrimed = false;

  RealtimeService(this._apiClient, this._networkManager);

  Stream<RealtimeEvent> get events => _controller.stream;

  void start({Duration interval = const Duration(seconds: 8)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _pollOnce());
    _pollOnce();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _pollOnce() async {
    try {
      // Level + XP
      final levelResp = await _apiClient.get(ApiEndpoints.level);
      final levelData = (levelResp.data is Map<String, dynamic>) ? levelResp.data as Map<String, dynamic> : <String, dynamic>{};
      final levelRoot = (levelData['data'] is Map<String, dynamic>) ? levelData['data'] as Map<String, dynamic> : levelData;
      final int currentXP = ((levelRoot['currentXP'] ?? levelRoot['totalXP'] ?? 0) as num).toInt();
      final String? levelLabel = (levelRoot['currentLevelEnglish'] ?? levelRoot['currentLevel'] as String?)?.toString();

      if (_lastXP != null && currentXP > _lastXP!) {
        _controller.add(RealtimeEvent(RealtimeEventType.xpChanged, {
          'deltaXP': currentXP - _lastXP!,
          'totalXP': currentXP,
        }));
        HapticFeedback.lightImpact();
      }
      if (_lastLevelLabel != null && levelLabel != null && levelLabel != _lastLevelLabel) {
        _controller.add(RealtimeEvent(RealtimeEventType.levelUp, {
          'levelLabel': levelLabel,
          'totalXP': currentXP,
        }));
        HapticFeedback.mediumImpact();
      }
      _lastXP = currentXP;
      _lastLevelLabel = levelLabel ?? _lastLevelLabel;

      // Streak
      final streakResp = await _networkManager.get('/api/ApiProgressStats/streak');
      final sroot = (streakResp.data is Map<String, dynamic>) ? streakResp.data as Map<String, dynamic> : <String, dynamic>{};
      final sdat = (sroot['data'] is Map<String, dynamic>) ? sroot['data'] as Map<String, dynamic> : <String, dynamic>{};
      final int streakDays = ((sdat['currentStreak'] ?? 0) as num).toInt();
      if (_lastStreak != null && streakDays != _lastStreak) {
        _controller.add(RealtimeEvent(RealtimeEventType.streakUpdated, {
          'currentStreak': streakDays,
        }));
        HapticFeedback.selectionClick();
      }
      _lastStreak = streakDays;

      // Badges (new earned)
      final badgesResp = await _networkManager.get('/api/ApiGamification/badges');
      final broot = (badgesResp.data is Map<String, dynamic>) ? badgesResp.data as Map<String, dynamic> : <String, dynamic>{};
      final list = (broot['data'] is List) ? broot['data'] as List<dynamic> : const <dynamic>[];
      for (final item in list) {
        final m = item as Map<String, dynamic>;
        final String name = (m['name'] ?? m['Name'] ?? '').toString();
        final bool earned = ((m['isEarned'] ?? m['IsEarned']) as bool?) ?? false;
        if (earned) {
          if (!_badgesPrimed) {
            // Prime without toasts on first load
            _earnedBadgeNames.add(name);
          } else if (!_earnedBadgeNames.contains(name)) {
            _earnedBadgeNames.add(name);
            _controller.add(RealtimeEvent(RealtimeEventType.badgeEarned, {
              'name': name,
              'imageUrl': (m['imageUrl'] ?? m['ImageUrl'])?.toString(),
            }));
            HapticFeedback.selectionClick();
          }
        }
      }
      _badgesPrimed = true;
    } catch (_) {
      // swallow network errors quietly
    }
  }
}


