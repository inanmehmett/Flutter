import 'package:equatable/equatable.dart';

class NetworkError extends Equatable implements Exception {
  final String message;
  final NetworkErrorType type;
  final int? statusCode;

  const NetworkError({
    required this.type,
    required this.message,
    this.statusCode,
  });

  @override
  List<Object?> get props => [type, message, statusCode];

  @override
  String toString() => message;
}

enum NetworkErrorType {
  invalidUrl,
  requestFailed,
  invalidResponse,
  invalidData,
  decodingFailed,
  serverError,
  unauthorized,
  noInternetConnection,
  timeout,
  unknown,
  rateLimitExceeded,
  invalidContentType,
  cacheError,
  sslError,
  invalidToken,
  networkNotReachable,
  invalidParameter,
}

extension NetworkErrorTypeExtension on NetworkErrorType {
  String get message {
    switch (this) {
      case NetworkErrorType.invalidUrl:
        return 'Invalid URL';
      case NetworkErrorType.requestFailed:
        return 'Request failed';
      case NetworkErrorType.invalidResponse:
        return 'Invalid response from server';
      case NetworkErrorType.invalidData:
        return 'Invalid data received';
      case NetworkErrorType.decodingFailed:
        return 'Failed to decode data';
      case NetworkErrorType.serverError:
        return 'Server error';
      case NetworkErrorType.unauthorized:
        return 'Unauthorized access';
      case NetworkErrorType.noInternetConnection:
        return 'No internet connection';
      case NetworkErrorType.timeout:
        return 'Request timed out';
      case NetworkErrorType.unknown:
        return 'An unknown error occurred';
      case NetworkErrorType.rateLimitExceeded:
        return 'Rate limit exceeded. Please try again later.';
      case NetworkErrorType.invalidContentType:
        return 'Invalid content type received from server';
      case NetworkErrorType.cacheError:
        return 'Cache operation failed';
      case NetworkErrorType.sslError:
        return 'SSL/TLS handshake failed';
      case NetworkErrorType.invalidToken:
        return 'Invalid or expired authentication token';
      case NetworkErrorType.networkNotReachable:
        return 'Network is not reachable';
      case NetworkErrorType.invalidParameter:
        return 'Invalid parameter provided in the request';
    }
  }

  int get errorCode {
    switch (this) {
      case NetworkErrorType.invalidUrl:
        return 1001;
      case NetworkErrorType.requestFailed:
        return 1002;
      case NetworkErrorType.invalidResponse:
        return 1003;
      case NetworkErrorType.invalidData:
        return 1004;
      case NetworkErrorType.decodingFailed:
        return 1005;
      case NetworkErrorType.serverError:
        return 500;
      case NetworkErrorType.unauthorized:
        return 401;
      case NetworkErrorType.noInternetConnection:
        return 1007;
      case NetworkErrorType.timeout:
        return 1008;
      case NetworkErrorType.unknown:
        return 1009;
      case NetworkErrorType.rateLimitExceeded:
        return 429;
      case NetworkErrorType.invalidContentType:
        return 1011;
      case NetworkErrorType.cacheError:
        return 1012;
      case NetworkErrorType.sslError:
        return 1013;
      case NetworkErrorType.invalidToken:
        return 1014;
      case NetworkErrorType.networkNotReachable:
        return 1015;
      case NetworkErrorType.invalidParameter:
        return 1016;
    }
  }
}
