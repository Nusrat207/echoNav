import 'package:flutter/material.dart';

class VoiceAssistantScreen extends StatelessWidget {
  const VoiceAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Voice Assistant"),
        backgroundColor: const Color(0xFF610A8A),
      ),
      body: const Center(
        child: Text(
          "Welcome to the Voice Assistant Feature!",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
