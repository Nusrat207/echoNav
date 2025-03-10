

class APIResultModel {
  final bool success;
  final String message;
  final dynamic data;

  APIResultModel({
    required this.success,
    required this.message,
    this.data,
  });

  factory APIResultModel.fromJson(Map<String, dynamic> json) {
    return APIResultModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}