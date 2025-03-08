import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import '../repositories/map_repository.dart';
import 'vision_page.dart';

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
  bool _inVisionPage = false;
  List<String> _directionsSteps = [];
  int _currentStepIndex = 0;

  // New state variables for control flow
  bool _isSpeaking = false;
  bool _processingNextInstruction = false;
  bool _isNavigatingToVisionPage = false;
  bool _isDisposed = false;

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
      if (_isDisposed) return;

      setState(() => _isListening = false);
      print('Speech recognition error: $error');
      await Future.delayed(Duration(seconds: 1));
      await _startListening();
    };

    // Start listening at the end of initialization
    await _startListening();

    // Configure TTS
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5); // Slower speech rate for clearer instructions
  }

  Future<void> _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
    if (_mapController != null) {
      _mapController.animateCamera(CameraUpdate.newLatLng(_currentLocation!));
    }
  }

  Future<void> _startListening() async {
    // Don't proceed if the widget is being disposed
    if (_isDisposed) return;

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
              if (!_isDisposed) {
                await Future.delayed(Duration(milliseconds: 500));
                await _startListening();
              }
            }
          },
          cancelOnError: false,
          listenMode: stt.ListenMode.confirmation,
        );

        // Uncomment for testing with a default destination
        await _processVoiceInput("Bangladesh open university");
      } catch (error) {
        print('Error during speech recognition: $error');
        setState(() => _isListening = false);

        // Restart listening after error with a delay
        if (!_isDisposed) {
          await Future.delayed(Duration(seconds: 1));
          await _startListening();
        }
      }
    }
  }

  Future<void> _processVoiceInput(String text) async {
    try {
      // First, get destination coordinates from voice input
      final geocodingUrl = 'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(text)}&key=AIzaSyDF2rKGbY2nhUoe1rKcI3DhUKM_HZu2oUY';
      final response = await http.get(Uri.parse(geocodingUrl));
      final data = json.decode(response.body);

      print('Geocoding response for: $text');

      if (data['status'] == 'OK') {
        final location = data['results'][0]['geometry']['location'];
        setState(() {
          _destination = LatLng(location['lat'], location['lng']);
        });

        // Get route and directions
        await _updateRouteAndDirections();
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

          // Start navigation
          //_speakCurrentInstruction();
          _processCameraImage();
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
    // If already speaking or processing, don't proceed
    if (_isSpeaking || _processingNextInstruction) {
      return;
    }

    if (_currentStepIndex < _directionsSteps.length) {
      setState(() {
        _isSpeaking = true;
      });

      String instruction = _directionsSteps[_currentStepIndex];
      setState(() {
        _navigationInstructions = instruction;
      });

      // Set up completion handler for TTS
      _tts.setCompletionHandler(() {
        if (_isDisposed) return;

        setState(() {
          _isSpeaking = false;
        });

        // After speech completion, process the camera image
        if (!_isDisposed && !_isNavigatingToVisionPage) {
          _processCameraImage();
        }
      });

      // Speak the current instruction
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
    // Prevent multiple simultaneous processing
    if (_processingNextInstruction || _isSpeaking || _isNavigatingToVisionPage) {
      return;
    }

    setState(() {
      _processingNextInstruction = true;
    });

    // Check if we need to switch to indoor navigation
    if (_isIndoors && !_inVisionPage && !_isNavigatingToVisionPage) {
      setState(() {
        _isNavigatingToVisionPage = true;
        _navigationInstructions = "Switching to indoor navigation mode";
      });

      // Set up completion handler for TTS
      _tts.setCompletionHandler(() async {
        if (_isDisposed) return;

        // Only navigate to vision page after speech is complete and only once
        if (_isNavigatingToVisionPage && !_inVisionPage) {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => VisionPage()),
          ).then((_) {
            if (!_isDisposed) {
              setState(() {
                _inVisionPage = true;
                _isNavigatingToVisionPage = false;
              });
            }
          });
        }
      });

      await _tts.speak(_navigationInstructions);
      setState(() {
        _processingNextInstruction = false;
      });
      return;
    }

    try {
      final image = await _cameraController.takePicture();
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      final indoorText = ". If you don't see a road ahead of you and determine that I am indoors, you will ONLY say 'Since you are indoors, I can't provide you detailed instructions to your destination'. ";

      String prompt = "You're helping me navigate the space you see in the image. You're going to read the following instruction, and also going to identify any potential obstacles you can see in the image while trying to follow the instruction. INSTRUCTION: " + _directionsSteps[_currentStepIndex] + indoorText + " Otherwise, If you can determine that user has completed the current instruction and is NOT indoors, end your statement by saying 'current instruction completed'.";

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
          _isSpeaking = true;
        });

        // Process indoor detection
        if (enhancedInstructions.trim().contains("Since you are indoors, I can't provide you detailed instructions to your destination")) {
          setState(() {
            _isIndoors = true;
          });
        }

        // Set up completion handler for this specific speech
        _tts.setCompletionHandler(() {
          if (_isDisposed) return;

          setState(() {
            _isSpeaking = false;
          });

          // Check if current instruction is completed and move to next
          if (!_isDisposed && !_isIndoors &&
              enhancedInstructions.trim().contains("Current instruction completed") ||
              enhancedInstructions.trim().contains("current instruction completed")) {

            if (_currentStepIndex < _directionsSteps.length - 1) {
              setState(() {
                _currentStepIndex++;
              });

              // Speak the next instruction
              _speakCurrentInstruction();
            } else {
              // Reached destination
              _tts.speak("You've reached your destination!");
            }
          } else if (_isIndoors && !_inVisionPage) {
            // If indoor was detected, process camera image again to handle transition
            _processCameraImage();
          }
        });

        await _tts.speak(enhancedInstructions);
      }

    } catch (e) {
      print('Error processing camera image: $e');
    } finally {
      setState(() {
        _processingNextInstruction = false;
      });
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