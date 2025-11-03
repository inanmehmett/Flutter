import 'package:injectable/injectable.dart';
import '../../../../core/network/network_manager.dart';

/// Minimal reading session tracking service
/// Tracks reading time and completion for gamification
@singleton
class ReadingSessionService {
  final NetworkManager _networkManager;

  ReadingSessionService(this._networkManager);

  /// Start a reading session
  Future<int> startSession({
    required int bookId,
    required String bookTitle,
    int startPage = 0,
  }) async {
    try {
      final response = await _networkManager.post(
        '/api/ApiReadingSession/start',
        data: {
          'bookId': bookId,
          'bookTitle': bookTitle,
          'startPage': startPage,
        },
      );

      final data = response.data is Map<String, dynamic> 
          ? response.data as Map<String, dynamic> 
          : <String, dynamic>{};
      
      final payload = (data['data'] is Map<String, dynamic>) 
          ? data['data'] as Map<String, dynamic> 
          : <String, dynamic>{};

      return (payload['sessionId'] as num?)?.toInt() ?? 0;
    } catch (e) {
      print('⚠️ Failed to start reading session: $e');
      return 0; // Return 0 if fails (graceful degradation)
    }
  }

  /// Complete a reading session
  Future<Map<String, dynamic>> completeSession({
    required int sessionId,
    required int endPage,
    required int durationSeconds,
    int wordsLearned = 0,
  }) async {
    try {
      if (sessionId == 0) {
        // No session was started (offline mode or error)
        return {'xpEarned': 0, 'pagesRead': 0};
      }

      final response = await _networkManager.post(
        '/api/ApiReadingSession/$sessionId/complete',
        data: {
          'endPage': endPage,
          'durationSeconds': durationSeconds,
          'wordsLearned': wordsLearned,
        },
      );

      final root = response.data is Map<String, dynamic> 
          ? response.data as Map<String, dynamic> 
          : <String, dynamic>{};
      
      final data = (root['data'] is Map<String, dynamic>) 
          ? root['data'] as Map<String, dynamic> 
          : <String, dynamic>{};

      return {
        'pagesRead': (data['pagesRead'] as num?)?.toInt() ?? 0,
        'durationSeconds': (data['durationSeconds'] as num?)?.toInt() ?? durationSeconds,
        'wordsLearned': (data['wordsLearned'] as num?)?.toInt() ?? wordsLearned,
        'xpEarned': (data['xpEarned'] as num?)?.toInt() ?? 0,
      };
    } catch (e) {
      print('⚠️ Failed to complete reading session: $e');
      // Graceful degradation
      return {
        'xpEarned': 0,
        'pagesRead': endPage,
        'durationSeconds': durationSeconds,
        'wordsLearned': wordsLearned,
      };
    }
  }

  /// Get today's reading minutes
  Future<int> getTodayMinutes() async {
    try {
      final response = await _networkManager.get('/api/ApiReadingSession/today');
      
      final root = response.data is Map<String, dynamic> 
          ? response.data as Map<String, dynamic> 
          : <String, dynamic>{};
      
      final data = (root['data'] is Map<String, dynamic>) 
          ? root['data'] as Map<String, dynamic> 
          : <String, dynamic>{};

      return (data['todayMinutes'] as num?)?.toInt() ?? 0;
    } catch (e) {
      print('⚠️ Failed to get today\'s reading minutes: $e');
      return 0;
    }
  }
}

