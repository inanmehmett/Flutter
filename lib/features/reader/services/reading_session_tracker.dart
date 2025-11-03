import 'dart:async';
import '../data/services/reading_session_service.dart';
import '../../../core/di/injection.dart';

/// Minimal reading session tracker
/// Tracks reading time with Stopwatch
/// Clean, simple, performant
class ReadingSessionTracker {
  final int bookId;
  final String bookTitle;
  final int startPage;
  
  int? _sessionId;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _syncTimer;
  int _lastSyncedSeconds = 0;
  int _wordsLearnedCount = 0;
  
  // Services
  late final ReadingSessionService _service;
  
  ReadingSessionTracker({
    required this.bookId,
    required this.bookTitle,
    this.startPage = 0,
  }) {
    _service = getIt<ReadingSessionService>();
  }

  /// Start tracking
  Future<void> start() async {
    _stopwatch.start();
    
    // Start session on backend
    _sessionId = await _service.startSession(
      bookId: bookId,
      bookTitle: bookTitle,
      startPage: startPage,
    );
    
    print('📖 Reading session started: $_sessionId');
  }

  /// Stop tracking and complete session
  Future<Map<String, dynamic>> complete(int endPage) async {
    _stopwatch.stop();
    _syncTimer?.cancel();
    
    final duration = _stopwatch.elapsed.inSeconds;
    
    final result = await _service.completeSession(
      sessionId: _sessionId ?? 0,
      endPage: endPage,
      durationSeconds: duration,
      wordsLearned: _wordsLearnedCount,
    );
    
    print('📖 Reading session completed: ${result['xpEarned']} XP');
    return result;
  }

  /// Pause tracking (optional, for future)
  void pause() => _stopwatch.stop();

  /// Resume tracking (optional, for future)
  void resume() => _stopwatch.start();

  /// Increment words learned counter
  void incrementWordsLearned() {
    _wordsLearnedCount++;
  }

  /// Get current elapsed time
  Duration get elapsed => _stopwatch.elapsed;
  
  /// Get elapsed seconds
  int get elapsedSeconds => _stopwatch.elapsed.inSeconds;
  
  /// Get elapsed minutes
  int get elapsedMinutes => (_stopwatch.elapsed.inSeconds / 60).floor();
  
  /// Format elapsed time as MM:SS
  String get formattedTime {
    final duration = _stopwatch.elapsed;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Dispose resources
  void dispose() {
    _stopwatch.stop();
    _syncTimer?.cancel();
  }
}

