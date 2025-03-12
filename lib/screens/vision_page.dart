import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image/image.dart' as img;

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

    // Speak the initial greeting and start listening afterward
    _flutterTts.speak("How May I help you today?").then((_) {
      _startListening(); // Start listening after TTS is done
    });
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
        _isListening = true; // Set to true when listening starts
      });
      _speechToText.listen(
        onResult: (result) {
          setState(() {
            _recognizedText = result.recognizedWords; // Update recognized text
          });

          // If the result is final and recognized text is empty, restart listening
          if (result.finalResult) {
            if (_recognizedText.isEmpty) {
              _startListening(); // Restart listening if no speech was recognized
            } else {
              _stopListening(); // Stop current listening
              _sendFrameToBackend(); // Send the frame to the backend
            }
          }
        },
        listenOptions: stt.SpeechListenOptions(
          cancelOnError: true, // Automatically stop on error
        ),
      );
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

        // Read image bytes
        Uint8List imageBytes = await imageFile.readAsBytes();

        // Compress the image
        img.Image? originalImage = img.decodeImage(imageBytes);
        if (originalImage != null) {
          img.Image compressedImage = img.copyResize(originalImage,
              width: 800); // Resize to 800px width
          Uint8List compressedBytes = Uint8List.fromList(img.encodeJpg(
              compressedImage,
              quality: 70)); // Compress with 70% quality

          // Convert to base64
          String base64Image = base64Encode(compressedBytes);

          // Prepare API request
          var url = Uri.parse("http://192.168.238.54:8000/api/ask");
          var response = await http.post(
            url,
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              'prompt': _recognizedText,
              'image': base64Image,
            },
          );

          if (response.statusCode == 200) {
            var data = json.decode(response.body);
            String responseText = data['response'];

            setState(() {
              _responseText = responseText;
            });

            _flutterTts.speak(responseText).then((_) {
              _startListening(); // Restart listening after TTS is done
            });
          } else {
            print("Failed to send request: ${response.statusCode}");
            print("Response body: ${response.body}");
          }
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
          // Enlarge the camera preview with flexible space
          if (isCameraInitialized)
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: AspectRatio(
                  aspectRatio: _cameraController.value.aspectRatio,
                  child: CameraPreview(_cameraController),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),

          // Voice command and response text
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                "Voice Command: $_recognizedText",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                "Response: $_responseText",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Smaller buttons with icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _isListening ? _stopListening : _startListening,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(8.0), // Smaller padding
                ),
                child: Icon(_isListening ? Icons.stop : Icons.mic),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: _sendFrameToBackend,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(8.0), // Smaller padding
                ),
                child: const Icon(Icons.send),
              ),
            ],
          ),

          // Loading indicator if listening
          // if (_isListening)
          //   const Padding(
          //     padding: EdgeInsets.all(8.0),
          //     child: CircularProgressIndicator(),
          //   ),
        ],
      ),
    );
  }
}
