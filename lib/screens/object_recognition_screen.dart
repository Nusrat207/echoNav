import 'package:flutter/material.dart';

class ObjectRecognitionScreen extends StatefulWidget {
  const ObjectRecognitionScreen({super.key});

  @override
  _ObjectRecognitionScreenState createState() =>
      _ObjectRecognitionScreenState();
}

class _ObjectRecognitionScreenState extends State<ObjectRecognitionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Object Recognition"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            const Text(
              "Object Recognition",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "This is a placeholder for the object recognition feature",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Feature coming soon!")),
                );
              },
              child: const Text("Start Recognition"),
            ),
          ],
        ),
      ),
    );
  }
}
