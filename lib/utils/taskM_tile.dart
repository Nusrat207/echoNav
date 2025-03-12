import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class TaskMtile extends StatefulWidget {
  final String taskName;
  final bool taskCompleted;
  final Function(bool?)? onChanged;
  final Function(BuildContext)? deleteFunction;

  const TaskMtile({
    super.key,
    required this.taskName,
    required this.taskCompleted,
    required this.onChanged,
    required this.deleteFunction,
  });

  @override
  State<TaskMtile> createState() => _TaskMtileState();
}

class _TaskMtileState extends State<TaskMtile> {
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
    if (command.contains('complete') || command.contains('mark as done')) {
      // Mark task as completed
      widget.onChanged?.call(!widget.taskCompleted);
      _speak("Task marked as completed: ${widget.taskName}");
    } else if (command.contains('delete') || command.contains('remove')) {
      // Delete the task
      widget.deleteFunction?.call(context);
      _speak("Task deleted: ${widget.taskName}");
    } else {
      _speak("I didn't understand. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 25.0, right: 25, top: 25),
      child: Slidable(
        endActionPane: ActionPane(
          motion: ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (context) {
                widget.deleteFunction?.call(context);
                _speak("Task deleted: ${widget.taskName}");
              },
              icon: Icons.delete,
              backgroundColor: Colors.red.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        child: GestureDetector(
          onLongPress: _startListening,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 232, 180, 241),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Checkbox
                Checkbox(
                  value: widget.taskCompleted,
                  onChanged: (value) {
                    widget.onChanged?.call(value);
                    _speak("Task marked as completed: ${widget.taskName}");
                  },
                  activeColor: Colors.black,
                ),

                // Task Name
                Expanded(
                  child: Text(
                    widget.taskName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      decoration: widget.taskCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
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
            ),
          ),
        ),
      ),
    );
  }
}
