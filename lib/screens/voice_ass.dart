import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Stt extends StatefulWidget {
  const Stt({super.key});

  @override
  State<Stt> createState() => _Stt();
}

class _Stt extends State<Stt> {
  bool isListening = false;
  bool isSpeaking = false;
  bool isProcessing = false;
  bool isDisposed = false;

  late stt.SpeechToText _speechToText;
  late FlutterTts _flutterTts;

  String recognizedText = "";
  String responseText = "";
  double confidence = 1.0;

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _flutterTts = FlutterTts();

    // Configure TTS
    _flutterTts.setLanguage('en-US');
    _flutterTts.setSpeechRate(0.5);

    // Initialize and start the assistant
    _initializeAssistant();
  }

  Future<void> _initializeAssistant() async {
    await _speechToText.initialize(
      onError: (error) async {
        if (isDisposed) return;

        setState(() => isListening = false);
        print('Speech recognition error: $error');

        await Future.delayed(Duration(seconds: 1));
        await _startListening();
      },
    );

    // Set up TTS completion handler
    _flutterTts.setCompletionHandler(() {
      if (isDisposed) return;

      setState(() {
        isSpeaking = false;
      });

      // Start listening again after speaking is done
      _startListening();
    });

    // Initial greeting
    setState(() {
      isSpeaking = true;
    });

    await _flutterTts.speak("How may I help you today?");
    // Listening will start automatically after TTS completion via the completion handler
  }

  Future<void> _startListening() async {
    if (isDisposed || isListening || isSpeaking || isProcessing) return;

    try {
      bool available = await _speechToText.initialize();
      if (available) {
        setState(() => isListening = true);

        await _speechToText.listen(
          onResult: (result) {
            setState(() {
              recognizedText = result.recognizedWords;
            });

            // Process final result automatically
            if (result.finalResult && recognizedText.isNotEmpty) {
              _stopListening();
              _processVoiceInput(recognizedText);
            }
          },
          listenMode: stt.ListenMode.confirmation,
          cancelOnError: false,
        );
      }
    } catch (e) {
      print('Error starting listening: $e');
      setState(() => isListening = false);

      // Try again after a delay
      if (!isDisposed) {
        await Future.delayed(Duration(seconds: 1));
        await _startListening();
      }
    }
  }

  void _stopListening() {
    if (isListening) {
      _speechToText.stop();
      setState(() => isListening = false);
    }
  }

  Future<void> _processVoiceInput(String text) async {
    if (text.isEmpty || isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    try {
      // Send the voice input to the backend
      var url = Uri.parse("http://192.168.0.103:8000/api/ask/voice");
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'prompt': text,
        },
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        String aiResponse = data['response'];

        setState(() {
          responseText = aiResponse;
          isProcessing = false;
        });

        // Speak the response
        setState(() {
          isSpeaking = true;
        });

        await _flutterTts.speak(aiResponse);
        // Listening will restart via the TTS completion handler
      } else {
        print("Failed to send request: ${response.statusCode}");
        print("Response body: ${response.body}");

        setState(() {
          responseText = "Sorry, I couldn't process your request.";
          isProcessing = false;
        });

        // Speak error message
        setState(() {
          isSpeaking = true;
        });

        await _flutterTts.speak("Sorry, I couldn't process your request.");
        // Listening will restart via the TTS completion handler
      }
    } catch (e) {
      print('Error processing voice input: $e');

      setState(() {
        responseText = "Sorry, an error occurred.";
        isProcessing = false;
      });

      // Speak error message
      setState(() {
        isSpeaking = true;
      });

      await _flutterTts.speak("Sorry, an error occurred.");
      // Listening will restart via the TTS completion handler
    }
  }

  // Manual trigger for sending voice command
  Future<void> _sendVoiceCommand() async {
    if (recognizedText.isNotEmpty && !isProcessing && !isSpeaking) {
      _stopListening();
      await _processVoiceInput(recognizedText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Voice Assistant"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // Main content area
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Voice command display
                    Text(
                      "You said:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        padding: EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          recognizedText.isEmpty
                              ? "Waiting for your voice..."
                              : recognizedText,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Response display
                    Text(
                      "Assistant response:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        padding: EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          responseText.isEmpty
                              ? "I'll respond here..."
                              : responseText,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Status indicator
          if (isProcessing)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 10),
                  Text("Processing..."),
                ],
              ),
            ),

          // Button row
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: isListening || isSpeaking || isProcessing
                      ? _stopListening
                      : _startListening,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16.0),
                    shape: CircleBorder(),
                  ),
                  child: Icon(
                    isListening ? Icons.stop : Icons.mic,
                    size: 30,
                  ),
                ),
                ElevatedButton(
                  onPressed: (!isListening &&
                          !isSpeaking &&
                          !isProcessing &&
                          recognizedText.isNotEmpty)
                      ? _sendVoiceCommand
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16.0),
                    shape: CircleBorder(),
                  ),
                  child: Icon(
                    Icons.send,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    isDisposed = true;
    _speechToText.cancel();
    _flutterTts.stop();
    super.dispose();
  }
}
