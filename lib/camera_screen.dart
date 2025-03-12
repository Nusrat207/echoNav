import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'face_recognition.dart';
import 'package:echoNav/screens/second_page.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  bool _isCameraInitialized = false;
  bool _isFaceDetected = false;
  final FaceRecognition _faceRecognition = FaceRecognition();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
      );

      _initializeControllerFuture = _cameraController.initialize();
      await _initializeControllerFuture;

      setState(() {
        _isCameraInitialized = true;
      });

      // Start face detection
      _startFaceDetection();
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  Future<void> _startFaceDetection() async {
    while (!_isFaceDetected) {
      if (!_isCameraInitialized) {
        await Future.delayed(Duration(milliseconds: 500));
        continue;
      }

      try {
        // Capture a frame from the camera
        final image = await _cameraController.takePicture();

        // Detect faces in the captured image
        final faces = await _faceRecognition.detectFace(image.path);

        if (faces.isNotEmpty) {
          // Face detected
          setState(() {
            _isFaceDetected = true;
          });

          // Close the camera and navigate back with the image path
          Navigator.pop(context, image.path);

          // Navigate directly to SecondPage
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SecondPage()),
          );
          break;
        }
      } catch (e) {
        print("Error detecting face: $e");
      }

      // Wait for a short duration before checking again
      await Future.delayed(Duration(milliseconds: 500));
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Capture Face")),
      body: _isCameraInitialized
          ? CameraPreview(_cameraController)
          : Center(child: CircularProgressIndicator()),
    );
  }
}
