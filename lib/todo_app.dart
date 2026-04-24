import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAuth.instance.signInAnonymously();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: TodoScreen(), debugShowCheckedModeBanner: false);
  }
}

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  TextEditingController taskController = TextEditingController();
  TextEditingController editController = TextEditingController();
  List<Map<String, dynamic>> tasks = [];
  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  // ✅ Save tasks
  void saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(tasks);
    await prefs.setString("tasks", jsonString);
  }

  // ✅ Load tasks
  void loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString("tasks");

    if (jsonString != null) {
      List decoded = jsonDecode(jsonString);

      setState(() {
        tasks = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    }
  }

  void editTask(int index) {
    editController.text = tasks[index]["title"];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Task"),
          content: TextField(
            controller: editController,
            decoration: const InputDecoration(hintText: "Update task"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  tasks[index]["title"] = editController.text;
                });
                saveTasks();
                editController.clear();
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('My Wish List'),

        titleTextStyle: TextStyle(
          fontFamily: 'FontMain',
          color: Colors.black,
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
        elevation: 2,

        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: taskController,
              decoration: InputDecoration(
                hintText: "Enter Your Wish",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

            SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),

                elevation: 3,
              ),

              onPressed: () {
                String task = taskController.text;
                if (task.isNotEmpty) {
                  setState(() {
                    tasks.add({"title": task, "isDone": false});
                    taskController.clear();
                  });
                  saveTasks();
                }
              },

              child: Text("Add Your Wish Here"),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: tasks.isEmpty
                  ? const Center(
                      child: Text(
                        "No tasks yet ",
                        style: TextStyle(fontSize: 18, color: Colors.blue),
                      ),
                    )
                  : ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Checkbox(
                              value: tasks[index]["isDone"],
                              onChanged: (value) {
                                setState(() {
                                  tasks[index]["isDone"] = value;
                                });
                                saveTasks();
                              },
                            ),
                            title: Text(
                              tasks[index]["title"],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                decoration: tasks[index]["isDone"]
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () {
                                    editTask(index);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      tasks.removeAt(index);
                                    });
                                    saveTasks();
                                  },
                                ),
                              ],
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
}
