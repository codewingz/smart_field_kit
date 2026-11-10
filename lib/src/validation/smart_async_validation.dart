import 'dart:async';

import 'package:flutter/widgets.dart';

typedef SmartAsyncValidator = Future<String?> Function(String value);

enum SmartAsyncValidationTrigger { onChanged, onUnfocus, manual }

enum SmartAsyncValidationStatus { idle, pending, valid, invalid, unavailable }

@immutable
class SmartAsyncValidation {
  const SmartAsyncValidation({
    required this.validator,
    this.trigger = SmartAsyncValidationTrigger.onChanged,
    this.debounceDuration = const Duration(milliseconds: 400),
    this.timeout,
    this.controller,
    this.unavailableErrorText = 'Could not verify this value. Try again.',
    this.loadingIndicator,
    this.loadingSemanticsLabel = 'Validating',
  }) : assert(debounceDuration >= Duration.zero);

  final SmartAsyncValidator validator;
  final SmartAsyncValidationTrigger trigger;
  final Duration debounceDuration;
  final Duration? timeout;
  final SmartFieldAsyncController? controller;
  final String unavailableErrorText;
  final Widget? loadingIndicator;
  final String loadingSemanticsLabel;
}

class SmartFieldAsyncController extends ChangeNotifier {
  SmartAsyncValidationEngine? _engine;

  SmartAsyncValidationStatus get status =>
      _engine?.status ?? SmartAsyncValidationStatus.idle;

  String? get errorText => _engine?.errorText;

  Future<bool> validateAsync({bool force = false}) {
    final engine = _engine;
    if (engine == null) {
      return Future.value(false);
    }
    return engine.validateAsync(force: force);
  }

  void _publish() {
    notifyListeners();
  }
}

class SmartAsyncValidationEngine {
  SmartAsyncValidationEngine({
    required this.readText,
    required this.toRaw,
    required this.syncError,
    required this.isActive,
    required this.onUpdate,
    this.isComposing = _neverComposing,
  });

  static bool _neverComposing() => false;

  final String Function() readText;
  final String? Function(String text) toRaw;
  final String? Function(String text) syncError;
  final bool Function() isActive;
  final void Function() onUpdate;
  final bool Function() isComposing;

  SmartAsyncValidation? _config;
  SmartFieldAsyncController? _controller;
  Timer? _timer;
  int _generation = 0;
  bool _disposed = false;
  String? _lastRaw;
  String? _resultRaw;
  String? _pendingRaw;
  Future<bool>? _pendingFuture;
  SmartAsyncValidationStatus _status = SmartAsyncValidationStatus.idle;
  String? _message;

  SmartAsyncValidationStatus get status => _status;

  String? get errorText => _message;

  bool get isPending => _status == SmartAsyncValidationStatus.pending;

  void configure(SmartAsyncValidation config) {
    final previous = _controller;
    _config = config;
    if (!identical(previous, config.controller)) {
      if (previous != null && identical(previous._engine, this)) {
        previous._engine = null;
      }
      _controller = config.controller;
      _controller?._engine = this;
    }
  }

  String? errorFor(String text) {
    if (_status != SmartAsyncValidationStatus.invalid &&
        _status != SmartAsyncValidationStatus.unavailable) {
      return null;
    }
    return toRaw(text) == _resultRaw ? _message : null;
  }

  void observe(String text) {
    final config = _config;
    if (_disposed || config == null) {
      return;
    }
    if (isComposing()) {
      _lastRaw = null;
      _invalidate();
      return;
    }
    final raw = toRaw(text);
    if (raw == _lastRaw) {
      return;
    }
    _lastRaw = raw;
    _invalidate();
    if (config.trigger != SmartAsyncValidationTrigger.onChanged) {
      return;
    }
    if (!isActive() ||
        raw == null ||
        raw.isEmpty ||
        text.isEmpty ||
        syncError(text) != null) {
      return;
    }
    if (config.debounceDuration == Duration.zero) {
      unawaited(_run(raw));
      return;
    }
    _timer = Timer(config.debounceDuration, () {
      _timer = null;
      if (_disposed || !isActive() || isComposing()) {
        return;
      }
      final current = readText();
      if (toRaw(current) != raw || syncError(current) != null) {
        return;
      }
      unawaited(_run(raw));
    });
  }

  void focusLost() {
    if (_config?.trigger == SmartAsyncValidationTrigger.onUnfocus &&
        isActive()) {
      unawaited(validateAsync());
    }
  }

  Future<bool> validateAsync({bool force = false}) async {
    final config = _config;
    if (_disposed || config == null) {
      return false;
    }
    _timer?.cancel();
    _timer = null;
    final text = readText();
    final raw = toRaw(text);
    if (raw == null || syncError(text) != null) {
      return false;
    }
    if (raw.isEmpty || text.isEmpty) {
      _invalidate();
      return true;
    }
    _lastRaw = raw;
    if (!force) {
      if (_resultRaw == raw) {
        if (_status == SmartAsyncValidationStatus.valid) {
          return true;
        }
        if (_status == SmartAsyncValidationStatus.invalid) {
          return false;
        }
      }
      if (_pendingRaw == raw && _pendingFuture != null) {
        return _pendingFuture!;
      }
    }
    return _run(raw);
  }

  Future<bool> _run(String raw) {
    final config = _config!;
    final generation = ++_generation;
    _pendingRaw = raw;
    _resultRaw = null;
    _message = null;
    _setStatus(SmartAsyncValidationStatus.pending);
    final future = _execute(config, raw, generation);
    _pendingFuture = future;
    return future;
  }

  Future<bool> _execute(
    SmartAsyncValidation config,
    String raw,
    int generation,
  ) async {
    String? error;
    var unavailable = false;
    try {
      var future = config.validator(raw);
      final timeout = config.timeout;
      if (timeout != null) {
        future = future.timeout(timeout);
      }
      error = await future;
    } catch (_) {
      unavailable = true;
    }
    if (_disposed || generation != _generation || toRaw(readText()) != raw) {
      return false;
    }
    _pendingRaw = null;
    _pendingFuture = null;
    _resultRaw = raw;
    if (unavailable) {
      _message = config.unavailableErrorText;
      _setStatus(SmartAsyncValidationStatus.unavailable);
      return false;
    }
    if (error != null) {
      _message = error;
      _setStatus(SmartAsyncValidationStatus.invalid);
      return false;
    }
    _message = null;
    _setStatus(SmartAsyncValidationStatus.valid);
    return true;
  }

  void _invalidate() {
    _timer?.cancel();
    _timer = null;
    _generation++;
    _pendingRaw = null;
    _pendingFuture = null;
    _resultRaw = null;
    _message = null;
    if (_status != SmartAsyncValidationStatus.idle) {
      _setStatus(SmartAsyncValidationStatus.idle);
    }
  }

  void reset() {
    _lastRaw = null;
    _invalidate();
  }

  void _setStatus(SmartAsyncValidationStatus status) {
    _status = status;
    _controller?._publish();
    onUpdate();
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _generation++;
    final controller = _controller;
    if (controller != null && identical(controller._engine, this)) {
      controller._engine = null;
    }
    _controller = null;
  }
}
