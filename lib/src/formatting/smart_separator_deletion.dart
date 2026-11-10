import 'package:flutter/services.dart';

({int removeAt, int caret})? smartSeparatorDeletion({
  required TextEditingValue oldValue,
  required TextEditingValue newValue,
  required int rawCaret,
  required int rawLength,
}) {
  if (newValue.text.length >= oldValue.text.length ||
      !newValue.selection.isCollapsed) {
    return null;
  }
  final forward =
      oldValue.selection.isCollapsed &&
      oldValue.selection.baseOffset == newValue.selection.baseOffset;
  if (forward && rawCaret >= 0 && rawCaret < rawLength) {
    return (removeAt: rawCaret, caret: rawCaret);
  }
  if (rawCaret > 0 && rawCaret <= rawLength) {
    return (removeAt: rawCaret - 1, caret: rawCaret - 1);
  }
  return null;
}
