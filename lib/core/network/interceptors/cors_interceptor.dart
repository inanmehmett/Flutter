import 'package:dio/dio.dart';

class CorsInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Sadece temel JSON header'ları ekle
    options.headers.addAll({
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    });
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
} 