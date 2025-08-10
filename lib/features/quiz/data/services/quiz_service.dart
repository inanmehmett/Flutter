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
  }) async {
    try {
      final response = await _dio.get(
        '/questions',
        queryParameters: {
          'count': count,
          if (category != null) 'category': category,
          if (difficulty != null) 'difficulty': difficulty,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['questions'];
        return data.map((json) => QuizQuestion.fromJson(json)).toList();
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
      final response = await _dio.post(
        '/check-answer',
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
}
