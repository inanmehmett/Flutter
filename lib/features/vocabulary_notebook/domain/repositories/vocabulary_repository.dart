import '../entities/vocabulary_word.dart';
import '../entities/vocabulary_stats.dart';

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
}
