import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../api/api.dart';
import '../models/api_result_model.dart';

class MapRepository {
  final String apiKey;

  MapRepository({required this.apiKey});

  Future<List<LatLng>> getRoutePoints(LatLng origin, LatLng destination) async {
    try {
      final result = await API.getRouteCoordinates(
        origin: origin,
        destination: destination,
        apiKey: apiKey,
      );

      if (result.success && result.data != null) {
        final routes = result.data['routes'] as List;
        if (routes.isNotEmpty) {
          final points = _decodePolyline(
            routes[0]['overview_polyline']['points'] as String,
          );
          return points;
        }
      }
      return [];
    } catch (e) {
      print('Error getting route points: $e');
      return [];
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }
}