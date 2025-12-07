import 'package:injectable/injectable.dart';
import '../network/api_client.dart';
import '../utils/logger.dart';
import '../config/app_config.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import 'dart:async';

/// Comprehensive analytics service for tracking user behavior and app metrics
/// 
/// Features:
/// - User behavior tracking
/// - Screen navigation tracking
/// - Feature usage analytics
/// - Performance metrics
/// - Conversion funnel tracking
@lazySingleton
class AnalyticsService {
  final ApiClient _api;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  PackageInfo? _packageInfo;
  String? _userId;
  String? _sessionId;
  DateTime? _sessionStartTime;
  
  // Event batching to reduce API calls
  final List<Map<String, dynamic>> _eventQueue = [];
  static const int _maxBatchSize = 50;
  static const Duration _batchFlushInterval = Duration(seconds: 60); // Increased from 30s to 60s
  DateTime? _lastFlushTime;
  bool _isFlushing = false; // Prevent concurrent flush operations
  Timer? _flushTimer; // Timer for periodic flushing

  AnalyticsService(this._api) {
    _initPackageInfo();
    _startSession();
    _startBatchFlushTimer();
  }

  Future<void> _initPackageInfo() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
    } catch (e) {
      Logger.warning('Failed to get package info: $e');
    }
  }

  void _startSession() {
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _sessionStartTime = DateTime.now();
  }

  void _startBatchFlushTimer() {
    // Cancel existing timer if any
    _flushTimer?.cancel();
    
    // Flush events periodically
    // Note: Timer.periodic callback must be synchronous
    // We check the guard synchronously, then call the async function
    _flushTimer = Timer.periodic(_batchFlushInterval, (_) {
      // Synchronous guard check to prevent race conditions
      if (_eventQueue.isNotEmpty && !_isFlushing) {
        // Call async function without await - it will handle its own guard
        _flushEvents();
      }
    });
  }

  /// Cancel the flush timer (call during cleanup)
  void _cancelFlushTimer() {
    _flushTimer?.cancel();
    _flushTimer = null;
  }

  /// Set user identifier for analytics
  void setUserId(String? userId) {
    _userId = userId;
  }

  /// Track screen view
  Future<void> trackScreenView(String screenName, {Map<String, dynamic>? parameters}) async {
    await _trackEvent(
      eventType: 'screen_view',
      parameters: {
        'screen_name': screenName,
        ...?parameters,
      },
    );
  }

  /// Track user action
  Future<void> trackAction(String action, {Map<String, dynamic>? parameters}) async {
    await _trackEvent(
      eventType: 'user_action',
      parameters: {
        'action': action,
        ...?parameters,
      },
    );
  }

  /// Track feature usage
  Future<void> trackFeatureUsage(String featureName, {Map<String, dynamic>? parameters}) async {
    await _trackEvent(
      eventType: 'feature_usage',
      parameters: {
        'feature': featureName,
        ...?parameters,
      },
    );
  }

  /// Track conversion event (e.g., subscription, purchase)
  Future<void> trackConversion(String conversionType, {Map<String, dynamic>? parameters}) async {
    await _trackEvent(
      eventType: 'conversion',
      parameters: {
        'conversion_type': conversionType,
        ...?parameters,
      },
    );
  }

  /// Track performance metric
  Future<void> trackPerformance(String metricName, double value, {String? unit}) async {
    await _trackEvent(
      eventType: 'performance',
      parameters: {
        'metric': metricName,
        'value': value,
        if (unit != null) 'unit': unit,
      },
    );
  }

  /// Track error (non-fatal)
  Future<void> trackError(String errorType, String errorMessage, {Map<String, dynamic>? context}) async {
    final parameters = <String, dynamic>{
      'error_type': errorType,
      'error_message': errorMessage,
    };
    if (context != null) {
      parameters.addAll(context);
    }
    await _trackEvent(
      eventType: 'error',
      parameters: parameters,
    );
  }

  /// Internal method to track events
  Future<void> _trackEvent({
    required String eventType,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      // Get device info
      String? devicePlatform;
      String? deviceModel;
      String? osVersion;

      try {
        if (Platform.isAndroid) {
          devicePlatform = 'android';
          final androidInfo = await _deviceInfo.androidInfo;
          deviceModel = androidInfo.model;
          osVersion = 'Android ${androidInfo.version.release}';
        } else if (Platform.isIOS) {
          devicePlatform = 'ios';
          final iosInfo = await _deviceInfo.iosInfo;
          deviceModel = iosInfo.model;
          osVersion = 'iOS ${iosInfo.systemVersion}';
        }
      } catch (e) {
        // Ignore device info errors
      }

      final event = {
        'eventType': eventType,
        'occurredAt': DateTime.now().toUtc().toIso8601String(),
        'sessionId': _sessionId,
        if (_sessionStartTime != null)
          'sessionDuration': DateTime.now().difference(_sessionStartTime!).inSeconds,
        if (devicePlatform != null) 'devicePlatform': devicePlatform,
        if (_packageInfo != null) 'appVersion': _packageInfo!.version,
        if (deviceModel != null) 'deviceModel': deviceModel,
        if (osVersion != null) 'osVersion': osVersion,
        if (parameters != null && parameters.isNotEmpty) 'payload': parameters,
      };

      // Add to queue
      _eventQueue.add(event);

      // Flush if queue is full
      if (_eventQueue.length >= _maxBatchSize) {
        await _flushEvents();
      }
    } catch (e) {
      // Analytics must not break UX
      Logger.warning('Failed to track event: $e');
    }
  }

  /// Flush queued events to backend
  Future<void> _flushEvents() async {
    if (_eventQueue.isEmpty || _isFlushing) return;

    _isFlushing = true;
    try {
      final eventsToSend = List<Map<String, dynamic>>.from(_eventQueue);
      _eventQueue.clear();
      _lastFlushTime = DateTime.now();

      try {
        await _api.post('/api/events', data: {'events': eventsToSend});
        if (AppConfig.isDebug) {
          Logger.debug('Flushed ${eventsToSend.length} analytics events');
        }
      } catch (e) {
        // If flush fails, re-add events to queue (but limit queue size)
        // Check combined size: current queue + events being re-added
        if (_eventQueue.length + eventsToSend.length < _maxBatchSize * 2) {
          _eventQueue.insertAll(0, eventsToSend);
          Logger.warning('Failed to flush analytics events: $e');
        } else {
          // Queue would exceed limit - prioritize recent events over old ones
          // Drop oldest events from queue to make space for failed flush events
          final maxAllowed = _maxBatchSize * 2;
          final spaceAvailable = maxAllowed - _eventQueue.length;
          
          if (spaceAvailable <= 0) {
            // No space available - drop oldest events from queue to make room
            // Prioritize recent failed events over old queued events
            final eventsToDrop = eventsToSend.length;
            if (_eventQueue.length > eventsToDrop) {
              // Remove oldest events to make space
              _eventQueue.removeRange(_eventQueue.length - eventsToDrop, _eventQueue.length);
              _eventQueue.insertAll(0, eventsToSend);
              Logger.warning('Failed to flush analytics events: $e. Dropped $eventsToDrop oldest queued events to make room for failed flush events');
            } else {
              // Queue is smaller than failed events - replace entire queue with failed events
              final droppedOld = _eventQueue.length;
              _eventQueue.clear();
              _eventQueue.addAll(eventsToSend);
              Logger.warning('Failed to flush analytics events: $e. Replaced entire queue (dropped $droppedOld old events) with failed flush events');
            }
          } else {
            // Some space available - add as many as possible
            final eventsToReAdd = spaceAvailable < eventsToSend.length ? spaceAvailable : eventsToSend.length;
            _eventQueue.insertAll(0, eventsToSend.take(eventsToReAdd).toList());
            
            final droppedCount = eventsToSend.length - eventsToReAdd;
            if (droppedCount > 0) {
              Logger.warning('Failed to flush analytics events: $e. Dropped $droppedCount events due to queue limit');
            } else {
              Logger.warning('Failed to flush analytics events: $e');
            }
          }
        }
      }
    } finally {
      _isFlushing = false;
    }
  }

  /// Manually flush events (call before app closes)
  Future<void> flush() async {
    // Cancel timer before final flush
    _cancelFlushTimer();
    await _flushEvents();
  }

  /// End current session and start new one
  Future<void> endSession() async {
    await _flushEvents();
    _startSession();
  }
}

