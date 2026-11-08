import 'package:flutter/material.dart';

class SmartField extends StatelessWidget {
  const SmartField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.focusNode,
    this.enabled,
    this.readOnly = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSaved,
    this.validator,
    this.decoration = const InputDecoration(),
  });

  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool? enabled;
  final bool readOnly;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final FormFieldSetter<String>? onSaved;
  final FormFieldValidator<String>? validator;
  final InputDecoration decoration;

  InputDecoration get _effectiveDecoration {
    return decoration.copyWith(
      labelText: decoration.label == null && decoration.labelText == null
          ? label
          : null,
      hintText: decoration.hint == null && decoration.hintText == null
          ? hintText
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSaved: onSaved,
      validator: validator,
      decoration: _effectiveDecoration,
    );
  }
}
