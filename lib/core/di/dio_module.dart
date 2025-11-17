import 'package:injectable/injectable.dart';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../utils/logger.dart';

@module
abstract class DioModule {
  @singleton
  Dio get dio {
    final dio = Dio();
    
    // Base URL ve timeout ayarları
    final baseUrl = AppConfig.apiBaseUrl;
    dio.options.baseUrl = baseUrl;
    dio.options.connectTimeout = AppConfig.connectionTimeout;
    dio.options.receiveTimeout = AppConfig.receiveTimeout;
    dio.options.sendTimeout = AppConfig.sendTimeout;
    
    // Logging: Dio instance oluşturulduğunda base URL'i logla
    Logger.network('DioModule initialized');
    Logger.network('Base URL: $baseUrl');
    Logger.network('Connection timeout: ${AppConfig.connectionTimeout.inSeconds}s');
    Logger.network('Receive timeout: ${AppConfig.receiveTimeout.inSeconds}s');
    Logger.network('Send timeout: ${AppConfig.sendTimeout.inSeconds}s');
    
    // Temel headers
    dio.options.headers = {
      // Content-Type istek bazlı belirlenecek (JSON vs multipart)
      'Accept': 'application/json',
    };
    
    // 4xx hataları error olarak işlensin
    dio.options.validateStatus = (status) {
      return status != null && status < 400;
    };
    
    return dio;
  }
}
