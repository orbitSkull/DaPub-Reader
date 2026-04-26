import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/reader_settings.dart';
import '../services/tts_service.dart';

class WriterSettingsScreen extends StatefulWidget {
  const WriterSettingsScreen({super.key});

  @override
  State<WriterSettingsScreen> createState() => _WriterSettingsScreenState();
}

class _WriterSettingsScreenState extends State<WriterSettingsScreen> {
  bool _autoSave = true;
  bool _autoCapitalization = true;
  int _themeMode = 0;
  int _fontStyle = 0;
  int _lineSpacing = 1;
  int _textAlign = 0;

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
      _themeMode = prefs.getInt('writer_themeMode') ?? 0;
      _fontStyle = prefs.getInt('writer_fontStyle') ?? 0;
      _lineSpacing = prefs.getInt('writer_lineSpacing') ?? 1;
      _textAlign = prefs.getInt('writer_textAlign') ?? 0;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('writer_autoSave', _autoSave);
    await prefs.setBool('writer_autoCapitalization', _autoCapitalization);
    await prefs.setInt('writer_themeMode', _themeMode);
    await prefs.setInt('writer_fontStyle', _fontStyle);
    await prefs.setInt('writer_lineSpacing', _lineSpacing);
    await prefs.setInt('writer_textAlign', _textAlign);
  }

  String _getThemeLabel(int mode) {
    switch (mode) {
      case 0:
        return 'Light';
      case 1:
        return 'Dark';
      case 2:
        return 'Sepia';
      default:
        return 'Light';
    }
  }

  String _getFontLabel(int style) {
    switch (style) {
      case 0:
        return 'Sans';
      case 1:
        return 'Serif';
      default:
        return 'Sans';
    }
  }

  String _getSpacingLabel(int space) {
    switch (space) {
      case 0:
        return 'Single';
      case 1:
        return '1.5';
      case 2:
        return 'Double';
      default:
        return '1.5';
    }
  }

  String _getAlignLabel(int align) {
    switch (align) {
      case 0:
        return 'Left';
      case 1:
        return 'Justify';
      default:
        return 'Left';
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ReaderSettings>();
    final tts = Provider.of<TtsService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Studio Settings'),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('Editor Appearance'),
          _optionCard('Theme', _getThemeLabel(_themeMode), Icons.brightness_6, _chipRow([
            _chip('Light', _themeMode == 0, () => setState(() { _themeMode = 0; _saveSettings(); })),
            _chip('Dark', _themeMode == 1, () => setState(() { _themeMode = 1; _saveSettings(); })),
            _chip('Sepia', _themeMode == 2, () => setState(() { _themeMode = 2; _saveSettings(); })),
          ])),
          _optionCard('Font Size', '${settings.fontSize.toInt()}', Icons.format_size, Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.remove), onPressed: () { settings.decreaseFontSize(); _saveSettings(); }),
              Text('${settings.fontSize.toInt()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.add), onPressed: () { settings.increaseFontSize(); _saveSettings(); }),
            ],
          )),
          _optionCard('Font Style', _getFontLabel(_fontStyle), Icons.font_download, _chipRow([
            _chip('Sans', _fontStyle == 0, () => setState(() { _fontStyle = 0; settings.setFontFamily('Sans'); _saveSettings(); })),
            _chip('Serif', _fontStyle == 1, () => setState(() { _fontStyle = 1; settings.setFontFamily('Serif'); _saveSettings(); })),
          ])),
          _optionCard('Line Spacing', _getSpacingLabel(_lineSpacing), Icons.format_line_spacing, _chipRow([
            _chip('1', _lineSpacing == 0, () => setState(() { _lineSpacing = 0; settings.setLineHeight(1.0); _saveSettings(); })),
            _chip('1.5', _lineSpacing == 1, () => setState(() { _lineSpacing = 1; settings.setLineHeight(1.5); _saveSettings(); })),
            _chip('2', _lineSpacing == 2, () => setState(() { _lineSpacing = 2; settings.setLineHeight(2.0); _saveSettings(); })),
          ])),
          _optionCard('Text Alignment', _getAlignLabel(_textAlign), Icons.format_align_left, _chipRow([
            _chip('Left', _textAlign == 0, () => setState(() { _textAlign = 0; _saveSettings(); })),
            _chip('Justify', _textAlign == 1, () => setState(() { _textAlign = 1; _saveSettings(); })),
          ])),
          _sectionHeader('Writing Behavior'),
          _switchTile('Auto-Save', 'Automatically save changes', _autoSave, (val) => setState(() { _autoSave = val; _saveSettings(); })),
          _switchTile('Auto-Capitalization', 'Capitalize first letter of sentences', _autoCapitalization, (val) => setState(() { _autoCapitalization = val; _saveSettings(); })),
          _switchTile('Show Word Count', 'Display live word counter', settings.showWordCount, (val) => setState(() { settings.setShowWordCount(val); _saveSettings(); })),
          _switchTile('Focus Mode', 'Hide status bar and UI', settings.focusMode, (val) => setState(() { settings.setFocusMode(val); _saveSettings(); })),
          _switchTile('Typewriter Scrolling', 'Keep current line centered', settings.typewriterScrolling, (val) => setState(() { settings.setTypewriterScrolling(val); _saveSettings(); })),
          _sectionHeader('TTS Settings'),
          _sliderTile('Reading Speed', '${tts.speechRate.toStringAsFixed(2)}x', Icons.speed, tts.speechRate, 0.1, 4.0, tts.setSpeechRate),
          _sliderTile('Voice Pitch', tts.pitch.toStringAsFixed(1), Icons.record_voice_over, tts.pitch, 0.5, 2.0, tts.setPitch),
          _sliderTile('Pause at Period', '${tts.sentencePause}ms', Icons.pause_circle, tts.sentencePause.toDouble(), 0, 2000, (val) => tts.setSentencePause(val.toInt())),
          _switchTile('Highlight Spoken Word', 'Highlight text as TTS reads', tts.highlightSpokenWord, tts.setHighlightSpokenWord),
          _switchTile('Continuous Play', 'Auto move to next chapter', tts.continuousPlay, tts.setContinuousPlay),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 16),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
    );
  }

  Widget _optionCard(String title, String value, IconData icon, Widget trailing) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal),
        title: Text(title),
        trailing: trailing,
      ),
    );
  }

  Widget _switchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.teal,
      ),
    );
  }

  Widget _sliderTile(String title, String value, IconData icon, double current, double min, double max, Function(double) onChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.teal),
                const SizedBox(width: 16),
                Text(title),
                const Spacer(),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            Slider(
              value: current,
              min: min,
              max: max,
              activeColor: Colors.teal,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipRow(List<Widget> children) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: children),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: Colors.teal[200],
      ),
    );
  }
}