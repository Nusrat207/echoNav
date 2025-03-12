import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'voice_ass.dart';
import 'object_recognition_screen.dart';
import 'task_management_screen.dart';
import 'freemium_model_screen.dart';
import 'google_maps_screen.dart';
import 'vision_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:first_pro/main.dart';

class SecondPage extends StatefulWidget {
  const SecondPage({super.key});

  @override
  State<SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> with WidgetsBindingObserver {
  bool isListening = false;
  bool isTtsSpeaking = false;
  bool _hasNavigated = false;
  late stt.SpeechToText _speechToText;
  late FlutterTts _flutterTts;
  String text = "Press the button & speak";
  double confidence = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add lifecycle observer
    _speechToText = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initializeTts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove lifecycle observer
    _flutterTts.stop();
    _speechToText.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (state == AppLifecycleState.paused) {
      _flutterTts.stop(); // Stop TTS when app goes to the background
    } else if (state == AppLifecycleState.resumed) {
      _speakOptions(); // Restart TTS when app comes back to the foreground
    }
  }

  Future<void> _initializeTts() async {
    print("Initializing TTS...");
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    print("TTS initialized successfully.");

    // Add a small delay before speaking to ensure TTS is ready
    await Future.delayed(Duration(milliseconds: 500));
    _speakOptions();
  }

  Future<void> _speakOptions() async {
    print("Reached speak options");
    if (isTtsSpeaking) return; // Prevent multiple calls

    isTtsSpeaking = true;
    _hasNavigated = false;

    String optionsText =
        "The features are Voice Assistant, Navigation, Object Recognition, Vision, Task Management, and Freemium Model. Which one would you like to use?";
    print("Speaking: $optionsText");

    await _flutterTts.speak(optionsText);
    await _flutterTts.awaitSpeakCompletion(true);

    print("Speaking done!!!");
    if (isTtsSpeaking) {
      print("Starting voice capture...");
      captureVoice();
    }
  }

  void captureVoice() async {
    if (!isListening && isTtsSpeaking) {
      bool available = await _speechToText.initialize();
      if (available) {
        setState(() => isListening = true);
        _speechToText.listen(
          onResult: (result) {
            setState(() {
              text = result.recognizedWords;
              if (result.hasConfidenceRating && result.confidence > 0) {
                confidence = result.confidence;
              }
              print('Recognized: $text');

              _navigateToFeature(text.toLowerCase(), fromVoiceCommand: true);
            });
          },
        );

        await Future.delayed(Duration(seconds: 6));
        _speechToText.stop();
        setState(() => isListening = false);
      } else {
        print("Speech recognition not available");
      }
    }
  }

  Future<void> _logout() async {
    try {
      _flutterTts.stop();
      _speechToText.stop();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MyHomePage(title: 'Welcome to EchoNav')),
        );
      }
    } catch (e) {
      print('Error during logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error during logout')),
        );
      }
    }
  }

  void _navigateToFeature(String command, {required bool fromVoiceCommand}) {
    if (fromVoiceCommand && _hasNavigated) return;
    _hasNavigated = fromVoiceCommand;

    _speechToText.stop();

    if (command.contains('voice assistant') ||
        command.contains('voice') ||
        command.contains('assistant')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Stt()),
      ).then((_) {
        _hasNavigated = false;
        _speakOptions();
      });
    } else if (command.contains('navigation')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GoogleMapsScreen()),
      ).then((_) {
        _hasNavigated = false;
        _speakOptions();
      });
    } else if (command.contains('object recognition') ||
        command.contains('object') ||
        command.contains('recognition')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ObjectRecognitionScreen()),
      ).then((_) {
        _hasNavigated = false;
        _speakOptions();
      });
    } else if (command.contains('task management') ||
        command.contains('reminder')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TaskManagementScreen()),
      ).then((_) {
        _hasNavigated = false;
        _speakOptions();
      });
    } else if (command.contains('freemium') || command.contains('model') || command.contains('premium') ) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FreemiumModelScreen()),
      ).then((_) {
        _hasNavigated = false;
        _speakOptions();
      });
    } else if (command.contains('vision')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => VisionPage()),
      ).then((_) {
        _hasNavigated = false;
        _speakOptions();
      });
    } else {
      String x = "I didn't understand";
      _flutterTts.speak(x);
      text = "";
      _hasNavigated = false;
    }
  }

  Widget _buildFeatureTile(
      IconData icon, String title, String subtitle, String commandKeyword) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.deepPurple,
          size: 40,
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 17),
        ),
        onTap: () {
          _flutterTts.stop();
          isTtsSpeaking = false;
          _navigateToFeature(commandKeyword, fromVoiceCommand: false);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Explore EchoNav's Tools",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 248, 237, 253),
          ),
        ),
        backgroundColor: const Color(0xFF610A8A),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: Container(
        color: const Color.fromARGB(255, 249, 238, 255),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _buildFeatureTile(
                        Icons.mic,
                        "Voice Assistant",
                        "Convert speech to text or paste content for text-to-speech.",
                        "voice assistant"),
                    _buildFeatureTile(
                        Icons.navigation,
                        "Navigation",
                        "Seamless navigation with voice commands.",
                        "navigation"),
                    _buildFeatureTile(Icons.computer, "Vision",
                        "See your surroundings using AI.", "vision"),
                    _buildFeatureTile(
                        Icons.task,
                        "Reminders and Task Management",
                        "Organize tasks and set reminders",
                        "task management"),
                    _buildFeatureTile(Icons.monetization_on, "Freemium Model",
                        "Enjoy free features or upgrade", "freemium model"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}