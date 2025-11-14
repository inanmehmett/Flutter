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
  final CacheInterceptor _cacheInterceptor = CacheInterceptor();

  NetworkManager(this._dio, this._secureStorageService) {
    final baseUrl = AppConfig.apiVersion.isNotEmpty
        ? '${AppConfig.apiBaseUrl}/${AppConfig.apiVersion}'
        : AppConfig.apiBaseUrl;
    
    // Base URL ayarla
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = AppConfig.connectionTimeout;
    _dio.options.receiveTimeout = AppConfig.receiveTimeout;
    _dio.options.sendTimeout = AppConfig.sendTimeout;
    
    // İstemci tarafında CORS header'ları gereksizdir, kaldırıldı
    _dio.options.headers.addAll({
      // İçerik tipi istek düzeyinde belirlenecek (JSON vs multipart)
      'Accept': 'application/json',
    });
    
    // 4xx hataları error olarak işlensin ki 401 durumunda refresh tetiklensin
    _dio.options.validateStatus = (status) {
      return status != null && status < 400;
    };

    _dio.interceptors.addAll([
      CorsInterceptor(), // Opsiyonel; istersen kaldırılabilir
      AuthInterceptor(_secureStorageService),
      LoggingInterceptor(),
      _cacheInterceptor,
    ]);
  }

  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options ?? Options(extra: {'dio': _dio}),
      );
    } catch (e) {
      // Offline mode - return cached data if available
      print('⚠️ Network error, attempting to use cached data: $e');
      rethrow;
    }
  }

  Future<Response> post(String path, {dynamic data, Options? options}) async {
    try {
      // Token endpoint'i x-www-form-urlencoded bekler
      if (path == '/connect/token') {
        return await _dio.post(
          path,
          data: data,
          options: Options(
            headers: {
              ..._dio.options.headers,
              'Content-Type': Headers.formUrlEncodedContentType,
            },
            contentType: Headers.formUrlEncodedContentType,
            extra: {'dio': _dio},
          ),
        );
      }
      final isMultipart = data is FormData;
      final effectiveOptions = (options ?? Options()).copyWith(
        contentType: isMultipart ? Headers.multipartFormDataContentType : null,
        extra: {
          ...(options?.extra ?? {}),
          'dio': _dio,
        },
        headers: {
          // Varsayılan 'Content-Type' başlığını ezme; Dio FormData için boundary ekleyecek
          ..._dio.options.headers,
          ...(options?.headers ?? {}),
        },
      );

      return await _dio.post(
        path,
        data: data,
        options: effectiveOptions,
      );
    } catch (e) {
      print('⚠️ Network error in POST: $e');
      rethrow;
    }
  }

  Future<Response> put(String path, {dynamic data, Options? options}) async {
    return await _dio.put(
      path,
      data: data,
      options: options ?? Options(extra: {'dio': _dio}),
    );
  }

  Future<Response> delete(String path, {dynamic data, Options? options}) async {
    return await _dio.delete(
      path,
      data: data,
      options: options ?? Options(extra: {'dio': _dio}),
    );
  }

  Future<Response> request(
    String path, {
    String method = 'GET',
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? cacheKey,
    Options? options,
  }) async {
    switch (method.toUpperCase()) {
      case 'GET':
        return await get(path, queryParameters: queryParameters, options: options);
      case 'POST':
        return await post(path, data: data, options: options);
      case 'PUT':
        return await put(path, data: data, options: options);
      case 'DELETE':
        return await delete(path, data: data, options: options);
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }

  // Expose a way to clear in-memory HTTP cache (e.g., on logout or user switch)
  void clearHttpCache() {
    _cacheInterceptor.clearCache();
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