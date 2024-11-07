
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as imgLib;

class ObjectRecognitionScreen extends StatefulWidget {
  @override
  _ObjectRecognitionScreenState createState() => _ObjectRecognitionScreenState();
}

class _ObjectRecognitionScreenState extends State<ObjectRecognitionScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? cameras;
  CameraImage? imgCamera;
  bool isProcessing = false;
  List<dynamic> detections = [];

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    try {
      cameras = await availableCameras();
      _cameraController = CameraController(cameras![0], ResolutionPreset.high);
      await _cameraController!.initialize();

      if (_cameraController!.value.isInitialized) {
        setState(() {
          _cameraController?.startImageStream((image) {
            if (!isProcessing) {
              isProcessing = true;
              imgCamera = image;
              processFrame(image);
            }
          });
        });
      }
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  Future<void> processFrame(CameraImage image) async {
    final jpegBytes = await _convertImageToJpeg(image);
    final base64Image = base64Encode(jpegBytes);

    try {
      final response = await http.post(
        Uri.parse('http://192.168.229.217:5000/detect'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"image": base64Image}),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        setState(() {
          detections = result['detections'];
        });
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      isProcessing = false;
    }
  }

  Future<Uint8List> _convertImageToJpeg(CameraImage image) async {
    final img = imgLib.Image(image.width, image.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final uvIndex = (x ~/ 2) + (y ~/ 2) * image.planes[1].bytesPerRow;
        final yp = image.planes[0].bytes[y * image.width + x];
        final up = image.planes[1].bytes[uvIndex];
        final vp = image.planes[2].bytes[uvIndex];
        img.data[y * image.width + x] = _yuv2rgb(yp, up, vp);
      }
    }
    return Uint8List.fromList(imgLib.encodeJpg(img));
  }

  int _yuv2rgb(int y, int u, int v) {
    final r = (y + 1.370705 * (v - 128)).clamp(0, 255).toInt();
    final g = (y - 0.337633 * (u - 128) - 0.698001 * (v - 128)).clamp(0, 255).toInt();
    final b = (y + 1.732446 * (u - 128)).clamp(0, 255).toInt();
    return (0xFF << 24) | (b << 16) | (g << 8) | r;
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Object Recognition"),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(_cameraController!)),

          if(detections.isNotEmpty)
          Positioned.fill(
            child: CustomPaint(
              painter: DetectionBoxesPainter(detections),
            ),
          ),
        ],
      ),
    );
  }
}

class DetectionBoxesPainter extends CustomPainter {
  final List<dynamic> detections;

  DetectionBoxesPainter(this.detections);

  @override
  void paint(Canvas canvas, Size size) {

    if(detections.isEmpty || detections == null) return;

    final paintBox = Paint()..color = Colors.red..style = PaintingStyle.stroke..strokeWidth = 2.0;

    for (var detection in detections) {
      final bbox = detection['bounding_box'];
      final rect = Rect.fromLTWH(
        bbox['x'].toDouble(),
        bbox['y'].toDouble(),
        bbox['width'].toDouble(),
        bbox['height'].toDouble(),
      );
      canvas.drawRect(rect, paintBox);

      final label = detection['label'];
      final distance = detection['distance'] ?? 'Unknown';
      final textSpan = TextSpan(
        text: "$label: ${distance}m",
        style: TextStyle(color: Colors.white, fontSize: 14),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(bbox['x'].toDouble(), bbox['y'].toDouble() - 15));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}




/*import 'package:camera/camera.dart';
import 'package:flutter/material.dart';



class ObjectRecognitionScreen extends StatefulWidget {
  const ObjectRecognitionScreen({super.key});

  @override
  _ObjectRecognitionScreenState createState() =>
      _ObjectRecognitionScreenState();
}

class _ObjectRecognitionScreenState extends State<ObjectRecognitionScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? cameras;
  CameraImage? imgCamera;
  String result="";
  bool isWorking=false;

  /*loadModel() async {
    await Tflite.loadModel(
        model: "assets/mobilenet_v1_1.0_224.tflite",
        labels: "assets/mobilenet_v1_1.0_224.txt"
    );
  }*/

  @override
  void initState() {
    super.initState();
    initializeCamera();

    //loadModel();
  }

  // Initialize the camera
  Future<void> initializeCamera() async {
    try {
      cameras = await availableCameras();
      _cameraController = CameraController(cameras![0], ResolutionPreset.high);
      await _cameraController!.initialize();

      if( _cameraController!.value.isInitialized ) {
        setState(() {
          if(!isWorking) {
            isWorking = true;
            _cameraController?.startImageStream((imageFromStream) {
            imgCamera = imageFromStream;
            //runModelOnStreamFrames();
          });
        }
        });
      }
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  /*Future<void> runModelOnStreamFrames() async {
    // Use a local reference to ensure imgCamera doesn't change during execution
    final cameraImage = imgCamera;

    if (cameraImage != null){

      try {
        var recognitions = await Tflite.runModelOnFrame(
          bytesList: cameraImage.planes.map((plane) => plane.bytes).toList(),
          imageHeight: cameraImage.height,
          imageWidth: cameraImage.width,
          imageMean: 127.5,
          imageStd: 127.5,
          rotation: 90,
          numResults: 2,
          threshold: 0.1,
          asynch: true,
        );

        // Clear the result and populate with new recognitions
        String newResult = "";
        recognitions?.forEach((response) {
          newResult += "${response["label"]}  ${(response["confidence"] as double).toStringAsFixed(2)}\n\n";
        });

        // Update the result in the UI
        setState(() {
          result = newResult;
          print(result);
        });
      } catch (e) {
        print("Error running model on frame: $e");
      } finally {
        // Mark as not working regardless of success or failure
        //isWorking = false;
      }
    }
  }*/


  @override
  void dispose() async {
    _cameraController?.dispose();
    super.dispose();

    //await Tflite.close();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Object Recognition",
          style: TextStyle(
            fontSize: 22, // Larger font size for better visibility
            fontWeight: FontWeight.w600, // Semi-bold font weight
            color: Colors.white, // White text color for contrast
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF8E24AA), // Light purple
                Color(0xFF6A1B9A), // Darker purple
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4, // Add shadow effect for depth
      ),
      body: Stack(
        children: [
          // 1. Live camera feed
          Positioned.fill(
            child: CameraPreview(_cameraController!),
          ),

          // 2. Simulating object detection boxes
          Positioned.fill(
            child: CustomPaint(
              painter: DetectionBoxesPainter(),
            ),
          ),

          // 3. Bottom bar with mic icon and sound wave
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 120,
              decoration: const BoxDecoration(
                color: Color(0xFF610A8A), // Purple background
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.mic, color: Colors.white, size: 36),
                    onPressed: () {
                      // Add microphone interaction logic
                    },
                  ),
                  const SizedBox(width: 16),
                  // Visual representation of sound wave
                  Expanded(
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const SoundWaveVisualizer(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 5. Custom painter for drawing object detection boxes
class DetectionBoxesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintYellow = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final paintRed = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Example boxes for objects and people
    canvas.drawRect(
        Rect.fromLTWH(50, 100, 100, 200), paintYellow); // Example person
    canvas.drawRect(
        Rect.fromLTWH(200, 150, 120, 180), paintRed); // Example object
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 6. Placeholder widget for sound wave visualization
class SoundWaveVisualizer extends StatelessWidget {
  const SoundWaveVisualizer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.purple[200],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          20,
          (index) => Container(
            width: 4,
            height:
                (index % 2 == 0) ? 30 : 50, // Varying heights for wave effect
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}*/
