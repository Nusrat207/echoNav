import 'package:dio/dio.dart';
import '../models/api_result_model.dart';
import 'dio_manager.dart';

class API {
  static const String baseUrl = 'maps.googleapis.com';
  static const String directionsPath = '/maps/api/directions/json';
  static const String geocodePath = '/maps/api/geocode/json';
  static const String placesPath = '/maps/api/place/autocomplete/json';

  static Future<APIResultModel> getRouteCoordinates(Map<String, dynamic> parameters) async {
    try {
      final response = await DioManager.get(
        path: directionsPath,
        parameters: parameters,
      );

      return APIResultModel.fromResponse(
        response: response,
        data: null,
      );
    } catch (e) {
      return APIResultModel(
        success: false,
        message: 'Failed to get route coordinates: $e',
        data: null,
      );
    }
  }

  static Future<APIResultModel> geocodeAddress(Map<String, dynamic> parameters) async {
    try {
      final response = await DioManager.get(
        path: geocodePath,
        parameters: parameters,
      );

      return APIResultModel.fromResponse(
        response: response,
        data: null,
      );
    } catch (e) {
      return APIResultModel(
        success: false,
        message: 'Failed to geocode address: $e',
        data: null,
      );
    }
  }
}