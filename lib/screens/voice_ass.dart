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

  // Chat history to display conversation
  List<Map<String, String>> chatHistory = [];

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
        // Only start listening if not speaking
        if (!isSpeaking && !isDisposed) {
          await _startListening();
        }
      },
    );

    // Set up TTS completion handler
    _flutterTts.setCompletionHandler(() {
      if (isDisposed) return;

      setState(() {
        isSpeaking = false;
      });

      // Start listening again after speaking is done, but add a small delay
      // to ensure TTS is fully completed
      Future.delayed(Duration(milliseconds: 500), () {
        if (!isDisposed && !isListening && !isSpeaking && !isProcessing) {
          _startListening();
        }
      });
    });

    // Initial greeting
    setState(() {
      isSpeaking = true;
      // Add initial greeting to chat history
      chatHistory
          .add({'type': 'assistant', 'message': 'How may I help you today?'});
    });

    // Make sure we're not listening while speaking the initial greeting
    _stopListening();
    await _flutterTts.speak("How may I help you today?");
    // Listening will start automatically after TTS completion via the completion handler
  }

  Future<void> _startListening() async {
    // Don't start listening if already listening, speaking, processing, or disposed
    if (isDisposed || isListening || isSpeaking || isProcessing) return;

    try {
      bool available = await _speechToText.initialize();
      if (available) {
        setState(() => isListening = true);

        await _speechToText.listen(
          onResult: (result) {
            // Only update text if we're still listening and not speaking
            if (isListening && !isSpeaking && !isProcessing) {
              setState(() {
                recognizedText = result.recognizedWords;
              });

              // Process final result automatically
              if (result.finalResult && recognizedText.isNotEmpty) {
                _stopListening();
                _processVoiceInput(recognizedText);
              }
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
        if (!isSpeaking && !isProcessing) {
          await _startListening();
        }
      }
    }
  }

  void _stopListening() {
    if (isListening) {
      _speechToText.stop();
      setState(() => isListening = false);
    }
  }

  // Stop the TTS speech
  Future<void> _stopSpeaking() async {
    if (isSpeaking) {
      await _flutterTts.stop();
      setState(() {
        isSpeaking = false;
      });

      // Start listening again after stopping speech
      await _startListening();
    }
  }

  // Format chat history for the backend
  String _formatChatHistoryForBackend() {
    StringBuffer formattedHistory = StringBuffer();

    // Add previous conversations for context
    for (var chat in chatHistory) {
      String role = chat['type'] == 'user' ? 'User' : 'Assistant';
      formattedHistory.write('$role: ${chat['message']}\n');
    }

    return formattedHistory.toString();
  }

  Future<void> _processVoiceInput(String text) async {
    if (text.isEmpty || isProcessing) return;

    // Make sure we're not listening while processing
    _stopListening();

    // Add user message to chat history
    setState(() {
      chatHistory.add({'type': 'user', 'message': text});
      isProcessing = true;
    });

    try {
      // Format chat history for context
      String chatHistoryContext = _formatChatHistoryForBackend();

      // Create the full prompt with chat history and current query
      String fullPrompt = chatHistoryContext + "\nUser: " + text;

      // Send the voice input to the backend
      var url = Uri.parse("http://192.168.0.103:8000/api/ask/voice");
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'prompt': fullPrompt,
          'chat_history':
              chatHistoryContext, // Send chat history separately if needed
        },
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        String aiResponse = data['response'];

        setState(() {
          responseText = aiResponse;
          // Add assistant response to chat history
          chatHistory.add({'type': 'assistant', 'message': aiResponse});
          isProcessing = false;
        });

        // Speak the response
        setState(() {
          isSpeaking = true;
        });

        // Make sure we're not listening while speaking
        _stopListening();
        await _flutterTts.speak(aiResponse);
        // Listening will restart via the TTS completion handler
      } else {
        print("Failed to send request: ${response.statusCode}");
        print("Response body: ${response.body}");

        String errorMsg = "Sorry, I couldn't process your request.";
        setState(() {
          responseText = errorMsg;
          // Add error message to chat history
          chatHistory.add({'type': 'assistant', 'message': errorMsg});
          isProcessing = false;
        });

        // Speak error message
        setState(() {
          isSpeaking = true;
        });

        // Make sure we're not listening while speaking
        _stopListening();
        await _flutterTts.speak(errorMsg);
        // Listening will restart via the TTS completion handler
      }
    } catch (e) {
      print('Error processing voice input: $e');

      String errorMsg = "Sorry, an error occurred.";
      setState(() {
        responseText = errorMsg;
        // Add error message to chat history
        chatHistory.add({'type': 'assistant', 'message': errorMsg});
        isProcessing = false;
      });

      // Speak error message
      setState(() {
        isSpeaking = true;
      });

      // Make sure we're not listening while speaking
      _stopListening();
      await _flutterTts.speak(errorMsg);
      // Listening will restart via the TTS completion handler
    }
  }

  // Manual trigger for sending voice command
  Future<void> _sendVoiceCommand() async {
    if (recognizedText.isNotEmpty && !isProcessing && !isSpeaking) {
      _stopListening();
      await _processVoiceInput(recognizedText);
      // Clear recognized text after processing
      setState(() {
        recognizedText = "";
      });
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
          // Chat history area
          Expanded(
            child: chatHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.mic_none_outlined,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Speak to start a conversation",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: chatHistory.length,
                    reverse: false,
                    itemBuilder: (context, index) {
                      final chat = chatHistory[index];
                      final isUser = chat['type'] == 'user';

                      return Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: isUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              isUser ? "You:" : "Assistant:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? Colors.grey[200]
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Text(
                                chat['message'] ?? '',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Current voice input display
          if (isListening && recognizedText.isNotEmpty)
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.mic, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recognizedText,
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
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

          // Speaking indicator
          if (isSpeaking)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.volume_up, color: Colors.blue),
                  SizedBox(width: 8),
                  Text("Speaking..."),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _stopSpeaking,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      minimumSize: Size(0, 0),
                    ),
                    child: Text("Stop"),
                  ),
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
                  onPressed: isProcessing || isSpeaking
                      ? null
                      : (isListening ? _stopListening : _startListening),
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
                if (isSpeaking)
                  ElevatedButton(
                    onPressed: _stopSpeaking,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16.0),
                      shape: CircleBorder(),
                      backgroundColor: Colors.red,
                    ),
                    child: Icon(
                      Icons.volume_off,
                      size: 30,
                      color: Colors.white,
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

    // Clear the completion handler to prevent it from firing after disposal
    _flutterTts.setCompletionHandler(() {});

    super.dispose();
  }
}
