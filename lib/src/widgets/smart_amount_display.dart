import 'package:flutter/widgets.dart';
import 'package:smart_field_kit/src/formatting/smart_numeric_formatters.dart';

final class SmartAmountDisplay {
  bool _updating = false;

  void handleFocus(
    SmartAmountFormatter formatter,
    TextEditingController? controller,
    FocusNode? focusNode,
  ) {
    if (focusNode?.hasFocus ?? false) {
      _apply(controller, formatter.toEditableValue);
    } else {
      _apply(controller, formatter.toDisplayValue);
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
    TextEditingController? controller,
  ) {
    _apply(controller, formatter.toDisplayValue);
  }

  void _apply(
    TextEditingController? controller,
    TextEditingValue Function(TextEditingValue value) convert,
  ) {
    if (controller == null) {
      return;
    }
    final value = convert(controller.value);
    if (value == controller.value) {
      return;
    }
    _updating = true;
    try {
      controller.value = value;
    } finally {
      _updating = false;
    }
  }
}
