import '../entities/vocabulary_word.dart';
import '../entities/vocabulary_stats.dart';
import '../entities/learning_activity.dart';
import '../services/review_session.dart';

abstract class VocabularyRepository {
  // Kelime işlemleri
  Future<List<VocabularyWord>> getUserWords({
    String? searchQuery,
    VocabularyStatus? status,
    int limit = 50,
    int offset = 0,
  });

  Future<VocabularyWord?> getWordById(int id);
  
  Future<VocabularyWord> addWord(VocabularyWord word);
  
  Future<VocabularyWord> updateWord(VocabularyWord word);
  
  Future<void> deleteWord(int id);

  // İstatistikler
  Future<VocabularyStats> getUserStats();

  // Arama
  Future<List<VocabularyWord>> searchWords(String query);

  // Tekrar sistemi
  Future<List<VocabularyWord>> getWordsForReview(int limit);
  
  Future<void> markWordReviewed(int wordId, bool isCorrect);

  // Toplu işlemler
  Future<List<VocabularyWord>> addWordsFromText(
    String text, 
    int readingTextId,
  );

  // Senkronizasyon
  Future<void> syncWords();

  // Yeni öğrenme sistemi metodları
  Future<void> recordLearningActivity(LearningActivity activity);
  
  Future<List<LearningActivity>> getWordActivities(int wordId, {int limit = 10});
  
  Future<List<VocabularyWord>> getWordsNeedingReview({int limit = 20});
  
  Future<List<VocabularyWord>> getOverdueWords({int limit = 10});
  
  Future<Map<String, dynamic>> getLearningAnalytics();

  // Aralıklı tekrar sistemi metodları
  Future<List<VocabularyWord>> getDailyReviewWords();
  
  Future<ReviewStats> getReviewStats();
  
  Future<ReviewSession> startReviewSession();
  
  Future<void> completeReviewSession(ReviewSession session);
  
  Future<DateTime> getNextReviewTime();
  
  Future<int> getReviewStreak();
}
