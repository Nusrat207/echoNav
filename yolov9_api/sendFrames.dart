import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:camera/camera.dart';

class ObjectDetectionService {
  final WebSocketChannel channel;

  ObjectDetectionService(String serverAddress)
      : channel = WebSocketChannel.connect(Uri.parse(serverAddress));

  void sendFrame(CameraImage cameraImage) {
    // Convert the image to base64
    final bytes = _convertCameraImageToBytes(cameraImage);
    final base64Image = base64Encode(bytes);

    // Send the image data as a base64 string
    channel.sink.add(base64Image);
  }

  void listenForDetections(Function(List<dynamic> detections) onDetection) {
    // Listen for incoming detection data
    channel.stream.listen((data) {
      final detections = jsonDecode(data) as List<dynamic>;
      onDetection(detections);
    });
  }

  Uint8List _convertCameraImageToBytes(CameraImage image) {
    // Here, convert the CameraImage to Uint8List
    // This is highly device-dependent, and you may need to adjust based on your use case
    return Uint8List.fromList([]);
  }

  void dispose() {
    channel.sink.close();
  }
}


//DEPENDENCIES
/*
dependencies:
  web_socket_channel: ^2.1.0
*/