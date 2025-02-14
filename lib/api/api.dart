import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dio_manager.dart';
import '../models/api_result_model.dart';

class API {
  static const String directionsPath = '/directions/json';
  static const String geocodePath = '/geocode/json';

  static Future<APIResultModel> getRouteCoordinates({
    required LatLng origin,
    required LatLng destination,
    required String apiKey,
  }) async {
    try {
      final response = await DioManager.get(
        path: directionsPath,
        parameters: {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          'mode': 'walking',
          'key': apiKey,
        },
      );

      if (response?.statusCode == 200) {
        return APIResultModel(
          success: true,
          message: 'Route fetched successfully',
          data: response?.data,
        );
      } else {
        return APIResultModel(
          success: false,
          message: 'Failed to fetch route',
          data: null,
        );
      }
    } catch (e) {
      return APIResultModel(
        success: false,
        message: 'Error: $e',
        data: null,
      );
    }
  }
}