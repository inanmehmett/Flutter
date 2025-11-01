import 'dart:math';
import '../entities/vocabulary_word.dart';
import '../repositories/vocabulary_repository.dart';

/// Generated quiz answer option
class QuizAnswer {
  final String text;
  final bool isCorrect;

  const QuizAnswer({
    required this.text,
    required this.isCorrect,
  });
}

/// Service to generate quiz answer options
/// Uses multiple strategies to create realistic wrong answers
class QuizAnswerGenerator {
  final VocabularyRepository _repository;
  final Random _random = Random();

  QuizAnswerGenerator(this._repository);

  /// Generate quiz options for a word
  /// Returns a shuffled list of [QuizAnswer] with one correct and multiple wrong answers
  Future<List<QuizAnswer>> generateQuizOptions(
    VocabularyWord correctWord, {
    int wrongAnswerCount = 3,
  }) async {
    final wrongAnswers = await _generateWrongAnswers(
      correctWord,
      count: wrongAnswerCount,
    );

    // Create quiz answers list
    final options = <QuizAnswer>[
      QuizAnswer(text: correctWord.meaning, isCorrect: true),
      ...wrongAnswers.map((text) => QuizAnswer(text: text, isCorrect: false)),
    ];

    // Shuffle to randomize positions
    options.shuffle(_random);

    return options;
  }

  /// Generate wrong answers using multiple strategies
  Future<List<String>> _generateWrongAnswers(
    VocabularyWord correctWord, {
    required int count,
  }) async {
    final wrongAnswers = <String>[];

    // Strategy 1: Try to get similar words from backend (if available)
    try {
      final similarWords = await _getSimilarWords(correctWord, count: count);
      wrongAnswers.addAll(similarWords);
    } catch (_) {
      // Backend not available or failed, continue with fallback
    }

    // Strategy 2: Get random words from user's vocabulary
    if (wrongAnswers.length < count) {
      final randomWords = await _getRandomUserWords(
        correctWord,
        count: count - wrongAnswers.length,
      );
      wrongAnswers.addAll(randomWords);
    }

    // Strategy 3: Use common fallback words if still not enough
    if (wrongAnswers.length < count) {
      final fallbackWords = _getFallbackWords(
        correctWord,
        count: count - wrongAnswers.length,
      );
      wrongAnswers.addAll(fallbackWords);
    }

    // Ensure we have exactly the requested count
    return wrongAnswers.take(count).toList();
  }

  /// Get similar words from backend (Strategy 1)
  Future<List<String>> _getSimilarWords(
    VocabularyWord correctWord, {
    required int count,
  }) async {
    try {
      // TODO: Implement backend API for similar words
      // This would call something like:
      // final words = await _repository.getSimilarWords(correctWord.word, limit: count);
      
      // For now, return empty list - fallback to other strategies
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Get random words from user's vocabulary (Strategy 2)
  Future<List<String>> _getRandomUserWords(
    VocabularyWord correctWord, {
    required int count,
  }) async {
    try {
      // Fetch more words than needed to have options
      final allWords = await _repository.getUserWords(limit: 100);
      
      // Filter out the correct word
      final otherWords = allWords
          .where((w) => w.id != correctWord.id && w.meaning != correctWord.meaning)
          .toList();

      if (otherWords.isEmpty) {
        return [];
      }

      // Shuffle and take random words
      otherWords.shuffle(_random);
      
      return otherWords
          .take(count)
          .map((w) => w.meaning)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Get fallback words when other strategies fail (Strategy 3)
  List<String> _getFallbackWords(
    VocabularyWord correctWord, {
    required int count,
  }) {
    // Common English word meanings in Turkish
    // This is a last resort fallback
    final fallbackMeanings = <String>[
      'koşmak', 'yürümek', 'konuşmak', 'dinlemek', 'okumak',
      'yazmak', 'yemek', 'içmek', 'uyumak', 'düşünmek',
      'bilmek', 'görmek', 'duymak', 'hissetmek', 'anlamak',
      'sevmek', 'nefret etmek', 'istemek', 'ihtiyaç duymak', 'almak',
      'vermek', 'gelmek', 'gitmek', 'kalmak', 'çalışmak',
      'oynamak', 'öğrenmek', 'öğretmek', 'açıklamak', 'sormak',
      'cevaplamak', 'başlamak', 'bitirmek', 'devam etmek', 'durmak',
      'büyük', 'küçük', 'uzun', 'kısa', 'yüksek',
      'alçak', 'hızlı', 'yavaş', 'sıcak', 'soğuk',
      'iyi', 'kötü', 'güzel', 'çirkin', 'yeni',
      'eski', 'genç', 'yaşlı', 'zengin', 'fakir',
      'ev', 'araba', 'kitap', 'masa', 'sandalye',
      'kapı', 'pencere', 'duvar', 'tavan', 'zemin',
      'su', 'yiyecek', 'para', 'zaman', 'insan',
      'kadın', 'erkek', 'çocuk', 'aile', 'arkadaş',
    ];

    // Filter out the correct answer
    final filtered = fallbackMeanings
        .where((meaning) => meaning != correctWord.meaning)
        .toList();

    // Shuffle and take
    filtered.shuffle(_random);
    
    return filtered.take(count).toList();
  }

  /// Validate that all options are unique and correct answer is included
  bool validateOptions(List<QuizAnswer> options, String correctAnswer) {
    // Check if correct answer exists
    if (!options.any((opt) => opt.isCorrect && opt.text == correctAnswer)) {
      return false;
    }

    // Check for duplicates
    final texts = options.map((opt) => opt.text).toSet();
    if (texts.length != options.length) {
      return false;
    }

    // Check if only one correct answer exists
    final correctCount = options.where((opt) => opt.isCorrect).length;
    if (correctCount != 1) {
      return false;
    }

    return true;
  }
}

