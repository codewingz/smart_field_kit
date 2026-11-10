import 'package:flutter/services.dart';

bool smartIsComposing(TextEditingValue value) {
  return value.composing.isValid && !value.composing.isCollapsed;
}

TextEditingValue smartBeforeComposition(TextEditingValue value) {
  final range = value.composing;
  if (!smartIsComposing(value) || range.end > value.text.length) {
    return value;
  }
  return TextEditingValue(
    text: value.text.replaceRange(range.start, range.end, ''),
    selection: TextSelection.collapsed(offset: range.start),
  );
}
