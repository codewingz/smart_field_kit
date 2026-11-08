import 'package:country_picker/country_picker.dart' as country_picker;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:smart_field_kit/src/formatting/smart_numeric_formatters.dart';
import 'package:smart_field_kit/src/models/smart_phone_value.dart';
import 'package:smart_field_kit/src/validation/smart_phone_validation.dart';
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
       _phoneConfig = null,
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
       _phoneConfig = null,
       _isPassword = false,
       _isAmount = false,
       assert(minLength == null || minLength >= 0),
       assert(maxLength == null || maxLength >= 0),
       assert(minLength == null || maxLength == null || minLength <= maxLength);

  SmartField.name({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.enabled,
    this.readOnly = false,
    this.autofillHints = const [AutofillHints.name],
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
    List<TextInputFormatter>? inputFormatters,
    SmartTextValidationPreset? validationPreset,
    String? validationPresetErrorText,
  }) : keyboardType = TextInputType.name,
       textCapitalization = TextCapitalization.words,
       autocorrect = true,
       enableSuggestions = true,
       showVisibilityToggle = false,
       onRawChanged = null,
       onRawSaved = null,
       _fieldValidator = validationPreset == null
           ? null
           : SmartValidators.textPreset(
               validationPreset,
               message: validationPresetErrorText,
             ),
       _valueNormalizer = null,
       _minValueValidator = null,
       _maxValueValidator = null,
       _inputFormatters = inputFormatters?.toList(growable: false),
       _amountFormatter = null,
       _phoneConfig = null,
       _isPassword = false,
       _isAmount = false,
       assert(minLength == null || minLength >= 0),
       assert(maxLength == null || maxLength >= 0),
       assert(minLength == null || maxLength == null || minLength <= maxLength);

  SmartField.username({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.enabled,
    this.readOnly = false,
    this.autofillHints = const [AutofillHints.username],
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
    List<TextInputFormatter>? inputFormatters,
    SmartTextValidationPreset? validationPreset,
    String? validationPresetErrorText,
  }) : keyboardType = TextInputType.text,
       textCapitalization = TextCapitalization.none,
       autocorrect = false,
       enableSuggestions = false,
       showVisibilityToggle = false,
       onRawChanged = null,
       onRawSaved = null,
       _fieldValidator = validationPreset == null
           ? null
           : SmartValidators.textPreset(
               validationPreset,
               message: validationPresetErrorText,
             ),
       _valueNormalizer = null,
       _minValueValidator = null,
       _maxValueValidator = null,
       _inputFormatters = inputFormatters?.toList(growable: false),
       _amountFormatter = null,
       _phoneConfig = null,
       _isPassword = false,
       _isAmount = false,
       assert(minLength == null || minLength >= 0),
       assert(maxLength == null || maxLength >= 0),
       assert(minLength == null || maxLength == null || minLength <= maxLength);

  SmartField.phone({
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
    bool showCountryPicker = false,
    String? initialCountryCode,
    List<String>? allowedCountryCodes,
    List<String>? favoriteCountryCodes,
    bool showFlag = true,
    bool showContactPicker = false,
    bool showClearButton = false,
    SmartPhonePolicy policy = SmartPhonePolicy.auto,
    String phoneErrorText = 'Enter a valid phone number.',
    SmartPhoneCountryChanged? onCountryChanged,
    SmartPhoneChanged? onPhoneChanged,
    ValueChanged<SmartPhonePickerError>? onContactPickerError,
    SmartPhoneContactPicker? contactPicker,
    TextStyle? countryTextStyle,
    Widget? countryPlaceholder,
    EdgeInsetsGeometry? countryPadding,
  }) : keyboardType = TextInputType.phone,
       textCapitalization = TextCapitalization.none,
       autocorrect = false,
       enableSuggestions = false,
       autofillHints = const [AutofillHints.telephoneNumber],
       showVisibilityToggle = false,
       onRawChanged = null,
       onRawSaved = null,
       _fieldValidator = null,
       _valueNormalizer = null,
       _minValueValidator = null,
       _maxValueValidator = null,
       _inputFormatters = null,
       _amountFormatter = null,
       _phoneConfig = _SmartPhoneConfig(
         showCountryPicker: showCountryPicker,
         initialCountryCode: initialCountryCode,
         allowedCountryCodes: allowedCountryCodes,
         favoriteCountryCodes: favoriteCountryCodes,
         showFlag: showFlag,
         showContactPicker: showContactPicker,
         showClearButton: showClearButton,
         policy: policy,
         errorText: phoneErrorText,
         onCountryChanged: onCountryChanged,
         onPhoneChanged: onPhoneChanged,
         onContactPickerError: onContactPickerError,
         contactPicker: contactPicker,
         countryTextStyle: countryTextStyle,
         countryPlaceholder: countryPlaceholder,
         countryPadding: countryPadding,
       ),
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
       _phoneConfig = null,
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
       _phoneConfig = null,
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
       _phoneConfig = null,
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
  final _SmartPhoneConfig? _phoneConfig;
  final bool _isPassword;
  final bool _isAmount;

  bool get _isPhone => _phoneConfig != null;

  @override
  State<SmartField> createState() => _SmartFieldState();
}

class _SmartPhoneConfig {
  _SmartPhoneConfig({
    required this.showCountryPicker,
    required String? initialCountryCode,
    required List<String>? allowedCountryCodes,
    required List<String>? favoriteCountryCodes,
    required this.showFlag,
    required this.showContactPicker,
    required this.showClearButton,
    required this.policy,
    required this.errorText,
    required this.onCountryChanged,
    required this.onPhoneChanged,
    required this.onContactPickerError,
    required this.contactPicker,
    required this.countryTextStyle,
    required this.countryPlaceholder,
    required this.countryPadding,
  }) : initialCountryCode = initialCountryCode?.toUpperCase(),
       allowedCountryCodes = allowedCountryCodes
           ?.map((code) => code.toUpperCase())
           .toList(growable: false),
       favoriteCountryCodes = favoriteCountryCodes
           ?.map((code) => code.toUpperCase())
           .toList(growable: false);

  final bool showCountryPicker;
  final String? initialCountryCode;
  final List<String>? allowedCountryCodes;
  final List<String>? favoriteCountryCodes;
  final bool showFlag;
  final bool showContactPicker;
  final bool showClearButton;
  final SmartPhonePolicy policy;
  final String errorText;
  final SmartPhoneCountryChanged? onCountryChanged;
  final SmartPhoneChanged? onPhoneChanged;
  final ValueChanged<SmartPhonePickerError>? onContactPickerError;
  final SmartPhoneContactPicker? contactPicker;
  final TextStyle? countryTextStyle;
  final Widget? countryPlaceholder;
  final EdgeInsetsGeometry? countryPadding;
}

class _SmartFieldState extends State<SmartField> {
  late bool _obscureText = widget._isPassword;
  TextEditingController? _ownedAmountController;
  FocusNode? _ownedAmountFocusNode;
  TextEditingController? _ownedPhoneController;
  FocusNode? _ownedPhoneFocusNode;
  final GlobalKey<FormFieldState<String>> _phoneFieldKey = GlobalKey();
  final country_picker.CountryService _countryService =
      country_picker.CountryService();
  SmartPhoneCountry? _selectedCountry;
  String? _lastPhoneText;
  bool _updatingAmountText = false;

  TextEditingController? get _effectiveController {
    if (widget._isAmount) {
      return widget.controller ?? _ownedAmountController;
    }
    if (widget._isPhone) {
      return widget.controller ?? _ownedPhoneController;
    }
    return widget.controller;
  }

  FocusNode? get _effectiveFocusNode {
    if (widget._isAmount) {
      return widget.focusNode ?? _ownedAmountFocusNode;
    }
    if (widget._isPhone) {
      return widget.focusNode ?? _ownedPhoneFocusNode;
    }
    return widget.focusNode;
  }

  @override
  void initState() {
    super.initState();
    _configureAmountState();
    _configurePhoneState();
  }

  @override
  void didUpdateWidget(covariant SmartField oldWidget) {
    final oldAmountController = oldWidget._isAmount
        ? oldWidget.controller ?? _ownedAmountController
        : null;
    final oldAmountFocusNode = oldWidget._isAmount
        ? oldWidget.focusNode ?? _ownedAmountFocusNode
        : null;
    final oldPhoneController = oldWidget._isPhone
        ? oldWidget.controller ?? _ownedPhoneController
        : null;
    oldAmountController?.removeListener(_handleAmountControllerChange);
    oldAmountFocusNode?.removeListener(_handleAmountFocusChange);
    oldPhoneController?.removeListener(_handlePhoneControllerChange);
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
    if (oldWidget._isPhone &&
        oldWidget.controller == null &&
        (!widget._isPhone || widget.controller != null)) {
      _ownedPhoneController?.dispose();
      _ownedPhoneController = null;
    }
    if (oldWidget._isPhone &&
        oldWidget.focusNode == null &&
        (!widget._isPhone || widget.focusNode != null)) {
      _ownedPhoneFocusNode?.dispose();
      _ownedPhoneFocusNode = null;
    }
    if (widget._isPhone &&
        widget.controller == null &&
        _ownedPhoneController == null) {
      _ownedPhoneController = TextEditingController.fromValue(
        oldWidget.controller?.value,
      );
    }
    _configureAmountState();
    _configurePhoneState();
  }

  void _configurePhoneState() {
    if (!widget._isPhone) {
      return;
    }
    _ownedPhoneController ??= widget.controller == null
        ? TextEditingController()
        : null;
    _ownedPhoneFocusNode ??= widget.focusNode == null ? FocusNode() : null;
    _selectedCountry =
        _resolveCountry(_selectedCountry?.isoCode) ??
        _resolveCountry(widget._phoneConfig!.initialCountryCode);
    _lastPhoneText = _effectiveController?.text;
    _effectiveController?.addListener(_handlePhoneControllerChange);
  }

  SmartPhoneCountry? _resolveCountry(String? isoCode) {
    if (isoCode == null || !_isCountryAllowed(isoCode)) {
      return null;
    }
    final country = _countryService.findByCode(isoCode);
    return country == null ? null : _toSmartCountry(country);
  }

  bool _isCountryAllowed(String isoCode) {
    final allowed = widget._phoneConfig?.allowedCountryCodes;
    return allowed == null || allowed.contains(isoCode.toUpperCase());
  }

  SmartPhoneCountry _toSmartCountry(country_picker.Country country) {
    return SmartPhoneCountry(
      isoCode: country.countryCode,
      name: country.name,
      dialCode: '+${country.phoneCode}',
      flagEmoji: country.flagEmoji,
    );
  }

  void _handlePhoneControllerChange() {
    final text = _effectiveController?.text ?? '';
    if (text == _lastPhoneText) {
      return;
    }
    _lastPhoneText = text;
    widget._phoneConfig?.onPhoneChanged?.call(
      SmartPhoneValidation.parseValue(text, country: _selectedCountry),
    );
    if (mounted) {
      setState(() {});
    }
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
      prefixIcon: _phonePrefixIcon(decoration.prefixIcon),
      suffixIcon: _suffixIcon(decoration.suffixIcon),
    );
  }

  Widget? _phonePrefixIcon(Widget? existing) {
    final config = widget._phoneConfig;
    if (config == null || !config.showCountryPicker) {
      return existing;
    }
    final enabled = _isInteractive;
    final selected = _selectedCountry;
    final content = selected == null
        ? config.countryPlaceholder ?? const Icon(Icons.public, size: 20)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (config.showFlag) ...[
                Text(selected.flagEmoji),
                const SizedBox(width: 6),
              ],
              Text(
                selected.dialCode,
                style:
                    config.countryTextStyle ??
                    Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          );
    final picker = Semantics(
      label: selected == null
          ? 'Select country'
          : 'Change country, ${selected.name}, ${selected.dialCode}',
      button: true,
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? _showCountryPicker : null,
        child: Padding(
          padding:
              config.countryPadding ??
              const EdgeInsetsDirectional.symmetric(horizontal: 12),
          child: content,
        ),
      ),
    );
    if (existing == null) {
      return picker;
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [existing, picker]);
  }

  bool get _isInteractive {
    return (widget.enabled ?? widget.decoration.enabled) && !widget.readOnly;
  }

  bool get _supportsContactPicker {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  Widget? _suffixIcon(Widget? existing) {
    final children = <Widget>[?existing];

    if (widget._isPassword && widget.showVisibilityToggle) {
      children.add(_passwordToggle());
    }

    final phone = widget._phoneConfig;
    if (phone != null) {
      if (phone.showContactPicker && _supportsContactPicker) {
        children.add(
          IconButton(
            tooltip: 'Select phone number from contacts',
            onPressed: _isInteractive ? _pickContact : null,
            icon: const Icon(Icons.contact_phone),
          ),
        );
      }
      if (phone.showClearButton) {
        children.add(
          IconButton(
            tooltip: 'Clear phone number',
            onPressed:
                _isInteractive &&
                    (_effectiveController?.text.isNotEmpty ?? false)
                ? _clearPhone
                : null,
            icon: const Icon(Icons.clear),
          ),
        );
      }
    }

    if (children.isEmpty) {
      return null;
    }
    if (children.length == 1) {
      return children.single;
    }
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }

  Widget _passwordToggle() {
    final label = _obscureText ? 'Show password' : 'Hide password';
    final isEnabled = widget.enabled ?? widget.decoration.enabled;
    return Semantics(
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
  }

  void _showCountryPicker() {
    final config = widget._phoneConfig!;
    final theme = Theme.of(context);
    final favorites = config.favoriteCountryCodes
        ?.where(_isCountryAllowed)
        .toList(growable: false);
    country_picker.showCountryPicker(
      context: context,
      showPhoneCode: true,
      countryFilter: config.allowedCountryCodes,
      favorite: favorites ?? const [],
      customFlagBuilder: config.showFlag
          ? null
          : (country) => const SizedBox.shrink(),
      countryListTheme: country_picker.CountryListThemeData(
        backgroundColor: theme.colorScheme.surface,
        textStyle: theme.textTheme.bodyLarge,
        searchTextStyle: theme.textTheme.bodyLarge,
        inputDecoration: const InputDecoration(
          hintText: 'Search country',
          prefixIcon: Icon(Icons.search),
        ),
      ),
      onSelect: (country) {
        if (!_isCountryAllowed(country.countryCode)) {
          return;
        }
        final selected = _toSmartCountry(country);
        setState(() => _selectedCountry = selected);
        config.onCountryChanged?.call(selected);
        config.onPhoneChanged?.call(
          SmartPhoneValidation.parseValue(
            _effectiveController?.text ?? '',
            country: selected,
          ),
        );
        _phoneFieldKey.currentState?.validate();
      },
    );
  }

  void _clearPhone() {
    final controller = _effectiveController;
    if (controller == null || controller.text.isEmpty) {
      return;
    }
    controller.clear();
    widget.onChanged?.call('');
    _phoneFieldKey.currentState?.didChange('');
    _phoneFieldKey.currentState?.validate();
    setState(() {});
  }

  Future<void> _pickContact() async {
    final config = widget._phoneConfig!;
    if (!_supportsContactPicker) {
      _reportPhonePickerError(
        const SmartPhonePickerError(
          SmartPhonePickerErrorCode.unsupportedPlatform,
          'Contact selection is unavailable on this platform.',
        ),
      );
      return;
    }
    try {
      String? number;
      if (config.contactPicker == null) {
        final contact = await FlutterNativeContactPicker().selectPhoneNumber();
        if (!mounted || contact == null) {
          return;
        }
        number = contact.selectedPhoneNumber;
        if (number == null) {
          _reportPhonePickerError(
            const SmartPhonePickerError(
              SmartPhonePickerErrorCode.unavailableNumber,
              'The selected contact did not provide a phone number.',
            ),
          );
          return;
        }
      } else {
        number = await config.contactPicker!();
      }
      if (!mounted || number == null) {
        return;
      }
      if (number.isEmpty) {
        _reportPhonePickerError(
          const SmartPhonePickerError(
            SmartPhonePickerErrorCode.unavailableNumber,
            'The selected contact did not provide a phone number.',
          ),
        );
        return;
      }
      final inferred = _countryForInternationalNumber(number);
      if (inferred.disallowed) {
        _reportPhonePickerError(
          const SmartPhonePickerError(
            SmartPhonePickerErrorCode.disallowedCountry,
            'The selected phone number is outside the allowed countries.',
          ),
        );
        return;
      }
      final country = inferred.country ?? _selectedCountry;
      final parsed = SmartPhoneValidation.parseValue(number, country: country);
      if (!parsed.isValid) {
        _reportPhonePickerError(
          const SmartPhonePickerError(
            SmartPhonePickerErrorCode.invalidNumber,
            'The selected contact does not contain a valid phone number.',
          ),
        );
        return;
      }
      if (inferred.country != null && inferred.country != _selectedCountry) {
        setState(() => _selectedCountry = inferred.country);
        config.onCountryChanged?.call(inferred.country);
      }
      final controller = _effectiveController!;
      controller.value = TextEditingValue(
        text: number,
        selection: TextSelection.collapsed(offset: number.length),
      );
      widget.onChanged?.call(number);
      _phoneFieldKey.currentState?.didChange(number);
      _phoneFieldKey.currentState?.validate();
      if (mounted) {
        setState(() {});
      }
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      _reportPhonePickerError(
        SmartPhonePickerError(
          SmartPhonePickerErrorCode.platformFailure,
          'Unable to open the contact picker.',
          error,
        ),
      );
    }
  }

  ({SmartPhoneCountry? country, bool disallowed})
  _countryForInternationalNumber(String value) {
    if (!value.startsWith('+')) {
      return (country: null, disallowed: false);
    }
    final parsedIsoCode = SmartPhoneValidation.parsedIsoCode(value);
    if (parsedIsoCode != null && !_isCountryAllowed(parsedIsoCode)) {
      return (country: null, disallowed: true);
    }
    final compact = value.replaceAll(RegExp(r'[ ()-]'), '');
    final all = _countryService.getAll();
    final matching = all
        .where((country) => compact.startsWith('+${country.phoneCode}'))
        .toList();
    if (matching.isEmpty) {
      return (country: null, disallowed: false);
    }
    final longest = matching
        .map((country) => country.phoneCode.length)
        .reduce((left, right) => left > right ? left : right);
    final candidates = matching
        .where((country) => country.phoneCode.length == longest)
        .toList();
    final selected = _selectedCountry;
    if (selected != null &&
        candidates.any((country) => country.countryCode == selected.isoCode)) {
      return (country: selected, disallowed: false);
    }
    if (candidates.length != 1) {
      return (country: null, disallowed: false);
    }
    final candidate = candidates.single;
    if (!_isCountryAllowed(candidate.countryCode)) {
      return (country: null, disallowed: true);
    }
    return (country: _toSmartCountry(candidate), disallowed: false);
  }

  void _reportPhonePickerError(SmartPhonePickerError error) {
    final callback = widget._phoneConfig?.onContactPickerError;
    if (callback != null) {
      callback(error);
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(content: Text(error.message)));
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
    final phone = widget._phoneConfig;
    if (phone != null) {
      validators.add(
        SmartValidators.phone(
          policy: phone.policy,
          country: _selectedCountry,
          message: phone.errorText,
        ),
      );
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
    if (widget._isPhone) {
      setState(() {});
    }
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
    if (widget._isPhone) {
      _effectiveController?.removeListener(_handlePhoneControllerChange);
    }
    _ownedAmountController?.dispose();
    _ownedAmountFocusNode?.dispose();
    _ownedPhoneController?.dispose();
    _ownedPhoneFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: widget._isPhone ? _phoneFieldKey : null,
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
