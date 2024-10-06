import 'package:flutter/material.dart';

class FreemiumModelScreen extends StatelessWidget {
  const FreemiumModelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Freemium Model"),
        backgroundColor: const Color(0xFF610A8A),
      ),
      body: Center(
        child: Text(
          "Welcome to the Freemium Model Feature!",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
