import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TaskManagementScreen extends StatefulWidget {
  const TaskManagementScreen({super.key});

  @override
  State<TaskManagementScreen> createState() => _TaskManagementState();
}

class _TaskManagementState extends State<TaskManagementScreen> {
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ensureUserLoggedIn();
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
  void dispose() {
    _controller.dispose();
    super.dispose();
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: Icon(Icons.add),
      ),
      body: _isLoading
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
    );
  }
}
