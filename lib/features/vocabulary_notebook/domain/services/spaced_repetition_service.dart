import 'dart:math' as math;
import '../entities/vocabulary_word.dart';
import '../entities/learning_activity.dart';
import 'learning_analytics_service.dart';
import 'review_session.dart';

class SpacedRepetitionService {
  /// Günlük review için kelimeleri al
  static List<VocabularyWord> getDailyReviewWords(List<VocabularyWord> allWords) {
    final reviewWords = allWords.where((word) => word.needsReview).toList();
    final prioritizedWords = LearningAnalyticsService.prioritizeWordsForReview(reviewWords);
    
    // Günlük hedef: 20 kelime (overdue varsa daha fazla)
    final overdueCount = prioritizedWords.where((w) => w.isOverdue).length;
    final dailyLimit = math.max(20, overdueCount + 10);
    
    return prioritizedWords.take(dailyLimit).toList();
  }

  /// Review session'ı başlat
  static ReviewSession startReviewSession(List<VocabularyWord> words) {
    // ✅ FIX: Aynı kelime tekrarını önle
    // Eğer listede aynı kelime birden fazla varsa, sadece birini al
    final uniqueWords = <int, VocabularyWord>{};
    for (final word in words) {
      uniqueWords[word.id] = word;
    }
    
    return ReviewSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      words: uniqueWords.values.toList(),
      startedAt: DateTime.now(),
    );
  }

  /// Review sonucunu işle
  static VocabularyWord processReviewResult({
    required VocabularyWord word,
    required bool isCorrect,
    required int responseTimeMs,
  }) {
    return LearningAnalyticsService.recordLearningActivity(
      word: word,
      activityType: LearningActivityType.quiz,
      result: isCorrect 
          ? LearningActivityResult.correct 
          : LearningActivityResult.incorrect,
      responseTimeMs: responseTimeMs,
      context: 'daily_review',
    );
  }

  /// Review istatistiklerini hesapla
  static ReviewStats calculateReviewStats(List<VocabularyWord> words) {
    final totalWords = words.length;
    final newWords = words.where((w) => w.status == VocabularyStatus.new_).length;
    final learningWords = words.where((w) => w.status == VocabularyStatus.learning).length;
    final knownWords = words.where((w) => w.status == VocabularyStatus.known).length;
    final masteredWords = words.where((w) => w.status == VocabularyStatus.mastered).length;
    
    final overdueWords = words.where((w) => w.isOverdue).length;
    final needsReviewWords = words.where((w) => w.needsReview).length;
    
    // Ortalama doğruluk oranı
    final totalAccuracy = words.fold<double>(0.0, (sum, word) => sum + word.accuracyRate);
    final averageAccuracy = totalWords > 0 ? totalAccuracy / totalWords : 0.0;
    
    // Tahmini review süresi (kelime başına 10 saniye)
    final estimatedMinutes = (totalWords * 10 / 60).round();
    
    return ReviewStats(
      totalWords: totalWords,
      newWords: newWords,
      learningWords: learningWords,
      knownWords: knownWords,
      masteredWords: masteredWords,
      overdueWords: overdueWords,
      needsReviewWords: needsReviewWords,
      averageAccuracy: averageAccuracy,
      estimatedMinutes: estimatedMinutes,
    );
  }

  /// Optimal review zamanını hesapla
  static DateTime calculateOptimalReviewTime(List<VocabularyWord> words) {
    if (words.isEmpty) return DateTime.now();
    
    // En erken review tarihini bul
    final nextReviews = words
        .where((w) => w.nextReviewAt != null)
        .map((w) => w.nextReviewAt!)
        .toList();
    
    if (nextReviews.isEmpty) return DateTime.now();
    
    nextReviews.sort();
    return nextReviews.first;
  }

  /// Review streak hesapla
  static int calculateReviewStreak(List<VocabularyWord> words) {
    final now = DateTime.now();
    int streak = 0;
    
    // Son 30 günde review yapılan günleri say
    for (int i = 0; i < 30; i++) {
      final checkDate = now.subtract(Duration(days: i));
      final hasReviewOnDate = words.any((word) => 
        word.lastReviewedAt != null &&
        word.lastReviewedAt!.year == checkDate.year &&
        word.lastReviewedAt!.month == checkDate.month &&
        word.lastReviewedAt!.day == checkDate.day
      );
      
      if (hasReviewOnDate) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }
}
