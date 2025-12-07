/// Example usage of AnalyticsService and CrashTrackingService
/// 
/// This file demonstrates how to use the analytics and crash tracking services
/// in your Flutter app. These are examples only - not meant to be imported.

// Example 1: Using AnalyticsMixin for automatic screen tracking
/*
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AnalyticsMixin {
  @override
  String get screenName => 'home'; // Automatically tracked on initState
  
  void _onStartReading() {
    // Track user action
    trackAction('start_reading', parameters: {
      'source': 'home_page',
    });
    
    // Track feature usage
    trackFeature('book_reader', parameters: {
      'book_id': '123',
    });
  }
}
*/

// Example 2: Manual AnalyticsService usage
/*
import 'package:injectable/injectable.dart';
import '../core/di/injection.dart';
import '../core/analytics/analytics_service.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final analytics = getIt<AnalyticsService>();
    
    return ElevatedButton(
      onPressed: () async {
        // Track screen view
        await analytics.trackScreenView('settings');
        
        // Track user action
        await analytics.trackAction('button_clicked', parameters: {
          'button': 'save_settings',
        });
        
        // Track feature usage
        await analytics.trackFeatureUsage('settings_save', parameters: {
          'theme': 'dark',
        });
      },
      child: Text('Save'),
    );
  }
}
*/

// Example 3: CrashTrackingService with breadcrumbs
/*
import '../core/di/injection.dart';
import '../core/services/crash_tracking_service.dart';

class BookReaderPage extends StatefulWidget {
  @override
  _BookReaderPageState createState() => _BookReaderPageState();
}

class _BookReaderPageState extends State<BookReaderPage> {
  late final CrashTrackingService _crashTracking;
  
  @override
  void initState() {
    super.initState();
    _crashTracking = getIt<CrashTrackingService>();
    
    // Add breadcrumbs for debugging
    _crashTracking.addBreadcrumb('Book reader page opened');
    _crashTracking.setCustomKey('current_screen', 'book_reader');
  }
  
  Future<void> _loadBook() async {
    _crashTracking.addBreadcrumb('Loading book started', data: {'book_id': '123'});
    
    try {
      // Load book logic
      _crashTracking.addBreadcrumb('Book loaded successfully');
    } catch (e, stackTrace) {
      // Record non-fatal error
      _crashTracking.recordNonFatalError(
        e.toString(),
        stackTrace: stackTrace,
        priority: 'medium',
        context: {
          'operation': 'load_book',
          'book_id': '123',
        },
      );
    }
  }
}
*/

// Example 4: Performance tracking
/*
final analytics = getIt<AnalyticsService>();

// Track API response time
final stopwatch = Stopwatch()..start();
final response = await api.get('/api/books');
stopwatch.stop();

analytics.trackPerformance('api_response_time', stopwatch.elapsedMilliseconds.toDouble(), unit: 'ms');
*/

// Example 5: Conversion tracking
/*
final analytics = getIt<AnalyticsService>();

// Track subscription purchase
await analytics.trackConversion('subscription_purchased', parameters: {
  'plan': 'premium_monthly',
  'price': 49.99,
  'currency': 'TRY',
});
*/

