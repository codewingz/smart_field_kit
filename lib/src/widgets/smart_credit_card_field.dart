import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_field_kit/src/formatting/smart_card_utils.dart';
import 'package:smart_field_kit/src/formatting/smart_input_mask.dart';
import 'package:smart_field_kit/src/validation/smart_validation_options.dart';
import 'package:smart_field_kit/src/validation/smart_validators.dart';
import 'package:smart_field_kit/src/widgets/smart_field.dart';
import 'package:smart_field_kit/src/widgets/smart_field_support.dart';
import 'package:smart_field_kit/src/widgets/smart_listener_binding.dart';

final class SmartCreditCardValue {
  const SmartCreditCardValue({
    required this.number,
    required this.brand,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cvv,
    this.numberStatus = SmartCardNumberStatus.empty,
  });

  final String number;
  final SmartCardBrand brand;
  final int? expiryMonth;
  final int? expiryYear;
  final String cvv;
  final SmartCardNumberStatus numberStatus;

  String get last4 =>
      number.length <= 4 ? number : number.substring(number.length - 4);

  String get maskedNumber => SmartCardUtils.maskedNumber(number);

  bool get hasNumber => number.isNotEmpty;

  @override
  String toString() {
    return 'SmartCreditCardValue(brand: ${brand.displayName}, '
        'last4: $last4, status: ${numberStatus.name}, '
        'expiry: ${expiryMonth == null ? 'none' : 'set'}, cvv: hidden)';
  }
}

final class SmartCreditCardConfig {
  const SmartCreditCardConfig({
    this.numberLabel = 'Card number',
    this.expiryLabel = 'Expiry',
    this.cvvLabel = 'Security code',
    this.numberHint,
    this.expiryHint,
    this.cvvHint,
    this.numberController,
    this.expiryController,
    this.cvvController,
    this.numberFocusNode,
    this.expiryFocusNode,
    this.cvvFocusNode,
    this.acceptedBrands,
    this.validateLuhn = true,
    this.luhnExemptBrands = const {},
    this.showNumberStatus = true,
    this.numberStatusBuilder,
    this.brandErrorText = 'This card type is not accepted.',
    this.luhnErrorText = 'Check the card number.',
    this.expiryFormat = SmartExpiryFormat.mmYy,
    this.now = DateTime.now,
    this.cvvLengths,
    this.concealCvv = true,
    this.showBrand = true,
    this.autoAdvance = true,
    this.numberErrorText = 'Enter a valid card number.',
    this.expiryErrorText = 'Enter a valid expiry date.',
    this.expiredErrorText = 'This card has expired.',
    this.cvvErrorText,
    this.numberServerError,
    this.expiryServerError,
    this.cvvServerError,
    this.onChanged,
    this.onSaved,
  });

  final String numberLabel;
  final String expiryLabel;
  final String cvvLabel;
  final String? numberHint;
  final String? expiryHint;
  final String? cvvHint;
  final TextEditingController? numberController;
  final TextEditingController? expiryController;
  final TextEditingController? cvvController;
  final FocusNode? numberFocusNode;
  final FocusNode? expiryFocusNode;
  final FocusNode? cvvFocusNode;
  final Set<SmartCardBrand>? acceptedBrands;
  final bool validateLuhn;
  final Set<SmartCardBrand> luhnExemptBrands;
  final bool showNumberStatus;
  final String? Function(SmartCardNumberAssessment assessment)?
  numberStatusBuilder;
  final String brandErrorText;
  final String luhnErrorText;
  final SmartExpiryFormat expiryFormat;
  final DateTime Function() now;
  final Set<int>? cvvLengths;
  final bool concealCvv;
  final bool showBrand;
  final bool autoAdvance;
  final String numberErrorText;
  final String expiryErrorText;
  final String expiredErrorText;
  final String? cvvErrorText;
  final SmartServerError? numberServerError;
  final SmartServerError? expiryServerError;
  final SmartServerError? cvvServerError;
  final ValueChanged<SmartCreditCardValue>? onChanged;
  final FormFieldSetter<SmartCreditCardValue>? onSaved;
}

class SmartCreditCardField extends StatefulWidget {
  const SmartCreditCardField({
    super.key,
    required this.config,
    required this.enabled,
    required this.readOnly,
    required this.autofocus,
    required this.isRequired,
    required this.requiredErrorText,
    required this.autovalidateMode,
    required this.decoration,
  });

  final SmartCreditCardConfig config;
  final bool? enabled;
  final bool readOnly;
  final bool autofocus;
  final bool isRequired;
  final String requiredErrorText;
  final AutovalidateMode? autovalidateMode;
  final InputDecoration decoration;

  @override
  State<SmartCreditCardField> createState() => _SmartCreditCardFieldState();
}

class _SmartCreditCardFieldState extends State<SmartCreditCardField> {
  final SmartInputHandle _numberInput = SmartInputHandle(redacted: true);
  final SmartInputHandle _expiryInput = SmartInputHandle(redacted: true);
  final SmartInputHandle _cvvInput = SmartInputHandle(redacted: true);
  final SmartServerError _numberDisplay = SmartServerError(
    clearOnChange: false,
  );
  final SmartServerError _cvvDisplay = SmartServerError(clearOnChange: false);
  final SmartListenerGroup _listeners = SmartListenerGroup();
  late final SmartListenerBinding _numberText = _listeners.add(
    _handleNumberController,
  );
  late final SmartListenerBinding _numberServer = _listeners.add(
    _handleNumberServerChange,
  );
  late final SmartListenerBinding _cvvServer = _listeners.add(
    _handleCvvServerChange,
  );
  String? _cvvBrandError;
  String _lastNumberText = '';

  SmartCreditCardConfig get _config => widget.config;

  TextEditingController get _number => _numberInput.controller;
  TextEditingController get _expiry => _expiryInput.controller;
  TextEditingController get _cvv => _cvvInput.controller;
  FocusNode get _numberFocus => _numberInput.focusNode;
  FocusNode get _expiryFocus => _expiryInput.focusNode;
  FocusNode get _cvvFocus => _cvvInput.focusNode;

  SmartCardBrand get _brand => SmartCardUtils.detectBrand(_number.text);

  @override
  void initState() {
    super.initState();
    _syncInputs();
    _refreshNumberDisplay();
  }

  @override
  void didUpdateWidget(covariant SmartCreditCardField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncInputs();
    _refreshNumberDisplay();
    _refreshCvvDisplay();
  }

  void _syncInputs() {
    _numberInput.update(
      controller: _config.numberController,
      focusNode: _config.numberFocusNode,
    );
    _expiryInput.update(
      controller: _config.expiryController,
      focusNode: _config.expiryFocusNode,
    );
    _cvvInput.update(
      controller: _config.cvvController,
      focusNode: _config.cvvFocusNode,
    );
    if (_numberText.bind(_number)) {
      _lastNumberText = _number.text;
    }
    _numberServer.bind(_config.numberServerError);
    _cvvServer.bind(_config.cvvServerError);
  }

  void _handleNumberController() {
    final text = _number.text;
    if (text == _lastNumberText) {
      return;
    }
    _lastNumberText = text;
    _onNumberChanged(text);
  }

  void _handleNumberServerChange() => _refreshNumberDisplay();

  void _handleCvvServerChange() => _refreshCvvDisplay();

  SmartCardNumberAssessment _assess() {
    return SmartCardUtils.assessNumber(
      _number.text,
      acceptedBrands: _config.acceptedBrands,
      validateLuhn: _config.validateLuhn,
      luhnExemptBrands: _config.luhnExemptBrands,
    );
  }

  String? _instantNumberError(SmartCardNumberAssessment assessment) {
    if (assessment.status != SmartCardNumberStatus.invalid) {
      return null;
    }
    switch (assessment.issue) {
      case SmartCardNumberIssue.brandNotAccepted:
        return _config.brandErrorText;
      case SmartCardNumberIssue.failsChecksum:
        return _config.luhnErrorText;
      default:
        return _config.numberErrorText;
    }
  }

  void _refreshNumberDisplay() {
    _numberDisplay.set(
      _config.numberServerError?.errorText ?? _instantNumberError(_assess()),
    );
  }

  void _refreshCvvDisplay() {
    _cvvDisplay.set(_config.cvvServerError?.errorText ?? _cvvBrandError);
  }

  void _updateCvvForBrand() {
    final text = _cvv.text;
    if (text.isEmpty) {
      _cvvBrandError = null;
    } else {
      final validator = SmartValidators.cardCvv(
        brand: () => _brand,
        allowedLengths: _config.cvvLengths,
        message: _config.cvvErrorText,
      );
      _cvvBrandError = validator(text);
    }
    _refreshCvvDisplay();
  }

  String? _statusText(SmartCardNumberAssessment assessment) {
    if (!_config.showNumberStatus) {
      return null;
    }
    final builder = _config.numberStatusBuilder;
    if (builder != null) {
      return builder(assessment);
    }
    final brandName = assessment.match.isCertain
        ? '${assessment.brand.displayName} \u00b7 '
        : '';
    switch (assessment.status) {
      case SmartCardNumberStatus.empty:
      case SmartCardNumberStatus.invalid:
        return null;
      case SmartCardNumberStatus.incomplete:
        final remaining = assessment.remainingDigits;
        if (remaining == null || !assessment.match.isCertain) {
          return null;
        }
        return '$brandName$remaining more ${remaining == 1 ? 'digit' : 'digits'}';
      case SmartCardNumberStatus.valid:
        return '${brandName}Number format looks valid';
    }
  }

  @override
  void dispose() {
    _listeners.unbindAll();
    _numberDisplay.dispose();
    _cvvDisplay.dispose();
    _numberInput.dispose();
    _expiryInput.dispose();
    _cvvInput.dispose();
    super.dispose();
  }

  SmartCreditCardValue _value() {
    final expiry = SmartCardUtils.tryParseExpiry(
      _expiry.text,
      format: _config.expiryFormat,
    );
    final digits = SmartCardUtils.digitsOnly(_number.text);
    return SmartCreditCardValue(
      number: digits,
      brand: SmartCardUtils.detectBrand(digits),
      numberStatus: _assess().status,
      expiryMonth: expiry?.month,
      expiryYear: expiry?.year,
      cvv: _cvv.text,
    );
  }

  void _notify() {
    _config.onChanged?.call(_value());
  }

  void _onNumberChanged(String text) {
    _config.numberServerError?.notifyFieldChanged();
    final assessment = _assess();
    _refreshNumberDisplay();
    _updateCvvForBrand();
    if (mounted) {
      setState(() {});
    }
    final count = assessment.digitCount;
    if (_config.autoAdvance &&
        _numberFocus.hasFocus &&
        assessment.isLocallyValid &&
        (count == assessment.brand.primaryLength ||
            count == assessment.brand.maxLength)) {
      _expiryFocus.requestFocus();
    }
    _notify();
  }

  void _onCvvChanged(String text) {
    _config.cvvServerError?.notifyFieldChanged();
    _cvvBrandError = null;
    _refreshCvvDisplay();
    _notify();
  }

  void _onExpiryChanged(String text) {
    final format = _config.expiryFormat;
    final complete = text.length == (format == SmartExpiryFormat.mmYy ? 5 : 7);
    if (_config.autoAdvance &&
        complete &&
        SmartCardUtils.tryParseExpiry(text, format: format) != null) {
      _cvvFocus.requestFocus();
    }
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled ?? widget.decoration.enabled;
    final brand = _brand;
    final assessment = _assess();
    final numberDecoration = widget.decoration.copyWith(
      suffixText: _config.showBrand && brand != SmartCardBrand.unknown
          ? brand.displayName
          : null,
      helperText: _statusText(assessment),
    );
    final number = SmartField(
      label: _config.numberLabel,
      hintText: _config.numberHint ?? '1234 5678 9012 3456',
      controller: _number,
      focusNode: _numberFocus,
      autofocus: widget.autofocus,
      enabled: enabled,
      readOnly: widget.readOnly,
      keyboardType: TextInputType.number,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: const [AutofillHints.creditCardNumber],
      textInputAction: TextInputAction.next,
      isRequired: widget.isRequired,
      requiredErrorText: widget.requiredErrorText,
      autovalidateMode: widget.autovalidateMode,
      serverError: _numberDisplay,
      decoration: numberDecoration,
      inputFormatters: const [SmartCardNumberFormatter()],
      validator: SmartValidators.cardNumber(
        acceptedBrands: _config.acceptedBrands,
        validateLuhn: _config.validateLuhn,
        luhnExemptBrands: _config.luhnExemptBrands,
        message: _config.numberErrorText,
        brandMessage: _config.brandErrorText,
        luhnMessage: _config.luhnErrorText,
      ),
    );
    final expiryMask = _config.expiryFormat == SmartExpiryFormat.mmYy
        ? '##/##'
        : '##/####';
    final expiry = SmartField(
      label: _config.expiryLabel,
      hintText:
          _config.expiryHint ??
          (_config.expiryFormat == SmartExpiryFormat.mmYy
              ? 'MM/YY'
              : 'MM/YYYY'),
      controller: _expiry,
      focusNode: _expiryFocus,
      enabled: enabled,
      readOnly: widget.readOnly,
      keyboardType: TextInputType.number,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: const [AutofillHints.creditCardExpirationDate],
      textInputAction: TextInputAction.next,
      onChanged: _onExpiryChanged,
      isRequired: widget.isRequired,
      requiredErrorText: widget.requiredErrorText,
      autovalidateMode: widget.autovalidateMode,
      serverError: _config.expiryServerError,
      decoration: widget.decoration,
      inputFormatters: [SmartMaskFormatter(SmartInputMask(expiryMask))],
      validator: SmartValidators.cardExpiry(
        format: _config.expiryFormat,
        now: _config.now,
        message: _config.expiryErrorText,
        expiredMessage: _config.expiredErrorText,
      ),
    );
    final cvvValidator = SmartValidators.cardCvv(
      brand: () => _brand,
      allowedLengths: _config.cvvLengths,
      message: _config.cvvErrorText,
    );
    final cvvFormatters = <TextInputFormatter>[
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(4),
    ];
    final cvv = _config.concealCvv
        ? SmartField.password(
            label: _config.cvvLabel,
            hintText: _config.cvvHint,
            controller: _cvv,
            focusNode: _cvvFocus,
            enabled: enabled,
            readOnly: widget.readOnly,
            keyboardType: TextInputType.number,
            inputFormatters: cvvFormatters,
            textInputAction: TextInputAction.done,
            onChanged: _onCvvChanged,
            isRequired: widget.isRequired,
            requiredErrorText: widget.requiredErrorText,
            autovalidateMode: widget.autovalidateMode,
            serverError: _cvvDisplay,
            decoration: widget.decoration,
            validator: cvvValidator,
          )
        : SmartField(
            label: _config.cvvLabel,
            hintText: _config.cvvHint,
            controller: _cvv,
            focusNode: _cvvFocus,
            enabled: enabled,
            readOnly: widget.readOnly,
            keyboardType: TextInputType.number,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.creditCardSecurityCode],
            textInputAction: TextInputAction.done,
            onChanged: _onCvvChanged,
            isRequired: widget.isRequired,
            requiredErrorText: widget.requiredErrorText,
            autovalidateMode: widget.autovalidateMode,
            serverError: _cvvDisplay,
            decoration: widget.decoration,
            inputFormatters: cvvFormatters,
            validator: cvvValidator,
          );
    return FormField<SmartCreditCardValue>(
      enabled: enabled,
      onSaved: (_) => _config.onSaved?.call(_value()),
      builder: (_) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 300;
            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  number,
                  const SizedBox(height: 16),
                  expiry,
                  const SizedBox(height: 16),
                  cvv,
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                number,
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: expiry),
                    const SizedBox(width: 16),
                    Expanded(child: cvv),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}
