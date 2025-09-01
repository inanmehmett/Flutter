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
  
  SignalRService(this._networkManager, this._secureStorage);

  Stream<RealtimeEvent> get events => _controller.stream;
  bool get isConnected => _isConnected;

  /// Initialize and start SignalR connection
  Future<void> start() async {
    if (_isConnecting || _isConnected) return;
    
    _isConnecting = true;
    
    try {
      // Get authentication token
      final token = await _secureStorage.getToken();
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
            options: HttpConnectionOptions(
              accessTokenFactory: () async => token,
              headers: {
                'Authorization': 'Bearer $token',
              },
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
      if (args != null && args.isNotEmpty) {
        final data = args[0] as Map<String, dynamic>?;
        if (data != null) {
          _controller.add(RealtimeEvent(RealtimeEventType.badgeEarned, {
            'name': data['badgeName'] ?? '',
            'imageUrl': data['imageUrl'],
          }));
          
          HapticFeedback.selectionClick();
        }
      }
    });

    // Streak Updated event
    _connection!.on('Streak Updated', (List<Object?>? args) {
      if (args != null && args.isNotEmpty) {
        final data = args[0] as Map<String, dynamic>?;
        if (data != null) {
          _controller.add(RealtimeEvent(RealtimeEventType.streakUpdated, {
            'currentStreak': data['currentStreak'] ?? 0,
            'longestStreak': data['longestStreak'] ?? 0,
          }));
          
          HapticFeedback.selectionClick();
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
