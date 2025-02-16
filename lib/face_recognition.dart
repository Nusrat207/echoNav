
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class FaceRecognition {
   Future<List<Face>> detectFace(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final faceDetector = GoogleMlKit.vision.faceDetector(
      FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableLandmarks: true,
      ),
    );

    final List<Face> faces = await faceDetector.processImage(inputImage);
    faceDetector.close();
    return faces;
  }
  
  Future<String> generateFaceId(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final faceDetector = GoogleMlKit.vision.faceDetector(
        FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate,
          enableLandmarks: true,
        ),
      );

      final List<Face> faces = await faceDetector.processImage(inputImage);
      faceDetector.close();

      print("Faces detected: ${faces.length}");

      if (faces.isNotEmpty) {
        // Use facial landmarks to generate a unique ID
        final landmarks = faces.first.landmarks;
        final landmarksString = landmarks.toString(); // Convert landmarks to string
        final faceId = sha256.convert(utf8.encode(landmarksString)).toString(); // Hash the landmarks

        print("Generated Face ID: $faceId");
        return faceId;
      } else {
        throw Exception("No face detected!");
      }
    } catch (e) {
      print("Error in generateFaceId: $e");
      throw Exception("Error during face recognition: $e");
    }
  }
}
