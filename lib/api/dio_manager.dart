import 'package:dio/dio.dart';

class DioManager {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://maps.googleapis.com/maps/api',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
    validateStatus: (status) => status! < 500,
  ));

  static Future<Response?> get({
    required String path,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: parameters,
      );
      return response;
    } catch (e) {
      print('DioManager GET error: $e');
      return null;
    }
  }
}