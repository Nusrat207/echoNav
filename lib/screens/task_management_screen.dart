import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:first_pro/data/database.dart';
import 'package:first_pro/utils/dialog_box.dart';
import 'package:first_pro/utils/taskM_tile.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TaskManagementScreen extends StatefulWidget {
  const TaskManagementScreen({super.key});

  @override
  State<TaskManagementScreen> createState() => _TaskManagementState();
}

class _TaskManagementState extends State<TaskManagementScreen> {
  // Reference the hive box
  final _mybox = Hive.box('Mybox');
  TodoDatabase db = TodoDatabase();

  // STT and TTS variables
  late stt.SpeechToText _speechToText;
  late FlutterTts _flutterTts;
  bool isListening = false;
  bool isTtsSpeaking = false;
  String recognizedText = "Press the button & speak";
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Text controller
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Initialize Hive data
    if (_mybox.get("TASKMANAGER") == null) {
      db.createInitialData();
    } else {
      db.loadData();
    }

    // Initialize STT and TTS
    _speechToText = stt.SpeechToText();
    _flutterTts = FlutterTts();

    _flutterTts.setCompletionHandler(() async {
      await _playBeepSound();
      _startListening();
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _speechToText.stop();
    super.dispose();
  }

  Future<void> _playBeepSound() async {
    await _audioPlayer.play(AssetSource('assets/sounds/beep.mp3'));
  }

  Future<void> _startListening() async {
    if (!isListening) {
      bool available = await _speechToText.initialize();
      if (available) {
        setState(() => isListening = true);
        _speechToText.listen(
          onResult: (result) {
            setState(() {
              recognizedText = result.recognizedWords;
              if (result.hasConfidenceRating && result.confidence > 0) {
                print('Confidence: ${result.confidence}');
              }
              print('Recognized: $recognizedText');
              _handleVoiceCommand(recognizedText.toLowerCase());
            });
          },
        );
      } else {
        print("Speech recognition not available");
      }
    }
  }

  void _handleVoiceCommand(String command) {
    if (command.contains('add task') || command.contains('create task')) {
      _speak("What is the task?");
      _startListening();
    } else if (command.contains('delete task')) {
      _speak("Which task would you like to delete?");
      _startListening();
    } else if (command.contains('mark task')) {
      _speak("Which task would you like to mark as completed?");
      _startListening();
    } else {
      _speak("I didn't understand. Please try again.");
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
    await _flutterTts.awaitSpeakCompletion(true);
  }

  // Checkbox was tapped
  void checkboxChanged(bool? value, int index) {
    setState(() {
      db.todoList[index][1] = !db.todoList[index][1];
    });
    db.updateDatabase();
  }

  // Save new task
  void saveNewTask() {
    setState(() {
      db.todoList.add([_controller.text, false]);
      _controller.clear();
    });
    Navigator.of(context).pop();
    db.updateDatabase();
  }

  // Create a new task
  void createNewTask() {
    showDialog(
      context: context,
      builder: (context) {
        return DialogBox(
          controller: _controller,
          onSave: saveNewTask,
          onCancel: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  // Delete task
  void deleteTask(BuildContext context, int index) {
    setState(() {
      db.todoList.removeAt(index);
    });
    db.updateDatabase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 238, 255),
      appBar: AppBar(
        title: Text(
          'Task Management',
          style: TextStyle(
            color: Color.fromARGB(255, 248, 237, 253),
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF610A8A),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: createNewTask,
        child: Icon(Icons.add),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: db.todoList.length,
              itemBuilder: (context, index) {
                return TaskMtile(
                  taskName: db.todoList[index][0],
                  taskCompleted: db.todoList[index][1],
                  onChanged: (value) => checkboxChanged(value, index),
                  deleteFunction: (context) => deleteTask(context, index),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _startListening,
              child: Text(isListening ? "Listening..." : "Start Voice Command"),
            ),
          ),
        ],
      ),
    );
  }
}
