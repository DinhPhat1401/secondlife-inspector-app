class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final String? errorCode;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errorCode,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    final status = json['status'];
    final bool isSuccess = status == 'SUCCESS' ||
        status == 'success' ||
        json['success'] == true ||
        (json['code'] != null && json['code'] == 200) ||
        (status == null && json['data'] != null);

    final rawData = json.containsKey('data') ? json['data'] : json;

    return ApiResponse<T>(
      success: isSuccess,
      message: json['message'] as String?,
      data: rawData != null && fromJsonT != null ? fromJsonT(rawData) : rawData as T?,
      errorCode: json['errorCode']?.toString() ?? json['error']?.toString(),
    );
  }
}
