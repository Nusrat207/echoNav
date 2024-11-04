import 'package:camera/camera.dart';

List<CameraDescription> cameras;
late CameraController controller;
late ObjectDetectionService detectionService;

void main() async {
  // Initialize the camera
  cameras = await availableCameras();
  controller = CameraController(cameras[0], ResolutionPreset.medium);
  await controller.initialize();

  // Set up the detection service
  detectionService = ObjectDetectionService("ws://<server_ip>:8000/ws/detect");

  // Start listening for detection results
  detectionService.listenForDetections((detections) {
    print("Detections: $detections");
    // Handle the detection results
  });

  // Capture frames and send them for detection
  controller.startImageStream((CameraImage image) {
    detectionService.sendFrame(image);
  });
}
