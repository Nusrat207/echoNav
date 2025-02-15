import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import '../repositories/map_repository.dart';

class GoogleMapsScreen extends StatefulWidget {
  const GoogleMapsScreen({super.key});

  @override
  _GoogleMapsScreenState createState() => _GoogleMapsScreenState();
}

class _GoogleMapsScreenState extends State<GoogleMapsScreen> {
  late GoogleMapController _mapController;
  late CameraController _cameraController;
  late MapRepository _mapRepository;
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  LatLng? _currentLocation;
  LatLng? _destination;
  Set<Polyline> _polylines = {};
  bool _isListening = false;
  String _navigationInstructions = '';
  bool _isIndoors = false;
  bool _isCameraInitialized = false;
  String _recognizedText = '';

  @override
  void initState() {
    super.initState();
    _initializeComponents();
  }

  Future<void> _initializeComponents() async {
    // Initialize map repository
    _mapRepository =
        MapRepository(apiKey: 'AIzaSyDF2rKGbY2nhUoe1rKcI3DhUKM_HZu2oUY');

    // Initialize camera
    final cameras = await availableCameras();
    _cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    await _cameraController.initialize();
    setState(() {
      _isCameraInitialized = true;
    });

    // Initialize location
    _getCurrentLocation();

    // Initialize speech recognition
    await _speech.initialize();
  }

  Future<void> _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
    _mapController.animateCamera(CameraUpdate.newLatLng(_currentLocation!));
  }

  Future<void> _startListening() async {
    if (!_isListening) {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) async {
          setState(() {
            _recognizedText = result.recognizedWords;
          });

          if (result.finalResult) {
            if (_recognizedText.isEmpty) {
              _startListening(); // Restart listening if no speech was recognized
            } else {
              _stopListening(); // Stop current listening
              await _processVoiceInput(_recognizedText);
              _startListening(); // Restart listening after processing input
            }
          }
        },
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _processVoiceInput(String text) async {
    try {
      final geocodingUrl =
          'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(text)}&key=AIzaSyDF2rKGbY2nhUoe1rKcI3DhUKM_HZu2oUY';
      final response = await http.get(Uri.parse(geocodingUrl));
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final location = data['results'][0]['geometry']['location'];
        setState(() {
          _destination = LatLng(location['lat'], location['lng']);
        });

        await _updateRoute();
        await _processCameraImage();
      }
    } catch (e) {
      print('Error processing voice input: $e');
    }
  }

  Future<void> _updateRoute() async {
    if (_currentLocation != null && _destination != null) {
      final points =
          await _mapRepository.getRoutePoints(_currentLocation!, _destination!);
      setState(() {
        _polylines = {
          Polyline(
            polylineId: PolylineId('route'),
            points: points,
            color: Colors.blue,
            width: 5,
          ),
        };
      });
    }
  }

  Future<void> _processCameraImage() async {
    if (_isIndoors) {
      setState(() {
        _navigationInstructions =
            "You are indoors. Navigation will continue when you are outside.";
      });
      await _tts.speak(_navigationInstructions);
      return;
    }

    try {
      final image = await _cameraController.takePicture();
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      String prompt =
          'This is my location data, tell me how can I go to this destination: current_location:${_currentLocation?.latitude},${_currentLocation?.longitude},destination:${_destination?.latitude},${_destination?.longitude}';

      final response = await http.post(
        Uri.parse('http://192.168.0.103:8000/api/ask'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'prompt': prompt + _recognizedText,
          'image': base64Image,
        },
        // body: {
        //   'image': base64Image,
        //   'current_location':
        //       '${_currentLocation?.latitude},${_currentLocation?.longitude}',
        //   'destination': '${_destination?.latitude},${_destination?.longitude}',
        // },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _navigationInstructions = data['response'];
        });
        await _tts.speak(_navigationInstructions);
      } else {
        print("Failed to send request: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    } catch (e) {
      print('Error processing camera image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Map View (top half)
          Expanded(
            child: _currentLocation == null
                ? Center(child: CircularProgressIndicator())
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentLocation!,
                      zoom: 15,
                    ),
                    onMapCreated: (controller) => _mapController = controller,
                    myLocationEnabled: true,
                    polylines: _polylines,
                  ),
          ),

          // Camera View (bottom half)
          Expanded(
            child: _isCameraInitialized
                ? Column(
                    children: [
                      Expanded(
                        child: CameraPreview(_cameraController),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(_navigationInstructions),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(_recognizedText),
                      ),
                      ElevatedButton(
                        onPressed: _startListening,
                        child: Text(
                            _isListening ? 'Listening...' : 'Start Navigation'),
                      ),
                    ],
                  )
                : Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    _cameraController.dispose();
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }
}
