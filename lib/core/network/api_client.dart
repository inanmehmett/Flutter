import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/cache_interceptor.dart';
import '../storage/secure_storage_service.dart';
import '../config/app_config.dart';

@singleton
class ApiClient {
  late final Dio _dio;

  ApiClient(SecureStorageService secureStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 3),
      ),
    );

    print('🟡[App START] ApiClient.baseURL = ${_dio.options.baseUrl}');

    _dio.interceptors.addAll([
      AuthInterceptor(secureStorage),
      LoggingInterceptor(),
      CacheInterceptor(),
    ]);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }
}
