class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? dataDecoder,
  ) {
    return ApiResponse(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null && dataDecoder != null 
          ? dataDecoder(json['data']) 
          : null,
      message: json['message'] as String?,
    );
  }

  bool get hasError => !success;
}

class ErrorResponse {
  final bool success;
  final String error;
  final String? message;

  ErrorResponse({
    required this.success,
    required this.error,
    this.message,
  });

  factory ErrorResponse.fromJson(Map<String, dynamic> json) {
    return ErrorResponse(
      success: json['success'] as bool? ?? false,
      error: json['error'] as String? ?? 'Unknown error',
      message: json['message'] as String?,
    );
  }

  String get displayMessage => message ?? error;
}
