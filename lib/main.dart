/*

//this part runs properly. without face recognition 

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
*/


import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:first_pro/screens/second_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter binding is initialized
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
  // Function to check if the user is logged in
  Future<bool> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');
      //await prefs.setString('userId', "abc");
      final userId = prefs.getString('userId');
      return userId != null;
    } catch (e) {
      print('Error accessing SharedPreferences: $e');
      return false;
    }
  }

  // Navigate to the next page based on login status
  void _navigateToNextPage() async {
    bool isLoggedIn = await _checkLoginStatus();

    if (isLoggedIn) {
      // If logged in, navigate to the second page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SecondPage()),
      );
    } else {
      // If not logged in, navigate to the camera screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FaceAuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 210.0,
        title: SizedBox(
          height: 210.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'Welcome to EchoNav',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF610A8A),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Navigate, Detect, and Connect with ease',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.purple[200],
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
            ElevatedButton(
              onPressed: _navigateToNextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF610A8A),
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
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

class FaceAuthScreen extends StatefulWidget {
  @override
  _FaceAuthScreenState createState() => _FaceAuthScreenState();
}

class _FaceAuthScreenState extends State<FaceAuthScreen> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  bool _isLoading = false;
  late FlutterTts _flutterTts;
  Timer? _captureTimer;

  @override
  void initState() {
    super.initState();
    print('Initializing FaceAuthScreen...');
    _initializeCamera();
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    print('Initializing TTS...');
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    print('TTS initialized successfully.');
  }

  Future<void> _initializeCamera() async {
    print('Initializing camera...');
    try {
      final cameras = await availableCameras();
      print('Available cameras: $cameras');
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras[0],
      );
      print('Selected camera: ${frontCamera.name}');
      _cameraController = CameraController(frontCamera, ResolutionPreset.medium);
      _initializeControllerFuture = _cameraController.initialize();
      setState(() {});
      print('Camera initialized successfully.');
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _speak(String text) async {
    print('Speaking: $text');
    await _flutterTts.speak(text);
  }

  Future<void> _processImage() async {
    print('Processing image...');
    setState(() => _isLoading = true);
    try {
      await _initializeControllerFuture;
      print('Taking picture...');
      final image = await _cameraController.takePicture();
      print('Picture taken: ${image.path}');
      final file = File(image.path);

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.0.103:5000/register'),
      );
      request.files.add(await http.MultipartFile.fromPath('image', file.path));
      request.fields['name'] = 'User';

      print('Sending request to server...');
      var response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseBody);
      print('Server response: $jsonResponse');

      if (response.statusCode == 200) {
        final userId = jsonResponse['user_id'] ?? jsonResponse['user']?['id'];
        if (userId != null) {
          print('User ID received: $userId');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', userId);
          print('User ID saved to SharedPreferences.');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SecondPage()),
          );
        } else {
          print('Error: User ID not found in response.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: User ID not found')),
          );
        }
      } else {
        print('Error: ${jsonResponse['error'] ?? 'Unknown error'}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${jsonResponse['error'] ?? 'Unknown error'}')),
        );
      }
    } catch (e) {
      print('Error processing image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
      print('Image processing completed.');
    }
  }

  void _startCaptureTimer() {
    print('Starting 7-second capture timer...');
    _captureTimer = Timer(Duration(seconds: 8), () {
      if (!_isLoading) {
        print('7 seconds elapsed. Capturing image...');
        _processImage();
      }
    });
  }

  @override
  void dispose() {
    print('Disposing FaceAuthScreen resources...');
    _cameraController.dispose();
    _flutterTts.stop();
    _captureTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Face Authentication')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  print('Camera preview ready.');
                  _speak("Stay still for 5 seconds while your face is being captured.");
                  _startCaptureTimer();
                  return CameraPreview(_cameraController);
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _processImage,
        backgroundColor: const Color(0xFF610A8A),
        child: const Icon(Icons.camera, color: Colors.white),
      ),
    );
  }
}

