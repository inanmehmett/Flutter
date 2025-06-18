import 'package:dio/dio.dart';

class CacheInterceptor extends Interceptor {
  final Map<String, dynamic> _cache = {};

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    if (options.method == 'GET' && _cache.containsKey(options.path)) {
      final cachedResponse = _cache[options.path];
      if (cachedResponse != null) {
        return handler.resolve(cachedResponse);
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.requestOptions.method == 'GET') {
      _cache[response.requestOptions.path] = response;
    }
    handler.next(response);
  }

  void clearCache() {
    _cache.clear();
  }
}
