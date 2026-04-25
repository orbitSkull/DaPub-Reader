import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  double _defaultFontSize = 16.0;
  double _defaultLineHeight = 1.6;
  double _defaultSpeechRate = 1.0;
  double _defaultPitch = 1.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? false;
      _defaultFontSize = prefs.getDouble('defaultFontSize') ?? 16.0;
      _defaultLineHeight = prefs.getDouble('defaultLineHeight') ?? 1.6;
      _defaultSpeechRate = prefs.getDouble('defaultSpeechRate') ?? 1.0;
      _defaultPitch = prefs.getDouble('defaultPitch') ?? 1.0;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _darkMode);
    await prefs.setDouble('defaultFontSize', _defaultFontSize);
    await prefs.setDouble('defaultLineHeight', _defaultLineHeight);
    await prefs.setDouble('defaultSpeechRate', _defaultSpeechRate);
    await prefs.setDouble('defaultPitch', _defaultPitch);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _buildSection('Appearance', [
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme'),
            value: _darkMode,
            onChanged: (value) {
              setState(() => _darkMode = value);
              _saveSettings();
            },
          ),
          ListTile(
            title: const Text('Default Font Size'),
            subtitle: Text('${_defaultFontSize.toInt()}px'),
            trailing: SizedBox(
              width: 200,
              child: Slider(
                value: _defaultFontSize,
                min: 12,
                max: 32,
                divisions: 10,
                label: '${_defaultFontSize.toInt()}px',
                onChanged: (value) {
                  setState(() => _defaultFontSize = value);
                  _saveSettings();
                },
              ),
            ),
          ),
          ListTile(
            title: const Text('Default Line Height'),
            subtitle: Text(_defaultLineHeight.toStringAsFixed(1)),
            trailing: SizedBox(
              width: 200,
              child: Slider(
                value: _defaultLineHeight,
                min: 1.2,
                max: 2.0,
                divisions: 8,
                label: _defaultLineHeight.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() => _defaultLineHeight = value);
                  _saveSettings();
                },
              ),
            ),
          ),
        ]),
        _buildSection('Text-to-Speech', [
          ListTile(
            title: const Text('Default Speech Rate'),
            subtitle: Text('${_defaultSpeechRate.toStringAsFixed(1)}x'),
            trailing: SizedBox(
              width: 200,
              child: Slider(
                value: _defaultSpeechRate,
                min: 0.5,
                max: 2.0,
                divisions: 6,
                label: '${_defaultSpeechRate.toStringAsFixed(1)}x',
                onChanged: (value) {
                  setState(() => _defaultSpeechRate = value);
                  _saveSettings();
                },
              ),
            ),
          ),
          ListTile(
            title: const Text('Default Pitch'),
            subtitle: Text('${_defaultPitch.toStringAsFixed(1)}'),
            trailing: SizedBox(
              width: 200,
              child: Slider(
                value: _defaultPitch,
                min: 0.5,
                max: 2.0,
                divisions: 6,
                label: _defaultPitch.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() => _defaultPitch = value);
                  _saveSettings();
                },
              ),
            ),
          ),
        ]),
        _buildSection('Storage', [
          ListTile(
            title: const Text('Clear Library'),
            subtitle: const Text('Remove all books from library'),
            trailing: const Icon(Icons.delete_outline, color: Colors.red),
            onTap: () => _showClearLibraryDialog(),
          ),
        ]),
        _buildSection('About', [
          const ListTile(
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
          const ListTile(
            title: Text('Developer'),
            subtitle: Text('DaPub Reader Team'),
          ),
        ]),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  void _showClearLibraryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Library'),
        content: const Text(
            'Are you sure you want to remove all books from your library?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('library');
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Library cleared')),
                );
              }
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}