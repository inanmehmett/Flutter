import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/entities/vocabulary_quiz_models.dart';

class VocabularyQuizService {
  final Dio _dio;

  VocabularyQuizService(this._dio) {
    _dio.options.baseUrl = AppConfig.apiBaseUrl;
    _dio.options.connectTimeout = AppConfig.connectionTimeout;
  }

  /// Get a random vocabulary quiz (10 questions)
  Future<List<VocabularyQuizQuestion>> getRandomQuiz() async {
    try {
      final response = await _dio.get('/api/quiz/random-quiz');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final List<dynamic> questionsData = data['data'];
          return questionsData
              .map((json) => VocabularyQuizQuestion.fromBackendJson(json))
              .toList();
        } else {
          throw VocabularyQuizException(data['message'] ?? 'Failed to load quiz');
        }
      } else {
        throw VocabularyQuizException('Failed to load quiz: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw VocabularyQuizException('Authentication required');
      } else if (e.response?.statusCode == 400) {
        // Backend'den gelen error mesajını göster (örn: "En az 40 kelime gereklidir")
        final errorData = e.response?.data;
        final message = errorData?['message'] ?? 'Quiz oluşturulamadı';
        throw VocabularyQuizException(message);
      } else if (e.response?.statusCode == 404) {
        throw VocabularyQuizException('Quiz not found');
      } else {
        throw VocabularyQuizException('Network error: ${e.message}');
      }
    } catch (e) {
      if (e is VocabularyQuizException) {
        rethrow;
      }
      throw VocabularyQuizException('Failed to load quiz: $e');
    }
  }

  /// Get a single random vocabulary question
  Future<VocabularyQuizQuestion> getRandomQuestion() async {
    try {
      final response = await _dio.get('/api/quiz/random-question');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return VocabularyQuizQuestion.fromBackendJson(data['data']);
        } else {
          throw VocabularyQuizException(data['message'] ?? 'Failed to load question');
        }
      } else {
        throw VocabularyQuizException('Failed to load question: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw VocabularyQuizException('Authentication required');
      } else if (e.response?.statusCode == 404) {
        throw VocabularyQuizException('Question not found');
      } else {
        throw VocabularyQuizException('Network error: ${e.message}');
      }
    } catch (e) {
      throw VocabularyQuizException('Failed to load question: $e');
    }
  }

  /// Get a specific question by ID
  Future<VocabularyQuizQuestion> getQuestionById(int id) async {
    try {
      final response = await _dio.get('/api/quiz/question/$id');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return VocabularyQuizQuestion.fromBackendJson(data['data']);
        } else {
          throw VocabularyQuizException(data['message'] ?? 'Failed to load question');
        }
      } else {
        throw VocabularyQuizException('Failed to load question: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw VocabularyQuizException('Authentication required');
      } else if (e.response?.statusCode == 404) {
        throw VocabularyQuizException('Question not found');
      } else {
        throw VocabularyQuizException('Network error: ${e.message}');
      }
    } catch (e) {
      throw VocabularyQuizException('Failed to load question: $e');
    }
  }

  /// Complete a vocabulary quiz and get results
  Future<VocabularyQuizResult> completeQuiz(VocabularyQuizCompletionRequest request) async {
    try {
      final response = await _dio.post(
        '/api/quiz/complete',
        data: request.toJson(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return VocabularyQuizResult.fromJson(data['data']);
        } else {
          throw VocabularyQuizException(data['message'] ?? 'Failed to complete quiz');
        }
      } else {
        throw VocabularyQuizException('Failed to complete quiz: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw VocabularyQuizException('Authentication required');
      } else if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        final errors = errorData?['errors'];
        if (errors != null) {
          final errorMessages = <String>[];
          errors.forEach((key, value) {
            if (value is List) {
              errorMessages.addAll(value.cast<String>());
            }
          });
          throw VocabularyQuizException('Validation error: ${errorMessages.join(', ')}');
        }
        throw VocabularyQuizException(errorData?['message'] ?? 'Invalid request');
      } else {
        throw VocabularyQuizException('Network error: ${e.message}');
      }
    } catch (e) {
      throw VocabularyQuizException('Failed to complete quiz: $e');
    }
  }

  /// Get quiz statistics for the current user
  Future<Map<String, dynamic>> getQuizStats() async {
    try {
      final response = await _dio.get('/api/quiz/stats');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw VocabularyQuizException(data['message'] ?? 'Failed to load stats');
        }
      } else {
        throw VocabularyQuizException('Failed to load stats: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw VocabularyQuizException('Authentication required');
      } else {
        throw VocabularyQuizException('Network error: ${e.message}');
      }
    } catch (e) {
      throw VocabularyQuizException('Failed to load stats: $e');
    }
  }

  /// Get quiz history for the current user
  Future<List<Map<String, dynamic>>> getQuizHistory() async {
    try {
      final response = await _dio.get('/api/quiz/history');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']['history']);
        } else {
          throw VocabularyQuizException(data['message'] ?? 'Failed to load history');
        }
      } else {
        throw VocabularyQuizException('Failed to load history: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw VocabularyQuizException('Authentication required');
      } else {
        throw VocabularyQuizException('Network error: ${e.message}');
      }
    } catch (e) {
      throw VocabularyQuizException('Failed to load history: $e');
    }
  }
}

/// Custom exception for vocabulary quiz operations
class VocabularyQuizException implements Exception {
  final String message;
  
  const VocabularyQuizException(this.message);
  
  @override
  String toString() => 'VocabularyQuizException: $message';
}
