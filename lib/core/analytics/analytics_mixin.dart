import 'package:flutter/material.dart';
import 'analytics_service.dart';
import '../di/injection.dart';

/// Mixin for automatic screen view tracking
/// 
/// Usage:
/// ```dart
/// class MyPage extends StatefulWidget {
///   @override
///   _MyPageState createState() => _MyPageState();
/// }
/// 
/// class _MyPageState extends State<MyPage> with AnalyticsMixin {
///   @override
///   String get screenName => 'my_page';
/// }
/// ```
mixin AnalyticsMixin<T extends StatefulWidget> on State<T> {
  AnalyticsService? _analytics;

  /// Screen name to track (must be overridden)
  String get screenName;

  @override
  void initState() {
    super.initState();
    _analytics = getIt<AnalyticsService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _analytics?.trackScreenView(screenName);
    });
  }

  /// Track user action
  void trackAction(String action, {Map<String, dynamic>? parameters}) {
    _analytics?.trackAction(action, parameters: parameters);
  }

  /// Track feature usage
  void trackFeature(String featureName, {Map<String, dynamic>? parameters}) {
    _analytics?.trackFeatureUsage(featureName, parameters: parameters);
  }

  /// Track conversion
  void trackConversion(String conversionType, {Map<String, dynamic>? parameters}) {
    _analytics?.trackConversion(conversionType, parameters: parameters);
  }
}

