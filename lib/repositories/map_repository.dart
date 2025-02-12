import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/api_result_model.dart';
import '../api/api.dart';

class MapRepository {
  final String apiKey;
  final String baseUrl = 'https://maps.googleapis.com/maps/api';

  MapRepository({required this.apiKey});

  Future<APIResultModel> getRouteCoordinates(LatLng origin, LatLng destination, {String mode = 'walking'}) async {
    try {
      final params = {
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'mode': mode,
        'alternatives': 'true',
        'key': apiKey,
      };

      return await API.getRouteCoordinates(params);
    } catch (e) {
      throw MapRepositoryException('Failed to get route coordinates: $e');
    }
  }

  Future<LatLng> geocodeAddress(String address) async {
    try {
      final encodedAddress = Uri.encodeComponent(address);
      final url = '$baseUrl/geocode/json?address=$encodedAddress&key=$apiKey';

      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] != 'OK') {
        throw MapRepositoryException('Geocoding failed: ${data['status']}');
      }

      final location = data['results'][0]['geometry']['location'];
      return LatLng(location['lat'], location['lng']);
    } catch (e) {
      throw MapRepositoryException('Geocoding failed: $e');
    }
  }

  Future<List<String>> getPlacePredictions(String input) async {
    try {
      final url = '$baseUrl/place/autocomplete/json?input=$input&key=$apiKey&types=address';

      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] != 'OK') {
        return [];
      }

      return (data['predictions'] as List)
          .map((prediction) => prediction['description'] as String)
          .toList();
    } catch (e) {
      print('Error getting place predictions: $e');
      return [];
    }
  }
}

class MapRepositoryException implements Exception {
  final String message;
  MapRepositoryException(this.message);

  @override
  String toString() => message;
}