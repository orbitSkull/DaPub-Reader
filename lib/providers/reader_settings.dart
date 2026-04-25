import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReaderSettings extends ChangeNotifier {
  double _fontSize = 16.0;
  double _lineHeight = 1.6;
  String _fontFamily = 'Serif';
  bool _darkMode = false;

  double get fontSize => _fontSize;
  double get lineHeight => _lineHeight;
  String get fontFamily => _fontFamily;
  bool get darkMode => _darkMode;

  void setFontSize(double size) {
    _fontSize = size.clamp(12.0, 32.0);
    notifyListeners();
  }

  void setLineHeight(double height) {
    _lineHeight = height.clamp(1.2, 2.0);
    notifyListeners();
  }

  void setFontFamily(String family) {
    _fontFamily = family;
    notifyListeners();
  }

  void toggleDarkMode() {
    _darkMode = !_darkMode;
    notifyListeners();
  }

  void increaseFontSize() {
    if (_fontSize < 32.0) {
      _fontSize += 2.0;
      notifyListeners();
    }
  }

  void decreaseFontSize() {
    if (_fontSize > 12.0) {
      _fontSize -= 2.0;
      notifyListeners();
    }
  }
}