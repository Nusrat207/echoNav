/*
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
*/

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:logger/logger.dart';

class FaceRecognition {
  final logger = Logger();

  Future<List<Face>> detectFace(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final faceDetector = FaceDetector(
      options: FaceDetectorOptions(
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
    final faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableLandmarks: true,
      ),
    );

    final List<Face> faces = await faceDetector.processImage(inputImage);
    faceDetector.close();

    logger.d("Faces detected: ${faces.length}");

    if (faces.isNotEmpty) {
      // Extract landmarks and format them into a unique string
      final landmarks = faces.first.landmarks;
      final landmarkData = landmarks.entries
          .where((entry) => entry.value != null) // Filter out nulls
          .map((entry) {
            final landmarkType = entry.key;
            final landmark = entry.value!; // Non-null after filtering
            return '${landmarkType.name}:${landmark.position.x},${landmark.position.y}';
          }).join('|');

      // Hash the landmark data to generate a unique face ID
      final faceId = sha256.convert(utf8.encode(landmarkData)).toString();

      logger.d("Generated Face ID: $faceId");
      return faceId;
    } else {
      throw Exception("No face detected!");
    }
  } catch (e) {
    logger.e("Error in generateFaceId: $e");
    throw Exception("Error during face recognition: $e");
  }
}
}