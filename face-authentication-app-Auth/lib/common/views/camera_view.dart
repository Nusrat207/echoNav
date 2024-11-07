import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';

// Web-only imports
import 'dart:html' as html;

class CameraView extends StatefulWidget {
  const CameraView({
    Key? key,
    required this.onImage,
    required this.onInputImage,
  }) : super(key: key);

  final Function(Uint8List) onImage;
  final Function(InputImage) onInputImage;

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes; // Change to Uint8List to hold image bytes

  html.VideoElement? _videoElement;
  html.CanvasElement? _canvasElement;
  html.ImageElement? _imageElement;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _videoElement = html.VideoElement();
      _canvasElement = html.CanvasElement(width: 400, height: 400);
      _imageElement = html.ImageElement();
      _initializeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              color: Colors.white,
              size: 30.0,
            ),
          ],
        ),
        const SizedBox(height: 20.0),
        _imageBytes != null
            ? CircleAvatar(
                radius: 80.0,
                backgroundColor: const Color(0xffD9D9D9),
                backgroundImage:
                    MemoryImage(_imageBytes!), // Display image bytes
              )
            : CircleAvatar(
                radius: 80.0,
                backgroundColor: const Color(0xffD9D9D9),
                child: Icon(
                  Icons.camera_alt,
                  size: 50.0,
                  color: const Color(0xff2E2E2E),
                ),
              ),
        GestureDetector(
          onTap: kIsWeb ? _captureImageWeb : _captureImageMobile,
          child: Container(
            width: 60,
            height: 60,
            margin: const EdgeInsets.only(top: 44, bottom: 20),
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                stops: [0.4, 0.65, 1],
                colors: [
                  Color(0xffD9D9D9),
                  Colors.white,
                  Color(0xffD9D9D9),
                ],
              ),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Text(
          "Click here to Capture",
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  // Initialize camera for web
  void _initializeCamera() async {
    final stream = await html.window.navigator.mediaDevices!.getUserMedia(
      {'video': true},
    );
    _videoElement!.srcObject = stream;
    _videoElement!.autoplay = true;
    setState(() {});
  }

  // Capture image for mobile
  Future<void> _captureImageMobile() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 400,
      maxHeight: 400,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
      _processImage(bytes);
    }
  }

  // Capture image for web
  Future<void> _captureImageWeb() async {
    final context = _canvasElement!.context2D;
    context.drawImage(_videoElement!, 0, 0);
    final imageData = _canvasElement!.toDataUrl('image/png');
    _imageElement!.src = imageData;

    final response = await html.window.fetch(imageData);
    final blob = await response.blob();
    final reader = html.FileReader();
    reader.readAsArrayBuffer(blob);
    reader.onLoadEnd.listen((_) {
      final bytes = reader.result as Uint8List;
      setState(() {
        _imageBytes = bytes;
      });
      _processImage(bytes);
    });
  }

  // Process the image and send it for ML model processing
  void _processImage(Uint8List bytes) {
    widget.onImage(bytes);

    InputImage inputImage;

    if (kIsWeb) {
      inputImage = InputImage.fromBytes(
        bytes: bytes,
        inputImageData: InputImageData(
          size: const Size(400, 400),
          imageRotation: InputImageRotation.rotation0deg,
          inputImageFormat: InputImageFormat.yuv420, // Use yuv420 for web
          planeData: [],
        ),
      );
    } else {
      inputImage = InputImage.fromBytes(
        bytes: bytes,
        inputImageData: InputImageData(
          size: const Size(400, 400),
          imageRotation: InputImageRotation.rotation0deg,
          inputImageFormat: InputImageFormat.nv21, // Use nv21 for mobile
          planeData: [],
        ),
      );
    }

    widget.onInputImage(inputImage);
  }

  @override
  void dispose() {
    _videoElement?.pause();
    super.dispose();
  }
}
