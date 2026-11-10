import 'dart:async';

import 'package:flutter/foundation.dart';

/// Which rules run for a field: the built-in rule, the developer
/// `validator`, both, or only the built-in checks listed in
/// `builtInChecks`.
enum SmartValidationMode { builtIn, custom, both, selected }

/// A built-in check that can be chosen with
/// [SmartValidationMode.selected].
enum SmartBuiltInCheck {
  fieldFormat,
  passwordUppercase,
  passwordLowercase,
  passwordDigit,
  passwordSpecialCharacter,
  passwordNoWhitespace,
}

/// A server-side error message shown on one field.
///
/// While a message is set, the field shows it and `FormState.validate()`
/// fails. The application owns and disposes this object.
class SmartServerError extends ChangeNotifier {
  /// Creates a server error holder. With [clearOnChange] the message is
  /// removed on the next user edit.
  SmartServerError({this.clearOnChange = true});

  /// Whether a user edit clears the message. When `false` it stays until
  /// [clear] is called.
  final bool clearOnChange;
  String? _errorText;
  int _version = 0;
  bool _disposed = false;

  /// The current message, or `null`.
  String? get errorText => _errorText;

  /// Whether a message is set.
  bool get hasError => _errorText != null;

  /// Shows [message], or clears it when `null`.
  void set(String? message) {
    _apply(message);
  }

  /// Removes the message.
  void clear() {
    _apply(null);
  }

  /// Applies the result of [request] unless a newer `track`, `set`, `clear`
  /// or user edit happened first. Returns whether it was applied.
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
