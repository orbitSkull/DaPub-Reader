import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:piper_tts_plugin/enums/piper_voice_pack.dart';
import 'package:piper_tts_plugin/piper_tts_plugin.dart';

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
  PiperVoicePack _selectedVoice = PiperVoicePack.norman;
  bool _isLoadingVoice = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final voiceIndex = prefs.getInt('selectedVoice') ?? PiperVoicePack.norman.index;
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? false;
      _defaultFontSize = prefs.getDouble('defaultFontSize') ?? 16.0;
      _defaultLineHeight = prefs.getDouble('defaultLineHeight') ?? 1.6;
      _defaultSpeechRate = prefs.getDouble('defaultSpeechRate') ?? 1.0;
      _defaultPitch = prefs.getDouble('defaultPitch') ?? 1.0;
      _selectedVoice = PiperVoicePack.values[voiceIndex];
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _darkMode);
    await prefs.setDouble('defaultFontSize', _defaultFontSize);
    await prefs.setDouble('defaultLineHeight', _defaultLineHeight);
    await prefs.setDouble('defaultSpeechRate', _defaultSpeechRate);
    await prefs.setDouble('defaultPitch', _defaultPitch);
    await prefs.setInt('selectedVoice', _selectedVoice.index);
  }

  Future<void> _downloadVoiceModel() async {
    setState(() => _isLoadingVoice = true);
    try {
      final tts = PiperTtsPlugin();
      await tts.loadViaVoicePack(_selectedVoice);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_selectedVoice.name} voice model loaded!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading voice: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingVoice = false);
    }
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
            title: const Text('Voice Model'),
            subtitle: Text(_selectedVoice.name),
            trailing: const Icon(Icons.arrow_drop_down),
            onTap: () => _showVoiceSelector(),
          ),
          ListTile(
            title: const Text('Download/Load Voice'),
            subtitle: _isLoadingVoice
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Tap to download voice model'),
            trailing: _isLoadingVoice
                ? null
                : ElevatedButton(
                    onPressed: _downloadVoiceModel,
                    child: const Text('Download'),
                  ),
          ),
          const Divider(),
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

  void _showVoiceSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: PiperVoicePack.values.map((voice) {
          return ListTile(
            title: Text(voice.name),
            trailing: _selectedVoice == voice
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              setState(() => _selectedVoice = voice);
              _saveSettings();
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }
}