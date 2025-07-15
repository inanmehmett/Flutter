import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/cache_interceptor.dart';
import 'interceptors/cors_interceptor.dart';

@singleton
class NetworkManager {
  final Dio _dio;
  final SecureStorageService _secureStorageService;

  NetworkManager(this._dio, this._secureStorageService) {
    final baseUrl = AppConfig.apiVersion.isNotEmpty
        ? '${AppConfig.apiBaseUrl}/${AppConfig.apiVersion}'
        : AppConfig.apiBaseUrl;
    
    // Base URL ayarla
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = AppConfig.connectionTimeout;
    _dio.options.receiveTimeout = AppConfig.receiveTimeout;
    _dio.options.sendTimeout = AppConfig.sendTimeout;
    
    // CORS headers ekle
    _dio.options.headers.addAll({
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization, X-Requested-With',
    });
    
    // CORS preflight request'leri için status validation
    _dio.options.validateStatus = (status) {
      return status != null && status < 500;
    };

    _dio.interceptors.addAll([
      CorsInterceptor(), // CORS interceptor'ı en başa ekle
      AuthInterceptor(_secureStorageService),
      LoggingInterceptor(),
      CacheInterceptor(),
    ]);
  }

  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  Future<Response> delete(String path, {dynamic data}) async {
    return await _dio.delete(path, data: data);
  }

  Future<Response> request(
    String path, {
    String method = 'GET',
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? cacheKey,
  }) async {
    switch (method.toUpperCase()) {
      case 'GET':
        return await get(path, queryParameters: queryParameters);
      case 'POST':
        return await post(path, data: data);
      case 'PUT':
        return await put(path, data: data);
      case 'DELETE':
        return await delete(path, data: data);
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
}

class RequestCancelledException implements Exception {}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
}
