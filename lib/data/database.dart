import 'package:hive_flutter/hive_flutter.dart';

class TodoDatabase {
  List todoList = [];

  //reference our box
  final _mybox = Hive.box('Mybox');

  //run this method if this is the first time ever opening this app
  void createInitialData() {
    todoList = [
      ["Demo task 1", false],
      ["Demo task 2", false],
    ];
  }

  // load the data from database
  void loadData() {
    todoList = _mybox.get("TASKMANAGER");
  }

  //update the database
  void updateDatabase() {
    _mybox.put("TASKMANAGER", todoList);
  }
}
