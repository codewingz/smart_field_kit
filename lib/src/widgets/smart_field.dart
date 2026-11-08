import 'package:flutter/material.dart';
import 'package:smart_field_kit/src/validation/smart_validators.dart';

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
    this.isRequired = false,
    this.requiredErrorText = 'This field is required.',
    this.minLength,
    this.minLengthErrorText,
    this.maxLength,
    this.maxLengthErrorText,
    this.validator,
    this.autovalidateMode,
    this.decoration = const InputDecoration(),
  }) : assert(minLength == null || minLength >= 0),
       assert(maxLength == null || maxLength >= 0),
       assert(minLength == null || maxLength == null || minLength <= maxLength);

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
  final bool isRequired;
  final String requiredErrorText;
  final int? minLength;
  final String? minLengthErrorText;
  final int? maxLength;
  final String? maxLengthErrorText;
  final FormFieldValidator<String>? validator;
  final AutovalidateMode? autovalidateMode;
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

  SmartValidator get _effectiveValidator {
    final validators = <SmartValidator>[];
    if (isRequired) {
      validators.add(SmartValidators.requiredField(message: requiredErrorText));
    }
    if (minLength != null) {
      validators.add(
        SmartValidators.minLength(minLength!, message: minLengthErrorText),
      );
    }
    if (maxLength != null) {
      validators.add(
        SmartValidators.maxLength(maxLength!, message: maxLengthErrorText),
      );
    }
    if (validator != null) {
      validators.add(validator!);
    }
    return SmartValidators.compose(validators);
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
      validator: _effectiveValidator,
      autovalidateMode: autovalidateMode,
      decoration: _effectiveDecoration,
    );
  }
}
