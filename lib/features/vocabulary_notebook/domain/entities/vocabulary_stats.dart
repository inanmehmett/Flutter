import 'package:equatable/equatable.dart';

class VocabularyStats extends Equatable {
  final int totalWords;
  final int newWords;
  final int learningWords;
  final int knownWords;
  final int masteredWords;
  final int wordsNeedingReview;
  final double averageAccuracy;
  final int wordsAddedToday;
  final int wordsReviewedToday;
  final int streakDays;

  const VocabularyStats({
    required this.totalWords,
    required this.newWords,
    required this.learningWords,
    required this.knownWords,
    required this.masteredWords,
    required this.wordsNeedingReview,
    required this.averageAccuracy,
    required this.wordsAddedToday,
    required this.wordsReviewedToday,
    required this.streakDays,
  });

  double get learningProgress {
    if (totalWords == 0) return 0.0;
    return (knownWords + masteredWords) / totalWords;
  }

  int get wordsInProgress => learningWords + knownWords;

  VocabularyStats copyWith({
    int? totalWords,
    int? newWords,
    int? learningWords,
    int? knownWords,
    int? masteredWords,
    int? wordsNeedingReview,
    double? averageAccuracy,
    int? wordsAddedToday,
    int? wordsReviewedToday,
    int? streakDays,
  }) {
    return VocabularyStats(
      totalWords: totalWords ?? this.totalWords,
      newWords: newWords ?? this.newWords,
      learningWords: learningWords ?? this.learningWords,
      knownWords: knownWords ?? this.knownWords,
      masteredWords: masteredWords ?? this.masteredWords,
      wordsNeedingReview: wordsNeedingReview ?? this.wordsNeedingReview,
      averageAccuracy: averageAccuracy ?? this.averageAccuracy,
      wordsAddedToday: wordsAddedToday ?? this.wordsAddedToday,
      wordsReviewedToday: wordsReviewedToday ?? this.wordsReviewedToday,
      streakDays: streakDays ?? this.streakDays,
    );
  }

  @override
  List<Object?> get props => [
        totalWords,
        newWords,
        learningWords,
        knownWords,
        masteredWords,
        wordsNeedingReview,
        averageAccuracy,
        wordsAddedToday,
        wordsReviewedToday,
        streakDays,
      ];
}
