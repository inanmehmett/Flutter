import 'dart:async';
import 'package:flutter/services.dart';
import 'package:signalr_core/signalr_core.dart';
import 'package:injectable/injectable.dart';
import '../network/network_manager.dart';
import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';

enum RealtimeEventType { xpChanged, levelUp, badgeEarned, streakUpdated }

class RealtimeEvent {
  final RealtimeEventType type;
  final Map<String, dynamic> payload;
  const RealtimeEvent(this.type, this.payload);
}

/// SignalR-based real-time service for gamification events
@singleton
class SignalRService {
  final NetworkManager _networkManager;
  final SecureStorageService _secureStorage;
  
  HubConnection? _connection;
  final StreamController<RealtimeEvent> _controller = StreamController.broadcast();
  
  bool _isConnected = false;
  bool _isConnecting = false;
  Timer? _reconnectTimer;
  int? _lastNotifiedStreak; // prevent duplicate streak toasts when value unchanged
  
  SignalRService(this._networkManager, this._secureStorage);

  Stream<RealtimeEvent> get events => _controller.stream;
  bool get isConnected => _isConnected;

  /// Initialize and start SignalR connection
  Future<void> start() async {
    if (_isConnecting || _isConnected) return;
    
    _isConnecting = true;
    
    try {
      // Ensure we have a valid (non-expired) token. Try refresh if needed.
      await _ensureValidToken();
      // Get authentication token
      final token = await _secureStorage.getAccessToken();
      if (token == null) {
        print('⚠️ No auth token found, skipping SignalR connection');
        _isConnecting = false;
        return;
      }

      // Build SignalR URL
      final baseUrl = AppConfig.apiBaseUrl;
      final hubUrl = '$baseUrl/gamificationHub';
      
      print('🔌 Connecting to SignalR hub: $hubUrl');

      // Create connection with authentication
      _connection = HubConnectionBuilder()
          .withUrl(
            hubUrl,
            HttpConnectionOptions(
              accessTokenFactory: () async => token,
              skipNegotiation: false,
              transport: HttpTransportType.webSockets,
            ),
          )
          .withAutomaticReconnect([0, 2000, 10000, 30000])
          .build();

      // Set up event handlers
      _setupEventHandlers();

      // Start connection
      await _connection!.start();
      _isConnected = true;
      _isConnecting = false;
      
      print('✅ SignalR connected successfully');
      
      // Send test message to verify connection
      await _connection!.invoke('SendTestMessage', args: ['Flutter client connected']);
      
    } catch (e) {
      _isConnecting = false;
      print('❌ SignalR connection failed: $e');
      // If unauthorized (expired token), try refresh once then retry immediately
      final err = e.toString();
      if (err.contains("401") || err.contains('Unauthorized') || err.contains('invalid_token')) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          print('🔄 Token refreshed after 401. Retrying SignalR connect...');
          return start();
        }
      }
      
      // Fallback to polling after 5 seconds
      _scheduleReconnect();
    }
  }

  /// Stop SignalR connection
  Future<void> stop() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    
    if (_connection != null) {
      await _connection!.stop();
      _connection = null;
    }
    
    _isConnected = false;
    _isConnecting = false;
    print('🔌 SignalR connection stopped');
  }

  /// Set up event handlers for different gamification events
  void _setupEventHandlers() {
    if (_connection == null) return;

    // Connection established
    _connection!.on('ConnectionEstablished', (List<Object?>? args) {
      print('✅ SignalR connection established');
    });

    // Connection error
    _connection!.on('ConnectionError', (List<Object?>? args) {
      print('❌ SignalR connection error: $args');
    });

    // Test message received
    _connection!.on('TestMessageReceived', (List<Object?>? args) {
      print('📨 Test message received: $args');
    });

    // XP Earned event
    _connection!.on('XP Earned', (List<Object?>? args) {
      if (args != null && args.isNotEmpty) {
        final data = args[0] as Map<String, dynamic>?;
        if (data != null) {
          _controller.add(RealtimeEvent(RealtimeEventType.xpChanged, {
            'deltaXP': data['xpEarned'] ?? 0,
            'totalXP': data['newTotalXP'] ?? 0,
            'isLevelUp': data['isLevelUp'] ?? false,
            'newLevel': data['newLevel'],
          }));
          
          // Haptic feedback
          if (data['isLevelUp'] == true) {
            HapticFeedback.mediumImpact();
          } else {
            HapticFeedback.lightImpact();
          }
        }
      }
    });

    // Level Up event
    _connection!.on('Level Up', (List<Object?>? args) {
      if (args != null && args.isNotEmpty) {
        final data = args[0] as Map<String, dynamic>?;
        if (data != null) {
          _controller.add(RealtimeEvent(RealtimeEventType.levelUp, {
            'levelLabel': data['newLevel'] ?? '',
            'totalXP': data['newTotalXP'] ?? 0,
          }));
          
          HapticFeedback.mediumImpact();
        }
      }
    });

    // Badge Earned event
    _connection!.on('Badge Earned', (List<Object?>? args) {
      print('🎯 SignalR: Badge Earned event received: $args');
      if (args != null && args.isNotEmpty) {
        final data = args[0] as Map<String, dynamic>?;
        if (data != null) {
          print('🎯 SignalR: Badge data: $data');
          _controller.add(RealtimeEvent(RealtimeEventType.badgeEarned, {
            'badgeName': data['badgeName'] ?? '',
            'name': data['badgeName'] ?? '', // Alias for consistency
            'description': data['badgeDescription'] ?? data['description'] ?? 'Tebrikler! Yeni bir başarı kazandınız!',
            'imageUrl': data['badgeImageUrl'] ?? data['imageUrl'],
            'category': data['badgeCategory'] ?? data['category'],
            'rarity': data['rarity'],
            'rarityColor': data['rarityColor'],
            'xpEarned': data['xpEarned'] ?? 0,
          }));
          print('✅ SignalR: Badge earned event added to controller');
          HapticFeedback.mediumImpact(); // Changed from selectionClick for more impact
        } else {
          print('❌ SignalR: Badge data is null');
        }
      } else {
        print('❌ SignalR: Badge Earned args is null or empty');
      }
    });

    // Badge Earned event (alternative event name)
    _connection!.on('BadgeEarned', (List<Object?>? args) {
      print('🎯 SignalR: BadgeEarned event received: $args');
      if (args != null && args.isNotEmpty) {
        final data = args[0] as Map<String, dynamic>?;
        if (data != null) {
          print('🎯 SignalR: Badge data: $data');
          _controller.add(RealtimeEvent(RealtimeEventType.badgeEarned, {
            'badgeName': data['badgeName'] ?? '',
            'name': data['badgeName'] ?? '', // Alias for consistency
            'description': data['badgeDescription'] ?? data['description'] ?? 'Tebrikler! Yeni bir başarı kazandınız!',
            'imageUrl': data['badgeImageUrl'] ?? data['imageUrl'],
            'category': data['badgeCategory'] ?? data['category'],
            'rarity': data['rarity'],
            'rarityColor': data['rarityColor'],
            'xpEarned': data['xpEarned'] ?? 0,
          }));
          print('✅ SignalR: Badge earned event added to controller');
          HapticFeedback.mediumImpact();
        } else {
          print('❌ SignalR: Badge data is null');
        }
      } else {
        print('❌ SignalR: BadgeEarned args is null or empty');
      }
    });

    // Streak Updated event
    _connection!.on('Streak Updated', (List<Object?>? args) {
      if (args != null && args.isNotEmpty) {
        final data = args[0] as Map<String, dynamic>?;
        if (data != null) {
          final int current = (data['currentStreak'] ?? 0) is num ? (data['currentStreak'] as num).toInt() : 0;
          if (_lastNotifiedStreak == null) {
            _lastNotifiedStreak = current; // prime without toast on first event
            return;
          }
          if (current != _lastNotifiedStreak) {
            _lastNotifiedStreak = current;
            _controller.add(RealtimeEvent(RealtimeEventType.streakUpdated, {
              'currentStreak': current,
              'longestStreak': data['longestStreak'] ?? 0,
            }));
            HapticFeedback.selectionClick();
          }
        }
      }
    });

    // Alias: backend might emit lowercase name 'streakUpdated'
    _connection!.on('streakUpdated', (List<Object?>? args) {
      if (args != null && args.isNotEmpty) {
        final data = args[0] as Map<String, dynamic>?;
        if (data != null) {
          final int current = (data['currentStreak'] ?? 0) is num ? (data['currentStreak'] as num).toInt() : 0;
          if (_lastNotifiedStreak == null) {
            _lastNotifiedStreak = current; // prime without toast on first event
            return;
          }
          if (current != _lastNotifiedStreak) {
            _lastNotifiedStreak = current;
            _controller.add(RealtimeEvent(RealtimeEventType.streakUpdated, {
              'currentStreak': current,
              'longestStreak': data['longestStreak'] ?? 0,
            }));
            HapticFeedback.selectionClick();
          }
        }
      }
    });

    // Real-time progress update
    _connection!.on('Real Time Progress Update', (List<Object?>? args) {
      if (args != null && args.isNotEmpty) {
        final data = args[0] as Map<String, dynamic>?;
        if (data != null) {
          // Handle progress updates
          print('📊 Progress update: $data');
        }
      }
    });

    // Milestone completed
    _connection!.on('Milestone Completed', (List<Object?>? args) {
      if (args != null && args.isNotEmpty) {
        final data = args[0] as Map<String, dynamic>?;
        if (data != null) {
          _controller.add(RealtimeEvent(RealtimeEventType.badgeEarned, {
            'name': data['milestoneName'] ?? '',
            'message': data['message'] ?? '',
          }));
          
          HapticFeedback.mediumImpact();
        }
      }
    });

    // Connection state changes
    _connection!.onclose((error) {
      _isConnected = false;
      print('🔌 SignalR connection closed: $error');
      _scheduleReconnect();
    });
  }

  /// Ensure access token is valid; if not, attempt to refresh using refresh_token grant
  Future<void> _ensureValidToken() async {
    try {
      final valid = await _secureStorage.isTokenValid();
      if (valid) return;
      await _refreshToken();
    } catch (_) {}
  }

  /// Attempt to refresh tokens. Returns true if refreshed.
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;
      final resp = await _networkManager.post('/connect/token', data: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      });
      if (resp.statusCode == 200 && resp.data is Map) {
        final data = resp.data as Map;
        final accessToken = (data['access_token'] ?? data['accessToken'])?.toString();
        final newRefresh = (data['refresh_token'] ?? data['refreshToken'])?.toString();
        final expiresInRaw = data['expires_in'] ?? 3600;
        final expiresIn = expiresInRaw is int ? expiresInRaw : int.tryParse('$expiresInRaw') ?? 3600;
        if (accessToken != null && newRefresh != null) {
          await _secureStorage.saveTokens(accessToken: accessToken, refreshToken: newRefresh, expiresIn: expiresIn);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('❌ SignalR token refresh failed: $e');
      return false;
    }
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected && !_isConnecting) {
        print('🔄 Attempting to reconnect SignalR...');
        start();
      }
    });
  }

  /// Send test message to server
  Future<void> sendTestMessage(String message) async {
    if (_connection != null && _isConnected) {
      try {
        await _connection!.invoke('SendTestMessage', args: [message]);
      } catch (e) {
        print('❌ Failed to send test message: $e');
      }
    }
  }

  /// Dispose resources
  void dispose() {
    stop();
    _controller.close();
  }
}
