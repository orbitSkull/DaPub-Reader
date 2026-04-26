import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReaderSettings extends ChangeNotifier {
  double _fontSize = 16.0;
  double _lineHeight = 1.6;
  String _fontFamily = 'Serif';
  bool _darkMode = false;
  bool? _showWordCount;
  bool? _focusMode;
  bool? _typewriterScrolling;

  double get fontSize => _fontSize;
  double get lineHeight => _lineHeight;
  String get fontFamily => _fontFamily;
  bool get darkMode => _darkMode;
  bool get showWordCount => _showWordCount ?? true;
  bool get focusMode => _focusMode ?? false;
  bool get typewriterScrolling => _typewriterScrolling ?? false;

  ReaderSettings() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble('defaultFontSize') ?? 16.0;
    _lineHeight = prefs.getDouble('defaultLineHeight') ?? 1.6;
    _darkMode = prefs.getBool('darkMode') ?? false;
    _showWordCount = prefs.getBool('writer_showWordCount');
    _focusMode = prefs.getBool('writer_focusMode');
    _typewriterScrolling = prefs.getBool('writer_typewriterScrolling');
    notifyListeners();
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size.clamp(12.0, 32.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('defaultFontSize', _fontSize);
    notifyListeners();
  }

  Future<void> setLineHeight(double height) async {
    _lineHeight = height.clamp(1.2, 2.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('defaultLineHeight', _lineHeight);
    notifyListeners();
  }

  void setFontFamily(String family) {
    _fontFamily = family;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _darkMode);
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    await setDarkMode(!_darkMode);
  }

  void increaseFontSize() {
    if (_fontSize < 32.0) {
      setFontSize(_fontSize + 2.0);
    }
  }

  void decreaseFontSize() {
    if (_fontSize > 12.0) {
      setFontSize(_fontSize - 2.0);
    }
  }

  Future<void> setShowWordCount(bool value) async {
    _showWordCount = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('writer_showWordCount', value);
    notifyListeners();
  }

  Future<void> setFocusMode(bool value) async {
    _focusMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('writer_focusMode', value);
    notifyListeners();
  }

  Future<void> setTypewriterScrolling(bool value) async {
    _typewriterScrolling = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('writer_typewriterScrolling', value);
    notifyListeners();
  }
}