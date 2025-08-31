import 'package:injectable/injectable.dart';
import '../network/api_client.dart';

@lazySingleton
class EventService {
  final ApiClient _api;
  EventService(this._api);

  Future<void> sendEvents(List<Map<String, dynamic>> events) async {
    try {
      await _api.post('/api/events', data: { 'events': events });
    } catch (_) {
      // swallow errors; analytics must not break UX
    }
  }

  Future<void> readingStarted(int readingTextId) async {
    await sendEvents([
      {
        'eventType': 'reading_started',
        'occurredAt': DateTime.now().toUtc().toIso8601String(),
        'payload': { 'readingTextId': readingTextId }
      }
    ]);
  }

  Future<void> sentenceListened(int readingTextId, int sentenceIndex, int durationMs) async {
    await sendEvents([
      {
        'eventType': 'sentence_listened',
        'occurredAt': DateTime.now().toUtc().toIso8601String(),
        'payload': {
          'readingTextId': readingTextId,
          'sentenceIndex': sentenceIndex,
          'durationMs': durationMs,
        }
      }
    ]);
  }

  Future<void> readingCompleted(int readingTextId, {int? totalMs}) async {
    await sendEvents([
      {
        'eventType': 'reading_completed',
        'occurredAt': DateTime.now().toUtc().toIso8601String(),
        'payload': {
          'readingTextId': readingTextId,
          if (totalMs != null) 'totalMs': totalMs,
        }
      }
    ]);
  }

  Future<void> readingActive(int readingTextId, int seconds) async {
    await sendEvents([
      {
        'eventType': 'reading_active',
        'occurredAt': DateTime.now().toUtc().toIso8601String(),
        'payload': {
          'readingTextId': readingTextId,
          'durationMs': seconds * 1000,
        }
      }
    ]);
  }

  Future<void> quizCompleted(int readingTextId, {required int score, required double percentage, required bool passed}) async {
    await sendEvents([
      {
        'eventType': 'quiz_completed',
        'occurredAt': DateTime.now().toUtc().toIso8601String(),
        'payload': {
          'readingTextId': readingTextId,
          'score': score,
          'percentage': percentage,
          'passed': passed,
        }
      },
      if (passed)
        {
          'eventType': 'quiz_passed',
          'occurredAt': DateTime.now().toUtc().toIso8601String(),
          'payload': {
            'readingTextId': readingTextId,
            'score': score,
            'percentage': percentage,
          }
        },
    ]);
  }
}


