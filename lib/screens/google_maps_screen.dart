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
  String _lastProcessedImage = '';
  String _navigationInstructions = '';
  bool _isIndoors = false;
  List<String> _directionsSteps = [];
  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeComponents();
  }

  Future<void> _initializeComponents() async {
    // Initialize map repository
    _mapRepository = MapRepository(apiKey: 'AIzaSyDF2rKGbY2nhUoe1rKcI3DhUKM_HZu2oUY');

    // Initialize camera
    final cameras = await availableCameras();
    _cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    await _cameraController.initialize();

    // Initialize location
    _getCurrentLocation();

    await _speech.initialize();

    // Set up the error listener once during initialization
    _speech.errorListener = (error) async {
      setState(() => _isListening = false);
      print('Speech recognition error: $error');
      await Future.delayed(Duration(seconds: 1));
      await _startListening();
    };

    // Your existing code...

    // Start listening at the end of initialization
    await _startListening();

    // Configure TTS
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5); // Slower speech rate for clearer instructions

    /*
    _tts.setCompletionHandler(() {
      // When current instruction finished speaking, move to next if available
      if (_currentStepIndex < _directionsSteps.length - 1) {
        _currentStepIndex++;
        _speakCurrentInstruction();
      }
    });*/

  }

  Future<void> _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
    _mapController.animateCamera(CameraUpdate.newLatLng(_currentLocation!));
  }

  Future<void> _startListening() async {
    // Cancel any ongoing listening session first
    await _speech.cancel();

    if (!_speech.isListening) {
      setState(() => _isListening = true);

      try {
        await _speech.listen(
          onResult: (result) async {
            if (result.finalResult) {
              // Process the voice input to get destination
              final text = result.recognizedWords;

              // Only process if there's actual text to process
              if (text.isNotEmpty) {
                await _processVoiceInput(text);
              }

              // Restart listening after a short delay
              await Future.delayed(Duration(milliseconds: 500));
              await _startListening();
            }
          },


          cancelOnError: false,
          listenMode: stt.ListenMode.confirmation,
        );

        await _processVoiceInput("Bangladesh open university");
      } catch (error) {
        print('Error during speech recognition: $error');
        setState(() => _isListening = false);

        // Restart listening after error with a delay
        await Future.delayed(Duration(seconds: 1));
        await _startListening();
      }
    }
  }


  Future<void> _processVoiceInput(String text) async {
    try {
      // First, get destination coordinates from voice input
      final geocodingUrl = 'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(text)}&key=AIzaSyDF2rKGbY2nhUoe1rKcI3DhUKM_HZu2oUY';
      final response = await http.get(Uri.parse(geocodingUrl));
      final data = json.decode(response.body);

      print(response);

      if (data['status'] == 'OK') {
        final location = data['results'][0]['geometry']['location'];
        setState(() {
          _destination = LatLng(location['lat'], location['lng']);
        });

        // Get route and directions
        await _updateRouteAndDirections();

        // Process camera image and get navigation instructions
        await _processCameraImage();
      }
    } catch (e) {
      print('Error processing voice input: $e');
    }
  }

  Future<void> _updateRouteAndDirections() async {
    if (_currentLocation != null && _destination != null) {
      try {
        // Get directions
        final directionsUrl =
            'https://maps.googleapis.com/maps/api/directions/json?'
            'origin=${_currentLocation!.latitude},${_currentLocation!.longitude}'
            '&destination=${_destination!.latitude},${_destination!.longitude}'
            '&mode=walking'
            '&key=AIzaSyDF2rKGbY2nhUoe1rKcI3DhUKM_HZu2oUY';

        final response = await http.get(Uri.parse(directionsUrl));
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          // Extract route points for polyline
          final points = _decodePolyline(
              data['routes'][0]['overview_polyline']['points']
          );

          // Extract steps for navigation
          final steps = data['routes'][0]['legs'][0]['steps'] as List;
          setState(() {
            _polylines = {
              Polyline(
                polylineId: PolylineId('route'),
                points: points,
                color: Colors.blue,
                width: 5,
              ),
            };

            // Store and process directions steps
            _directionsSteps = steps.map((step) {
              // Remove HTML tags from instructions
              String instruction = step['html_instructions'].toString()
                  .replaceAll(RegExp(r'<[^>]*>'), ' ')
                  .replaceAll('  ', ' ');
              return instruction;
            }).toList();

            _currentStepIndex = 0;
          });

          // Start speaking directions
          //_speakDirections();
        }
      } catch (e) {
        print('Error getting directions: $e');
      }
    }
  }

  Future<void> _speakDirections() async {
    if (_directionsSteps.isNotEmpty) {
      _currentStepIndex = 0;
      await _speakCurrentInstruction();
    }
  }

  Future<void> _speakCurrentInstruction() async {
    if (_currentStepIndex < _directionsSteps.length) {
      String instruction = _directionsSteps[_currentStepIndex];
      setState(() {
        _navigationInstructions = instruction;
      });
      await _tts.speak(instruction);
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

  Future<void> _processCameraImage() async {
    if (_isIndoors) {
      setState(() {
        _navigationInstructions = "You are indoors. Navigation will continue when you are outside.";
      });
      await _tts.speak(_navigationInstructions);
      return;
    }

    try {
      final image = await _cameraController.takePicture();
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      String prompt = "You're helping me navigate the space you see in the image. You're going to read the following instruction, and also going to identify any potential obstacles you can see in the image while trying to follow the instruction. INSTRUCTION: " + _directionsSteps[_currentStepIndex] + "If you don't see a road ahead of you and determine that I am indoors, you will say something like 'Since you are indoors, I can't provide you detailed instructions to your destination' ";

      final response = await http.post(
        Uri.parse('http://192.168.240.181:8000/api/ask'),
        body: {
          'image': base64Image,
          'prompt': prompt,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final enhancedInstructions = data['response'];
        setState(() {
          _navigationInstructions = enhancedInstructions;
        });
        await _tts.speak(enhancedInstructions);
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
            child: Column(
              children: [
                Expanded(
                  child: CameraPreview(_cameraController),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(_navigationInstructions),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _startListening,
                      child: Text(_isListening ? 'Listening...' : 'Start Navigation'),
                    ),
                    if (_directionsSteps.isNotEmpty)
                      ElevatedButton(
                        onPressed: _speakCurrentInstruction,
                        child: Text('Repeat Instruction'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _mapController.dispose();
    _cameraController.dispose();
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }
}