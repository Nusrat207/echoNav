import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import '../repositories/map_repository.dart';



class SmartNavigationService {
  final FlutterTts flutterTts = FlutterTts();
  final MapRepository mapRepository;
  late CameraController cameraController;
  StreamSubscription<Position>? _positionStream;
  List<LatLng> _routePoints = [];
  int _currentRouteIndex = 0;
  bool _isNavigating = false;
  Timer? _surroundingsTimer;
  final String visionServerUrl = 'http://your-python-server/api/ask';

  SmartNavigationService({required this.mapRepository}) {
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _initializeTTS();
    await _initializeCamera();
    await _requestLocationPermissions();
  }

  Future<void> _initializeTTS() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      cameraController = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await cameraController.initialize();
    } catch (e) {
      throw Exception('Failed to initialize camera: $e');
    }
  }

  Future<void> _requestLocationPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
  }

  void _startLocationTracking() {
    _positionStream?.cancel(); // Cancel any existing stream

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5, // Update every 5 meters
      ),
    ).listen((Position position) {
      _handleLocationUpdate(position);
    });
  }


  Future<bool> isIndoors() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      // Check multiple factors to determine if indoors
      bool likelyIndoors = position.accuracy > 20 || // Poor GPS accuracy
          !position.isMocked && position.speed < 0.2; // Very low speed

      if (likelyIndoors) {
        await speakMessage("You appear to be indoors. Please move outside for better navigation accuracy.");
        return true;
      }
      return false;
    } catch (e) {
      await speakMessage("Unable to determine if you're indoors. Please ensure you're outside for the best experience.");
      return true;
    }
  }


  Future<void> startNavigation(String destination) async {
    try {
      if (await isIndoors()) return;

      final position = await Geolocator.getCurrentPosition();
      final currentLatLng = LatLng(position.latitude, position.longitude);

      // Get route from Google Maps
      final result = await mapRepository.getRouteCoordinates(
        currentLatLng,
        await _geocodeAddress(destination),
      );

      if (!result.success) {
        throw Exception('Failed to get route: ${result.message}');
      }

      _routePoints = _decodePolyline(result.data['routes'][0]['overview_polyline']['points']);
      _currentRouteIndex = 0;
      _isNavigating = true;

      // Start continuous monitoring
      _startLocationTracking();
      _startSurroundingsMonitoring();

      // Provide initial directions
      await _provideNextDirection();
    } catch (e) {
      await speakMessage("I couldn't start the navigation. Please try again.");
      print('Navigation error: $e');
    }
  }

  void _startSurroundingsMonitoring() {
    _surroundingsTimer?.cancel();
    _surroundingsTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _analyzeSurroundings();
    });
  }

  Future<void> _analyzeSurroundings() async {
    if (!_isNavigating) return;

    try {
      XFile image = await cameraController.takePicture();
      List<int> imageBytes = await image.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // Send to Python vision server
      final response = await http.post(
        Uri.parse(visionServerUrl),
        body: {
          'prompt': 'What obstacles are in front of me?',
          'image': base64Image,
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> result = json.decode(response.body);
        String description = result['response'];

        // Only speak if there's a significant obstacle
        if (description.toLowerCase().contains('obstacle') ||
            description.toLowerCase().contains('careful') ||
            description.toLowerCase().contains('warning')) {
          await speakMessage(description);
        }
      }
    } catch (e) {
      print('Error analyzing surroundings: $e');
    }
  }

  Future<void> _handleLocationUpdate(Position position) async {
    if (!_isNavigating) return;

    final LatLng currentLatLng = LatLng(position.latitude, position.longitude);

    // Check if we've reached the next waypoint
    if (_currentRouteIndex < _routePoints.length - 1) {
      double distanceToNext = await _calculateDistance(
        currentLatLng,
        _routePoints[_currentRouteIndex + 1],
      );

      if (distanceToNext < 10) { // Within 10 meters
        _currentRouteIndex++;
        await _provideNextDirection();
      }
    } else {
      // Reached destination
      await speakMessage("You have reached your destination!");
      stopNavigation();
    }
  }

  Future<double> _calculateDistance(LatLng point1, LatLng point2) async {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  Future<void> _provideNextDirection() async {
    if (_currentRouteIndex >= _routePoints.length - 1) {
      await speakMessage("You have reached your destination!");
      stopNavigation();
      return;
    }

    final currentPoint = _routePoints[_currentRouteIndex];
    final nextPoint = _routePoints[_currentRouteIndex + 1];

    double bearing = _calculateBearing(currentPoint, nextPoint);
    double distance = await _calculateDistance(currentPoint, nextPoint);

    String direction = _getDirectionInstruction(bearing, distance);
    await speakMessage(direction);
  }

  double _calculateBearing(LatLng start, LatLng end) {
    double lat1 = start.latitude * (pi / 180);
    double lat2 = end.latitude * (pi / 180);
    double long1 = start.longitude * (pi / 180);
    double long2 = end.longitude * (pi / 180);

    double dLon = (long2 - long1);

    double y = sin(dLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    double bearing = atan2(y, x);
    bearing = bearing * (180 / pi);
    bearing = (bearing + 360) % 360;

    return bearing;
  }

  String _getDirectionInstruction(double bearing, double distance) {
    String direction;
    if (bearing < 22.5 || bearing > 337.5) {
      direction = "Continue straight";
    } else if (bearing < 67.5) {
      direction = "Take a slight right";
    } else if (bearing < 112.5) {
      direction = "Turn right";
    } else if (bearing < 157.5) {
      direction = "Take a sharp right";
    } else if (bearing < 202.5) {
      direction = "Turn around";
    } else if (bearing < 247.5) {
      direction = "Take a sharp left";
    } else if (bearing < 292.5) {
      direction = "Turn left";
    } else {
      direction = "Take a slight left";
    }

    return "$direction and walk ${distance.round()} meters";
  }

  Future<LatLng> _geocodeAddress(String address) async {
    // Implementation needed - Use Google Geocoding API
    // For now, returning Times Square coordinates as example
    return const LatLng(40.7580, -73.9855);
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  Future<void> speakMessage(String message) async {
    await flutterTts.speak(message);
  }

  void stopNavigation() {
    _isNavigating = false;
    _positionStream?.cancel();
    _surroundingsTimer?.cancel();
    _routePoints.clear();
    _currentRouteIndex = 0;
  }

  void dispose() {
    stopNavigation();
    cameraController.dispose();
    flutterTts.stop();
  }
}