import '../models/api_result_model.dart';
import '../api/api.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapRepository {
  Future<APIResultModel> getRouteCoordinates(LatLng l1, LatLng l2) {
    return API.getRouteCoordinates({
      'origin': '${l1.latitude},${l1.longitude}',
      'destination': '${l2.latitude},${l2.longitude}',
      'key': "AIzaSyDZF_oNL8olqMqAbgcjl6HU1vj2eEjx1Hw",
    });
  }
}
