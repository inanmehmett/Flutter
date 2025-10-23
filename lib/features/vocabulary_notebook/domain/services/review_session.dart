import '../entities/vocabulary_word.dart';

class ReviewSession {
  final String id;
  final List<VocabularyWord> words;
  final DateTime startedAt;
  DateTime? completedAt;
  final List<ReviewResult> results = [];

  ReviewSession({
    required this.id,
    required this.words,
    required this.startedAt,
  });

  int get totalWords => words.length;
  int get completedWords => results.length;
  int get correctAnswers => results.where((r) => r.isCorrect).length;
  double get accuracyRate => completedWords > 0 ? correctAnswers / completedWords : 0.0;
  Duration get duration => completedAt?.difference(startedAt) ?? Duration.zero;

  void addResult(ReviewResult result) {
    results.add(result);
  }

  void complete() {
    completedAt = DateTime.now();
  }

  bool get isCompleted => completedAt != null;
}

class ReviewResult {
  final String wordId;
  final bool isCorrect;
  final int responseTimeMs;
  final DateTime completedAt;

  ReviewResult({
    required this.wordId,
    required this.isCorrect,
    required this.responseTimeMs,
    required this.completedAt,
  });
}

class ReviewStats {
  final int totalWords;
  final int newWords;
  final int learningWords;
  final int knownWords;
  final int masteredWords;
  final int overdueWords;
  final int needsReviewWords;
  final double averageAccuracy;
  final int estimatedMinutes;

  ReviewStats({
    required this.totalWords,
    required this.newWords,
    required this.learningWords,
    required this.knownWords,
    required this.masteredWords,
    required this.overdueWords,
    required this.needsReviewWords,
    required this.averageAccuracy,
    required this.estimatedMinutes,
  });

  double get learningProgress => totalWords > 0 ? (knownWords + masteredWords) / totalWords : 0.0;
  double get overdueRate => totalWords > 0 ? overdueWords / totalWords : 0.0;
}
