import '../../domain/entities/vocabulary_word.dart';
import '../../domain/entities/vocabulary_stats.dart';
import '../../domain/entities/learning_activity.dart';
import '../../domain/repositories/vocabulary_repository.dart';
import '../../domain/services/spaced_repetition_service.dart';
import '../../domain/services/review_session.dart';
import '../../domain/services/learning_analytics_service.dart';
import '../../../vocab/domain/services/vocab_learning_service.dart';
import '../../../vocab/domain/entities/user_word_entity.dart' as ue;
import '../../../../core/di/injection.dart';
import '../local/local_vocabulary_store.dart';

class VocabularyRepositoryImpl implements VocabularyRepository {
  final VocabLearningService _svc = getIt<VocabLearningService>();
  final LocalVocabularyStore _store = LocalVocabularyStore();

  int _stableId(String input) {
    // FNV-1a 64-bit (deterministic across runs/platforms)
    BigInt hash = BigInt.parse('1469598103934665603');
    final BigInt prime = BigInt.parse('1099511628211');
    final BigInt mask = BigInt.parse('18446744073709551615'); // 2^64-1
    for (int i = 0; i < input.length; i++) {
      hash = (hash ^ BigInt.from(input.codeUnitAt(i))) & mask;
      hash = (hash * prime) & mask;
    }
    // Keep it positive and within signed 63-bit range for Flutter widgets
    final BigInt signedMask = BigInt.parse('9223372036854775807'); // 2^63-1
    return (hash & signedMask).toInt();
  }

  VocabularyStatus _mapProgress(int p) {
    if (p <= 0) return VocabularyStatus.new_;
    if (p == 1) return VocabularyStatus.learning;
    return VocabularyStatus.known;
  }

  VocabularyWord _mapEntity(ue.UserWordEntity e) {
    final mapped = VocabularyWord(
      id: _stableId(e.id),
      word: e.word,
      meaning: e.meaningTr,
      personalNote: null,
      exampleSentence: e.example,
      status: _mapProgress(e.progress),
      readingTextId: null,
      addedAt: e.addedAt,
      lastReviewedAt: null,
      reviewCount: 0,
      correctCount: 0,
      consecutiveCorrectCount: 0,
      nextReviewAt: null,
      difficultyLevel: 0.5,
      recentActivities: const [],
    );
    return _store.mergeWithPersisted(mapped);
  }

  @override
  Future<List<VocabularyWord>> getUserWords({
    String? searchQuery,
    VocabularyStatus? status,
    int limit = 50,
    int offset = 0,
  }) async {
    final list = await _svc.listWords(query: searchQuery);
    var words = list.map(_mapEntity).toList();
    if (status != null) {
      words = words.where((w) => w.status == status).toList();
    }
    final int start = offset.clamp(0, words.length);
    final int end = (offset + limit).clamp(0, words.length);
    if (start >= end) {
      return <VocabularyWord>[];
    }
    return words.sublist(start, end);
  }

  @override
  Future<VocabularyWord?> getWordById(int id) async {
    final list = await _svc.listWords();
    final idx = list.indexWhere((x) => _stableId(x.id) == id);
    if (idx == -1) return null;
    return _mapEntity(list[idx]);
  }

  @override
  Future<VocabularyWord> addWord(VocabularyWord word) async {
    final existing = await _svc.listWords(query: word.word);
    final exists = existing.any((e) => e.word.toLowerCase().trim() == word.word.toLowerCase().trim());
    if (exists) {
      // Return existing mapped entity to keep UI consistent
      return _mapEntity(existing.first);
    }
    await _svc.addWord(word: word.word, meaningTr: word.meaning);
    final list = await _svc.listWords(query: word.word);
    final mapped = list.isNotEmpty ? _mapEntity(list.first) : word.copyWith(id: DateTime.now().millisecondsSinceEpoch);
    _store.upsertWord(mapped);
    return mapped;
  }

  @override
  Future<VocabularyWord> updateWord(VocabularyWord word) async {
    // Persist SRS fields locally and sync coarse progress to remote
    final p = switch (word.status) { VocabularyStatus.new_ => 0, VocabularyStatus.learning => 1, _ => 2 };
    final list = await _svc.listWords(query: word.word);
    if (list.isNotEmpty) {
      await _svc.updateProgress(list.first.id, p);
    }
    _store.upsertWord(word);
    return word;
  }

  @override
  Future<void> deleteWord(int id) async {
    final list = await _svc.listWords();
    final idx = list.indexWhere((x) => _stableId(x.id) == id);
    if (idx != -1) {
      await _svc.removeWord(list[idx].id);
    }
    // Remove from local store as well
    _store.removeWord(id);
  }

  @override
  Future<VocabularyStats> getUserStats() async {
    final list = await _svc.listWords();
    final words = list.map(_mapEntity).toList();
    final totalWords = words.length;
    final newWords = words.where((w) => w.status == VocabularyStatus.new_).length;
    final learningWords = words.where((w) => w.status == VocabularyStatus.learning).length;
    final knownWords = words.where((w) => w.status == VocabularyStatus.known).length;
    final masteredWords = words.where((w) => w.status == VocabularyStatus.mastered).length;
    final wordsNeedingReview = words.where((w) => w.needsReview).length;
    final totalAccuracy = words.fold<double>(0.0, (sum, w) => sum + w.accuracyRate);
    final averageAccuracy = totalWords > 0 ? totalAccuracy / totalWords : 0.0;
    final today = DateTime.now();
    final wordsAddedToday = words.where((w) => w.addedAt.year == today.year && w.addedAt.month == today.month && w.addedAt.day == today.day).length;
    final wordsReviewedToday = words.where((w) => w.lastReviewedAt != null && w.lastReviewedAt!.year == today.year && w.lastReviewedAt!.month == today.month && w.lastReviewedAt!.day == today.day).length;
    return VocabularyStats(
      totalWords: totalWords,
      newWords: newWords,
      learningWords: learningWords,
      knownWords: knownWords,
      masteredWords: masteredWords,
      wordsNeedingReview: wordsNeedingReview,
      averageAccuracy: averageAccuracy,
      wordsAddedToday: wordsAddedToday,
      wordsReviewedToday: wordsReviewedToday,
      streakDays: SpacedRepetitionService.calculateReviewStreak(words),
    );
  }

  @override
  Future<List<VocabularyWord>> searchWords(String query) async {
    final list = await _svc.listWords(query: query);
    return list.map(_mapEntity).toList();
  }

  @override
  Future<List<VocabularyWord>> getWordsForReview(int limit) async {
    // Use SRS-based due words instead of raw progress filter
    final list = await _svc.listWords();
    final all = list.map(_mapEntity).toList();
    final due = all.where((w) => w.needsReview).toList();
    final prioritized = LearningAnalyticsService.prioritizeWordsForReview(due);
    return prioritized.take(limit).toList();
  }

  @override
  Future<void> markWordReviewed(int wordId, bool isCorrect) async {
    final current = _store.getById(wordId);
    if (current == null) return;
    final updated = SpacedRepetitionService.processReviewResult(
      word: current,
      isCorrect: isCorrect,
      responseTimeMs: 3000,
    );
    await updateWord(updated);
  }

  @override
  Future<List<VocabularyWord>> addWordsFromText(String text, int readingTextId) async {
    return [];
  }

  @override
  Future<void> syncWords() async {
    return;
  }

  // Yeni öğrenme sistemi metodları
  @override
  Future<void> recordLearningActivity(LearningActivity activity) async {
    // Şimdilik boş implementasyon - gelecekte local storage'a kaydedilecek
    return;
  }

  @override
  Future<List<LearningActivity>> getWordActivities(int wordId, {int limit = 10}) async {
    // Şimdilik boş liste döndür - gelecekte local storage'dan alınacak
    return [];
  }

  @override
  Future<List<VocabularyWord>> getWordsNeedingReview({int limit = 20}) async {
    final list = await _svc.listWords();
    final words = list.map(_mapEntity).toList();
    
    // Review'e ihtiyacı olan kelimeleri filtrele
    final reviewWords = words.where((word) => word.needsReview).toList();
    
    // Limit uygula
    return reviewWords.take(limit).toList();
  }

  @override
  Future<List<VocabularyWord>> getOverdueWords({int limit = 10}) async {
    final list = await _svc.listWords();
    final words = list.map(_mapEntity).toList();
    
    // Geciken kelimeleri filtrele
    final overdueWords = words.where((word) => word.isOverdue).toList();
    
    // Limit uygula
    return overdueWords.take(limit).toList();
  }

  @override
  Future<Map<String, dynamic>> getLearningAnalytics() async {
    final list = await _svc.listWords();
    final words = list.map(_mapEntity).toList();
    
    final totalWords = words.length;
    final newWords = words.where((w) => w.status == VocabularyStatus.new_).length;
    final learningWords = words.where((w) => w.status == VocabularyStatus.learning).length;
    final knownWords = words.where((w) => w.status == VocabularyStatus.known).length;
    final masteredWords = words.where((w) => w.status == VocabularyStatus.mastered).length;
    
    final wordsNeedingReview = words.where((w) => w.needsReview).length;
    final overdueWords = words.where((w) => w.isOverdue).length;
    
    // Ortalama doğruluk oranı
    final totalAccuracy = words.fold<double>(0.0, (sum, word) => sum + word.accuracyRate);
    final averageAccuracy = totalWords > 0 ? totalAccuracy / totalWords : 0.0;
    
    // Bugün eklenen kelimeler
    final today = DateTime.now();
    final wordsAddedToday = words.where((w) => 
      w.addedAt.year == today.year && 
      w.addedAt.month == today.month && 
      w.addedAt.day == today.day
    ).length;
    
    final wordsReviewedToday = words.where((w) => w.lastReviewedAt != null && w.lastReviewedAt!.year == today.year && w.lastReviewedAt!.month == today.month && w.lastReviewedAt!.day == today.day).length;
    
    // Streak hesaplama (basit implementasyon)
    final streakDays = SpacedRepetitionService.calculateReviewStreak(words);
    
    return {
      'totalWords': totalWords,
      'newWords': newWords,
      'learningWords': learningWords,
      'knownWords': knownWords,
      'masteredWords': masteredWords,
      'wordsNeedingReview': wordsNeedingReview,
      'overdueWords': overdueWords,
      'averageAccuracy': averageAccuracy,
      'wordsAddedToday': wordsAddedToday,
      'wordsReviewedToday': wordsReviewedToday,
      'streakDays': streakDays,
      'learningProgress': totalWords > 0 ? (knownWords + masteredWords) / totalWords : 0.0,
      'difficultyDistribution': _calculateDifficultyDistribution(words),
    };
  }

  // Removed local added-at streak; use review-based streak from service

  Map<String, int> _calculateDifficultyDistribution(List<VocabularyWord> words) {
    final distribution = <String, int>{
      'easy': 0,
      'medium': 0,
      'hard': 0,
    };
    
    for (final word in words) {
      if (word.difficultyLevel < 0.3) {
        distribution['easy'] = distribution['easy']! + 1;
      } else if (word.difficultyLevel < 0.7) {
        distribution['medium'] = distribution['medium']! + 1;
      } else {
        distribution['hard'] = distribution['hard']! + 1;
      }
    }
    
    return distribution;
  }

  // Aralıklı tekrar sistemi metodları
  @override
  Future<List<VocabularyWord>> getDailyReviewWords() async {
    final list = await _svc.listWords();
    final words = list.map(_mapEntity).toList();
    return SpacedRepetitionService.getDailyReviewWords(words);
  }

  @override
  Future<ReviewStats> getReviewStats() async {
    final list = await _svc.listWords();
    final words = list.map(_mapEntity).toList();
    return SpacedRepetitionService.calculateReviewStats(words);
  }

  @override
  Future<ReviewSession> startReviewSession() async {
    final reviewWords = await getDailyReviewWords();
    return SpacedRepetitionService.startReviewSession(reviewWords);
  }

  @override
  Future<void> completeReviewSession(ReviewSession session) async {
    // Session tamamlandığında kelimeleri güncelle
    for (final result in session.results) {
      final word = session.words.firstWhere((w) => w.id.toString() == result.wordId);
      final updatedWord = SpacedRepetitionService.processReviewResult(
        word: word,
        isCorrect: result.isCorrect,
        responseTimeMs: result.responseTimeMs,
      );
      await updateWord(updatedWord);
    }
  }

  @override
  Future<DateTime> getNextReviewTime() async {
    final list = await _svc.listWords();
    final words = list.map(_mapEntity).toList();
    return SpacedRepetitionService.calculateOptimalReviewTime(words);
  }

  @override
  Future<int> getReviewStreak() async {
    final list = await _svc.listWords();
    final words = list.map(_mapEntity).toList();
    return SpacedRepetitionService.calculateReviewStreak(words);
  }
}
