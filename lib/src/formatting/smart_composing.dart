import 'package:flutter/services.dart';

bool smartIsComposing(TextEditingValue value) {
  return value.composing.isValid && !value.composing.isCollapsed;
}
