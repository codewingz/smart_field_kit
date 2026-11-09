import 'dart:async';

import 'package:flutter/foundation.dart';

enum SmartValidationMode { builtIn, custom, both, selected }

enum SmartBuiltInCheck {
  fieldFormat,
  passwordUppercase,
  passwordLowercase,
  passwordDigit,
  passwordSpecialCharacter,
  passwordNoWhitespace,
}

class SmartServerError extends ChangeNotifier {
  SmartServerError({this.clearOnChange = true});

  final bool clearOnChange;
  String? _errorText;
  int _version = 0;
  bool _disposed = false;

  String? get errorText => _errorText;

  bool get hasError => _errorText != null;

  void set(String? message) {
    _apply(message);
  }

  void clear() {
    _apply(null);
  }

  Future<bool> track(Future<String?> request) async {
    final version = ++_version;
    final String? message;
    try {
      message = await request;
    } catch (_) {
      return false;
    }
    if (_disposed || version != _version) {
      return false;
    }
    _apply(message, bumpVersion: false);
    return true;
  }

  void notifyFieldChanged() {
    if (clearOnChange && _errorText != null) {
      clear();
    } else {
      _version++;
    }
  }

  void _apply(String? message, {bool bumpVersion = true}) {
    if (_disposed) {
      return;
    }
    if (bumpVersion) {
      _version++;
    }
    final normalized = message == null || message.isEmpty ? null : message;
    if (normalized == _errorText) {
      return;
    }
    _errorText = normalized;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
