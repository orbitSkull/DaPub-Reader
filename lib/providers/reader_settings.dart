import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReaderSettings extends ChangeNotifier {
  double _fontSize = 16.0;
  double _lineHeight = 1.6;
  String _fontFamily = 'Serif';
  bool _darkMode = false;

  double get fontSize => _fontSize;
  double get lineHeight => _lineHeight;
  String get fontFamily => _fontFamily;
  bool get darkMode => _darkMode;

  ReaderSettings() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble('defaultFontSize') ?? 16.0;
    _lineHeight = prefs.getDouble('defaultLineHeight') ?? 1.6;
    _darkMode = prefs.getBool('darkMode') ?? false;
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
}