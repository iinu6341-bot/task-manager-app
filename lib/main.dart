import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:my_first_project/onboarding_screen.dart';
import 'package:my_first_project/widgets/home_screen.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'onboarding_screen.dart';
import 'package:my_first_project/widgets/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: LoginScreen(), debugShowCheckedModeBanner: false);
  }
}

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final TextEditingController controller = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addTodo(String title) async {
    await _firestore.collection('todos').add({
      'title': title,
      'createdAt': FieldValue.serverTimestamp(),
      'isDone': false,
    });
  }

  Future<void> deleteTodo(String id) async {
    await _firestore.collection('todos').doc(id).delete();
  }

  Future<void> updateTodo(String id, String newTitle) async {
    await _firestore.collection('todos').doc(id).update({'title': newTitle});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Firebase Todo App")),
      body: Column(
        children: [
          // INPUT BOX
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "Enter task",
                border: OutlineInputBorder(),
              ),
            ),
          ),

          // ADD BUTTON
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                addTodo(controller.text);
                controller.clear();
              }
            },
            child: const Text("Add Todo"),
          ),

          const SizedBox(height: 10),

          // FIREBASE LIST (THIS REPLACES YOUR OLD ListView.builder)
          Expanded(
            child: StreamBuilder(
              stream: _firestore
                  .collection('todos')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tasks = snapshot.data!.docs;

                if (tasks.isEmpty) {
                  return const Center(child: Text("No tasks yet"));
                }

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: Checkbox(
                          value:
                              (task.data() as Map<String, dynamic>)['isDone'] ??
                              false,
                          onChanged: (value) {
                            _firestore.collection('todos').doc(task.id).update({
                              'isDone': value,
                            });
                          },
                        ),

                        title: Text(
                          task['title'],
                          style: TextStyle(
                            decoration:
                                ((task.data()
                                        as Map<String, dynamic>)['isDone'] ??
                                    false)
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),

                        // DELETE BUTTON
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ✏️ EDIT BUTTON
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                TextEditingController editController =
                                    TextEditingController(text: task['title']);

                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text("Edit Todo"),
                                      content: TextField(
                                        controller: editController,
                                        decoration: const InputDecoration(
                                          labelText: "Update task",
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text("Cancel"),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            updateTodo(
                                              task.id,
                                              editController.text,
                                            );
                                            Navigator.pop(context);
                                          },
                                          child: const Text("Save"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),

                            // ❌ DELETE BUTTON
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                deleteTodo(task.id);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
