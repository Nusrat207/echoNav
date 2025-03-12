import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class MyButtons extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  const MyButtons({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  State<MyButtons> createState() => _MyButtonsState();
}

class _MyButtonsState extends State<MyButtons> {
  late stt.SpeechToText _speechToText;
  late FlutterTts _flutterTts;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _flutterTts = FlutterTts();
  }

  Future<void> _startListening() async {
    if (!_isListening) {
      bool available = await _speechToText.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speechToText.listen(
          onResult: (result) {
            setState(() {
              _handleVoiceCommand(result.recognizedWords.toLowerCase());
            });
          },
        );
      } else {
        print("Speech recognition not available");
      }
    }
  }

  Future<void> _stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
  }

  void _handleVoiceCommand(String command) {
    if (command.contains(widget.text.toLowerCase())) {
      // If the voice command matches the button's text, trigger the onPressed action
      widget.onPressed();
      _speak("Button pressed: ${widget.text}");
    } else {
      _speak("I didn't understand. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Button
        MaterialButton(
          onPressed: () {
            widget.onPressed();
            _speak("Button pressed: ${widget.text}");
          },
          color: Theme.of(context).primaryColor,
          child: Text(widget.text),
        ),

        // Microphone Icon for Voice Commands
        IconButton(
          icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
          onPressed: () {
            if (_isListening) {
              _stopListening();
            } else {
              _startListening();
            }
          },
        ),
      ],
    );
  }
}
