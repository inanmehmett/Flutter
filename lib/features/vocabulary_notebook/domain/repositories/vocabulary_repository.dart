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

  // Tekrar sistemi
  Future<void> markWordReviewed(int wordId, bool isCorrect);

  // Aralıklı tekrar sistemi metodları
  Future<List<VocabularyWord>> getDailyReviewWords();

  Future<ReviewSession> startReviewSession({String? modeFilter});

  Future<List<VocabularyWord>> completeReviewSession(ReviewSession session);
}
