import 'package:country_picker/country_picker.dart' as country_picker;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:smart_field_kit/src/formatting/smart_date_utils.dart';
import 'package:smart_field_kit/src/formatting/smart_input_mask.dart';
import 'package:smart_field_kit/src/formatting/smart_numeric_formatters.dart';
import 'package:smart_field_kit/src/formatting/smart_text_formatters.dart';
import 'package:smart_field_kit/src/formatting/smart_text_utils.dart';
import 'package:smart_field_kit/src/masking/smart_masking.dart';
import 'package:smart_field_kit/src/models/smart_otp_style.dart';
import 'package:smart_field_kit/src/models/smart_phone_value.dart';
import 'package:smart_field_kit/src/validation/smart_async_validation.dart';
import 'package:smart_field_kit/src/validation/smart_password_strength.dart';
import 'package:smart_field_kit/src/validation/smart_phone_validation.dart';
import 'package:smart_field_kit/src/validation/smart_validation_options.dart';
import 'package:smart_field_kit/src/validation/smart_url_validation.dart';
import 'package:smart_field_kit/src/formatting/smart_card_utils.dart';
import 'package:smart_field_kit/src/widgets/smart_credit_card_field.dart';
import 'package:smart_field_kit/src/widgets/smart_date_time_field.dart';
import 'package:smart_field_kit/src/widgets/smart_field_design.dart';
import 'package:smart_field_kit/src/widgets/smart_field_support.dart';
import 'package:smart_field_kit/src/widgets/smart_amount_display.dart';
import 'package:smart_field_kit/src/widgets/smart_listener_binding.dart';
import 'package:smart_field_kit/src/widgets/smart_password_strength_indicator.dart';
import 'package:smart_field_kit/src/widgets/smart_search_debouncer.dart';
import 'package:smart_field_kit/src/validation/smart_validators.dart';
import 'package:smart_field_kit/src/widgets/smart_otp_field.dart';

part 'smart_field_internals.dart';
part 'smart_field_phone.dart';

abstract class _SmartFieldBase extends StatefulWidget {
  const _SmartFieldBase(
    this._core, {
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
    this.autocorrect = false,
    this.enableSuggestions = false,
    this.autofillHints,
    this.textInputAction,
    this.minLines,
    this.maxLines = 1,
    this.expands = false,
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
    this.validator,
    this.autovalidateMode,
    this.asyncValidation,
    this.validationMode = SmartValidationMode.both,
    this.builtInChecks = const {},
    this.serverError,
    this.restorationId,
    this.decoration = const InputDecoration(),
    this.showVisibilityToggle = false,
    List<TextInputFormatter>? inputFormatters,
  }) : _developerFormatters = inputFormatters,
       assert(minLines == null || minLines > 0),
       assert(maxLines == null || maxLines > 0),
       assert(minLines == null || maxLines == null || maxLines >= minLines),
       assert(!expands || (minLines == null && maxLines == null)),
       assert(minLength == null || minLength >= 0),
       assert(maxLength == null || maxLength >= 0),
       assert(minLength == null || maxLength == null || minLength <= maxLength);

  final _SmartFieldCore _core;
  final List<TextInputFormatter>? _developerFormatters;
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
  final int? minLines;
  final int? maxLines;
  final bool expands;
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
  final SmartAsyncValidation? asyncValidation;
  final SmartValidationMode validationMode;
  final Set<SmartBuiltInCheck> builtInChecks;
  final SmartServerError? serverError;
  final String? restorationId;
  final InputDecoration decoration;
  final bool showVisibilityToggle;

  List<TextInputFormatter>? get inputFormatters {
    final own = _core.formatters;
    if (own.isEmpty) {
      return _developerFormatters;
    }
    return [...own, ...?_developerFormatters];
  }

  SmartValidator? get _fieldValidator => _core.fieldValidator;
  SmartValueNormalizer? get _valueNormalizer => _core.valueNormalizer;
  SmartValidator? get _minValueValidator => _core.minValueValidator;
  SmartValidator? get _maxValueValidator => _core.maxValueValidator;
  SmartAmountFormatter? get _amountFormatter => _core.amountFormatter;
  _SmartMaskConfig? get _maskConfig => _core.maskConfig;
  _SmartPhoneConfig? get _phoneConfig => _core.phoneConfig;
  SmartOtpConfiguration? get _otpConfig => _core.otpConfig;
  _SmartSearchConfig? get _searchConfig => _core.searchConfig;
  String? get _percentageSuffix => _core.percentageSuffix;
  bool get _isPassword => _core.isPassword;
  bool get _isAmount => _core.isAmount;
  bool get _isPhone => _phoneConfig != null;
  bool get _isSearch => _searchConfig != null;
  bool get _supportsMasking => _maskConfig != null;
}

class SmartField extends _SmartFieldBase {
  const SmartField({
    super.key,
    super.label,
    super.hintText,
    super.controller,
    super.focusNode,
    super.autofocus,
    super.enabled,
    super.readOnly,
    super.textInputAction,
    super.onChanged,
    super.onSaved,
    super.isRequired,
    super.requiredErrorText,
    super.minLength,
    super.minLengthErrorText,
    super.maxLength,
    super.maxLengthErrorText,
    super.validator,
    super.autovalidateMode,
    super.asyncValidation,
    super.validationMode,
    super.builtInChecks,
    super.serverError,
    super.restorationId,
    super.decoration,
    super.keyboardType,
    super.textCapitalization,
    super.autocorrect = true,
    super.enableSuggestions = true,
    super.autofillHints,
    super.minLines,
    super.maxLines,
    super.expands,
    super.inputFormatters,
  }) : super(const _SmartFieldCore());

  SmartField.description({
    super.key,
    super.label,
    super.hintText,
    super.controller,
    super.focusNode,
    super.autofocus,
    super.enabled,
    super.readOnly,
    super.onChanged,
    super.onSaved,
    super.isRequired,
    super.requiredErrorText,
    super.minLength,
    super.minLengthErrorText,
    super.maxLength,
    super.maxLengthErrorText,
    super.validator,
    super.autovalidateMode,
    super.asyncValidation,
    super.validationMode,
    super.builtInChecks,
    super.serverError,
    super.restorationId,
    super.decoration,
    super.keyboardType = TextInputType.multiline,
    super.textCapitalization,
    super.autocorrect = true,
    super.enableSuggestions = true,
    super.autofillHints,
    super.textInputAction = TextInputAction.newline,
    super.minLines = 3,
    super.maxLines = null,
    super.expands,
    super.inputFormatters,
    SmartTextCase textCase = SmartTextCase.none,
    bool collapseWhitespace = false,
    int? minWords,
    int? maxWords,
    bool showWordCount = false,
    String? minWordsErrorText,
    String? maxWordsErrorText,
    SmartTextValidationPreset? validationPreset,
    String? validationPresetErrorText,
  }) : assert(_hasValidLengthRange(minWords, maxWords)),
       super(
         _textCore(
           textCase: textCase,
           collapseWhitespace: collapseWhitespace,
           minWords: minWords,
           maxWords: maxWords,
           showWordCount: showWordCount,
           minWordsErrorText: minWordsErrorText,
           maxWordsErrorText: maxWordsErrorText,
           validationPreset: validationPreset,
           validationPresetErrorText: validationPresetErrorText,
         ),
       );

  SmartField.text({
    super.key,
    super.label,
    super.hintText,
    super.controller,
    super.focusNode,
    super.autofocus,
    super.enabled,
    super.readOnly,
    super.textInputAction,
    super.onChanged,
    super.onSaved,
    super.isRequired,
    super.requiredErrorText,
    super.minLength,
    super.minLengthErrorText,
    super.maxLength,
    super.maxLengthErrorText,
    super.validator,
    super.autovalidateMode,
    super.asyncValidation,
    super.validationMode,
    super.builtInChecks,
    super.serverError,
    super.restorationId,
    super.decoration,
    super.keyboardType,
    super.textCapitalization,
    super.autocorrect = true,
    super.enableSuggestions = true,
    super.autofillHints,
    super.minLines,
    super.maxLines,
    super.expands,
    super.onRawChanged,
    super.onRawSaved,
    super.inputFormatters,
    SmartTextCase textCase = SmartTextCase.none,
    bool collapseWhitespace = false,
    String? inputMask,
    SmartValueNormalizer? rawValueBuilder,
    String inputMaskErrorText = 'Complete the value.',
    int? minWords,
    int? maxWords,
    bool showWordCount = false,
    String? minWordsErrorText,
    String? maxWordsErrorText,
    SmartTextValidationPreset? validationPreset,
    String? validationPresetErrorText,
  }) : assert(_hasValidLengthRange(minWords, maxWords)),
       super(
         _textCore(
           textCase: textCase,
           collapseWhitespace: collapseWhitespace,
           inputMask: inputMask,
           inputMaskErrorText: inputMaskErrorText,
           rawValueBuilder: rawValueBuilder,
           minWords: minWords,
           maxWords: maxWords,
           showWordCount: showWordCount,
           minWordsErrorText: minWordsErrorText,
           maxWordsErrorText: maxWordsErrorText,
           validationPreset: validationPreset,
           validationPresetErrorText: validationPresetErrorText,
         ),
       );

  SmartField.email({
    super.key,
    super.label,
    super.hintText,
    super.controller,
    super.focusNode,
    super.autofocus,
    super.enabled,
    super.readOnly,
    super.textInputAction,
    super.onChanged,
    super.onSaved,
    super.isRequired,
    super.requiredErrorText,
    super.minLength,
    super.minLengthErrorText,
    super.maxLength,
    super.maxLengthErrorText,
    super.validator,
    super.autovalidateMode,
    super.asyncValidation,
    super.validationMode,
    super.builtInChecks,
    super.serverError,
    super.restorationId,
    super.decoration,
    SmartEmailPolicy policy = SmartEmailPolicy.standard,
    String emailErrorText = 'Enter a valid email address.',
  }) : super(
         _SmartFieldCore(
           fieldValidator: SmartValidators.email(
             policy: policy,
             message: emailErrorText,
           ),
         ),
         keyboardType: TextInputType.emailAddress,
         autofillHints: const [AutofillHints.email],
       );

  SmartField.url({
    super.key,
    super.label,
    super.hintText,
    super.controller,
    super.focusNode,
    super.autofocus,
    super.enabled,
    super.readOnly,
    super.textInputAction = TextInputAction.done,
    super.onChanged,
    super.onSaved,
    super.isRequired,
    super.requiredErrorText,
    super.minLength,
    super.minLengthErrorText,
    super.maxLength,
    super.maxLengthErrorText,
    super.validator,
    super.autovalidateMode,
    super.asyncValidation,
    super.validationMode,
    super.builtInChecks,
    super.serverError,
    super.restorationId,
    super.decoration,
    super.inputFormatters,
    Set<String> allowedSchemes = SmartUrlValidation.defaultSchemes,
    bool allowBareDomain = false,
    String urlErrorText = 'Enter a valid URL.',
  }) : super(
         _SmartFieldCore(
           fieldValidator: SmartValidators.url(
             allowedSchemes: allowedSchemes,
             allowBareDomain: allowBareDomain,
             message: urlErrorText,
           ),
         ),
         keyboardType: TextInputType.url,
         autofillHints: const [AutofillHints.url],
       );

  SmartField.name({
    super.key,
    super.label,
    super.hintText,
    super.controller,
    super.focusNode,
    super.autofocus,
    super.enabled,
    super.readOnly,
    super.textInputAction,
    super.onChanged,
    super.onSaved,
    super.isRequired,
    super.requiredErrorText,
    super.minLength,
    super.minLengthErrorText,
    super.maxLength,
    super.maxLengthErrorText,
    super.validator,
    super.autovalidateMode,
    super.asyncValidation,
    super.validationMode,
    super.builtInChecks,
    super.serverError,
    super.restorationId,
    super.decoration,
    super.autofillHints = const [AutofillHints.name],
    super.inputFormatters,
    bool capitalizeWords = false,
    SmartTextValidationPreset? validationPreset,
    String? validationPresetErrorText,
  }) : super(
         _textCore(
           extraFormatters: [
             if (capitalizeWords)
               const SmartTextCaseFormatter(SmartTextCase.capitalizeWords),
           ],
           validationPreset: validationPreset,
           validationPresetErrorText: validationPresetErrorText,
         ),
         keyboardType: TextInputType.name,
         textCapitalization: TextCapitalization.words,
         autocorrect: true,
         enableSuggestions: true,
       );

  SmartField.username({
    super.key,
    super.label,
    super.hintText,
    super.controller,
    super.focusNode,
    super.autofocus,
    super.enabled,
    super.readOnly,
    super.textInputAction,
    super.onChanged,
    super.onSaved,
    super.isRequired,
    super.requiredErrorText,
    super.minLength,
    super.minLengthErrorText,
    super.maxLength,
    super.maxLengthErrorText,
    super.validator,
    super.autovalidateMode,
    super.asyncValidation,
    super.validationMode,
    super.builtInChecks,
    super.serverError,
    super.restorationId,
    super.decoration,
    super.autofillHints = const [AutofillHints.username],
    super.inputFormatters,
    SmartTextCase usernameCase = SmartTextCase.none,
    SmartUsernameCharacters allowedCharacters = SmartUsernameCharacters.any,
    SmartTextValidationPreset? validationPreset,
    String? validationPresetErrorText,
  }) : super(
         _textCore(
           extraFormatters: [
             if (usernameCase != SmartTextCase.none ||
                 allowedCharacters != SmartUsernameCharacters.any)
               SmartUsernameFormatter(
                 allowedCharacters: allowedCharacters,
                 textCase: usernameCase,
               ),
           ],
           validationPreset: validationPreset,
           validationPresetErrorText: validationPresetErrorText,
         ),
         keyboardType: TextInputType.text,
       );

  SmartField.search({
    super.key,
    super.label,
    super.hintText,
    super.controller,
    super.focusNode,
    super.autofocus,
    super.enabled,
    super.readOnly,
    super.onChanged,
    super.onSaved,
    super.isRequired,
    super.requiredErrorText,
    super.minLength,
    super.minLengthErrorText,
    super.maxLength,
    super.maxLengthErrorText,
    super.validator,
    super.autovalidateMode,
    super.asyncValidation,
    super.validationMode,
    super.builtInChecks,
    super.serverError,
    super.restorationId,
    super.decoration,
    super.inputFormatters,
    GestureTapCallback? onTap,
    ValueChanged<String>? onSubmitted,
    ValueChanged<String>? onSearch,
    Duration? debounceDuration,
    VoidCallback? onCleared,
    bool showClearButton = true,
    bool isLoading = false,
    Widget? searchIcon = const Icon(Icons.search),
    Widget? clearIcon = const Icon(Icons.clear),
  }) : super(
         _SmartFieldCore(
           searchConfig: _createSearchConfig(
             onTap: onTap,
             onSubmitted: onSubmitted,
             onSearch: onSearch,
             debounceDuration: debounceDuration,
             onCleared: onCleared,
             showClearButton: showClearButton,
             isLoading: isLoading,
             searchIcon: searchIcon,
             clearIcon: clearIcon,
           ),
         ),
         keyboardType: TextInputType.text,
         autocorrect: true,
         enableSuggestions: true,
         textInputAction: TextInputAction.search,
       );

  SmartField.phone({
    super.key,
    super.label,
    super.hintText,
    super.controller,
    super.focusNode,
    super.autofocus,
    super.enabled,
    super.readOnly,
    super.textInputAction,
    super.onChanged,
    super.onSaved,
    super.isRequired,
    super.requiredErrorText,
    super.minLength,
    super.minLengthErrorText,
    super.maxLength,
    super.maxLengthErrorText,
    super.validator,
    super.autovalidateMode,
    super.asyncValidation,
    super.validationMode,
    super.builtInChecks,
    super.serverError,
    super.restorationId,
    super.decoration,
    bool mask = false,
    int maskVisibleSuffixDigits = 4,
    String maskCharacter = '*',
    bool revealMaskOnFocus = true,
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
  }) : super(
         _SmartFieldCore(
           maskConfig: _createMaskConfig(
             enabled: mask,
             kind: _SmartMaskKind.phone,
             visibleSuffixDigits: maskVisibleSuffixDigits,
             maskCharacter: maskCharacter,
             revealOnFocus: revealMaskOnFocus,
           ),
           phoneConfig: _SmartPhoneConfig(
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
         ),
         keyboardType: TextInputType.phone,
         autofillHints: const [AutofillHints.telephoneNumber],
       );

  SmartField.password({
    super.key,
    super.label,
    super.hintText,
    super.controller,
    super.focusNode,
    super.autofocus,
    super.enabled,
    super.readOnly,
    super.textInputAction,
    super.onChanged,
    super.onSaved,
    super.isRequired,
    super.requiredErrorText,
    super.minLength,
    super.minLengthErrorText,
    super.maxLength,
    super.maxLengthErrorText,
    super.validator,
    super.autovalidateMode,
    super.asyncValidation,
    super.validationMode,
    super.builtInChecks,
    super.serverError,
    super.restorationId,
    super.decoration,
    super.showVisibilityToggle = true,
    super.keyboardType = TextInputType.visiblePassword,
    super.inputFormatters,
    SmartPasswordPolicy? policy,
    String passwordErrorText = 'Password does not meet the selected policy.',
    TextEditingController? matchController,
    String mismatchErrorText = 'Passwords do not match.',
    bool showStrengthIndicator = false,
    List<SmartPasswordCriterion>? strengthCriteria,
    Map<SmartPasswordStrengthLevel, String>? strengthLabels,
    bool showStrengthChecklist = false,
  }) : super(
         _SmartFieldCore(
           fieldValidator: policy == null
               ? null
               : SmartValidators.password(
                   policy: policy,
                   message: passwordErrorText,
                 ),
           isPassword: true,
           matchController: matchController,
           mismatchMessage: mismatchErrorText,
           strength: showStrengthIndicator
               ? _SmartStrengthConfig(
                   criteria: strengthCriteria,
                   labels: strengthLabels,
                   showChecklist: showStrengthChecklist,
                 )
               : null,
         ),
         autofillHints: const [AutofillHints.password],
       );

  SmartField.number({
    super.key,
    super.label,
    super.hintText,
    super.controller,
    super.focusNode,
    super.autofocus,
    super.enabled,
    super.readOnly,
    super.textInputAction,
    super.onChanged,
    super.onSaved,
    super.isRequired,
    super.requiredErrorText,
    super.minLength,
    super.minLengthErrorText,
    super.maxLength,
    super.maxLengthErrorText,
    super.validator,
    super.autovalidateMode,
    super.asyncValidation,
    super.validationMode,
    super.builtInChecks,
    super.serverError,
    super.restorationId,
    super.decoration,
    String? minValue,
    String? minValueErrorText,
    String? maxValue,
    String? maxValueErrorText,
    bool mask = false,
    int maskVisibleSuffixDigits = 4,
    String maskCharacter = '*',
    bool revealMaskOnFocus = true,
    bool allowNegative = false,
    SmartNumberPolicy policy = SmartNumberPolicy.standard,
    String numberErrorText = 'Enter a valid whole number.',
  }) : super(
         _SmartFieldCore(
           fieldValidator: SmartValidators.number(
             policy: policy,
             allowNegative: allowNegative,
             message: numberErrorText,
           ),
           minValueValidator: minValue == null
               ? null
               : SmartValidators.minValue(minValue, message: minValueErrorText),
           maxValueValidator: maxValue == null
               ? null
               : SmartValidators.maxValue(maxValue, message: maxValueErrorText),
           maskConfig: _createMaskConfig(
             enabled: mask,
             kind: _SmartMaskKind.account,
             visibleSuffixDigits: maskVisibleSuffixDigits,
             maskCharacter: maskCharacter,
             revealOnFocus: revealMaskOnFocus,
           ),
           formatters: [
             SmartNumberInputFormatter(allowNegative: allowNegative),
           ],
         ),
         keyboardType: TextInputType.numberWithOptions(signed: allowNegative),
       );

  SmartField.percentage({
    super.key,
    super.label,
    super.hintText,
    super.controller,
    super.focusNode,
    super.autofocus,
    super.enabled,
    super.readOnly,
    super.textInputAction,
    super.onChanged,
    super.onSaved,
    super.isRequired,
    super.requiredErrorText,
    super.minLength,
    super.minLengthErrorText,
    super.maxLength,
    super.maxLengthErrorText,
    super.validator,
    super.autovalidateMode,
    super.asyncValidation,
    super.validationMode,
    super.builtInChecks,
    super.serverError,
    super.restorationId,
    super.decoration,
    String? minValue,
    String? minValueErrorText,
    String? maxValue,
    String? maxValueErrorText,
    int? decimalPlaces,
    bool allowNegative = true,
    String? percentSymbol = '%',
    String percentageErrorText = 'Enter a valid percentage.',
  }) : assert(decimalPlaces == null || decimalPlaces >= 0),
       super(
         _percentageCore(
           minValue: minValue,
           minValueErrorText: minValueErrorText,
           maxValue: maxValue,
           maxValueErrorText: maxValueErrorText,
           decimalPlaces: decimalPlaces,
           allowNegative: allowNegative,
           percentSymbol: percentSymbol,
           errorText: percentageErrorText,
         ),
         keyboardType: TextInputType.numberWithOptions(
           decimal: true,
           signed: allowNegative,
         ),
       );

  SmartField.amount({
    super.key,
    super.label,
    super.hintText,
    super.controller,
    super.focusNode,
    super.autofocus,
    super.enabled,
    super.readOnly,
    super.textInputAction,
    super.onChanged,
    super.onSaved,
    super.onRawChanged,
    super.onRawSaved,
    super.isRequired,
    super.requiredErrorText,
    super.minLength,
    super.minLengthErrorText,
    super.maxLength,
    super.maxLengthErrorText,
    super.validator,
    super.autovalidateMode,
    super.asyncValidation,
    super.validationMode,
    super.builtInChecks,
    super.serverError,
    super.restorationId,
    super.decoration,
    String? minValue,
    String? minValueErrorText,
    String? maxValue,
    String? maxValueErrorText,
    int? decimalPlaces,
    Object? decimalLength,
    SmartRoundingMode rounding = SmartRoundingMode.none,
    SmartGroupingStyle groupingStyle = SmartGroupingStyle.international,
    bool useGrouping = false,
    String groupingSeparator = ',',
    String decimalSeparator = '.',
    String? currencySymbol,
    SmartCurrencyPosition currencyPosition = SmartCurrencyPosition.prefix,
    bool allowNegative = false,
    bool mask = false,
    int maskVisibleSuffixDigits = 0,
    String maskCharacter = '*',
    bool revealMaskOnFocus = true,
    SmartAmountPolicy policy = SmartAmountPolicy.standard,
    String amountErrorText = 'Enter a valid amount.',
  }) : super(
         _amountCore(
           minValue: minValue,
           minValueErrorText: minValueErrorText,
           maxValue: maxValue,
           maxValueErrorText: maxValueErrorText,
           decimalPlaces: decimalPlaces,
           decimalLength: decimalLength,
           rounding: rounding,
           groupingStyle: groupingStyle,
           useGrouping: useGrouping,
           groupingSeparator: groupingSeparator,
           decimalSeparator: decimalSeparator,
           currencySymbol: currencySymbol,
           currencyPosition: currencyPosition,
           allowNegative: allowNegative,
           mask: mask,
           maskVisibleSuffixDigits: maskVisibleSuffixDigits,
           maskCharacter: maskCharacter,
           revealMaskOnFocus: revealMaskOnFocus,
           policy: policy,
           errorText: amountErrorText,
         ),
         keyboardType: TextInputType.numberWithOptions(
           signed: allowNegative,
           decimal: _amountPlaces(decimalLength, decimalPlaces) != 0,
         ),
       );

  SmartField.otp({
    super.key,
    super.label,
    super.hintText,
    super.controller,
    super.focusNode,
    super.autofocus,
    super.enabled,
    super.readOnly,
    super.textInputAction,
    super.onChanged,
    super.onSaved,
    super.isRequired,
    super.requiredErrorText,
    super.minLength,
    super.minLengthErrorText,
    super.maxLength,
    super.maxLengthErrorText,
    super.validator,
    super.autovalidateMode,
    super.asyncValidation,
    super.validationMode,
    super.builtInChecks,
    super.serverError,
    super.restorationId,
    super.decoration,
    ValueChanged<String>? onCompleted,
    int length = 6,
    bool obscureText = false,
    SmartOtpPolicy policy = SmartOtpPolicy.standard,
    String digitErrorText = 'Enter digits only.',
    String? otpLengthErrorText,
    String legacyErrorText = 'Enter a valid verification code.',
    String? errorText,
    bool notifyOnProgrammaticChanges = false,
    SmartOtpStyle style = const SmartOtpStyle(),
  }) : super(
         _otpCore(
           onCompleted: onCompleted,
           length: length,
           obscureText: obscureText,
           policy: policy,
           digitErrorText: digitErrorText,
           otpLengthErrorText: otpLengthErrorText,
           legacyErrorText: legacyErrorText,
           errorText: errorText,
           notifyOnProgrammaticChanges: notifyOnProgrammaticChanges,
           style: style,
         ),
         keyboardType: TextInputType.number,
         autofillHints: const [AutofillHints.oneTimeCode],
       );

  SmartField.date({
    super.key,
    super.label,
    super.hintText,
    super.controller,
    super.focusNode,
    super.autofocus,
    super.enabled,
    super.readOnly,
    super.textInputAction,
    super.onChanged,
    super.onSaved,
    super.isRequired,
    super.requiredErrorText,
    super.validator,
    super.autovalidateMode,
    super.asyncValidation,
    super.validationMode,
    super.builtInChecks,
    super.serverError,
    super.decoration,
    ValueChanged<String>? onRawChanged,
    FormFieldSetter<String>? onRawSaved,
    bool showClearButton = false,
    String? invalidErrorText,
    String? minErrorText,
    String? maxErrorText,
    DateTime Function() now = DateTime.now,
    SmartDateMode mode = SmartDateMode.manual,
    String dateFormat = 'dd/MM/yyyy',
    DateTime? initialDate,
    DateTime? minDate,
    DateTime? maxDate,
    SmartDateRestriction restriction = SmartDateRestriction.none,
    List<String> monthNames = smartEnglishMonthNames,
    int? firstYear,
    int? lastYear,
    String incompleteErrorText = 'Select a complete date.',
    String pastErrorText = 'Choose a date in the past.',
    String futureErrorText = 'Choose a date in the future.',
    ValueChanged<DateTime?>? onDateChanged,
  }) : assert((firstYear == null) == (lastYear == null)),
       super(
         _SmartFieldCore(
           dateTimeConfig: SmartDateTimeConfig(
             kind: SmartDateTimeKind.date,
             dateMode: mode,
             dateFormat: SmartDateFormat(dateFormat),
             minDate: minDate,
             maxDate: maxDate,
             restriction: restriction,
             initialDate: initialDate == null
                 ? null
                 : SmartDateUtils.dateOnly(initialDate),
             now: now,
             monthNames: monthNames,
             showClearButton: showClearButton,
             invalidErrorText: invalidErrorText,
             incompleteErrorText: incompleteErrorText,
             minErrorText: minErrorText,
             maxErrorText: maxErrorText,
             pastErrorText: pastErrorText,
             futureErrorText: futureErrorText,
             onDateChanged: onDateChanged,
             onRawChanged: onRawChanged,
             onRawSaved: onRawSaved,
             yearRange: firstYear == null ? null : (firstYear, lastYear!),
           ),
         ),
         keyboardType: TextInputType.datetime,
       );

  SmartField.time({
    super.key,
    super.label,
    super.hintText,
    super.controller,
    super.focusNode,
    super.autofocus,
    super.enabled,
    super.readOnly,
    super.textInputAction,
    super.onChanged,
    super.onSaved,
    super.isRequired,
    super.requiredErrorText,
    super.validator,
    super.autovalidateMode,
    super.asyncValidation,
    super.validationMode,
    super.builtInChecks,
    super.serverError,
    super.decoration,
    ValueChanged<String>? onRawChanged,
    FormFieldSetter<String>? onRawSaved,
    bool showClearButton = false,
    String? invalidErrorText,
    String? minErrorText,
    String? maxErrorText,
    DateTime Function() now = DateTime.now,
    SmartTimeMode mode = SmartTimeMode.manual,
    bool use24Hour = true,
    TimeOfDay? initialTime,
    TimeOfDay? minTime,
    TimeOfDay? maxTime,
    ValueChanged<TimeOfDay?>? onTimeChanged,
  }) : super(
         _SmartFieldCore(
           dateTimeConfig: SmartDateTimeConfig(
             kind: SmartDateTimeKind.time,
             timeMode: mode,
             timeFormat: SmartTimeFormat(use24Hour: use24Hour),
             minTime: minTime,
             maxTime: maxTime,
             initialTime: initialTime,
             now: now,
             showClearButton: showClearButton,
             invalidErrorText: invalidErrorText,
             minErrorText: minErrorText,
             maxErrorText: maxErrorText,
             onTimeChanged: onTimeChanged,
             onRawChanged: onRawChanged,
             onRawSaved: onRawSaved,
           ),
         ),
         keyboardType: TextInputType.datetime,
       );

  SmartField.dateTime({
    super.key,
    super.label,
    super.hintText,
    super.controller,
    super.focusNode,
    super.autofocus,
    super.enabled,
    super.readOnly,
    super.textInputAction,
    super.onChanged,
    super.onSaved,
    super.isRequired,
    super.requiredErrorText,
    super.validator,
    super.autovalidateMode,
    super.asyncValidation,
    super.validationMode,
    super.builtInChecks,
    super.serverError,
    super.decoration,
    ValueChanged<String>? onRawChanged,
    FormFieldSetter<String>? onRawSaved,
    bool showClearButton = false,
    String? invalidErrorText,
    String? minErrorText,
    String? maxErrorText,
    DateTime Function() now = DateTime.now,
    SmartTimeMode mode = SmartTimeMode.manual,
    bool use24Hour = true,
    String dateFormat = 'dd/MM/yyyy',
    DateTime? initialDateTime,
    DateTime? minDateTime,
    DateTime? maxDateTime,
    SmartDateRestriction restriction = SmartDateRestriction.none,
    String pastErrorText = 'Choose a date and time in the past.',
    String futureErrorText = 'Choose a date and time in the future.',
    ValueChanged<DateTime?>? onDateTimeChanged,
  }) : assert(mode != SmartTimeMode.wheel),
       super(
         _SmartFieldCore(
           dateTimeConfig: SmartDateTimeConfig(
             kind: SmartDateTimeKind.dateTime,
             dateMode: mode == SmartTimeMode.manual
                 ? SmartDateMode.manual
                 : SmartDateMode.calendar,
             timeMode: mode,
             dateFormat: SmartDateFormat(dateFormat),
             timeFormat: SmartTimeFormat(use24Hour: use24Hour),
             minDate: minDateTime,
             maxDate: maxDateTime,
             restriction: restriction,
             initialDate: initialDateTime,
             now: now,
             showClearButton: showClearButton,
             invalidErrorText: invalidErrorText,
             minErrorText: minErrorText,
             maxErrorText: maxErrorText,
             pastErrorText: pastErrorText,
             futureErrorText: futureErrorText,
             onDateTimeChanged: onDateTimeChanged,
             onRawChanged: onRawChanged,
             onRawSaved: onRawSaved,
           ),
         ),
         keyboardType: TextInputType.datetime,
       );

  SmartField.creditCard({
    super.key,
    super.enabled,
    super.readOnly,
    super.autofocus,
    super.isRequired,
    super.requiredErrorText,
    super.autovalidateMode,
    super.decoration,
    String numberLabel = 'Card number',
    String expiryLabel = 'Expiry',
    String cvvLabel = 'Security code',
    String? numberHint,
    String? expiryHint,
    String? cvvHint,
    TextEditingController? numberController,
    TextEditingController? expiryController,
    TextEditingController? cvvController,
    FocusNode? numberFocusNode,
    FocusNode? expiryFocusNode,
    FocusNode? cvvFocusNode,
    Set<SmartCardBrand>? acceptedBrands,
    bool validateLuhn = true,
    Set<SmartCardBrand> luhnExemptBrands = const {},
    bool showNumberStatus = true,
    String? Function(SmartCardNumberAssessment assessment)? numberStatusBuilder,
    String brandErrorText = 'This card type is not accepted.',
    String luhnErrorText = 'Check the card number.',
    SmartExpiryFormat expiryFormat = SmartExpiryFormat.mmYy,
    DateTime Function() now = DateTime.now,
    Set<int>? cvvLengths,
    bool concealCvv = true,
    bool showBrand = true,
    bool autoAdvance = true,
    String numberErrorText = 'Enter a valid card number.',
    String expiryErrorText = 'Enter a valid expiry date.',
    String expiredErrorText = 'This card has expired.',
    String? cvvErrorText,
    SmartServerError? numberServerError,
    SmartServerError? expiryServerError,
    SmartServerError? cvvServerError,
    ValueChanged<SmartCreditCardValue>? onChanged,
    FormFieldSetter<SmartCreditCardValue>? onSaved,
  }) : super(
         _SmartFieldCore(
           cardConfig: SmartCreditCardConfig(
             numberLabel: numberLabel,
             expiryLabel: expiryLabel,
             cvvLabel: cvvLabel,
             numberHint: numberHint,
             expiryHint: expiryHint,
             cvvHint: cvvHint,
             numberController: numberController,
             expiryController: expiryController,
             cvvController: cvvController,
             numberFocusNode: numberFocusNode,
             expiryFocusNode: expiryFocusNode,
             cvvFocusNode: cvvFocusNode,
             acceptedBrands: acceptedBrands,
             validateLuhn: validateLuhn,
             luhnExemptBrands: luhnExemptBrands,
             showNumberStatus: showNumberStatus,
             numberStatusBuilder: numberStatusBuilder,
             brandErrorText: brandErrorText,
             luhnErrorText: luhnErrorText,
             expiryFormat: expiryFormat,
             now: now,
             cvvLengths: cvvLengths,
             concealCvv: concealCvv,
             showBrand: showBrand,
             autoAdvance: autoAdvance,
             numberErrorText: numberErrorText,
             expiryErrorText: expiryErrorText,
             expiredErrorText: expiredErrorText,
             cvvErrorText: cvvErrorText,
             numberServerError: numberServerError,
             expiryServerError: expiryServerError,
             cvvServerError: cvvServerError,
             onChanged: onChanged,
             onSaved: onSaved,
           ),
         ),
         keyboardType: TextInputType.number,
       );

  @override
  State<SmartField> createState() => _SmartFieldState();
}

class _SmartFieldState extends State<SmartField> implements _PhoneHost {
  late bool _obscureText = widget._isPassword;
  TextEditingController? _ownedController;
  FocusNode? _ownedFocusNode;
  GlobalKey<FormFieldState<String>> _phoneFieldKey = GlobalKey();
  GlobalKey<FormFieldState<String>> _maskFieldKey = GlobalKey();
  GlobalKey<FormFieldState<String>> _searchFieldKey = GlobalKey();
  _PhoneBehavior? _phoneBehavior;
  final SmartAmountDisplay _amountDisplay = SmartAmountDisplay();
  final SmartSearchDebouncer _search = SmartSearchDebouncer();
  SmartAsyncValidationEngine? _asyncEngine;
  TextEditingController? _ownedOtpController;
  final GlobalKey<FormFieldState<String>> _asyncFieldKey = GlobalKey();
  final SmartListenerGroup _listeners = SmartListenerGroup();
  TextEditingController? _lastAsyncController;
  late final SmartListenerBinding _amountController = _listeners.add(
    _handleAmountControllerChange,
  );
  late final SmartListenerBinding _amountFocus = _listeners.add(
    _handleAmountFocusChange,
  );
  late final SmartListenerBinding _phoneController = _listeners.add(
    () => _phone?.handleControllerChange(),
  );
  late final SmartListenerBinding _maskController = _listeners.add(
    _handleMaskControllerChange,
  );
  late final SmartListenerBinding _maskFocus = _listeners.add(
    _handleMaskFocusChange,
  );
  late final SmartListenerBinding _searchController = _listeners.add(
    _handleSearchControllerChange,
  );
  late final SmartListenerBinding _matchBinding = _listeners.add(
    _handleMatchChange,
  );
  late final SmartListenerBinding _wordBinding = _listeners.add(
    _handleWordCountChange,
  );
  late final SmartListenerBinding _serverBinding = _listeners.add(
    _handleServerErrorChange,
  );
  late final SmartListenerBinding _asyncTextBinding = _listeners.add(
    _handleAsyncText,
  );

  static bool _usesOwnedState(SmartField source) {
    return source._isAmount ||
        source._isPhone ||
        source._isSearch ||
        source._supportsMasking;
  }

  TextEditingController? _controllerFor(SmartField source) {
    return source.controller ??
        (_usesOwnedState(source) ? _ownedController : null);
  }

  FocusNode? _focusNodeFor(SmartField source) {
    return source.focusNode ??
        (_usesOwnedState(source) ? _ownedFocusNode : null);
  }

  TextEditingController? get _effectiveController => _controllerFor(widget);

  FocusNode? get _effectiveFocusNode => _focusNodeFor(widget);

  @override
  void initState() {
    super.initState();
    _ensureOwnedState(null);
    _syncBindings();
  }

  @override
  void didUpdateWidget(covariant SmartField oldWidget) {
    final oldController = _controllerFor(oldWidget);
    _listeners.unbindAll();
    super.didUpdateWidget(oldWidget);

    final oldSearch = oldWidget._searchConfig;
    final search = widget._searchConfig;
    if (oldSearch == null ||
        search == null ||
        oldWidget.controller != widget.controller ||
        !oldSearch.hasSameDebounceBehavior(search) ||
        !_isInteractive) {
      _search.cancel();
    }

    if (oldWidget.controller != widget.controller && widget._supportsMasking) {
      if (widget._isPhone) {
        _phoneFieldKey = GlobalKey();
      } else {
        _maskFieldKey = GlobalKey();
      }
    }
    if (oldWidget.controller != widget.controller && widget._isSearch) {
      _searchFieldKey = GlobalKey();
    }

    if (oldWidget._isPassword != widget._isPassword ||
        oldWidget.showVisibilityToggle && !widget.showVisibilityToggle) {
      _obscureText = widget._isPassword;
    }

    if (_usesOwnedState(oldWidget) &&
        oldWidget.controller == null &&
        (!_usesOwnedState(widget) || widget.controller != null)) {
      _ownedController?.dispose();
      _ownedController = null;
    }
    if (_usesOwnedState(oldWidget) &&
        oldWidget.focusNode == null &&
        (!_usesOwnedState(widget) || widget.focusNode != null)) {
      _ownedFocusNode?.dispose();
      _ownedFocusNode = null;
    }
    _ensureOwnedState(oldController?.value);
    _syncBindings();
    if (!(widget.enabled ?? widget.decoration.enabled)) {
      _asyncEngine?.reset();
    }
  }

  _PhoneBehavior? get _phone {
    if (!widget._isPhone) {
      return null;
    }
    return _phoneBehavior ??= _PhoneBehavior(this);
  }

  @override
  _SmartPhoneConfig get phoneConfig => widget._phoneConfig!;

  @override
  TextEditingController? get textController => _effectiveController;

  @override
  GlobalKey<FormFieldState<String>> get phoneFieldKey => _phoneFieldKey;

  @override
  bool get isInteractive => _isInteractive;

  @override
  ValueChanged<String>? get onChanged => widget.onChanged;

  @override
  void rebuild() {
    if (mounted) {
      setState(() {});
    }
  }

  void _syncBindings() {
    final controller = _effectiveController;
    final focusNode = _effectiveFocusNode;
    _amountController.bind(widget._isAmount ? controller : null);
    _amountFocus.bind(widget._isAmount ? focusNode : null);
    _phoneController.bind(widget._isPhone ? controller : null);
    _maskController.bind(widget._supportsMasking ? controller : null);
    _maskFocus.bind(widget._supportsMasking ? focusNode : null);
    _searchController.bind(widget._isSearch ? controller : null);
    _matchBinding.bind(widget._core.matchController);
    _wordBinding.bind(_tracksText ? controller : null);
    _serverBinding.bind(widget.serverError);
    if (widget._isAmount && !(focusNode?.hasFocus ?? false)) {
      _amountDisplay.showDisplay(widget._amountFormatter!, controller);
    }
    _phone?.initialize();
    _syncAsyncBinding();
  }

  String _wordCountText() {
    final count = SmartTextUtils.countWords(_asyncText());
    final maxWords = widget._core.maxWords;
    if (maxWords != null) {
      return '$count / $maxWords words';
    }
    return count == 1 ? '1 word' : '$count words';
  }

  void _handleWordCountChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleMatchChange() {
    if (!mounted || _asyncText().isEmpty) {
      return;
    }
    _activeFormFieldKey.currentState?.validate();
  }

  void _handleServerErrorChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _ensureOwnedState(TextEditingValue? initialValue) {
    if (!_usesOwnedState(widget)) {
      return;
    }
    if (widget.controller == null) {
      _ownedController ??= TextEditingController.fromValue(initialValue);
    }
    if (widget.focusNode == null) {
      _ownedFocusNode ??= FocusNode();
    }
  }

  TextEditingController? get _asyncTextController {
    if (widget._otpConfig != null) {
      return widget.controller ?? _ownedOtpController;
    }
    return _effectiveController;
  }

  GlobalKey<FormFieldState<String>> get _activeFormFieldKey {
    if (widget._isPhone) {
      return _phoneFieldKey;
    }
    if (widget._isSearch) {
      return _searchFieldKey;
    }
    if (widget._supportsMasking) {
      return _maskFieldKey;
    }
    return _asyncFieldKey;
  }

  String _asyncText() {
    return _asyncTextController?.text ??
        _activeFormFieldKey.currentState?.value ??
        '';
  }

  String? _asyncRaw(String text) {
    final normalizer = widget._valueNormalizer;
    return normalizer == null ? text : normalizer(text);
  }

  void _syncAsyncBinding() {
    final config = widget._core.dateTimeConfig != null
        ? null
        : widget.asyncValidation;
    if (config == null) {
      _lastAsyncController = null;
      _asyncEngine?.dispose();
      _asyncEngine = null;
      _releaseOwnedOtpController();
      return;
    }
    if (widget._otpConfig != null && widget.controller == null) {
      _ownedOtpController ??= TextEditingController();
    } else {
      _releaseOwnedOtpController();
    }
    final engine = _asyncEngine ??= SmartAsyncValidationEngine(
      readText: _asyncText,
      toRaw: _asyncRaw,
      syncError: _synchronousValidator,
      isActive: () => mounted && _isInteractive,
      onUpdate: _handleAsyncUpdate,
    );
    engine.configure(config);
    final controller = _asyncTextController;
    _asyncTextBinding.bind(controller);
    if (_lastAsyncController != null &&
        !identical(_lastAsyncController, controller)) {
      engine.reset();
    }
    _lastAsyncController = controller;
  }

  void _releaseOwnedOtpController() {
    final owned = _ownedOtpController;
    if (owned == null) {
      return;
    }
    _ownedOtpController = null;
    WidgetsBinding.instance.addPostFrameCallback((_) => owned.dispose());
  }

  void _handleAsyncText() {
    _asyncEngine?.observe(_asyncTextController?.text ?? '');
  }

  void _handleAsyncUpdate() {
    if (!mounted) {
      return;
    }
    setState(() {});
    final status = _asyncEngine?.status;
    if (widget._otpConfig == null &&
        (status == SmartAsyncValidationStatus.valid ||
            status == SmartAsyncValidationStatus.invalid ||
            status == SmartAsyncValidationStatus.unavailable)) {
      _activeFormFieldKey.currentState?.validate();
    }
  }

  void _handleSearchControllerChange() {
    _search.cancel();
    if (mounted) {
      setState(() {});
    }
  }

  void _handleMaskControllerChange() {
    if ((widget._maskConfig?.enabled ?? false) && mounted) {
      setState(() {});
    }
  }

  void _handleMaskFocusChange() {
    if ((widget._maskConfig?.enabled ?? false) && mounted) {
      setState(() {});
    }
  }

  void _handleAmountFocusChange() {
    _amountDisplay.handleFocus(
      widget._amountFormatter!,
      _effectiveController,
      _effectiveFocusNode,
    );
  }

  void _handleAmountControllerChange() {
    _amountDisplay.handleControllerChange(
      widget._amountFormatter!,
      _effectiveController,
      _effectiveFocusNode,
    );
  }

  InputDecoration get _effectiveDecoration {
    final decoration = widget.decoration;
    return SmartFieldDesign.resolve(
      context,
      decoration.copyWith(
        labelText: decoration.label == null && decoration.labelText == null
            ? widget.label
            : null,
        hintText: decoration.hint == null && decoration.hintText == null
            ? widget.hintText
            : null,
        counterText:
            widget._core.showWordCount &&
                decoration.counter == null &&
                decoration.counterText == null
            ? _wordCountText()
            : null,
        suffixText:
            decoration.suffix == null &&
                decoration.suffixText == null &&
                decoration.suffixIcon != null
            ? widget._percentageSuffix
            : null,
        prefixIcon: _searchPrefixIcon(
          _phone?.prefixIcon(decoration.prefixIcon),
        ),
        suffixIcon: _suffixIcon(decoration.suffixIcon),
      ),
    );
  }

  Widget? _searchPrefixIcon(Widget? existing) {
    final icon = widget._searchConfig?.searchIcon;
    if (widget._isSearch && existing == null && icon != null) {
      return ExcludeSemantics(child: icon);
    }
    return existing;
  }

  bool get _isInteractive {
    return (widget.enabled ?? widget.decoration.enabled) && !widget.readOnly;
  }

  Widget? _suffixIcon(Widget? existing) {
    final children = <Widget>[?existing];

    final percentSymbol = widget._percentageSuffix;
    final decoration = widget.decoration;
    if (percentSymbol != null &&
        existing == null &&
        decoration.suffix == null &&
        decoration.suffixText == null) {
      final theme = Theme.of(context);
      final color = (widget.enabled ?? widget.decoration.enabled)
          ? theme.colorScheme.onSurfaceVariant
          : theme.disabledColor;
      children.add(
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 12),
          child: Center(
            widthFactor: 1,
            child: Text(
              percentSymbol,
              style:
                  decoration.suffixStyle ??
                  theme.textTheme.bodyLarge?.copyWith(color: color),
            ),
          ),
        ),
      );
    }

    final asyncConfig = widget.asyncValidation;
    if (asyncConfig != null && (_asyncEngine?.isPending ?? false)) {
      children.add(
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 12),
          child: Semantics(
            label: asyncConfig.loadingSemanticsLabel,
            liveRegion: true,
            child:
                asyncConfig.loadingIndicator ??
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
          ),
        ),
      );
    }

    if (widget._isPassword && widget.showVisibilityToggle) {
      children.add(_passwordToggle());
    }

    children.addAll(_phone?.suffixActions() ?? const []);

    final search = widget._searchConfig;
    if (search != null) {
      if (search.isLoading) {
        children.add(
          Semantics(
            label: 'Loading search',
            child: ExcludeSemantics(
              child: SizedBox(
                width: 24,
                height: 24,
                child: Padding(
                  padding: EdgeInsets.all(4),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
        );
      }
      if (search.showClearButton &&
          search.clearIcon != null &&
          _isInteractive &&
          (_effectiveController?.text.isNotEmpty ?? false)) {
        children.add(
          Semantics(
            label: 'Clear search',
            button: true,
            child: ExcludeSemantics(
              child: IconButton(
                tooltip: 'Clear search',
                onPressed: _clearSearch,
                icon: search.clearIcon!,
              ),
            ),
          ),
        );
      }
    }

    return composeSuffixActions(children);
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

  SmartValidator get _effectiveValidator {
    final engine = _asyncEngine;
    if (engine == null || widget._otpConfig != null) {
      return _synchronousValidator;
    }
    return SmartValidators.compose([
      _synchronousValidator,
      (value) => engine.errorFor(value ?? ''),
    ]);
  }

  String? _synchronousValidator(String? value) {
    final mode = widget.validationMode;
    final checks = widget.builtInChecks;
    final core = widget._core;
    final phone = widget._phoneConfig;
    final mask = core.inputMask;
    final match = core.matchController;
    return SmartValidators.compose([
      if (widget.isRequired)
        SmartValidators.requiredField(message: widget.requiredErrorText),
      if (widget._isPassword && mode == SmartValidationMode.selected)
        SmartValidators.passwordRules(checks),
      SmartValidators.modeAware(
        mode: mode,
        checks: checks,
        builtIn: SmartValidators.compose([
          ?widget._fieldValidator,
          if (phone != null)
            SmartValidators.phone(
              policy: phone.policy,
              country: _phone?.selectedCountry,
              message: phone.errorText,
            ),
        ]),
      ),
      if (widget.minLength != null)
        SmartValidators.minLength(
          widget.minLength!,
          message: widget.minLengthErrorText,
          normalizer: widget._valueNormalizer,
        ),
      if (widget.maxLength != null)
        SmartValidators.maxLength(
          widget.maxLength!,
          message: widget.maxLengthErrorText,
          normalizer: widget._valueNormalizer,
        ),
      ?widget._minValueValidator,
      ?widget._maxValueValidator,
      if (mask != null && SmartValidators.runsBuiltIn(mode, checks))
        (value) => _validateMask(mask, value, core.inputMaskMessage),
      if (core.minWords != null)
        SmartValidators.minWords(core.minWords!, message: core.minWordsMessage),
      if (core.maxWords != null)
        SmartValidators.maxWords(core.maxWords!, message: core.maxWordsMessage),
      if (match != null)
        SmartValidators.matches(
          () => match.text,
          message: core.mismatchMessage,
        ),
      SmartValidators.modeAware(
        mode: mode,
        checks: checks,
        custom: widget.validator,
      ),
    ])(value);
  }

  static String? _validateMask(
    SmartInputMask mask,
    String? value,
    String message,
  ) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final raw = mask.extractRaw(value);
    return raw != null && mask.isComplete(raw) ? null : message;
  }

  void _handleOtpChanged(String value) {
    widget.onChanged?.call(value);
    widget.serverError?.notifyFieldChanged();
  }

  void _handleChanged(String value) {
    widget.onChanged?.call(value);
    widget.serverError?.notifyFieldChanged();
    if (_tracksText && !_wordBinding.isBound) {
      setState(() {});
    }
    _asyncEngine?.observe(value);
    if (widget._isSearch) {
      _scheduleSearch(value);
    }
    if (widget._isPhone) {
      setState(() {});
    }
    final raw = widget._core.rawValue(value, partial: true);
    if (raw != null) {
      widget.onRawChanged?.call(raw);
    }
  }

  void _scheduleSearch(String query) {
    final config = widget._searchConfig;
    _search.schedule(
      query: query,
      onSearch: config?.onSearch,
      debounce: config?.debounceDuration ?? Duration.zero,
      canSearch: () => mounted && _isInteractive,
      currentText: () => _effectiveController?.text ?? '',
    );
  }

  void _handleSubmitted(String value) {
    _search.cancel();
    widget._searchConfig?.onSubmitted?.call(value);
  }

  void _clearSearch() {
    final controller = _effectiveController;
    final config = widget._searchConfig;
    if (controller == null || controller.text.isEmpty || config == null) {
      return;
    }
    _search.cancel();
    controller.clear();
    _searchFieldKey.currentState?.didChange('');
    _handleChanged('');
    config.onCleared?.call();
  }

  void _handleSaved(String? value) {
    widget.onSaved?.call(value);
    widget.onRawSaved?.call(
      value == null ? null : widget._core.rawValue(value),
    );
  }

  bool get _showsMaskedPresentation {
    final config = widget._maskConfig;
    final controller = _effectiveController;
    if (config == null ||
        !config.enabled ||
        controller == null ||
        controller.text.isEmpty) {
      return false;
    }
    if (!_isInteractive || !config.revealOnFocus) {
      return true;
    }
    return !(_effectiveFocusNode?.hasFocus ?? false);
  }

  String _maskedText() {
    return widget._maskConfig!.render(
      _effectiveController?.text ?? '',
      widget._amountFormatter,
    );
  }

  InputDecoration _maskedDecoration(String maskedText) {
    final decoration = _effectiveDecoration;
    return decoration.copyWith(
      prefixText: '${decoration.prefixText ?? ''}$maskedText',
      prefixStyle:
          decoration.prefixStyle ?? Theme.of(context).textTheme.bodyLarge,
    );
  }

  @override
  void dispose() {
    _search.cancel();
    _listeners.unbindAll();
    _asyncEngine?.dispose();
    _ownedOtpController?.dispose();
    _ownedController?.dispose();
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardConfig = widget._core.cardConfig;
    if (cardConfig != null) {
      return SmartCreditCardField(config: cardConfig, source: widget);
    }
    final dateTimeConfig = widget._core.dateTimeConfig;
    if (dateTimeConfig != null) {
      return SmartDateTimeField(config: dateTimeConfig, source: widget);
    }
    final otpConfig = widget._otpConfig;
    if (otpConfig != null) {
      final asyncError =
          widget.serverError?.errorText ?? _asyncEngine?.errorFor(_asyncText());
      return _withAsyncFocus(
        SmartOtpField(
          configuration: otpConfig,
          source: widget,
          controller: widget.controller ?? _ownedOtpController,
          onChanged: _handleOtpChanged,
          validator: _synchronousValidator,
          decoration: asyncError == null || widget.decoration.errorText != null
              ? widget.decoration
              : widget.decoration.copyWith(errorText: asyncError),
        ),
      );
    }
    final showsMask = _showsMaskedPresentation;
    final maskedText = showsMask ? _maskedText() : null;
    final field = TextFormField(
      key: widget._isPhone
          ? _phoneFieldKey
          : widget._isSearch
          ? _searchFieldKey
          : widget._supportsMasking
          ? _maskFieldKey
          : _needsFieldKey
          ? _asyncFieldKey
          : null,
      controller: _effectiveController,
      focusNode: _effectiveFocusNode,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      readOnly:
          widget.readOnly ||
          (showsMask && !(widget._maskConfig?.revealOnFocus ?? true)),
      keyboardType: widget.keyboardType,
      textCapitalization: widget.textCapitalization,
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.enableSuggestions,
      autofillHints: widget.autofillHints,
      textInputAction: widget.textInputAction,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      expands: widget.expands,
      obscureText: _obscureText,
      style: showsMask ? const TextStyle(color: Colors.transparent) : null,
      showCursor: showsMask ? false : null,
      enableInteractiveSelection: !showsMask,
      inputFormatters: widget.inputFormatters,
      onTap: widget._searchConfig?.onTap,
      onChanged: _handleChanged,
      onFieldSubmitted: widget._isSearch ? _handleSubmitted : null,
      onSaved: _handleSaved,
      validator: _effectiveValidator,
      forceErrorText: widget.serverError?.errorText,
      restorationId: _restorationId,
      autovalidateMode: widget.autovalidateMode,
      decoration: showsMask
          ? _maskedDecoration(maskedText!)
          : _effectiveDecoration,
    );
    if (!showsMask) {
      return _withStrength(_withAsyncFocus(field));
    }
    final enabled = widget.enabled ?? widget.decoration.enabled;
    final canReveal = _isInteractive && widget._maskConfig!.revealOnFocus;
    return _withAsyncFocus(
      Semantics(
        container: true,
        excludeSemantics: true,
        textField: true,
        enabled: enabled,
        readOnly: !canReveal,
        label: widget.label,
        value: maskedText,
        onTap: canReveal ? () => _effectiveFocusNode?.requestFocus() : null,
        child: field,
      ),
    );
  }

  bool get _tracksText {
    return widget._core.showWordCount || widget._core.strength != null;
  }

  bool get _needsFieldKey {
    return widget.asyncValidation != null ||
        widget._core.matchController != null ||
        _tracksText;
  }

  String? get _restorationId {
    if (widget._isPassword ||
        widget._otpConfig != null ||
        _usesOwnedState(widget)) {
      return null;
    }
    return widget.restorationId;
  }

  Widget _withStrength(Widget child) {
    final config = widget._core.strength;
    if (config == null) {
      return child;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        child,
        const SizedBox(height: 8),
        SmartPasswordStrengthIndicator(
          password: _asyncText(),
          criteria: config.criteria,
          labels: config.labels,
          showChecklist: config.showChecklist,
        ),
      ],
    );
  }

  Widget _withAsyncFocus(Widget child) {
    final engine = _asyncEngine;
    if (engine == null) {
      return child;
    }
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (focused) {
        if (!focused) {
          engine.focusLost();
        }
      },
      child: child,
    );
  }
}
