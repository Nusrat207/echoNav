import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class TaskManagementScreen extends StatefulWidget {
  const TaskManagementScreen({super.key});

  @override
  State<TaskManagementScreen> createState() => _TaskManagementState();
}

class _TaskManagementState extends State<TaskManagementScreen> {
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;
  final _controller = TextEditingController();

  // Add these new variables for voice interaction
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _currentCommand = '';

  // Add this variable to store the transcription
  String _transcription = '';

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _initializeSpeech();
    _ensureUserLoggedIn().then((_) {
      // Welcome message after user is logged in and tasks are loaded
      _speakWelcomeMessage();
    });
  }

  // Initialize Text-to-Speech
  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  // Initialize Speech-to-Text
  Future<void> _initializeSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        print('Speech recognition status: $status');
        if (status == 'done') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        print('Speech recognition error: $error');
        setState(() => _isListening = false);
      },
    );
    print('Speech recognition available: $available');
  }

  // Speak welcome message
  Future<void> _speakWelcomeMessage() async {
    const message =
        "Would you like an overview of your tasks, or do you want to add or delete a task?";
    await _speak(message);
    // Start listening after speaking
    Future.delayed(Duration(milliseconds: 500), () {
      _startListening();
    });
  }

  // Speak a message
  Future<void> _speak(String message) async {
    await _flutterTts.speak(message);
  }

  // Start listening for voice input - updated to show transcription
  void _startListening() {
    if (!_isListening) {
      setState(() {
        _isListening = true;
        _transcription = 'Listening...'; // Set initial state
      });

      _speech.listen(
        onResult: (result) {
          setState(() {
            // Update transcription in real-time
            _transcription = result.recognizedWords.isEmpty
                ? 'Listening...'
                : result.recognizedWords;
          });

          if (result.finalResult) {
            final recognizedWords = result.recognizedWords;
            print('Recognized: $recognizedWords');

            setState(() {
              _isListening = false;
              // Keep the final transcription visible
              _transcription = recognizedWords;
            });

            if (_currentCommand.isEmpty) {
              _processInitialCommand(recognizedWords);
            } else {
              _processFollowUpCommand(recognizedWords);
            }
          }
        },
      );
    }
  }

  // Process initial voice command
  Future<void> _processInitialCommand(String command) async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://192.168.0.103:8000/api/tasks/command'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'command': command},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final responseText = data['response'];
        final commandType = data['command'];

        // Speak the response
        await _speak(responseText);

        // Store the command type for follow-up
        setState(() {
          _currentCommand = commandType;
          _isLoading = false;
        });

        // If it's a list command, we're done
        if (commandType != 'list') {
          // For add or delete, we need to listen for follow-up
          Future.delayed(Duration(milliseconds: 500), () {
            _startListening();
          });
        }
      } else {
        print('Failed to process command: ${response.body}');
        setState(() => _isLoading = false);
        await _speak('Sorry, I had trouble understanding that command.');
      }
    } catch (e) {
      print('Error processing command: $e');
      setState(() => _isLoading = false);
      await _speak('Sorry, there was an error processing your command.');
    }
  }

  // Process follow-up voice command
  Future<void> _processFollowUpCommand(String command) async {
    setState(() => _isLoading = true);

    try {
      String endpoint;

      if (_currentCommand == 'add') {
        endpoint = 'http://192.168.0.103:8000/api/tasks/command/add';
        await http.post(
          Uri.parse(endpoint),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'task_title': command},
        );
      } else if (_currentCommand == 'delete') {
        endpoint = 'http://192.168.0.103:8000/api/tasks/command/delete';
        await http.post(
          Uri.parse(endpoint),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'task_name': command},
        );
      }

      // Refresh tasks after command execution
      await _fetchTasks();

      // Reset current command
      setState(() {
        _currentCommand = '';
        _isLoading = false;
      });

      // Speak confirmation
      if (_currentCommand == 'add') {
        await _speak('Task added successfully.');
      } else if (_currentCommand == 'delete') {
        await _speak('Task deleted successfully.');
      }

      // Ask if they want to do something else
      Future.delayed(Duration(milliseconds: 500), () {
        _speak("Would you like to do something else with your tasks?");
        Future.delayed(Duration(milliseconds: 500), () {
          _startListening();
        });
      });
    } catch (e) {
      print('Error processing follow-up command: $e');
      setState(() {
        _currentCommand = '';
        _isLoading = false;
      });
      await _speak('Sorry, there was an error processing your request.');
    }
  }

  // Ensure user is logged in before fetching tasks
  Future<void> _ensureUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId != null) {
      // Send login request to ensure current_user_id is set on backend
      await _loginUser(userId);
      // Then fetch tasks
      await _fetchTasks();
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ID not found. Please log in first.')),
      );
    }
  }

  // Login user to set current_user_id on backend
  Future<void> _loginUser(String userId) async {
    try {
      var formData = {
        'user_id': userId,
      };

      final response = await http.post(
        Uri.parse('http://192.168.0.103:8000/api/login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: formData,
      );

      if (response.statusCode != 200) {
        print('Failed to login: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to login')),
        );
      }
    } catch (e) {
      print('Error logging in: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging in: $e')),
      );
    }
  }

  // Fetch tasks from backend
  Future<void> _fetchTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://192.168.0.103:8000/api/tasks'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _tasks = List<Map<String, dynamic>>.from(data['tasks']);
          _isLoading = false;
        });
      } else {
        print('Failed to load tasks: ${response.body}');
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load tasks')),
        );
      }
    } catch (e) {
      print('Error fetching tasks: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading tasks: $e')),
      );
    }
  }

  // Add a new task
  Future<void> _addTask(String title) async {
    if (title.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      var formData = {
        'task_title': title,
      };

      final response = await http.post(
        Uri.parse('http://192.168.0.103:8000/api/tasks/add'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: formData,
      );

      if (response.statusCode == 200) {
        await _fetchTasks(); // Refresh the task list
      } else {
        print('Failed to add task: ${response.body}');
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add task')),
        );
      }
    } catch (e) {
      print('Error adding task: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding task: $e')),
      );
    }
  }

  // Delete a task
  Future<void> _deleteTask(int taskId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.delete(
        Uri.parse('http://192.168.0.103:8000/api/tasks/$taskId'),
      );

      if (response.statusCode == 200) {
        await _fetchTasks(); // Refresh the task list
      } else {
        print('Failed to delete task: ${response.body}');
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete task')),
        );
      }
    } catch (e) {
      print('Error deleting task: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting task: $e')),
      );
    }
  }

  // Delete all tasks
  Future<void> _deleteAllTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.delete(
        Uri.parse('http://192.168.0.103:8000/api/tasks'),
      );

      if (response.statusCode == 200) {
        await _fetchTasks(); // Refresh the task list
      } else {
        print('Failed to delete all tasks: ${response.body}');
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete all tasks')),
        );
      }
    } catch (e) {
      print('Error deleting all tasks: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting all tasks: $e')),
      );
    }
  }

  // Create a new task dialog
  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Task'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Enter task...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  _addTask(_controller.text);
                  _controller.clear();
                  Navigator.of(context).pop();
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchTasks,
          ),
          IconButton(
            icon: Icon(Icons.delete_sweep),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Delete All Tasks'),
                  content: Text('Are you sure you want to delete all tasks?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        _deleteAllTasks();
                        Navigator.of(context).pop();
                      },
                      child: Text('Delete All'),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
            onPressed: _startListening,
            color: _isListening ? Colors.red : null,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: Icon(Icons.add),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // TRANSCRIPTION CARD - Very visible at the top
              Container(
                width: double.infinity,
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening ? Colors.red : Colors.blue,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Voice Input:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (_currentCommand.isNotEmpty)
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Chip(
                                label: Text(
                                  _currentCommand.toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: _currentCommand == 'add'
                                    ? Colors.green
                                    : _currentCommand == 'delete'
                                        ? Colors.red
                                        : Colors.blue,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        _transcription.isEmpty
                            ? 'Tap the microphone to speak'
                            : _transcription,
                        style: TextStyle(
                          fontSize: 18,
                          color: _transcription.isEmpty
                              ? Colors.grey
                              : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Task list - now in an Expanded widget to take remaining space
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _tasks.isEmpty
                        ? Center(child: Text('No tasks yet. Add some!'))
                        : ListView.builder(
                            itemCount: _tasks.length,
                            itemBuilder: (context, index) {
                              final task = _tasks[index];
                              return ListTile(
                                title: Text(task['title']),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () => _deleteTask(task['id']),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _flutterTts.stop();
    super.dispose();
  }
}
