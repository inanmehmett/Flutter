import 'package:dio/dio.dart';

class CacheInterceptor extends Interceptor {
  final Map<String, dynamic> _cache = {};

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    // Do not serve cached responses for authenticated requests
    final hasAuthorization =
        (options.headers['Authorization'] ?? '').toString().isNotEmpty;

    if (!hasAuthorization && options.method == 'GET' && _cache.containsKey(options.path)) {
      final cachedResponse = _cache[options.path];
      if (cachedResponse != null) {
        return handler.resolve(cachedResponse);
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Do not cache responses that were fetched with Authorization header
    final hasAuthorization = (response.requestOptions.headers['Authorization'] ?? '')
        .toString()
        .isNotEmpty;

    if (response.requestOptions.method == 'GET' && !hasAuthorization) {
      _cache[response.requestOptions.path] = response;
    }
    handler.next(response);
  }

  void clearCache() {
    _cache.clear();
  }
}
