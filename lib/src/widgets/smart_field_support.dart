import 'package:flutter/material.dart';

final class SmartRedactedTextEditingController extends TextEditingController {
  SmartRedactedTextEditingController({super.text});

  @override
  String toString() => 'TextEditingController(redacted)';
}

final class SmartInputHandle {
  SmartInputHandle({this.redacted = false, this.initialText});

  final bool redacted;
  final String? initialText;
  TextEditingController? _externalController;
  FocusNode? _externalFocusNode;
  TextEditingController? _ownedController;
  FocusNode? _ownedFocusNode;

  TextEditingValue? _seed;

  void update({
    TextEditingController? controller,
    FocusNode? focusNode,
    TextEditingValue? seed,
  }) {
    _externalController = controller;
    _externalFocusNode = focusNode;
    _seed = seed ?? _seed;
  }

  void releaseUnused() {
    if (_externalController != null) {
      _ownedController?.dispose();
      _ownedController = null;
    }
    if (_externalFocusNode != null) {
      _ownedFocusNode?.dispose();
      _ownedFocusNode = null;
    }
  }

  bool get ownsController => _externalController == null;

  TextEditingController get controller {
    return _externalController ?? (_ownedController ??= _createController());
  }

  TextEditingController _createController() {
    final seed = _seed;
    if (redacted) {
      return SmartRedactedTextEditingController(
        text: seed?.text ?? initialText,
      );
    }
    return seed == null
        ? TextEditingController(text: initialText)
        : TextEditingController.fromValue(seed);
  }

  FocusNode get focusNode {
    return _externalFocusNode ?? (_ownedFocusNode ??= FocusNode());
  }

  void dispose() {
    _ownedController?.dispose();
    _ownedFocusNode?.dispose();
    _ownedController = null;
    _ownedFocusNode = null;
  }
}

Widget? composeSuffixActions(Iterable<Widget> children) {
  final list = children.toList(growable: false);
  if (list.isEmpty) {
    return null;
  }
  if (list.length == 1) {
    return list.single;
  }
  return Row(mainAxisSize: MainAxisSize.min, children: list);
}
