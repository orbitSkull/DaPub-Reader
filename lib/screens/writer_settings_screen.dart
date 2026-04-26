import 'package:flutter/material.dart';

class WriterSettingsScreen extends StatefulWidget {
  const WriterSettingsScreen({super.key});

  @override
  State<WriterSettingsScreen> createState() => _WriterSettingsScreenState();
}

class _WriterSettingsScreenState extends State<WriterSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Studio Settings'),
        backgroundColor: Colors.teal,
      ),
      body: const Center(
        child: Text('Settings coming soon', style: TextStyle(color: Colors.teal)),
      ),
    );
  }
}