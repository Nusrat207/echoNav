// google_maps_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/SmartNavigationService.dart';
import '../repositories/map_repository.dart';
import '../widgets/search_bar_widget.dart';

class GoogleMapsScreen extends StatefulWidget {
  const GoogleMapsScreen({super.key});

  @override
  State<GoogleMapsScreen> createState() => _GoogleMapsScreenState();
}

class _GoogleMapsScreenState extends State<GoogleMapsScreen> {
  GoogleMapController? mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  late SmartNavigationService navigationService;
  late MapRepository mapRepository;
  LatLng? _currentLocation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize map repository with your API key
      mapRepository = MapRepository(apiKey: 'YOUR_GOOGLE_MAPS_API_KEY');
      navigationService = SmartNavigationService(mapRepository: mapRepository);

      // Request location permission and get current location
      await _getCurrentLocation();
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error initializing services: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: _currentLocation!,
            infoWindow: const InfoWindow(title: 'Current Location'),
          ),
        );
      });

      if (mapController != null) {
        await mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _currentLocation!,
              zoom: 15,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  Future<void> _startNavigation(String destination) async {
    try {
      setState(() => _isLoading = true);

      // Clear previous route
      _polylines.clear();
      _markers.removeWhere((marker) => marker.markerId.value != 'current_location');

      // Get destination coordinates
      final destinationLatLng = await mapRepository.geocodeAddress(destination);

      // Add destination marker
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: destinationLatLng,
          infoWindow: InfoWindow(title: destination),
        ),
      );

      // Get route
      if (_currentLocation != null) {
        final result = await mapRepository.getRouteCoordinates(
          _currentLocation!,
          destinationLatLng,
        );

        if (result.success) {
          // Add route polyline
          final points = _decodePolyline(result.data['routes'][0]['overview_polyline']['points']);
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('navigation_route'),
              points: points,
              color: Colors.blue,
              width: 5,
            ),
          );

          // Start navigation service
          await navigationService.startNavigation(destination);

          // Update camera to show entire route
          _fitRoute(points);
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error starting navigation: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting navigation: $e')),
        );
      }
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

  void _fitRoute(List<LatLng> points) {
    if (points.isEmpty || mapController == null) return;

    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLng = points[0].longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100, // padding
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_currentLocation != null)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentLocation!,
                zoom: 15,
              ),
              onMapCreated: (controller) => mapController = controller,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              markers: _markers,
              polylines: _polylines,
            )
          else
            const Center(child: Text('Getting location...')),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SearchBarWidget(
                    onSearch: _startNavigation,
                    mapRepository: mapRepository,
                  ),
                  if (_isLoading)
                    const LinearProgressIndicator(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    navigationService.dispose();
    mapController?.dispose();
    super.dispose();
  }
}