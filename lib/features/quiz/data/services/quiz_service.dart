import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/entities/quiz_models.dart';

class QuizService {
  final Dio _dio;

  QuizService(this._dio) {
    // Base URL'i global konfigürasyondan al
    _dio.options.baseUrl = AppConfig.apiBaseUrl;
    _dio.options.connectTimeout = AppConfig.connectionTimeout;
  }

  Future<List<QuizQuestion>> getQuestions({
    required int count,
    String? category,
    String? difficulty,
    int? readingTextId,
  }) async {
    try {
      String endpoint;
      Map<String, dynamic> queryParams = {};
      
      if (readingTextId != null) {
        // Reading quiz için özel endpoint
        endpoint = '/api/reading-quiz/start/$readingTextId';
      } else {
        // Genel quiz için (backend quiz)
        endpoint = '/api/quiz/random-quiz';
        queryParams = {
          'count': count,
          if (category != null) 'category': category,
          if (difficulty != null) 'difficulty': difficulty,
        };
      }

      final response = await _dio.get(endpoint, queryParameters: queryParams);

      if (response.statusCode == 200) {
        if (readingTextId != null) {
          // Reading quiz response formatı
          final List<dynamic> questionsData = response.data['data']['questions'];
          return questionsData.map((json) => QuizQuestion.fromReadingQuizJson(json)).toList();
        } else {
          // Genel quiz response formatı
          final List<dynamic> data = response.data['questions'];
          return data.map((json) => QuizQuestion.fromJson(json)).toList();
        }
      } else {
        throw Exception('Failed to load questions');
      }
    } catch (e) {
      throw Exception('Failed to load questions: $e');
    }
  }

  Future<AnswerResult> checkAnswer(
    QuizQuestion question,
    QuizOption selectedOption,
  ) async {
    try {
      // Reading quiz için answer checking
      final response = await _dio.post(
        '/api/reading-quiz/check-answer',
        data: {
          'questionId': question.id,
          'selectedOptionId': selectedOption.id,
        },
      );

      if (response.statusCode == 200) {
        return AnswerResult.fromJson(response.data);
      } else {
        throw Exception('Failed to check answer');
      }
    } catch (e) {
      throw Exception('Failed to check answer: $e');
    }
  }

  Future<AnswerResult> completeQuiz({
    required int readingTextId,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      final response = await _dio.post(
        '/api/reading-quiz/complete',
        data: {
          'readingTextId': readingTextId,
          'answers': answers,
        },
      );

      if (response.statusCode == 200) {
        return AnswerResult.fromJson(response.data);
      } else {
        throw Exception('Failed to complete quiz');
      }
    } catch (e) {
      throw Exception('Failed to complete quiz: $e');
    }
  }
}
