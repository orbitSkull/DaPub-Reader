import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WriterSettingsScreen extends StatefulWidget {
  const WriterSettingsScreen({super.key});

  @override
  State<WriterSettingsScreen> createState() => _WriterSettingsScreenState();
}

class _WriterSettingsScreenState extends State<WriterSettingsScreen> {
  bool _autoSave = true;
  bool _autoCapitalization = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoSave = prefs.getBool('writer_autoSave') ?? true;
      _autoCapitalization = prefs.getBool('writer_autoCapitalization') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('writer_autoSave', _autoSave);
    await prefs.setBool('writer_autoCapitalization', _autoCapitalization);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Studio Settings'),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Writing Behavior', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
          const SizedBox(height: 16),
          Card(
            child: SwitchListTile(
              title: const Text('Auto-Save'),
              subtitle: const Text('Automatically save changes'),
              value: _autoSave,
              onChanged: (val) => setState(() { _autoSave = val; _saveSettings(); }),
              activeColor: Colors.teal,
            ),
          ),
          Card(
            child: SwitchListTile(
              title: const Text('Auto-Capitalization'),
              subtitle: const Text('Capitalize first letter of sentences'),
              value: _autoCapitalization,
              onChanged: (val) => setState(() { _autoCapitalization = val; _saveSettings(); }),
              activeColor: Colors.teal,
            ),
          ),
        ],
      ),
    );
  }
}