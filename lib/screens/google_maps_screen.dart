import 'package:flutter/material.dart';
import '../widgets/google_maps_widget.dart';

class GoogleMapsScreen extends StatefulWidget {
  const GoogleMapsScreen({super.key});

  @override
  State<GoogleMapsScreen> createState() => _GoogleMapsScreenState();
}

class _GoogleMapsScreenState extends State<GoogleMapsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps Screen'),
      ),
      body: FutureBuilder(
        future: _checkMapReady(), // Ensure the map is ready
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading map: ${snapshot.error}'));
          } else {
            return const GoogleMapsWidget(); // Render the map widget
          }
        },
      ),
    );
  }

  Future<bool> _checkMapReady() async {
    // Simulate any pre-requisites check here (like API key validation)
    return true; // Return true if map setup is fine
  }
}
