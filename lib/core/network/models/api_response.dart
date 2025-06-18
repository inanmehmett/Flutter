class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ApiResponse.fromJson(
      Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJson) {
    return ApiResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: json['data'] != null
          ? fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJson) {
    return {
      'success': success,
      'message': message,
      'data': data != null ? toJson(data as T) : null,
    };
  }
}

class ApiDetailResponse<T> {
  final bool success;
  final String message;
  final T data;

  ApiDetailResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ApiDetailResponse.fromJson(
      Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJson) {
    return ApiDetailResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJson) {
    return {
      'success': success,
      'message': message,
      'data': toJson(data),
    };
  }
}
