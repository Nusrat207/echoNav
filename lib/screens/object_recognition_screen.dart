import 'package:camera/camera.dart';
import 'package:flutter/material.dart';


/*
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

  loadModel() async {
    await Tflite.loadModel(
        model: "assets/mobilenet_v1_1.0_224.tflite",
        labels: "assets/mobilenet_v1_1.0_224.txt"
    );
  }

  @override
  void initState() {
    super.initState();
    initializeCamera();

    loadModel();
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
            runModelOnStreamFrames();
          });
        }
        });
      }
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  Future<void> runModelOnStreamFrames() async {
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
  }


  /*runModelOnStreamFrames() async{
    if(imgCamera != null)
    {
      var recognitions = await Tflite.runModelOnFrame(

        bytesList: imgCamera.planes.map((plane)
        {
          return plane.bytes;
        }).toList(),

        imageHeight: imgCamera.height,
        imageWidth: imgCamera.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90,
        numResults: 2,
        threshold: 0.1,
        asynch: true,
      );
      result="";

      recognitions?.forEach((response)
      {
        result += response["label"] + "  " + (response["confidence"] as double).toStringAsFixed(2) + "\n\n";

      });

      setState((){
        result;
      });

      isWorking = false;
    }
  }*/

  @override
  void dispose() async {
    _cameraController?.dispose();
    super.dispose();

    await Tflite.close();
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
}
*/