import 'package:daily_english/core/network/network_manager.dart';
import 'package:daily_english/core/cache/cache_manager.dart';

class Quiz {
  final String id;
  final String bookId;
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;

  Quiz({
    required this.id,
    required this.bookId,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      question: json['question'] as String,
      options: (json['options'] as List).map((e) => e as String).toList(),
      correctOptionIndex: json['correctOptionIndex'] as int,
      explanation: json['explanation'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'question': question,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'explanation': explanation,
    };
  }
}

class QuizService {
  final NetworkManager _networkManager;
  final CacheManager _cacheManager;

  QuizService({
    required NetworkManager networkManager,
    required CacheManager cacheManager,
  })  : _networkManager = networkManager,
        _cacheManager = cacheManager;

  Future<List<Quiz>> getQuizzesForBook(String bookId) async {
    final cacheKey = 'quizzes_$bookId';

    try {
      final cachedQuizzes = await _cacheManager.getData<List<Quiz>>(cacheKey);
      if (cachedQuizzes != null) {
        return cachedQuizzes;
      }

      final response = await _networkManager.get('/books/$bookId/quizzes');
      final quizzes = (response.data['data'] as List)
          .map((json) => Quiz.fromJson(json as Map<String, dynamic>))
          .toList();

      await _cacheManager.setData(cacheKey, quizzes);
      return quizzes;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> submitQuizAnswer({
    required String quizId,
    required int selectedOptionIndex,
  }) async {
    try {
      await _networkManager.post(
        '/quizzes/$quizId/answer',
        data: {'selectedOptionIndex': selectedOptionIndex},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getQuizResults(String bookId) async {
    final cacheKey = 'quiz_results_$bookId';

    try {
      final cachedResults =
          await _cacheManager.getData<Map<String, dynamic>>(cacheKey);
      if (cachedResults != null) {
        return cachedResults;
      }

      final response = await _networkManager.get('/books/$bookId/quiz-results');
      final results = response.data['data'] as Map<String, dynamic>;

      await _cacheManager.setData(cacheKey, results);
      return results;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resetQuizProgress(String bookId) async {
    try {
      await _networkManager.delete('/books/$bookId/quiz-progress');
      await _cacheManager.removeData('quiz_results_$bookId');
    } catch (e) {
      rethrow;
    }
  }
}
