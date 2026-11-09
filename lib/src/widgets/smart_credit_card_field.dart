import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_field_kit/src/formatting/smart_card_utils.dart';
import 'package:smart_field_kit/src/formatting/smart_input_mask.dart';
import 'package:smart_field_kit/src/validation/smart_validation_options.dart';
import 'package:smart_field_kit/src/validation/smart_validators.dart';
import 'package:smart_field_kit/src/widgets/smart_field.dart';

final class SmartCreditCardValue {
  const SmartCreditCardValue({
    required this.number,
    required this.brand,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cvv,
  });

  final String number;
  final SmartCardBrand brand;
  final int? expiryMonth;
  final int? expiryYear;
  final String cvv;

  String get last4 =>
      number.length <= 4 ? number : number.substring(number.length - 4);

  String get maskedNumber => SmartCardUtils.maskedNumber(number);

  bool get hasNumber => number.isNotEmpty;

  @override
  String toString() {
    return 'SmartCreditCardValue(brand: ${brand.displayName}, '
        'last4: $last4, expiry: ${expiryMonth == null ? 'none' : 'set'}, '
        'cvv: hidden)';
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
  TextEditingController? _ownedNumber;
  TextEditingController? _ownedExpiry;
  TextEditingController? _ownedCvv;
  FocusNode? _ownedNumberFocus;
  FocusNode? _ownedExpiryFocus;
  FocusNode? _ownedCvvFocus;

  SmartCreditCardConfig get _config => widget.config;

  TextEditingController get _number =>
      _config.numberController ?? _ownedNumber!;
  TextEditingController get _expiry =>
      _config.expiryController ?? _ownedExpiry!;
  TextEditingController get _cvv => _config.cvvController ?? _ownedCvv!;
  FocusNode get _numberFocus => _config.numberFocusNode ?? _ownedNumberFocus!;
  FocusNode get _expiryFocus => _config.expiryFocusNode ?? _ownedExpiryFocus!;
  FocusNode get _cvvFocus => _config.cvvFocusNode ?? _ownedCvvFocus!;

  SmartCardBrand get _brand => SmartCardUtils.detectBrand(_number.text);

  @override
  void initState() {
    super.initState();
    _ownedNumber = _config.numberController == null
        ? TextEditingController()
        : null;
    _ownedExpiry = _config.expiryController == null
        ? TextEditingController()
        : null;
    _ownedCvv = _config.cvvController == null ? TextEditingController() : null;
    _ownedNumberFocus = _config.numberFocusNode == null ? FocusNode() : null;
    _ownedExpiryFocus = _config.expiryFocusNode == null ? FocusNode() : null;
    _ownedCvvFocus = _config.cvvFocusNode == null ? FocusNode() : null;
  }

  @override
  void dispose() {
    _ownedNumber?.dispose();
    _ownedExpiry?.dispose();
    _ownedCvv?.dispose();
    _ownedNumberFocus?.dispose();
    _ownedExpiryFocus?.dispose();
    _ownedCvvFocus?.dispose();
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
      expiryMonth: expiry?.month,
      expiryYear: expiry?.year,
      cvv: _cvv.text,
    );
  }

  void _notify() {
    _config.onChanged?.call(_value());
  }

  void _onNumberChanged(String text) {
    final digits = SmartCardUtils.digitsOnly(text);
    final brand = SmartCardUtils.detectBrand(digits);
    if (_config.showBrand && mounted) {
      setState(() {});
    }
    if (_config.autoAdvance &&
        digits.length == _preferredLength(brand) &&
        SmartValidators.cardNumber(
              acceptedBrands: _config.acceptedBrands,
              validateLuhn: _config.validateLuhn,
            )(text) ==
            null) {
      _expiryFocus.requestFocus();
    }
    _notify();
  }

  int _preferredLength(SmartCardBrand brand) {
    switch (brand) {
      case SmartCardBrand.amex:
        return 15;
      case SmartCardBrand.dinersClub:
        return 14;
      default:
        return 16;
    }
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
    final numberDecoration = widget.decoration.copyWith(
      suffixText: _config.showBrand && brand != SmartCardBrand.unknown
          ? brand.displayName
          : null,
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
      onChanged: _onNumberChanged,
      isRequired: widget.isRequired,
      requiredErrorText: widget.requiredErrorText,
      autovalidateMode: widget.autovalidateMode,
      serverError: _config.numberServerError,
      decoration: numberDecoration,
      inputFormatters: const [SmartCardNumberFormatter()],
      validator: SmartValidators.cardNumber(
        acceptedBrands: _config.acceptedBrands,
        validateLuhn: _config.validateLuhn,
        message: _config.numberErrorText,
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
            onChanged: (_) => _notify(),
            isRequired: widget.isRequired,
            requiredErrorText: widget.requiredErrorText,
            autovalidateMode: widget.autovalidateMode,
            serverError: _config.cvvServerError,
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
            onChanged: (_) => _notify(),
            isRequired: widget.isRequired,
            requiredErrorText: widget.requiredErrorText,
            autovalidateMode: widget.autovalidateMode,
            serverError: _config.cvvServerError,
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
