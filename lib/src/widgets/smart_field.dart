import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_field_kit/src/formatting/smart_numeric_formatters.dart';
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
  }) : showVisibilityToggle = false,
       onRawChanged = null,
       onRawSaved = null,
       _fieldValidator = null,
       _valueNormalizer = null,
       _minValueValidator = null,
       _maxValueValidator = null,
       _inputFormatters = null,
       _amountFormatter = null,
       _isPassword = false,
       _isAmount = false,
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
       showVisibilityToggle = false,
       onRawChanged = null,
       onRawSaved = null,
       _fieldValidator = SmartValidators.email(
         policy: policy,
         message: emailErrorText,
       ),
       _valueNormalizer = null,
       _minValueValidator = null,
       _maxValueValidator = null,
       _inputFormatters = null,
       _amountFormatter = null,
       _isPassword = false,
       _isAmount = false,
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
       onRawChanged = null,
       onRawSaved = null,
       _fieldValidator = policy == null
           ? null
           : SmartValidators.password(
               policy: policy,
               message: passwordErrorText,
             ),
       _valueNormalizer = null,
       _minValueValidator = null,
       _maxValueValidator = null,
       _inputFormatters = null,
       _amountFormatter = null,
       _isPassword = true,
       _isAmount = false,
       assert(minLength == null || minLength >= 0),
       assert(maxLength == null || maxLength >= 0),
       assert(minLength == null || maxLength == null || minLength <= maxLength);

  SmartField.number({
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
    String? minValue,
    String? minValueErrorText,
    String? maxValue,
    String? maxValueErrorText,
    this.validator,
    this.autovalidateMode,
    this.decoration = const InputDecoration(),
    bool allowNegative = false,
    SmartNumberPolicy policy = SmartNumberPolicy.standard,
    String numberErrorText = 'Enter a valid whole number.',
  }) : keyboardType = TextInputType.numberWithOptions(signed: allowNegative),
       textCapitalization = TextCapitalization.none,
       autocorrect = false,
       enableSuggestions = false,
       autofillHints = null,
       showVisibilityToggle = false,
       onRawChanged = null,
       onRawSaved = null,
       _fieldValidator = SmartValidators.number(
         policy: policy,
         allowNegative: allowNegative,
         message: numberErrorText,
       ),
       _valueNormalizer = null,
       _minValueValidator = minValue == null
           ? null
           : SmartValidators.minValue(minValue, message: minValueErrorText),
       _maxValueValidator = maxValue == null
           ? null
           : SmartValidators.maxValue(maxValue, message: maxValueErrorText),
       _inputFormatters = [
         SmartNumberInputFormatter(allowNegative: allowNegative),
       ],
       _amountFormatter = null,
       _isPassword = false,
       _isAmount = false,
       assert(minLength == null || minLength >= 0),
       assert(maxLength == null || maxLength >= 0),
       assert(minLength == null || maxLength == null || minLength <= maxLength);

  factory SmartField.amount({
    Key? key,
    String? label,
    String? hintText,
    TextEditingController? controller,
    FocusNode? focusNode,
    bool autofocus = false,
    bool? enabled,
    bool readOnly = false,
    TextInputAction? textInputAction,
    ValueChanged<String>? onChanged,
    FormFieldSetter<String>? onSaved,
    ValueChanged<String>? onRawChanged,
    FormFieldSetter<String>? onRawSaved,
    bool isRequired = false,
    String requiredErrorText = 'This field is required.',
    int? minLength,
    String? minLengthErrorText,
    int? maxLength,
    String? maxLengthErrorText,
    String? minValue,
    String? minValueErrorText,
    String? maxValue,
    String? maxValueErrorText,
    FormFieldValidator<String>? validator,
    AutovalidateMode? autovalidateMode,
    InputDecoration decoration = const InputDecoration(),
    int? decimalPlaces,
    bool useGrouping = false,
    String groupingSeparator = ',',
    String decimalSeparator = '.',
    String? currencySymbol,
    SmartCurrencyPosition currencyPosition = SmartCurrencyPosition.prefix,
    bool allowNegative = false,
    SmartAmountPolicy policy = SmartAmountPolicy.standard,
    String amountErrorText = 'Enter a valid amount.',
  }) {
    final formatter = SmartAmountFormatter(
      decimalPlaces: decimalPlaces,
      useGrouping: useGrouping,
      groupingSeparator: groupingSeparator,
      decimalSeparator: decimalSeparator,
      currencySymbol: currencySymbol,
      currencyPosition: currencyPosition,
      allowNegative: allowNegative,
    );
    return SmartField._amount(
      key: key,
      label: label,
      hintText: hintText,
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      enabled: enabled,
      readOnly: readOnly,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSaved: onSaved,
      onRawChanged: onRawChanged,
      onRawSaved: onRawSaved,
      isRequired: isRequired,
      requiredErrorText: requiredErrorText,
      minLength: minLength,
      minLengthErrorText: minLengthErrorText,
      maxLength: maxLength,
      maxLengthErrorText: maxLengthErrorText,
      minValue: minValue,
      minValueErrorText: minValueErrorText,
      maxValue: maxValue,
      maxValueErrorText: maxValueErrorText,
      validator: validator,
      autovalidateMode: autovalidateMode,
      decoration: decoration,
      formatter: formatter,
      policy: policy,
      amountErrorText: amountErrorText,
      decimalPlaces: decimalPlaces,
      allowNegative: allowNegative,
    );
  }

  SmartField._amount({
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
    this.onRawChanged,
    this.onRawSaved,
    this.isRequired = false,
    this.requiredErrorText = 'This field is required.',
    this.minLength,
    this.minLengthErrorText,
    this.maxLength,
    this.maxLengthErrorText,
    String? minValue,
    String? minValueErrorText,
    String? maxValue,
    String? maxValueErrorText,
    this.validator,
    this.autovalidateMode,
    this.decoration = const InputDecoration(),
    required SmartAmountFormatter formatter,
    required SmartAmountPolicy policy,
    required String amountErrorText,
    required int? decimalPlaces,
    required bool allowNegative,
  }) : keyboardType = TextInputType.numberWithOptions(
         signed: allowNegative,
         decimal: decimalPlaces != 0,
       ),
       textCapitalization = TextCapitalization.none,
       autocorrect = false,
       enableSuggestions = false,
       autofillHints = null,
       showVisibilityToggle = false,
       _fieldValidator = SmartValidators.amount(
         formatter: formatter,
         policy: policy,
         message: amountErrorText,
       ),
       _valueNormalizer = formatter.normalize,
       _minValueValidator = minValue == null
           ? null
           : SmartValidators.minValue(
               minValue,
               normalizer: formatter.normalize,
               message: minValueErrorText,
             ),
       _maxValueValidator = maxValue == null
           ? null
           : SmartValidators.maxValue(
               maxValue,
               normalizer: formatter.normalize,
               message: maxValueErrorText,
             ),
       _inputFormatters = [formatter],
       _amountFormatter = formatter,
       _isPassword = false,
       _isAmount = true,
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
  final ValueChanged<String>? onRawChanged;
  final FormFieldSetter<String>? onRawSaved;
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
  final SmartValidator? _fieldValidator;
  final SmartValueNormalizer? _valueNormalizer;
  final SmartValidator? _minValueValidator;
  final SmartValidator? _maxValueValidator;
  final List<TextInputFormatter>? _inputFormatters;
  final SmartAmountFormatter? _amountFormatter;
  final bool _isPassword;
  final bool _isAmount;

  @override
  State<SmartField> createState() => _SmartFieldState();
}

class _SmartFieldState extends State<SmartField> {
  late bool _obscureText = widget._isPassword;
  TextEditingController? _ownedAmountController;
  FocusNode? _ownedAmountFocusNode;
  bool _updatingAmountText = false;

  TextEditingController? get _effectiveController {
    return widget._isAmount
        ? widget.controller ?? _ownedAmountController
        : widget.controller;
  }

  FocusNode? get _effectiveFocusNode {
    return widget._isAmount
        ? widget.focusNode ?? _ownedAmountFocusNode
        : widget.focusNode;
  }

  @override
  void initState() {
    super.initState();
    _configureAmountState();
  }

  @override
  void didUpdateWidget(covariant SmartField oldWidget) {
    final oldAmountController = oldWidget._isAmount
        ? oldWidget.controller ?? _ownedAmountController
        : null;
    final oldAmountFocusNode = oldWidget._isAmount
        ? oldWidget.focusNode ?? _ownedAmountFocusNode
        : null;
    oldAmountController?.removeListener(_handleAmountControllerChange);
    oldAmountFocusNode?.removeListener(_handleAmountFocusChange);
    super.didUpdateWidget(oldWidget);

    if (oldWidget._isPassword != widget._isPassword ||
        oldWidget.showVisibilityToggle && !widget.showVisibilityToggle) {
      _obscureText = widget._isPassword;
    }

    if (oldWidget._isAmount &&
        oldWidget.controller == null &&
        (!widget._isAmount || widget.controller != null)) {
      _ownedAmountController?.dispose();
      _ownedAmountController = null;
    }
    if (oldWidget._isAmount &&
        oldWidget.focusNode == null &&
        (!widget._isAmount || widget.focusNode != null)) {
      _ownedAmountFocusNode?.dispose();
      _ownedAmountFocusNode = null;
    }
    if (widget._isAmount &&
        widget.controller == null &&
        _ownedAmountController == null) {
      _ownedAmountController = TextEditingController.fromValue(
        oldWidget.controller?.value,
      );
    }
    _configureAmountState();
  }

  void _configureAmountState() {
    if (!widget._isAmount) {
      return;
    }
    _ownedAmountController ??= widget.controller == null
        ? TextEditingController()
        : null;
    _ownedAmountFocusNode ??= widget.focusNode == null ? FocusNode() : null;
    _effectiveController?.addListener(_handleAmountControllerChange);
    _effectiveFocusNode?.addListener(_handleAmountFocusChange);
    if (!(_effectiveFocusNode?.hasFocus ?? false)) {
      _applyAmountDisplay();
    }
  }

  void _handleAmountFocusChange() {
    if (_effectiveFocusNode?.hasFocus ?? false) {
      _applyAmountEditable();
    } else {
      _applyAmountDisplay();
    }
  }

  void _handleAmountControllerChange() {
    if (_updatingAmountText || (_effectiveFocusNode?.hasFocus ?? false)) {
      return;
    }
    _applyAmountDisplay();
  }

  void _applyAmountEditable() {
    final controller = _effectiveController;
    final formatter = widget._amountFormatter;
    if (controller == null || formatter == null) {
      return;
    }
    final value = formatter.toEditableValue(controller.value);
    if (value != controller.value) {
      _setAmountValue(controller, value);
    }
  }

  void _applyAmountDisplay() {
    final controller = _effectiveController;
    final formatter = widget._amountFormatter;
    if (controller == null || formatter == null) {
      return;
    }
    final value = formatter.toDisplayValue(controller.value);
    if (value != controller.value) {
      _setAmountValue(controller, value);
    }
  }

  void _setAmountValue(
    TextEditingController controller,
    TextEditingValue value,
  ) {
    _updatingAmountText = true;
    try {
      controller.value = value;
    } finally {
      _updatingAmountText = false;
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
    if (widget._fieldValidator != null) {
      validators.add(widget._fieldValidator!);
    }
    if (widget.minLength != null) {
      validators.add(
        SmartValidators.minLength(
          widget.minLength!,
          message: widget.minLengthErrorText,
          normalizer: widget._valueNormalizer,
        ),
      );
    }
    if (widget.maxLength != null) {
      validators.add(
        SmartValidators.maxLength(
          widget.maxLength!,
          message: widget.maxLengthErrorText,
          normalizer: widget._valueNormalizer,
        ),
      );
    }
    if (widget._minValueValidator != null) {
      validators.add(widget._minValueValidator!);
    }
    if (widget._maxValueValidator != null) {
      validators.add(widget._maxValueValidator!);
    }
    if (widget.validator != null) {
      validators.add(widget.validator!);
    }
    return SmartValidators.compose(validators);
  }

  void _handleChanged(String value) {
    widget.onChanged?.call(value);
    final formatter = widget._amountFormatter;
    if (formatter != null) {
      final raw = formatter.normalize(value, allowPartial: true);
      if (raw != null) {
        widget.onRawChanged?.call(raw);
      }
    }
  }

  void _handleSaved(String? value) {
    widget.onSaved?.call(value);
    final formatter = widget._amountFormatter;
    widget.onRawSaved?.call(
      value == null || formatter == null ? null : formatter.normalize(value),
    );
  }

  @override
  void dispose() {
    if (widget._isAmount) {
      _effectiveController?.removeListener(_handleAmountControllerChange);
      _effectiveFocusNode?.removeListener(_handleAmountFocusChange);
    }
    _ownedAmountController?.dispose();
    _ownedAmountFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _effectiveController,
      focusNode: _effectiveFocusNode,
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
      inputFormatters: widget._inputFormatters,
      onChanged: _handleChanged,
      onSaved: _handleSaved,
      validator: _effectiveValidator,
      autovalidateMode: widget.autovalidateMode,
      decoration: _effectiveDecoration,
    );
  }
}
