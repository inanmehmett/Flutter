import 'package:dio/dio.dart';
import '../../domain/entities/reading_quiz_models.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/logger.dart';

class ReadingQuizService {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;

  ReadingQuizService(this._apiClient, this._secureStorage);

  /// Kitap için quiz başlatır
  Future<ReadingQuizStartResponse> startQuiz(int readingTextId) async {
    try {
      Logger.network('ReadingQuizService.startQuiz -> GET ${ApiEndpoints.readingQuiz}/start/$readingTextId');
      final response = await _apiClient.get(
        '${ApiEndpoints.readingQuiz}/start/$readingTextId',
      );
      Logger.network('ReadingQuizService.startQuiz <- ${response.statusCode} ${response.data}');
      return ReadingQuizStartResponse.fromJson(response.data);
    } on DioException catch (e) {
      Logger.error('ReadingQuizService.startQuiz DioException', e, e.stackTrace);
      if (e.response?.statusCode == 404) {
        return ReadingQuizStartResponse(
          success: false,
          message: e.response?.data['message'] ?? 'Quiz bulunamadı',
        );
      }
      throw Exception('Quiz başlatılamadı: ${e.message}');
    } catch (e, st) {
      Logger.error('ReadingQuizService.startQuiz Exception', e, st);
      throw Exception('Quiz başlatılamadı: $e');
    }
  }

  /// Quiz'i tamamlar
  Future<ReadingQuizCompleteResponse> completeQuiz(
      ReadingQuizCompleteRequest request) async {
    try {
      Logger.network('ReadingQuizService.completeQuiz -> POST ${ApiEndpoints.readingQuiz}/complete body=${request.toJson()}');
      final response = await _apiClient.post(
        '${ApiEndpoints.readingQuiz}/complete',
        data: request.toJson(),
      );
      Logger.network('ReadingQuizService.completeQuiz <- ${response.statusCode} ${response.data}');
      return ReadingQuizCompleteResponse.fromJson(response.data);
    } on DioException catch (e) {
      Logger.error('ReadingQuizService.completeQuiz DioException', e, e.stackTrace);
      if (e.response?.statusCode == 404) {
        return ReadingQuizCompleteResponse(
          success: false,
          message: e.response?.data['message'] ?? 'Quiz bulunamadı',
        );
      }
      throw Exception('Quiz tamamlanamadı: ${e.message}');
    } catch (e, st) {
      Logger.error('ReadingQuizService.completeQuiz Exception', e, st);
      throw Exception('Quiz tamamlanamadı: $e');
    }
  }

  /// Quiz sonucunu getirir
  Future<Map<String, dynamic>> getQuizResult(int resultId) async {
    try {
      Logger.network('ReadingQuizService.getQuizResult -> GET ${ApiEndpoints.readingQuiz}/result/$resultId');
      final response = await _apiClient.get(
        '${ApiEndpoints.readingQuiz}/result/$resultId',
      );
      Logger.network('ReadingQuizService.getQuizResult <- ${response.statusCode} ${response.data}');
      return response.data;
    } on DioException catch (e) {
      Logger.error('ReadingQuizService.getQuizResult DioException', e, e.stackTrace);
      throw Exception('Quiz sonucu getirilemedi: ${e.message}');
    } catch (e, st) {
      Logger.error('ReadingQuizService.getQuizResult Exception', e, st);
      throw Exception('Quiz sonucu getirilemedi: $e');
    }
  }

  /// Quiz geçmişini getirir
  Future<Map<String, dynamic>> getQuizHistory() async {
    try {
      Logger.network('ReadingQuizService.getQuizHistory -> GET ${ApiEndpoints.readingQuiz}/history');
      final response = await _apiClient.get(
        '${ApiEndpoints.readingQuiz}/history',
      );
      Logger.network('ReadingQuizService.getQuizHistory <- ${response.statusCode} ${response.data}');
      return response.data;
    } on DioException catch (e) {
      Logger.error('ReadingQuizService.getQuizHistory DioException', e, e.stackTrace);
      throw Exception('Quiz geçmişi getirilemedi: ${e.message}');
    } catch (e, st) {
      Logger.error('ReadingQuizService.getQuizHistory Exception', e, st);
      throw Exception('Quiz geçmişi getirilemedi: $e');
    }
  }

  /// Quiz istatistiklerini getirir
  Future<Map<String, dynamic>> getQuizStats() async {
    try {
      Logger.network('ReadingQuizService.getQuizStats -> GET ${ApiEndpoints.readingQuiz}/stats');
      final response = await _apiClient.get(
        '${ApiEndpoints.readingQuiz}/stats',
      );
      Logger.network('ReadingQuizService.getQuizStats <- ${response.statusCode} ${response.data}');
      return response.data;
    } on DioException catch (e) {
      Logger.error('ReadingQuizService.getQuizStats DioException', e, e.stackTrace);
      throw Exception('Quiz istatistikleri getirilemedi: ${e.message}');
    } catch (e, st) {
      Logger.error('ReadingQuizService.getQuizStats Exception', e, st);
      throw Exception('Quiz istatistikleri getirilemedi: $e');
    }
  }
}
