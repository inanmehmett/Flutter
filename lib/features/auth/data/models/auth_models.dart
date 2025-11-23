import 'package:json_annotation/json_annotation.dart';

part 'auth_models.g.dart';

@JsonSerializable()
class LoginRequest {
  final String userNameOrEmail;
  final String password;
  final bool rememberMe;

  LoginRequest({
    required this.userNameOrEmail,
    required this.password,
    required this.rememberMe,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class RegisterRequest {
  final String email;
  final String userName;
  final String password;
  final String confirmPassword;

  RegisterRequest({
    required this.email,
    required this.userName,
    required this.password,
    required this.confirmPassword,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}

@JsonSerializable()
class LoginResponse {
  final bool success;
  final String message;
  final String userId;
  final String userName;
  final String email;

  LoginResponse({
    required this.success,
    required this.message,
    required this.userId,
    required this.userName,
    required this.email,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}

@JsonSerializable()
class SimpleResponse {
  final bool success;
  final String? message;

  SimpleResponse({
    required this.success,
    this.message,
  });

  factory SimpleResponse.fromJson(Map<String, dynamic> json) =>
      _$SimpleResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SimpleResponseToJson(this);
}

enum AuthError {
  invalidCredentials,
  networkError,
  serverError,
  decodingError,
  unknown;

  String get localizedDescription {
    switch (this) {
      case AuthError.invalidCredentials:
        return "Kullanıcı adı veya şifre hatalı";
      case AuthError.networkError:
        return "Bağlantı hatası. Lütfen internet bağlantınızı kontrol edin";
      case AuthError.serverError:
        return "Sunucu hatası oluştu. Lütfen daha sonra tekrar deneyin";
      case AuthError.decodingError:
        return "Sunucu yanıtı işlenirken hata oluştu";
      case AuthError.unknown:
        return "Bilinmeyen bir hata oluştu";
    }
  }
}
