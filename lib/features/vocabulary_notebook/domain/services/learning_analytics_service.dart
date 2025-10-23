import 'package:uuid/uuid.dart';
import '../entities/vocabulary_word.dart';
import '../entities/learning_activity.dart';

class LearningAnalyticsService {
  static const _uuid = Uuid();

  /// Kelime öğrenme aktivitesini kaydet ve progress'i güncelle
  static VocabularyWord recordLearningActivity({
    required VocabularyWord word,
    required LearningActivityType activityType,
    required LearningActivityResult result,
    required int responseTimeMs,
    String? context,
    Map<String, dynamic>? metadata,
  }) {
    final activity = LearningActivity(
      id: _uuid.v4(),
      wordId: word.id.toString(),
      type: activityType,
      result: result,
      completedAt: DateTime.now(),
      responseTimeMs: responseTimeMs,
      context: context,
      metadata: metadata,
    );

    // Yeni aktiviteyi ekle (son 10'u tut)
    final updatedActivities = [
      activity,
      ...word.recentActivities.take(9),
    ];

    // İstatistikleri güncelle
    final newReviewCount = word.reviewCount + 1;
    final newCorrectCount = result == LearningActivityResult.correct 
        ? word.correctCount + 1 
        : word.correctCount;

    // Ardışık doğru cevap sayısını güncelle
    final newConsecutiveCorrectCount = result == LearningActivityResult.correct
        ? word.consecutiveCorrectCount + 1
        : 0;

    // Zorluk seviyesini güncelle (SM-2 algoritması benzeri)
    final newDifficultyLevel = _calculateDifficultyLevel(
      word.difficultyLevel,
      result,
      responseTimeMs,
    );

    // Status'u otomatik güncelle
    final newStatus = _calculateNewStatus(
      word.status,
      newConsecutiveCorrectCount,
      newCorrectCount,
      newReviewCount,
    );

    // Bir sonraki review tarihini hesapla
    final nextReviewAt = _calculateNextReviewDate(
      newStatus,
      newConsecutiveCorrectCount,
      newDifficultyLevel,
    );

    return word.copyWith(
      status: newStatus,
      reviewCount: newReviewCount,
      correctCount: newCorrectCount,
      consecutiveCorrectCount: newConsecutiveCorrectCount,
      nextReviewAt: nextReviewAt,
      difficultyLevel: newDifficultyLevel,
      recentActivities: updatedActivities,
      lastReviewedAt: DateTime.now(),
    );
  }

  /// Zorluk seviyesini hesapla
  static double _calculateDifficultyLevel(
    double currentDifficulty,
    LearningActivityResult result,
    int responseTimeMs,
  ) {
    double quality = 0.0;
    
    switch (result) {
      case LearningActivityResult.correct:
        // Yanıt süresine göre kalite hesapla (daha hızlı = daha iyi)
        if (responseTimeMs < 2000) {
          quality = 1.0; // Mükemmel
        } else if (responseTimeMs < 5000) {
          quality = 0.8; // İyi
        } else {
          quality = 0.6; // Orta
        }
        break;
      case LearningActivityResult.incorrect:
        quality = 0.0; // Kötü
        break;
      case LearningActivityResult.skipped:
        quality = 0.3; // Çok kötü
        break;
    }

    // SM-2 benzeri algoritma
    final newDifficulty = currentDifficulty + 
        (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    
    return newDifficulty.clamp(0.0, 1.0);
  }

  /// Yeni status'u hesapla
  static VocabularyStatus _calculateNewStatus(
    VocabularyStatus currentStatus,
    int consecutiveCorrectCount,
    int totalCorrectCount,
    int totalReviewCount,
  ) {
    // Yeni → Öğreniyorum: İlk doğru cevap
    if (currentStatus == VocabularyStatus.new_ && consecutiveCorrectCount >= 1) {
      return VocabularyStatus.learning;
    }

    // Öğreniyorum → Biliyorum: 3 ardışık doğru veya %80+ doğruluk
    if (currentStatus == VocabularyStatus.learning) {
      if (consecutiveCorrectCount >= 3 || 
          (totalReviewCount >= 5 && (totalCorrectCount / totalReviewCount) >= 0.8)) {
        return VocabularyStatus.known;
      }
    }

    // Biliyorum → Uzman: 5 ardışık doğru veya %90+ doğruluk
    if (currentStatus == VocabularyStatus.known) {
      if (consecutiveCorrectCount >= 5 || 
          (totalReviewCount >= 10 && (totalCorrectCount / totalReviewCount) >= 0.9)) {
        return VocabularyStatus.mastered;
      }
    }

    // Geri düşme: 3 ardışık yanlış
    if (consecutiveCorrectCount == 0 && totalReviewCount >= 3) {
      final recentWrongCount = totalReviewCount - totalCorrectCount;
      if (recentWrongCount >= 3) {
        switch (currentStatus) {
          case VocabularyStatus.mastered:
            return VocabularyStatus.known;
          case VocabularyStatus.known:
            return VocabularyStatus.learning;
          case VocabularyStatus.learning:
            return VocabularyStatus.new_;
          case VocabularyStatus.new_:
            return VocabularyStatus.new_;
        }
      }
    }

    return currentStatus;
  }

  /// Bir sonraki review tarihini hesapla
  static DateTime _calculateNextReviewDate(
    VocabularyStatus status,
    int consecutiveCorrectCount,
    double difficultyLevel,
  ) {
    Duration interval;

    switch (status) {
      case VocabularyStatus.new_:
        interval = const Duration(hours: 1);
        break;
      case VocabularyStatus.learning:
        // Zorluk seviyesine göre interval ayarla
        interval = Duration(
          days: (consecutiveCorrectCount * (1 + difficultyLevel)).round().clamp(1, 3),
        );
        break;
      case VocabularyStatus.known:
        interval = Duration(
          days: (consecutiveCorrectCount * 2 * (1 + difficultyLevel)).round().clamp(3, 14),
        );
        break;
      case VocabularyStatus.mastered:
        interval = Duration(
          days: (consecutiveCorrectCount * 7 * (1 + difficultyLevel)).round().clamp(14, 90),
        );
        break;
    }

    return DateTime.now().add(interval);
  }

  /// Review için kelimeleri öncelik sırasına göre sırala
  static List<VocabularyWord> prioritizeWordsForReview(List<VocabularyWord> words) {
    return words.where((word) => word.needsReview).toList()
      ..sort((a, b) {
        // Önce overdue olanlar
        if (a.isOverdue && !b.isOverdue) return -1;
        if (!a.isOverdue && b.isOverdue) return 1;

        // Sonra zorluk seviyesine göre
        final difficultyDiff = b.difficultyLevel.compareTo(a.difficultyLevel);
        if (difficultyDiff != 0) return difficultyDiff;

        // Sonra status'a göre (yeni > öğreniyorum > biliyorum > uzman)
        final statusOrder = {
          VocabularyStatus.new_: 0,
          VocabularyStatus.learning: 1,
          VocabularyStatus.known: 2,
          VocabularyStatus.mastered: 3,
        };
        return statusOrder[a.status]!.compareTo(statusOrder[b.status]!);
      });
  }

  /// Günlük öğrenme hedefini hesapla
  static int calculateDailyGoal(List<VocabularyWord> words) {
    final reviewWords = words.where((w) => w.needsReview).length;
    final newWords = words.where((w) => w.status == VocabularyStatus.new_).length;
    
    // Review kelimelerinin %20'si + yeni kelimelerin %10'u
    return (reviewWords * 0.2 + newWords * 0.1).round().clamp(5, 50);
  }
}
