/*import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart'; 
import 'camera_screen.dart'; 
import 'face_recognition.dart'; 
import 'databse_service.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart'; // Add Supabase
import 'package:first_pro/screens/second_page.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://dsfxxychapttdbtyqltq.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzZnh4eWNoYXB0dGRidHlxbHRxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk1MzIzNjIsImV4cCI6MjA1NTEwODM2Mn0.x8wEiBTwyq99aXOjrR0wjnso8_hSqHt-IuIHhfv4bs8', // Replace with your Supabase anon key
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EchoNav',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 238, 213, 253)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 238, 213, 253),
        ),
        scaffoldBackgroundColor: const Color.fromARGB(255, 238, 213, 253),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Welcome to EchoNav'),
      routes: {
        '/camera': (context) => CameraScreen(), // Add this route
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Timer? _timer;
  final FaceRecognition _faceRecognition = FaceRecognition();
  final DatabaseService _databaseService = DatabaseService();
  final FlutterTts _flutterTts = FlutterTts();
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance(); // Initialize SharedPreferences

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _checkExistingLogin(); // Check for existing login on app launch
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.85); 

  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> _checkExistingLogin() async {
   // _clearSharedPreferences();
    final SharedPreferences prefs = await _prefs;
    final String? storedFaceId = prefs.getString('faceId'); // Retrieve stored Face ID

    if (storedFaceId != null) {
      // User is already logged in
      await _speak("Welcome back! You are already logged in.");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SecondPage()),
      );
    } else {
      // No existing login, start the timer for automatic navigation
      _timer = Timer(const Duration(seconds: 5), () {
        _navigateToCamera();
      });
    }
  }

  Future<void> _navigateToCamera() async {
    await _speak("Please stay still while the camera scans your face");
    await Future.delayed(Duration(seconds: 2));

    final imagePath = await Navigator.pushNamed(context, '/camera');

    if (imagePath != null) {
      try {
        final imagePathString = imagePath.toString();
        print("Image Path: $imagePathString");

        final faceId = await _faceRecognition.generateFaceId(imagePathString);
        print("Generated Face ID: $faceId");

        final isUserExists = await _databaseService.isUserExists(faceId);
        print("Is User Exists: $isUserExists");

        if (isUserExists) {
          // Old user
          //await _speak("Welcome back! You are an existing user.");
          await _storeFaceId(faceId); // Store Face ID locally
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SecondPage()),
          );
        } else {
          // New user
          await _databaseService.addUser(faceId);
          //await _speak("Welcome! You are a new user.");
          await _storeFaceId(faceId); // Store Face ID locally
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SecondPage()),
          );
        }
      } catch (e) {
        print("Error in face recognition: $e");
        await _speak("An error occurred. Please try again.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  Future<void> _storeFaceId(String faceId) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setString('faceId', faceId); // Store Face ID locally
  }

  Future<void> _clearSharedPreferences() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear(); // Clears all data in shared preferences
  print("Shared preferences cleared.");
}

  Future<void> _logout() async {
    final SharedPreferences prefs = await _prefs;
    await prefs.remove('faceId'); // Clear stored Face ID
    await _speak("You have been logged out.");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MyHomePage(title: widget.title)),
    );
  }


   @override
  void dispose() {
    _timer?.cancel();
    _flutterTts.stop(); // Stop TTS when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 210.0,
        title: SizedBox(
          height: 210.0,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Welcome to EchoNav',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF610A8A),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Navigate, Detect, and Connect with ease',
                style: TextStyle(
                  fontSize: 20,
                  color: Color.fromARGB(255, 152, 118, 152),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'assets/image.jpg',
              width: 300,
              height: 401,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                _timer?.cancel();
                _navigateToCamera();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF610A8A),
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                textStyle: const TextStyle(fontSize: 24),
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:first_pro/screens/second_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EchoNav',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 238, 213, 253)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 238, 213, 253),
        ),
        scaffoldBackgroundColor: const Color.fromARGB(255, 238, 213, 253),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Welcome to EchoNav'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer(const Duration(seconds: 5), () {
      _navigateToNextPage();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _navigateToNextPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SecondPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 210.0,
        title: SizedBox(
          height: 210.0,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Welcome to EchoNav',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF610A8A),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Navigate, Detect, and Connect with ease',
                style: TextStyle(
                  fontSize: 20,
                  color: Color.fromARGB(255, 152, 118, 152),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'assets/image.jpg',
              width: 300,
              height: 401,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                _timer?.cancel();
                _navigateToNextPage();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF610A8A),
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                textStyle: const TextStyle(fontSize: 24),
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
