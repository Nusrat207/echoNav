import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'voice_assistant_screen.dart';
import 'navigation_screen.dart';
import 'object_recognition_screen.dart';
import 'task_management_screen.dart';
import 'freemium_model_screen.dart';

class SecondPage extends StatefulWidget {
  const SecondPage({super.key});

  @override
  _SecondPageState createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage>
    with SingleTickerProviderStateMixin {
  late FlutterTts flutterTts;
  late stt.SpeechToText speech;
  bool isListening = false;
  bool isSpeaking = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  bool hasSpokenOptions = false;

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    speech = stt.SpeechToText();
    _checkSpeechRecognitionAvailability();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.3).animate(_controller);
    _speakFeatures();
  }

  @override
  void dispose() {
    //flutterTts.stop();
    // speech.stop();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkSpeechRecognitionAvailability() async {
    bool available = await speech.initialize(
      onStatus: (status) => print('Status: $status'),
      onError: (error) => print('Error: ${error.errorMsg}'),
    );
    print('Speech recognition available: $available');
  }

  Future<void> _speakFeatures() async {
    String features =
        "Welcome to EchoNav's Tools. Say 1 for Voice Assistant, say 2 for Navigation, say 3 for Object Recognition, say 4 for Reminders and Task Management, and say 5 for Freemium Model.";
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);

    setState(() {
      isSpeaking = true; 
    });

    await flutterTts.speak(features);

    flutterTts.setCompletionHandler(() async {
      setState(() {
        isSpeaking = false;
      });
      _controller.stop();
      _controller.reset();

      await Future.delayed(const Duration(seconds: 1));
      _listen();
    });
  }

  void _navigateToFeature(String recognizedWords) {
    flutterTts.stop();
    //  speech.stop();
    _controller.dispose();

    switch (recognizedWords) {
      case 'one':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VoiceAssistantScreen()),
        );
        break;
      case 'two':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NavigationScreen()),
        );
        break;
     case 'three':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const ObjectRecognitionScreen()),
        );
        break;
      case 'four':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TaskManagementScreen()),
        );
        break;
      case 'five':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FreemiumModelScreen()),
        );
        break;
      default:
        break;
    }
  }

  void _listen() async {
    if (!isListening) {
      bool available = await speech.initialize(
        onStatus: (status) {
          print('Status: $status');
          setState(() {
            isListening = status == "listening";
          });
        },
        onError: (error) {
          print('Error: ${error.errorMsg}');
        },
      );

      if (available) {
        setState(() {
          isListening = true;
        });

        speech.listen(
          onResult: (result) {
            String recognizedWords = result.recognizedWords.toLowerCase();
            print('Recognized words: $recognizedWords');

            if (result.hasConfidenceRating && result.confidence > 0) {
              print("Confidence: ${result.confidence}");
            }

            if (recognizedWords.isNotEmpty) {
              if (['one', 'two', 'three', 'four', 'five']
                  .contains(recognizedWords)) {
                speech.stop();
                _navigateToFeature(recognizedWords);
              } else {
                print('Unrecognized option: $recognizedWords');
                flutterTts.speak(
                    "I didn't understand that. Please say one, two, three, four, or five.");
              }
            } else {
              print("No words recognized");
            }
          },
          listenFor: Duration(seconds: 8),
          pauseFor: Duration(seconds: 3),
          localeId: 'en_US',
          cancelOnError: true,
        );
      } else {
        print('Speech recognition not available');
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
   // if (!isSpeaking) {
   //   _speakFeatures();
   // }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Explore EchoNav's Tools",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 248, 237, 253),
          ),
        ),
        backgroundColor: const Color(0xFF610A8A),
      ),
      body: Container(
        color: const Color.fromARGB(255, 249, 238, 255),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 50),
            GestureDetector(
              onTap: () {
                if (!isSpeaking) {
                  _listen();
                }
              },
              child: ScaleTransition(
                scale: _animation,
                child: const Icon(
                  Icons.volume_up,
                  size: 130,
                  color: Color(0xFF610A8A),
                ),
              ),
            ),
            const SizedBox(height: 40),
            // const Text(
            //   'Select a feature to explore:',
            //   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            //  ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.mic, color: Colors.deepPurple),
                    title: const Text(
                      'Voice Assistant',
                      style:
                          TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                        'Convert speech to text or paste content for text-to-speech.'),
                    onTap: () => _navigateToFeature('one'),
                  ),
                  const SizedBox(height: 7),
                  ListTile(
                    leading:
                        const Icon(Icons.navigation, color: Colors.deepPurple),
                    title: const Text(
                      'Navigation',
                      style:
                          TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                    ),
                    subtitle:
                        const Text('Seamless navigation with voice commands.'),
                    onTap: () => _navigateToFeature('two'),
                  ),
                  const SizedBox(height: 7),
                  ListTile(
                    leading:
                        const Icon(Icons.computer, color: Colors.deepPurple),
                    title: const Text(
                      'Object Recognition',
                      style:
                          TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                    ),
                    subtitle:
                        const Text('Detect and identify objects using AI.'),
                    onTap: () => _navigateToFeature('three'),
                  ),
                  const SizedBox(height: 7),
                  ListTile(
                    leading: const Icon(Icons.task, color: Colors.deepPurple),
                    title: const Text(
                      'Reminders and Task Management',
                      style:
                          TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Organize tasks and set reminders'),
                    onTap: () => _navigateToFeature('four'),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: const Icon(Icons.monetization_on,
                        color: Colors.deepPurple),
                    title: const Text(
                      'Freemium Model',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Enjoy free features or upgrade'),
                    onTap: () => _navigateToFeature('five'),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

