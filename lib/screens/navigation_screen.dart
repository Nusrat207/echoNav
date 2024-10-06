import 'package:flutter/material.dart';

class NavigationScreen extends StatelessWidget {
  const NavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Navigation"),
        backgroundColor: const Color(0xFF610A8A),
      ),
      body: Center(
        child: Text(
          "Welcome to the Navigation Feature!",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
