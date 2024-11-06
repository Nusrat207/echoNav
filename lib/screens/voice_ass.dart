import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart'; // Import flutter_tts
import 'package:flutter/material.dart';

class Stt extends StatefulWidget {
  const Stt({super.key});

  @override
  State<Stt> createState() => _Stt();
}

class _Stt extends State<Stt> {
  bool isListening = false;
  late stt.SpeechToText _speechToText;
  late FlutterTts _flutterTts; // TTS instance using flutter_tts
  String text = "Press the button & speak";
  double confidence = 1.0;

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _flutterTts = FlutterTts(); // Initialize flutter_tts

    // Speak the initial message when the page opens
    _speakAndStartListening();
  }

  Future<void> _speakAndStartListening() async {
    await _flutterTts.speak("You can speak now"); // Speak the message

    // Wait for TTS to complete speaking
    await Future.delayed(Duration(seconds: 2));

    // Start listening automatically
    captureVoice();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Speech to Text"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: captureVoice,
        child: Icon(
          isListening ? Icons.mic : Icons.mic_none,
          size: 30,
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        reverse: true,
        child: Container(
          padding: EdgeInsets.all(30),
          child: Column(
            children: [Text(text)],
          ),
        ),
      ),
    );
  }

  void captureVoice() async {
    if (!isListening) {
      bool available = await _speechToText.initialize();
      if (available) {
        setState(() => isListening = true);
        _speechToText.listen(
          onResult: (result) => setState(() {
            text = result.recognizedWords;
            if (result.hasConfidenceRating && result.confidence > 0) {
              confidence = result.confidence;
            }
          }),
        );
      }
    } else {
      setState(() => isListening = false);
      _speechToText.stop();
    }
  }
}
