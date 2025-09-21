import '../../domain/entities/vocabulary_word.dart';
import '../../domain/entities/vocabulary_stats.dart';
import '../../domain/repositories/vocabulary_repository.dart';

class VocabularyRepositoryImpl implements VocabularyRepository {
  // Geçici mock data
  final List<VocabularyWord> _mockWords = [
    VocabularyWord(
      id: 1,
      word: 'beautiful',
      meaning: 'güzel, hoş, şık',
      personalNote: 'Çok kullanılan bir kelime',
      exampleSentence: 'It\'s a beautiful day today.',
      status: VocabularyStatus.known,
      readingTextId: 1,
      addedAt: DateTime.now().subtract(const Duration(days: 2)),
      lastReviewedAt: DateTime.now().subtract(const Duration(days: 1)),
      reviewCount: 3,
      correctCount: 3,
    ),
    VocabularyWord(
      id: 2,
      word: 'magnificent',
      meaning: 'muhteşem, görkemli',
      personalNote: 'Daha resmi bir kelime',
      exampleSentence: 'The view from the mountain was magnificent.',
      status: VocabularyStatus.learning,
      readingTextId: 1,
      addedAt: DateTime.now().subtract(const Duration(days: 1)),
      lastReviewedAt: null,
      reviewCount: 1,
      correctCount: 1,
    ),
    VocabularyWord(
      id: 3,
      word: 'extraordinary',
      meaning: 'olağanüstü, sıra dışı',
      exampleSentence: 'She has an extraordinary talent for music.',
      status: VocabularyStatus.new_,
      readingTextId: 2,
      addedAt: DateTime.now(),
      lastReviewedAt: null,
      reviewCount: 0,
      correctCount: 0,
    ),
  ];

  @override
  Future<List<VocabularyWord>> getUserWords({
    String? searchQuery,
    VocabularyStatus? status,
    int limit = 50,
    int offset = 0,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    var words = List<VocabularyWord>.from(_mockWords);
    
    // Filter by search query
    if (searchQuery != null && searchQuery.isNotEmpty) {
      words = words.where((word) => 
        word.word.toLowerCase().contains(searchQuery.toLowerCase()) ||
        word.meaning.toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();
    }
    
    // Filter by status
    if (status != null) {
      words = words.where((word) => word.status == status).toList();
    }
    
    // Apply pagination
    final start = offset;
    final end = (offset + limit).clamp(0, words.length);
    
    return words.sublist(start, end);
  }

  @override
  Future<VocabularyWord?> getWordById(int id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _mockWords.firstWhere((word) => word.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<VocabularyWord> addWord(VocabularyWord word) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newWord = word.copyWith(
      id: _mockWords.length + 1,
      addedAt: DateTime.now(),
    );
    _mockWords.add(newWord);
    return newWord;
  }

  @override
  Future<VocabularyWord> updateWord(VocabularyWord word) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockWords.indexWhere((w) => w.id == word.id);
    if (index != -1) {
      _mockWords[index] = word;
      return word;
    }
    throw Exception('Word not found');
  }

  @override
  Future<void> deleteWord(int id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _mockWords.removeWhere((word) => word.id == id);
  }

  @override
  Future<VocabularyStats> getUserStats() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final totalWords = _mockWords.length;
    final newWords = _mockWords.where((w) => w.status == VocabularyStatus.new_).length;
    final learningWords = _mockWords.where((w) => w.status == VocabularyStatus.learning).length;
    final knownWords = _mockWords.where((w) => w.status == VocabularyStatus.known).length;
    final masteredWords = _mockWords.where((w) => w.status == VocabularyStatus.mastered).length;
    final wordsNeedingReview = _mockWords.where((w) => w.needsReview).length;
    
    final totalReviews = _mockWords.fold<int>(0, (sum, word) => sum + word.reviewCount);
    final totalCorrect = _mockWords.fold<int>(0, (sum, word) => sum + word.correctCount);
    final averageAccuracy = totalReviews > 0 ? totalCorrect / totalReviews : 0.0;
    
    final today = DateTime.now();
    final wordsAddedToday = _mockWords.where((w) => 
      w.addedAt.day == today.day && 
      w.addedAt.month == today.month && 
      w.addedAt.year == today.year
    ).length;
    
    final wordsReviewedToday = _mockWords.where((w) => 
      w.lastReviewedAt != null &&
      w.lastReviewedAt!.day == today.day && 
      w.lastReviewedAt!.month == today.month && 
      w.lastReviewedAt!.year == today.year
    ).length;
    
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
      streakDays: 7, // Mock value
    );
  }

  @override
  Future<List<VocabularyWord>> searchWords(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockWords.where((word) => 
      word.word.toLowerCase().contains(query.toLowerCase()) ||
      word.meaning.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  @override
  Future<List<VocabularyWord>> getWordsForReview(int limit) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockWords.where((word) => word.needsReview).take(limit).toList();
  }

  @override
  Future<void> markWordReviewed(int wordId, bool isCorrect) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockWords.indexWhere((w) => w.id == wordId);
    if (index != -1) {
      final word = _mockWords[index];
      _mockWords[index] = word.copyWith(
        reviewCount: word.reviewCount + 1,
        correctCount: isCorrect ? word.correctCount + 1 : word.correctCount,
        lastReviewedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<List<VocabularyWord>> addWordsFromText(String text, int readingTextId) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    // TODO: Implement text parsing and word extraction
    return [];
  }

  @override
  Future<void> syncWords() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    // TODO: Implement sync with backend
  }
}
