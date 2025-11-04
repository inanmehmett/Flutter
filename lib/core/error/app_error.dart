import 'package:dio/dio.dart';

/// Base class for all application errors
abstract class AppError implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppError(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

/// Network-related errors
class NetworkError extends AppError {
  NetworkError(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);

  factory NetworkError.noInternet() => NetworkError(
        'İnternet bağlantınızı kontrol edin',
        code: 'NO_INTERNET',
      );

  factory NetworkError.timeout() => NetworkError(
        'İstek zaman aşımına uğradı, lütfen tekrar deneyin',
        code: 'TIMEOUT',
      );

  factory NetworkError.serverError() => NetworkError(
        'Sunucu hatası, lütfen daha sonra tekrar deneyin',
        code: 'SERVER_ERROR',
      );
}

/// Authentication errors
class AuthError extends AppError {
  AuthError(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);

  factory AuthError.unauthorized() => AuthError(
        'Lütfen giriş yapın',
        code: 'UNAUTHORIZED',
      );

  factory AuthError.tokenExpired() => AuthError(
        'Oturum süreniz dolmuş, lütfen tekrar giriş yapın',
        code: 'TOKEN_EXPIRED',
      );

  factory AuthError.forbidden() => AuthError(
        'Bu işlem için yetkiniz yok',
        code: 'FORBIDDEN',
      );
}

/// Validation errors
class ValidationError extends AppError {
  final Map<String, List<String>>? fieldErrors;

  ValidationError(String message, {String? code, this.fieldErrors, dynamic originalError})
      : super(message, code: code, originalError: originalError);

  factory ValidationError.invalidInput() => ValidationError(
        'Lütfen girdiğiniz bilgileri kontrol edin',
        code: 'INVALID_INPUT',
      );

  factory ValidationError.missingRequired() => ValidationError(
        'Gerekli alanları doldurun',
        code: 'MISSING_REQUIRED',
      );
}

/// Resource not found errors
class NotFoundError extends AppError {
  NotFoundError(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);

  factory NotFoundError.resource(String resourceName) => NotFoundError(
        '$resourceName bulunamadı',
        code: 'NOT_FOUND',
      );

  factory NotFoundError.generic() => NotFoundError(
        'Aradığınız içerik bulunamadı',
        code: 'NOT_FOUND',
      );
}

/// Conflict errors (e.g., duplicate resources)
class ConflictError extends AppError {
  ConflictError(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);

  factory ConflictError.alreadyExists() => ConflictError(
        'Bu içerik zaten mevcut',
        code: 'ALREADY_EXISTS',
      );

  factory ConflictError.generic() => ConflictError(
        'Bu işlem şu anda yapılamıyor',
        code: 'CONFLICT',
      );
}

/// Business logic errors
class BusinessError extends AppError {
  BusinessError(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);

  factory BusinessError.quotaExceeded() => BusinessError(
        'Günlük limitinize ulaştınız',
        code: 'QUOTA_EXCEEDED',
      );

  factory BusinessError.ruleViolation(String rule) => BusinessError(
        rule,
        code: 'RULE_VIOLATION',
      );
}

/// Parse DioException to AppError
AppError parseError(dynamic error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkError.timeout();

      case DioExceptionType.connectionError:
        return NetworkError.noInternet();

      case DioExceptionType.badResponse:
        return _parseHttpError(error);

      default:
        return NetworkError('Bağlantı hatası', originalError: error);
    }
  }

  if (error is AppError) {
    return error;
  }

  return NetworkError('Bilinmeyen hata', originalError: error);
}

/// Parse HTTP response error
AppError _parseHttpError(DioException error) {
  final statusCode = error.response?.statusCode;
  final data = error.response?.data;

  // Try to extract message from response
  String message = 'Bir hata oluştu';
  String? errorCode;

  if (data is Map<String, dynamic>) {
    message = data['message'] ?? message;
    errorCode = data['errorCode'];
  }

  switch (statusCode) {
    case 400:
      return ValidationError(message, code: errorCode ?? 'VALIDATION_FAILED');
    case 401:
      return AuthError(message, code: errorCode ?? 'UNAUTHORIZED');
    case 403:
      return AuthError(message, code: errorCode ?? 'FORBIDDEN');
    case 404:
      return NotFoundError(message, code: errorCode ?? 'NOT_FOUND');
    case 409:
      return ConflictError(message, code: errorCode ?? 'CONFLICT');
    case 429:
      return BusinessError(message, code: errorCode ?? 'TOO_MANY_REQUESTS');
    case 500:
    case 502:
    case 503:
      return NetworkError.serverError();
    default:
      return NetworkError(message, code: errorCode, originalError: error);
  }
}

