import 'package:flutter/material.dart';

class NotesViewTest extends StatefulWidget {
  const NotesViewTest({super.key});

  @override
  State<NotesViewTest> createState() => _NotesViewTestState();
}

class _NotesViewTestState extends State<NotesViewTest> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes Test'),
      ),
      body: const Center(
        child: Text('Notes View Test'),
      ),
    );
  }
}
