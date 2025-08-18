import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/cache_interceptor.dart';
import '../storage/secure_storage_service.dart';
import '../config/app_config.dart';

@singleton
class ApiClient {
  late final Dio dio;

  ApiClient(SecureStorageService secureStorage) {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 3),
      ),
    );

    print('🟡[App START] ApiClient.baseURL = ${dio.options.baseUrl}');

    dio.interceptors.addAll([
      AuthInterceptor(secureStorage),
      LoggingInterceptor(),
      CacheInterceptor(),
    ]);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return dio.get(
      path,
      queryParameters: queryParameters,
      options: Options(extra: {'dio': this.dio}),
    );
  }

  Future<Response> post(String path, {dynamic data}) {
    return dio.post(
      path,
      data: data,
      options: Options(extra: {'dio': this.dio}),
    );
  }
}