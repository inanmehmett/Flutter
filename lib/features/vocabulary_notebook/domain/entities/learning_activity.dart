import 'package:equatable/equatable.dart';

enum LearningActivityType {
  quiz,
  flashcard,
  reading,
  manual,
}

enum LearningActivityResult {
  correct,
  incorrect,
  skipped,
}

class LearningActivity extends Equatable {
  final String id;
  final String wordId;
  final LearningActivityType type;
  final LearningActivityResult result;
  final DateTime completedAt;
  final int responseTimeMs; // Milisaniye cinsinden yanıt süresi
  final String? context; // Hangi context'te öğrenildi (kitap, quiz, vs.)
  final Map<String, dynamic>? metadata; // Ek bilgiler

  const LearningActivity({
    required this.id,
    required this.wordId,
    required this.type,
    required this.result,
    required this.completedAt,
    required this.responseTimeMs,
    this.context,
    this.metadata,
  });

  LearningActivity copyWith({
    String? id,
    String? wordId,
    LearningActivityType? type,
    LearningActivityResult? result,
    DateTime? completedAt,
    int? responseTimeMs,
    String? context,
    Map<String, dynamic>? metadata,
  }) {
    return LearningActivity(
      id: id ?? this.id,
      wordId: wordId ?? this.wordId,
      type: type ?? this.type,
      result: result ?? this.result,
      completedAt: completedAt ?? this.completedAt,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
      context: context ?? this.context,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        wordId,
        type,
        result,
        completedAt,
        responseTimeMs,
        context,
        metadata,
      ];
}

class LearningSession extends Equatable {
  final String id;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<LearningActivity> activities;
  final String sessionType; // 'daily_review', 'quiz', 'flashcard', etc.
  final Map<String, dynamic>? metadata;

  const LearningSession({
    required this.id,
    required this.startedAt,
    this.completedAt,
    required this.activities,
    required this.sessionType,
    this.metadata,
  });

  int get totalActivities => activities.length;
  int get correctAnswers => activities.where((a) => a.result == LearningActivityResult.correct).length;
  int get incorrectAnswers => activities.where((a) => a.result == LearningActivityResult.incorrect).length;
  double get accuracyRate => totalActivities > 0 ? correctAnswers / totalActivities : 0.0;
  Duration get duration => completedAt?.difference(startedAt) ?? Duration.zero;

  LearningSession copyWith({
    String? id,
    DateTime? startedAt,
    DateTime? completedAt,
    List<LearningActivity>? activities,
    String? sessionType,
    Map<String, dynamic>? metadata,
  }) {
    return LearningSession(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      activities: activities ?? this.activities,
      sessionType: sessionType ?? this.sessionType,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        startedAt,
        completedAt,
        activities,
        sessionType,
        metadata,
      ];
}
