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
  bool _isSpeaking = false; // To track the speaking state
  bool _isProcessing = false; // To track processing state
  late stt.SpeechToText _speechToText; // Speech-to-text instance
  late FlutterTts _flutterTts; // Text-to-speech instance

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _speechToText = stt.SpeechToText();
    _flutterTts = FlutterTts();

    // Configure TTS settings
    _flutterTts.setCompletionHandler(() {
      if (!mounted) return;

      setState(() {
        _isSpeaking = false;
      });

      // Add a longer delay before starting to listen after speaking
      Future.delayed(Duration(milliseconds: 1500), () {
        if (!_isListening && !_isSpeaking && !_isProcessing && mounted) {
          _startListening();
        }
      });
    });

    // Initialize TTS settings
    _initTts();

    // Make absolutely sure we're not listening
    _stopListening();

    // Speak greeting - listening will start via completion handler only
    setState(() {
      _isSpeaking = true;
    });
    _flutterTts.speak("How May I help you today?");
  }

  // Initialize TTS with settings to avoid overlap issues
  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5); // Slightly slower rate
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
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
    // Extra safety check - never listen while speaking
    if (_isListening || _isSpeaking || _isProcessing || !mounted) {
      print("Not starting listening - conditions not met");
      return;
    }

    print("Starting speech recognition");
    bool available = await _speechToText.initialize(
      onError: (error) => print("Speech recognition error: $error"),
      onStatus: (status) => print("Speech recognition status: $status"),
    );

    if (available) {
      setState(() {
        _isListening = true;
      });

      await _speechToText.listen(
        onResult: (result) {
          // Only process results if we're still in listening mode and not speaking
          if (_isListening && !_isSpeaking && !_isProcessing && mounted) {
            setState(() {
              _recognizedText = result.recognizedWords;
            });

            // If the result is final and recognized text is not empty, process it
            if (result.finalResult) {
              _stopListening();

              if (_recognizedText.isNotEmpty) {
                _sendFrameToBackend();
              } else {
                // If no speech was recognized, restart listening after a delay
                Future.delayed(Duration(milliseconds: 800), () {
                  if (!_isSpeaking && !_isProcessing && mounted) {
                    _startListening();
                  }
                });
              }
            }
          }
        },
        listenOptions: stt.SpeechListenOptions(
          cancelOnError: true,
        ),
      );
    } else {
      print("Speech recognition not available");
    }
  }

  // Stop listening - with additional safety
  void _stopListening() {
    if (_speechToText.isListening) {
      print("Stopping speech recognition");
      _speechToText.stop();
    }

    if (_isListening) {
      setState(() {
        _isListening = false;
      });
    }
  }

  // Send frame and voice command to the backend
  Future<void> _sendFrameToBackend() async {
    if (_isSpeaking || _isProcessing || !mounted) return;

    // Make absolutely sure we're not listening while processing
    _stopListening();

    setState(() {
      _isProcessing = true;
    });

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
              _isProcessing = false;
              _isSpeaking = true;
            });

            // Make sure we're not listening while speaking
            _stopListening();
            await _flutterTts.speak(responseText);
            // Listening will restart via the TTS completion handler
          } else {
            print("Failed to send request: ${response.statusCode}");
            print("Response body: ${response.body}");

            setState(() {
              _isProcessing = false;
              _isSpeaking = true;
            });

            await _flutterTts.speak("Sorry, I couldn't process your request.");
            // Listening will restart via the TTS completion handler
          }
        }
      } else {
        setState(() {
          _isProcessing = false;
        });

        // If no text or camera not ready, restart listening
        if (!_isSpeaking && mounted) {
          _startListening();
        }
      }
    } catch (e) {
      print("Error: $e");

      setState(() {
        _isProcessing = false;
        _isSpeaking = true;
      });

      await _flutterTts.speak("Sorry, an error occurred.");
      // Listening will restart via the TTS completion handler
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _speechToText.stop();
    _flutterTts.stop();

    // Clear the completion handler to prevent it from firing after disposal
    _flutterTts.setCompletionHandler(() {});

    super.dispose();
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

          // Status indicators
          if (_isProcessing)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(width: 10),
                  Text("Processing..."),
                ],
              ),
            ),

          if (_isSpeaking)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.volume_up, color: Colors.blue),
                  SizedBox(width: 10),
                  Text("Speaking..."),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      await _flutterTts.stop();
                      setState(() {
                        _isSpeaking = false;
                      });
                      _startListening();
                    },
                    child: Text("Stop"),
                  ),
                ],
              ),
            ),

          // Smaller buttons with icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: (_isProcessing || _isSpeaking)
                    ? null
                    : (_isListening ? _stopListening : _startListening),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(8.0), // Smaller padding
                ),
                child: Icon(_isListening ? Icons.stop : Icons.mic),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: (_isListening ||
                        _isSpeaking ||
                        _isProcessing ||
                        _recognizedText.isEmpty)
                    ? null
                    : _sendFrameToBackend,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(8.0), // Smaller padding
                ),
                child: const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
