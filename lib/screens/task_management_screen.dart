import 'package:flutter/material.dart';

class TaskManagementScreen extends StatelessWidget {
  const TaskManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Task Management"),
        backgroundColor: const Color(0xFF610A8A),
      ),
      body: Center(
        child: Text(
          "Welcome to the Task Management Feature!",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
