import 'package:dio/dio.dart';

class CorsInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Sadece Accept ekle; Content-Type'ı istek türüne göre bırak (FormData vs JSON)
    options.headers['Accept'] = 'application/json';

    final isMultipart = options.data is FormData;
    final hasContentTypeHeader = options.headers.containsKey(Headers.contentTypeHeader);

    // Eğer multipart değilse ve Content-Type hiç ayarlanmamışsa JSON olarak belirle
    if (!isMultipart && options.contentType == null && !hasContentTypeHeader) {
      options.contentType = Headers.jsonContentType;
    }
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