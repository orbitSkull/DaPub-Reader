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
  double _defaultSpeechRate = 1.0;
  String _defaultVoice = 'en_US';

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
      _defaultSpeechRate = prefs.getDouble('defaultSpeechRate') ?? 1.0;
      _defaultVoice = prefs.getString('defaultVoice') ?? 'en_US';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _darkMode);
    await prefs.setDouble('defaultFontSize', _defaultFontSize);
    await prefs.setDouble('defaultSpeechRate', _defaultSpeechRate);
    await prefs.setString('defaultVoice', _defaultVoice);
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
        ]),
        _buildSection('Reading', [
          ListTile(
            title: const Text('Default Line Height'),
            subtitle: const Text('Set default line height for reading'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLineHeightDialog(),
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
            title: const Text('Default Voice'),
            subtitle: Text(_defaultVoice),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showVoiceDialog(),
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

  void _showLineHeightDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Line Height'),
        content: const Text('Line height setting coming soon...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showVoiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Voice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English (US)'),
              value: 'en_US',
              groupValue: _defaultVoice,
              onChanged: (value) {
                setState(() => _defaultVoice = value!);
                _saveSettings();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('English (UK)'),
              value: 'en_GB',
              groupValue: _defaultVoice,
              onChanged: (value) {
                setState(() => _defaultVoice = value!);
                _saveSettings();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
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