import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class VisionPage extends StatefulWidget {
  const VisionPage({super.key});

  @override
  _VisionPageState createState() => _VisionPageState();
}

class _VisionPageState extends State<VisionPage> {
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  late CameraDescription _camera;
  bool isCameraInitialized = false;
  XFile? _imageFile;
  String _recognizedText =
      'can you tell me what do you see'; // To store the recognized text from speech
  String _responseText = ''; // To store the response from backend
  bool _isListening = false; // To track the listening state
  late stt.SpeechToText _speechToText; // Speech-to-text instance
  late FlutterTts _flutterTts; // Text-to-speech instance

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _speechToText = stt.SpeechToText();
    _flutterTts = FlutterTts();
  }

  // Initialize the camera
  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _camera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back);
    _cameraController = CameraController(_camera, ResolutionPreset.high);
    await _cameraController.initialize();
    setState(() {
      isCameraInitialized = true;
    });
  }

  // Start listening for voice commands
  Future<void> _startListening() async {
    bool available = await _speechToText.initialize();
    if (available) {
      setState(() {
        _isListening = true;
      });
      _speechToText.listen(onResult: (result) {
        setState(() {
          _recognizedText = result.recognizedWords;
        });
      });
    }
  }

  // Stop listening
  void _stopListening() {
    _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  // Send frame and voice command to the backend
  Future<void> _sendFrameToBackend() async {
    try {
      if (_cameraController.value.isInitialized && _recognizedText.isNotEmpty) {
        // Capture image
        XFile imageFile = await _cameraController.takePicture();
        setState(() {
          _imageFile = imageFile;
        });

        // Read image bytes and convert to base64
        Uint8List imageBytes = await imageFile.readAsBytes();
        String base64Image = base64Encode(imageBytes);

        // Prepare API request
        var url = Uri.parse(
            "http://192.168.0.104:8000/api/ask"); // for physcial phone
        //  var url = Uri.parse("http://10.0.2.2:8000/api/ask"); // for emulator
        var response = await http.post(
          url,
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {
            'prompt': _recognizedText,
            'image': base64Image,
          },
        );

        if (response.statusCode == 200) {
          // Parse and display the response
          var data = json.decode(response.body);
          String responseText = data['response'];

          setState(() {
            _responseText = responseText;
          });

          // Convert response to speech
          _flutterTts.speak(responseText);
        } else {
          print("Failed to send request: ${response.statusCode}");
          print("Response body: ${response.body}");
        }
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  void dispose() {
    super.dispose();
    _cameraController.dispose();
    _speechToText.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vision Page'),
      ),
      body: Column(
        children: [
          // Camera preview

          // if (isCameraInitialized)
          //   AspectRatio(
          //     aspectRatio: _cameraController.value.aspectRatio,
          //     child: CameraPreview(_cameraController),
          //   )

          if (isCameraInitialized)
            Container(
              width: double.infinity, // Ensure the container takes full width
              height: MediaQuery.of(context).size.height *
                  0.6, // Adjust height as needed
              child: AspectRatio(
                aspectRatio: _cameraController.value.aspectRatio,
                child: CameraPreview(_cameraController),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),

          // Display the voice command
          // Voice command text with scroll
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis
                  .horizontal, // To make the voice command scroll horizontally
              child: Text(
                "Voice Command: $_recognizedText",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 2, // Limit the number of lines
                overflow: TextOverflow.ellipsis, // Handle overflow gracefully
              ),
            ),
          ),

          // Backend response text with scroll
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection:
                  Axis.horizontal, // To make the response scroll horizontally
              child: Text(
                "Response: $_responseText",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 2, // Limit the number of lines
                overflow: TextOverflow.ellipsis, // Handle overflow gracefully
              ),
            ),
          ),

          // Start/Stop listening and Send to Backend buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _isListening ? _stopListening : _startListening,
                child:
                    Text(_isListening ? "Stop Listening" : "Start Listening"),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: _sendFrameToBackend,
                child: const Text("Send to Backend"),
              ),
            ],
          ),

          // Display a loading indicator if the app is listening
          if (_isListening)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
