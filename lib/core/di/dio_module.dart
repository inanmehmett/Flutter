import 'package:injectable/injectable.dart';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../network/interceptors/cors_interceptor.dart';

@module
abstract class DioModule {
  @singleton
  Dio get dio {
    final dio = Dio();
    
    // CORS ve HTTP Headers konfigürasyonu
    dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization, X-Requested-With',
    };
    
    // Base URL ve timeout ayarları
    dio.options.baseUrl = AppConfig.apiBaseUrl;
    dio.options.connectTimeout = AppConfig.connectionTimeout;
    dio.options.receiveTimeout = AppConfig.receiveTimeout;
    dio.options.sendTimeout = AppConfig.sendTimeout;
    
    // CORS preflight request'leri için OPTIONS method'u handle et
    dio.options.validateStatus = (status) {
      return status != null && status < 500;
    };
    
    // Interceptors ekle
    dio.interceptors.addAll([
      CorsInterceptor(), // CORS interceptor'ı en başa ekle
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: true,
        error: true,
      ),
    ]);
    
    return dio;
  }
}
