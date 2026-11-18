import 'package:flutter/material.dart';

class ShowcaseSettings extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _rtl = false;
  double _textScale = 1;

  ThemeMode get themeMode => _themeMode;
  bool get rtl => _rtl;
  double get textScale => _textScale;

  set themeMode(ThemeMode value) {
    _themeMode = value;
    notifyListeners();
  }

  set rtl(bool value) {
    _rtl = value;
    notifyListeners();
  }

  set textScale(double value) {
    _textScale = value;
    notifyListeners();
  }
}
