import 'dart:async';

import 'package:flutter/widgets.dart';

/// Checks a raw field value asynchronously.
///
/// Return `null` when the value is accepted, or the message to show.
/// A thrown error is reported as [SmartAsyncValidationStatus.unavailable].
typedef SmartAsyncValidator = Future<String?> Function(String value);

/// When a field starts its asynchronous check.
///
/// `onChanged` runs after the debounce following an edit, `onUnfocus` when
/// focus leaves the field, and `manual` only from
/// [SmartFieldAsyncController.validateAsync].
enum SmartAsyncValidationTrigger { onChanged, onUnfocus, manual }

/// The state of a field's asynchronous check for its current value.
///
/// `unavailable` means the check threw or timed out; it never counts as
/// valid.
enum SmartAsyncValidationStatus { idle, pending, valid, invalid, unavailable }

/// Configuration for asynchronous validation of one field.
///
/// The check runs only for a non-empty value that already passes the
/// synchronous rules. A parent rebuild keeps the pending check and the
/// completed result, so [validator] may be an inline closure.
@immutable
class SmartAsyncValidation {
  /// Creates an asynchronous validation configuration.
  const SmartAsyncValidation({
    required this.validator,
    this.trigger = SmartAsyncValidationTrigger.onChanged,
    this.debounceDuration = const Duration(milliseconds: 400),
    this.timeout,
    this.controller,
    this.unavailableErrorText = 'Could not verify this value. Try again.',
    this.loadingIndicator,
    this.loadingSemanticsLabel = 'Validating',
    this.revalidationKey,
  }) : assert(debounceDuration >= Duration.zero);

  /// Receives the raw value: typed text, the normalized number for amount
  /// and percentage fields, the unmasked text for masked fields, and the
  /// trimmed address for the standard email policy.
  final SmartAsyncValidator validator;

  /// When the check starts. Defaults to `onChanged`.
  final SmartAsyncValidationTrigger trigger;

  /// Quiet period after an edit before an `onChanged` check starts.
  /// `Duration.zero` checks immediately.
  final Duration debounceDuration;

  /// Optional limit for one check. A timeout counts as unavailable.
  final Duration? timeout;

  /// Exposes status and lets the application await the check before
  /// submitting. Created and disposed by the application.
  final SmartFieldAsyncController? controller;

  /// Message shown when the check throws or times out.
  final String unavailableErrorText;

  /// Replaces the default progress indicator shown while a check is
  /// pending.
  final Widget? loadingIndicator;

  /// Screen-reader label of the pending indicator.
  final String loadingSemanticsLabel;

  /// Identifies the rule the [validator] applies.
  ///
  /// When a rebuild supplies a key that is not equal to the previous one,
  /// the completed result and any pending check are dropped and are not
  /// reused. With the `onChanged` trigger one new check then starts for the
  /// current value. With the other triggers nothing is requested until the
  /// next trigger. Leave it `null` when the rule never changes.
  final Object? revalidationKey;
}

/// Reads and drives the asynchronous validation of one field.
///
/// Attach one controller to one field through
/// [SmartAsyncValidation.controller]. Listeners are notified when [status]
/// changes. The application owns and disposes the controller.
class SmartFieldAsyncController extends ChangeNotifier {
  SmartAsyncValidationEngine? _engine;

  /// The status for the field's current value, or `idle` when detached.
  SmartAsyncValidationStatus get status =>
      _engine?.status ?? SmartAsyncValidationStatus.idle;

  /// The message of a rejected or unavailable result, otherwise `null`.
  String? get errorText => _engine?.errorText;

  /// Completes with `true` when the current value is accepted, or is empty
  /// and therefore needs no check.
  ///
  /// Returns the cached result for an unchanged value and joins a check
  /// that is already pending. With [force] it always starts one new check
  /// using the validator from the latest build. Completes with `false` when
  /// the value fails a synchronous rule, changes while the check runs, or
  /// the controller is not attached.
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
    this.onResultDropped,
  });

  static bool _neverComposing() => false;

  final String Function() readText;
  final String? Function(String text) toRaw;
  final String? Function(String text) syncError;
  final bool Function() isActive;
  final void Function() onUpdate;
  final bool Function() isComposing;
  final void Function()? onResultDropped;

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
    final earlier = _config;
    final policyChanged =
        earlier != null && earlier.revalidationKey != config.revalidationKey;
    _config = config;
    if (!identical(previous, config.controller)) {
      if (previous != null && identical(previous._engine, this)) {
        previous._engine = null;
      }
      _controller = config.controller;
      _controller?._engine = this;
    }
    if (policyChanged) {
      _dropForPolicyChange();
    }
  }

  void _dropForPolicyChange() {
    final hadWork = _pendingFuture != null || _resultRaw != null;
    if (!hadWork) {
      return;
    }
    final hadError =
        _status == SmartAsyncValidationStatus.invalid ||
        _status == SmartAsyncValidationStatus.unavailable;
    _timer?.cancel();
    _timer = null;
    final generation = ++_generation;
    _pendingRaw = null;
    _pendingFuture = null;
    _resultRaw = null;
    _message = null;
    _status = SmartAsyncValidationStatus.idle;
    scheduleMicrotask(() {
      if (_disposed) {
        return;
      }
      if (generation == _generation) {
        _controller?._publish();
        onUpdate();
      }
      if (hadError) {
        onResultDropped?.call();
      }
      if (generation == _generation &&
          _config?.trigger == SmartAsyncValidationTrigger.onChanged) {
        _lastRaw = null;
        observe(readText());
      }
    });
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
