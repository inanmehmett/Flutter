import 'package:injectable/injectable.dart';
import 'package:dio/dio.dart';
import '../config/app_config.dart';

@module
abstract class DioModule {
  @singleton
  Dio get dio {
    final dio = Dio();
    
    // Temel headers
    dio.options.headers = {
      // Content-Type istek bazlı belirlenecek (JSON vs multipart)
      'Accept': 'application/json',
    };
    
    // Base URL ve timeout ayarları
    dio.options.baseUrl = AppConfig.apiBaseUrl;
    dio.options.connectTimeout = AppConfig.connectionTimeout;
    dio.options.receiveTimeout = AppConfig.receiveTimeout;
    dio.options.sendTimeout = AppConfig.sendTimeout;
    
    // 4xx hataları error olarak işlensin
    dio.options.validateStatus = (status) {
      return status != null && status < 400;
    };
    
    return dio;
  }
}
