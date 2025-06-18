import 'package:equatable/equatable.dart';

class BookServiceError extends Equatable implements Exception {
  final String message;
  final BookServiceErrorType type;

  const BookServiceError({required this.type, required this.message});

  @override
  List<Object?> get props => [type, message];

  @override
  String toString() => 'BookServiceError: $message (Type: $type)';
}

enum BookServiceErrorType {
  networkError,
  decodingError,
  serverError,
  unauthorized,
  notFound,
  unknown
}

extension BookServiceErrorTypeExtension on BookServiceErrorType {
  String get message {
    switch (this) {
      case BookServiceErrorType.networkError:
        return 'Ağ hatası';
      case BookServiceErrorType.decodingError:
        return 'Veri işlenirken hata oluştu';
      case BookServiceErrorType.serverError:
        return 'Sunucu hatası';
      case BookServiceErrorType.unauthorized:
        return 'Yetkisiz erişim';
      case BookServiceErrorType.notFound:
        return 'Bulunamadı';
      case BookServiceErrorType.unknown:
        return 'Bilinmeyen hata';
    }
  }
}
