import '../../domain/entities/vocabulary_word.dart';
import '../../domain/entities/vocabulary_stats.dart';
import '../../domain/repositories/vocabulary_repository.dart';
import '../../../vocab/domain/services/vocab_learning_service.dart';
import '../../../vocab/domain/entities/user_word_entity.dart' as ue;
import '../../../../core/di/injection.dart';

class VocabularyRepositoryImpl implements VocabularyRepository {
  final VocabLearningService _svc = getIt<VocabLearningService>();

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
    return VocabularyWord(
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
    );
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
    return list.isNotEmpty ? _mapEntity(list.first) : word.copyWith(id: DateTime.now().millisecondsSinceEpoch);
  }

  @override
  Future<VocabularyWord> updateWord(VocabularyWord word) async {
    final p = switch (word.status) { VocabularyStatus.new_ => 0, VocabularyStatus.learning => 1, _ => 2 };
    final list = await _svc.listWords(query: word.word);
    if (list.isNotEmpty) {
      await _svc.updateProgress(list.first.id, p);
    }
    return word;
  }

  @override
  Future<void> deleteWord(int id) async {
    final list = await _svc.listWords();
    final idx = list.indexWhere((x) => _stableId(x.id) == id);
    if (idx != -1) {
      await _svc.removeWord(list[idx].id);
    }
  }

  @override
  Future<VocabularyStats> getUserStats() async {
    final list = await _svc.listWords();
    final totalWords = list.length;
    final newWords = list.where((e) => e.progress == 0).length;
    final learningWords = list.where((e) => e.progress == 1).length;
    final knownWords = list.where((e) => e.progress >= 2).length;
    final masteredWords = 0;
    final wordsNeedingReview = learningWords;
    final averageAccuracy = 0.0;
    final today = DateTime.now();
    final wordsAddedToday = list.where((e) => e.addedAt.year == today.year && e.addedAt.month == today.month && e.addedAt.day == today.day).length;
    final wordsReviewedToday = 0;
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
      streakDays: 0,
    );
  }

  @override
  Future<List<VocabularyWord>> searchWords(String query) async {
    final list = await _svc.listWords(query: query);
    return list.map(_mapEntity).toList();
  }

  @override
  Future<List<VocabularyWord>> getWordsForReview(int limit) async {
    final list = await _svc.listWords(progress: 1);
    return list.take(limit).map(_mapEntity).toList();
  }

  @override
  Future<void> markWordReviewed(int wordId, bool isCorrect) async {
    return;
  }

  @override
  Future<List<VocabularyWord>> addWordsFromText(String text, int readingTextId) async {
    return [];
  }

  @override
  Future<void> syncWords() async {
    return;
  }
}
