import 'package:dio/dio.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('🌐 [LoggingInterceptor] ===== REQUEST START =====');
    print('🌐 [LoggingInterceptor] Method: ${options.method}');
    print('🌐 [LoggingInterceptor] URL: ${options.uri}');
    print('🌐 [LoggingInterceptor] Path: ${options.path}');
    print('🌐 [LoggingInterceptor] Base URL: ${options.baseUrl}');
    print('🌐 [LoggingInterceptor] Headers: ${options.headers}');
    print('🌐 [LoggingInterceptor] Data: ${options.data}');
    print(
        '🌐 [LoggingInterceptor] Query Parameters: ${options.queryParameters}');
    print('🌐 [LoggingInterceptor] Connect Timeout: ${options.connectTimeout}');
    print('🌐 [LoggingInterceptor] Receive Timeout: ${options.receiveTimeout}');
    print('🌐 [LoggingInterceptor] Send Timeout: ${options.sendTimeout}');
    print('🌐 [LoggingInterceptor] ===== REQUEST END =====');

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('🌐 [LoggingInterceptor] ===== RESPONSE START =====');
    print('🌐 [LoggingInterceptor] Status Code: ${response.statusCode}');
    print('🌐 [LoggingInterceptor] Status Message: ${response.statusMessage}');
    print('🌐 [LoggingInterceptor] URL: ${response.requestOptions.uri}');
    print('🌐 [LoggingInterceptor] Path: ${response.requestOptions.path}');
    print('🌐 [LoggingInterceptor] Method: ${response.requestOptions.method}');
    print('🌐 [LoggingInterceptor] Headers: ${response.headers}');
    print('🌐 [LoggingInterceptor] Data: ${response.data}');
    print('🌐 [LoggingInterceptor] Data Type: ${response.data.runtimeType}');
    print('🌐 [LoggingInterceptor] ===== RESPONSE END =====');

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('🌐 [LoggingInterceptor] ===== ERROR START =====');
    print('🌐 [LoggingInterceptor] Error Type: ${err.type}');
    print('🌐 [LoggingInterceptor] Error Message: ${err.message}');
    print('🌐 [LoggingInterceptor] Status Code: ${err.response?.statusCode}');
    print(
        '🌐 [LoggingInterceptor] Status Message: ${err.response?.statusMessage}');
    print('🌐 [LoggingInterceptor] URL: ${err.requestOptions.uri}');
    print('🌐 [LoggingInterceptor] Path: ${err.requestOptions.path}');
    print('🌐 [LoggingInterceptor] Method: ${err.requestOptions.method}');
    print(
        '🌐 [LoggingInterceptor] Request Headers: ${err.requestOptions.headers}');
    print('🌐 [LoggingInterceptor] Request Data: ${err.requestOptions.data}');
    print('🌐 [LoggingInterceptor] Response Headers: ${err.response?.headers}');
    print('🌐 [LoggingInterceptor] Response Data: ${err.response?.data}');
    print('🌐 [LoggingInterceptor] Error: ${err.error}');
    print('🌐 [LoggingInterceptor] Stack Trace: ${err.stackTrace}');
    print('🌐 [LoggingInterceptor] ===== ERROR END =====');

    super.onError(err, handler);
  }
}
