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

  // Voice interaction variables
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isSpeaking = false; // Track when TTS is active
  String _currentCommand = '';
  String _transcription = '';

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _initializeSpeech();
    _ensureUserLoggedIn().then((_) {
      _speakWelcomeMessage();
    });
  }

  // Initialize Text-to-Speech with completion listener
  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // Add listeners to track speaking state
    _flutterTts.setStartHandler(() {
      setState(() => _isSpeaking = true);
      print('TTS: Started speaking');
    });

    _flutterTts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
      print('TTS: Finished speaking');
    });

    _flutterTts.setErrorHandler((error) {
      setState(() => _isSpeaking = false);
      print('TTS Error: $error');
    });
  }

  // Initialize Speech-to-Text
  Future<void> _initializeSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        print('STT Status: $status');
        if (status == 'done') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        print('STT Error: $error');
        setState(() => _isListening = false);
      },
    );
    print('Speech recognition available: $available');
  }

  // Speak welcome message and listen after completion
  Future<void> _speakWelcomeMessage() async {
    const message =
        "Would you like an overview of your tasks, or do you want to add or delete a task?";
    await _speakWithListenAfter(message);
  }

  // Enhanced speak method that prevents conflicts
  Future<void> _speak(String message) async {
    // Don't start speaking if already speaking or listening
    if (_isSpeaking) {
      print('Already speaking, stopping current speech');
      await _flutterTts.stop();
    }

    if (_isListening) {
      print('Currently listening, stopping speech recognition');
      _speech.stop();
      setState(() => _isListening = false);
    }

    print('Speaking: $message');
    await _flutterTts.speak(message);
  }

  // Speak and then listen after a delay
  Future<void> _speakWithListenAfter(String message,
      {int delayMs = 500}) async {
    await _speak(message);

    // Wait for speaking to complete plus a small delay
    await Future.delayed(Duration(milliseconds: delayMs));

    // Only start listening if we're not still speaking
    if (!_isSpeaking) {
      _startListening();
    } else {
      // If still speaking, set up a listener to start after completion
      _flutterTts.setCompletionHandler(() {
        setState(() => _isSpeaking = false);
        _startListening();
      });
    }
  }

  // Start listening with conflict prevention
  void _startListening() {
    // Don't start listening if already listening or speaking
    if (_isListening) {
      print('Already listening');
      return;
    }

    if (_isSpeaking) {
      print('Currently speaking, stopping TTS before listening');
      _flutterTts.stop();
      // Wait a moment for TTS to fully stop
      Future.delayed(Duration(milliseconds: 200), () {
        _activateListening();
      });
    } else {
      _activateListening();
    }
  }

  // Actual listening activation
  void _activateListening() {
    setState(() {
      _isListening = true;
      _transcription = 'Listening...';
    });

    _speech.listen(
      onResult: (result) {
        setState(() {
          _transcription = result.recognizedWords.isEmpty
              ? 'Listening...'
              : result.recognizedWords;
        });

        if (result.finalResult) {
          final recognizedWords = result.recognizedWords;
          print('Recognized: $recognizedWords');

          setState(() {
            _isListening = false;
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

  // Process initial voice command - fixed to prevent duplicate prompts
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

        setState(() {
          _currentCommand = commandType;
          _isLoading = false;
        });

        // Use the same approach for all command types to ensure consistency
        await _speak(responseText);

        // Only start listening for follow-up if it's add or delete
        if (commandType != 'list') {
          // Wait for speaking to complete before listening
          await Future.delayed(Duration(milliseconds: 500));
          if (!_isSpeaking) {
            _startListening();
          } else {
            // If still speaking, wait for completion
            _flutterTts.setCompletionHandler(() {
              setState(() => _isSpeaking = false);
              _startListening();

              // Reset the completion handler to the default
              _flutterTts.setCompletionHandler(() {
                setState(() => _isSpeaking = false);
              });
            });
          }
        } else {
          // For list command, ask if they want to do something else after a delay
          await Future.delayed(Duration(milliseconds: 1000));
          if (!_isSpeaking) {
            await _speakWithListenAfter(
                "Would you like to do something else with your tasks?");
          } else {
            // If still speaking, wait for completion
            _flutterTts.setCompletionHandler(() {
              setState(() => _isSpeaking = false);
              _speakWithListenAfter(
                  "Would you like to do something else with your tasks?");

              // Reset the completion handler to the default
              _flutterTts.setCompletionHandler(() {
                setState(() => _isSpeaking = false);
              });
            });
          }
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

  // Process follow-up voice command - updated to prevent conflicts
  Future<void> _processFollowUpCommand(String command) async {
    setState(() => _isLoading = true);

    try {
      String endpoint;
      String responseMessage;

      if (_currentCommand == 'add') {
        endpoint = 'http://192.168.0.103:8000/api/tasks/command/add';
        final response = await http.post(
          Uri.parse(endpoint),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'task_title': command},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          responseMessage = data['response'];
        } else {
          responseMessage = 'Failed to add task.';
        }
      } else if (_currentCommand == 'delete') {
        endpoint = 'http://192.168.0.103:8000/api/tasks/command/delete';
        final response = await http.post(
          Uri.parse(endpoint),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'task_name': command},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          responseMessage = data['response'];
        } else {
          responseMessage = 'Failed to delete task.';
        }
      } else {
        responseMessage = 'Unknown command.';
      }

      // Refresh tasks after command execution
      await _fetchTasks();

      // Reset current command
      setState(() {
        _currentCommand = '';
        _isLoading = false;
      });

      // Speak confirmation and ask if they want to do something else
      await _speak(responseMessage);

      // Wait a moment before asking the follow-up question
      await Future.delayed(Duration(milliseconds: 1000));

      // Only ask follow-up if not already speaking
      if (!_isSpeaking) {
        await _speakWithListenAfter(
            "Would you like to do something else with your tasks?");
      }
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
            icon: Icon(
              _isListening
                  ? Icons.mic
                  : (_isSpeaking ? Icons.volume_up : Icons.mic_none),
            ),
            onPressed: _startListening,
            color: _isListening
                ? Colors.red
                : (_isSpeaking ? Colors.orange : Colors.blue),
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
                          _isListening
                              ? Icons.mic
                              : (_isSpeaking
                                  ? Icons.volume_up
                                  : Icons.mic_none),
                          color: _isListening
                              ? Colors.red
                              : (_isSpeaking ? Colors.orange : Colors.blue),
                        ),
                        SizedBox(width: 8),
                        Text(
                          _isListening
                              ? 'Listening...'
                              : (_isSpeaking ? 'Speaking...' : 'Voice Input:'),
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
                            ? (_isSpeaking
                                ? 'Speaking...'
                                : 'Tap the microphone to speak')
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
