import 'package:flutter/foundation.dart';

final class SmartListenerBinding {
  SmartListenerBinding(this.listener);

  final VoidCallback listener;
  Listenable? _target;

  Listenable? get target => _target;

  bool get isBound => _target != null;

  bool bind(Listenable? target) {
    if (identical(target, _target)) {
      return false;
    }
    _target?.removeListener(listener);
    _target = target;
    target?.addListener(listener);
    return true;
  }

  void dispose() {
    bind(null);
  }
}

final class SmartListenerGroup {
  final List<SmartListenerBinding> _bindings = [];

  SmartListenerBinding add(VoidCallback listener) {
    final binding = SmartListenerBinding(listener);
    _bindings.add(binding);
    return binding;
  }

  void unbindAll() {
    for (final binding in _bindings) {
      binding.dispose();
    }
  }
}
