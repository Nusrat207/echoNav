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
          title: Text(
            'Add New Task',
            style: TextStyle(
              color: Colors.indigo.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Enter task...',
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.indigo, width: 2),
              ),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  _addTask(_controller.text);
                  _controller.clear();
                  Navigator.of(context).pop();
                }
              },
              child: Text('Add Task'),
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
        title: Text(
          'Task Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchTasks,
            tooltip: 'Refresh Tasks',
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
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red,
                      ),
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
            tooltip: 'Delete All Tasks',
          ),
          IconButton(
            icon: Icon(
              _isListening
                  ? Icons.mic
                  : (_isSpeaking ? Icons.volume_up : Icons.mic_none),
            ),
            onPressed: _restartListening,
            color: _isListening
                ? Colors.red
                : (_isSpeaking ? Colors.orange : Colors.white),
            tooltip: _isListening ? 'Listening...' : 'Speak a command',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: Icon(Icons.add),
        backgroundColor: Colors.indigo,
        tooltip: 'Add Task',
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            // TRANSCRIPTION CARD - Enhanced design
            Container(
              width: double.infinity,
              margin: EdgeInsets.fromLTRB(16, 16, 16, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Voice status header
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _isListening
                          ? Colors.red.shade50
                          : (_isSpeaking
                              ? Colors.orange.shade50
                              : Colors.indigo.shade50),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      border: Border.all(
                        color: _isListening
                            ? Colors.red.shade200
                            : (_isSpeaking
                                ? Colors.orange.shade200
                                : Colors.indigo.shade200),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isListening
                              ? Icons.mic
                              : (_isSpeaking
                                  ? Icons.volume_up
                                  : Icons.mic_none),
                          color: _isListening
                              ? Colors.red
                              : (_isSpeaking ? Colors.orange : Colors.indigo),
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          _isListening
                              ? 'Listening...'
                              : (_isSpeaking
                                  ? 'Speaking...'
                                  : 'Voice Assistant'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _isListening
                                ? Colors.red.shade700
                                : (_isSpeaking
                                    ? Colors.orange.shade700
                                    : Colors.indigo.shade700),
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
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor: _currentCommand == 'add'
                                    ? Colors.green
                                    : _currentCommand == 'delete'
                                        ? Colors.red
                                        : Colors.blue,
                                padding: EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Transcription content
                  Container(
                    padding: EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transcription:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(12),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
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
                                  ? Colors.grey.shade400
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Task list header
            Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Tasks',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade800,
                    ),
                  ),
                  Text(
                    '${_tasks.length} ${_tasks.length == 1 ? 'task' : 'tasks'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Task list with improved styling
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Colors.indigo,
                      ),
                    )
                  : _tasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.task_alt,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No tasks yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Add a task to get started',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _tasks.length,
                          itemBuilder: (context, index) {
                            final task = _tasks[index];
                            return Card(
                              elevation: 1,
                              margin: EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.indigo.shade100,
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: Colors.indigo.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  task['title'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Colors.red.shade400,
                                  ),
                                  onPressed: () => _deleteTask(task['id']),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  // New method to restart listening regardless of current state
  void _restartListening() async {
    // If speaking, stop it
    if (_isSpeaking) {
      print('Stopping current speech to restart listening');
      await _flutterTts.stop();

      // Wait a moment for TTS to fully stop
      await Future.delayed(Duration(milliseconds: 200));
    }

    // If already listening, stop it first
    if (_isListening) {
      print('Stopping current listening to restart');
      _speech.stop();
      setState(() => _isListening = false);

      // Wait a moment for STT to fully stop
      await Future.delayed(Duration(milliseconds: 200));
    }

    // Reset current command if any
    if (_currentCommand.isNotEmpty) {
      print('Resetting current command: $_currentCommand');
      setState(() => _currentCommand = '');
    }

    // Clear transcription
    setState(() => _transcription = '');

    // Start fresh listening
    print('Starting fresh listening session');
    _activateListening();
  }
}
