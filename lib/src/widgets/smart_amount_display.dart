import 'package:flutter/widgets.dart';
import 'package:smart_field_kit/src/formatting/smart_numeric_formatters.dart';

final class SmartAmountDisplay {
  bool _updating = false;

  void handleFocus(
    SmartAmountFormatter formatter,
    TextEditingController? controller,
    FocusNode? focusNode, {
    ValueChanged<String>? beforeWrite,
  }) {
    if (focusNode?.hasFocus ?? false) {
      _apply(controller, formatter.toEditableValue, beforeWrite);
    } else {
      _apply(controller, formatter.toDisplayValue, beforeWrite);
    }
  }

  void handleControllerChange(
    SmartAmountFormatter formatter,
    TextEditingController? controller,
    FocusNode? focusNode,
  ) {
    if (_updating || (focusNode?.hasFocus ?? false)) {
      return;
    }
    _apply(controller, formatter.toDisplayValue);
  }

  void showDisplay(
    SmartAmountFormatter formatter,
    TextEditingController? controller, {
    ValueChanged<String>? beforeWrite,
  }) {
    _apply(controller, formatter.toDisplayValue, beforeWrite);
  }

  void _apply(
    TextEditingController? controller,
    TextEditingValue Function(TextEditingValue value) convert, [
    ValueChanged<String>? beforeWrite,
  ]) {
    if (controller == null) {
      return;
    }
    final value = convert(controller.value);
    if (value == controller.value) {
      return;
    }
    _updating = true;
    try {
      beforeWrite?.call(value.text);
      controller.value = value;
    } finally {
      _updating = false;
    }
  }
}
