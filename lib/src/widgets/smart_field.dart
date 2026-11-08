import 'package:flutter/material.dart';
import 'package:smart_field_kit/src/validation/smart_validators.dart';

class SmartField extends StatefulWidget {
  const SmartField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.enabled,
    this.readOnly = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.autofillHints,
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
  }) : _emailValidator = null,
       _passwordValidator = null,
       _isPassword = false,
       showVisibilityToggle = false,
       assert(minLength == null || minLength >= 0),
       assert(maxLength == null || maxLength >= 0),
       assert(minLength == null || maxLength == null || minLength <= maxLength);

  SmartField.email({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.enabled,
    this.readOnly = false,
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
    SmartEmailPolicy policy = SmartEmailPolicy.standard,
    String emailErrorText = 'Enter a valid email address.',
  }) : keyboardType = TextInputType.emailAddress,
       textCapitalization = TextCapitalization.none,
       autocorrect = false,
       enableSuggestions = false,
       autofillHints = const [AutofillHints.email],
       _emailValidator = SmartValidators.email(
         policy: policy,
         message: emailErrorText,
       ),
       _passwordValidator = null,
       _isPassword = false,
       showVisibilityToggle = false,
       assert(minLength == null || minLength >= 0),
       assert(maxLength == null || maxLength >= 0),
       assert(minLength == null || maxLength == null || minLength <= maxLength);

  SmartField.password({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.enabled,
    this.readOnly = false,
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
    this.showVisibilityToggle = true,
    SmartPasswordPolicy? policy,
    String passwordErrorText = 'Password does not meet the selected policy.',
  }) : keyboardType = TextInputType.visiblePassword,
       textCapitalization = TextCapitalization.none,
       autocorrect = false,
       enableSuggestions = false,
       autofillHints = const [AutofillHints.password],
       _emailValidator = null,
       _passwordValidator = policy == null
           ? null
           : SmartValidators.password(
               policy: policy,
               message: passwordErrorText,
             ),
       _isPassword = true,
       assert(minLength == null || minLength >= 0),
       assert(maxLength == null || maxLength >= 0),
       assert(minLength == null || maxLength == null || minLength <= maxLength);

  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool? enabled;
  final bool readOnly;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final bool enableSuggestions;
  final Iterable<String>? autofillHints;
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
  final bool showVisibilityToggle;
  final SmartValidator? _emailValidator;
  final SmartValidator? _passwordValidator;
  final bool _isPassword;

  @override
  State<SmartField> createState() => _SmartFieldState();
}

class _SmartFieldState extends State<SmartField> {
  late bool _obscureText = widget._isPassword;

  @override
  void didUpdateWidget(covariant SmartField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget._isPassword != widget._isPassword ||
        oldWidget.showVisibilityToggle && !widget.showVisibilityToggle) {
      _obscureText = widget._isPassword;
    }
  }

  InputDecoration get _effectiveDecoration {
    final decoration = widget.decoration;
    return decoration.copyWith(
      labelText: decoration.label == null && decoration.labelText == null
          ? widget.label
          : null,
      hintText: decoration.hint == null && decoration.hintText == null
          ? widget.hintText
          : null,
      suffixIcon: _passwordSuffixIcon(decoration.suffixIcon),
    );
  }

  Widget? _passwordSuffixIcon(Widget? existing) {
    if (!widget._isPassword || !widget.showVisibilityToggle) {
      return existing;
    }

    final label = _obscureText ? 'Show password' : 'Hide password';
    final isEnabled = widget.enabled ?? widget.decoration.enabled;
    final toggle = Semantics(
      label: label,
      button: true,
      enabled: isEnabled,
      child: ExcludeSemantics(
        child: IconButton(
          tooltip: label,
          onPressed: !isEnabled
              ? null
              : () => setState(() => _obscureText = !_obscureText),
          icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
        ),
      ),
    );
    if (existing == null) {
      return toggle;
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [existing, toggle]);
  }

  SmartValidator get _effectiveValidator {
    final validators = <SmartValidator>[];
    if (widget.isRequired) {
      validators.add(
        SmartValidators.requiredField(message: widget.requiredErrorText),
      );
    }
    if (widget._emailValidator != null) {
      validators.add(widget._emailValidator!);
    }
    if (widget._passwordValidator != null) {
      validators.add(widget._passwordValidator!);
    }
    if (widget.minLength != null) {
      validators.add(
        SmartValidators.minLength(
          widget.minLength!,
          message: widget.minLengthErrorText,
        ),
      );
    }
    if (widget.maxLength != null) {
      validators.add(
        SmartValidators.maxLength(
          widget.maxLength!,
          message: widget.maxLengthErrorText,
        ),
      );
    }
    if (widget.validator != null) {
      validators.add(widget.validator!);
    }
    return SmartValidators.compose(validators);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      keyboardType: widget.keyboardType,
      textCapitalization: widget.textCapitalization,
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.enableSuggestions,
      autofillHints: widget.autofillHints,
      textInputAction: widget.textInputAction,
      obscureText: _obscureText,
      onChanged: widget.onChanged,
      onSaved: widget.onSaved,
      validator: _effectiveValidator,
      autovalidateMode: widget.autovalidateMode,
      decoration: _effectiveDecoration,
    );
  }
}
