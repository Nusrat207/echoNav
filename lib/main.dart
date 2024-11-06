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