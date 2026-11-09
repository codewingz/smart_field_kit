import 'dart:async';

import 'package:flutter/foundation.dart';

final class SmartSearchDebouncer {
  Timer? _timer;
  String? _pendingQuery;

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _pendingQuery = null;
  }

  void schedule({
    required String query,
    required ValueChanged<String>? onSearch,
    required Duration debounce,
    required bool Function() canSearch,
    required String Function() currentText,
  }) {
    cancel();
    if (onSearch == null || query.trim().isEmpty || !canSearch()) {
      return;
    }
    if (debounce == Duration.zero) {
      onSearch(query);
      return;
    }
    _pendingQuery = query;
    _timer = Timer(debounce, () {
      if (_pendingQuery != query || currentText() != query || !canSearch()) {
        return;
      }
      _timer = null;
      _pendingQuery = null;
      onSearch(query);
    });
  }
}
