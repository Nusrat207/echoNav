import 'package:flutter/material.dart';

class ObjectRecognitionScreen extends StatelessWidget {
  const ObjectRecognitionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Object Recognition"),
        backgroundColor: const Color(0xFF610A8A),
      ),
      body: Center(
        child: Text(
          "Welcome to the Object Recognition Feature!",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
