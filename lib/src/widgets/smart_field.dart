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

part 'smart_field_features.dart';
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

  bool get _asyncActive =>
      asyncValidation != null && _core.dateTimeConfig == null;
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
         _numberCore(
           minValue: minValue,
           minValueErrorText: minValueErrorText,
           maxValue: maxValue,
           maxValueErrorText: maxValueErrorText,
           mask: mask,
           maskVisibleSuffixDigits: maskVisibleSuffixDigits,
           maskCharacter: maskCharacter,
           revealMaskOnFocus: revealMaskOnFocus,
           allowNegative: allowNegative,
           policy: policy,
           errorText: numberErrorText,
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

class _SmartFieldState extends State<SmartField> implements _FieldHost {
  TextEditingController? _ownedController;
  FocusNode? _ownedFocusNode;
  GlobalKey<FormFieldState<String>> _fieldKey = GlobalKey();
  late List<_FieldFeature> _features = _createFeatures();

  static bool _usesOwnedState(SmartField source) {
    return source._isAmount ||
        source._isPhone ||
        source._isSearch ||
        source._supportsMasking ||
        source._core.strength != null;
  }

  static int _featureKey(SmartField source) {
    final flags = [
      source._percentageSuffix != null,
      source._maskConfig?.enabled ?? false,
      source._asyncActive,
      source._isPassword,
      source._isPhone,
      source._isSearch,
      source._isAmount,
      source._core.showWordCount,
      source._core.strength != null,
      source._core.matchController != null,
      source.serverError != null,
    ];
    var key = 0;
    for (final flag in flags) {
      key = (key << 1) | (flag ? 1 : 0);
    }
    return key;
  }

  List<_FieldFeature> _createFeatures() {
    final source = widget;
    return [
      if (source._percentageSuffix != null) _PercentageFeature(this),
      if (source._maskConfig?.enabled ?? false) _MaskFeature(this),
      if (source._asyncActive) _AsyncFeature(this),
      if (source._isPassword) _PasswordFeature(this),
      if (source._isPhone) _PhoneFeature(this),
      if (source._isSearch) _SearchFeature(this),
      if (source._isAmount) _AmountFeature(this),
      if (source._core.showWordCount) _WordCountFeature(this),
      if (source._core.strength != null) _StrengthFeature(this),
      if (source._core.matchController != null) _MatchFeature(this),
      if (source.serverError != null)
        _RebuildFeature(this, () => widget.serverError),
    ];
  }

  T? _feature<T extends _FieldFeature>() {
    for (final feature in _features) {
      if (feature is T) {
        return feature;
      }
    }
    return null;
  }

  TextEditingController? _controllerFor(SmartField source) {
    return source.controller ??
        (_usesOwnedState(source) ? _ownedController : null);
  }

  FocusNode? _focusNodeFor(SmartField source) {
    return source.focusNode ??
        (_usesOwnedState(source) ? _ownedFocusNode : null);
  }

  @override
  SmartField get field => widget;

  @override
  TextEditingController? get textController => _controllerFor(widget);

  @override
  FocusNode? get focusNode => _focusNodeFor(widget);

  @override
  GlobalKey<FormFieldState<String>> get fieldKey => _fieldKey;

  @override
  bool get isInteractive {
    return (widget.enabled ?? widget.decoration.enabled) && !widget.readOnly;
  }

  @override
  String get currentText =>
      textController?.text ?? _fieldKey.currentState?.value ?? '';

  @override
  String? validateSync(String? value) => _synchronousValidator(value);

  @override
  void rebuild() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void notifyChanged(String value) => _handleChanged(value);

  @override
  void initState() {
    super.initState();
    _ensureOwnedState(null);
    _bindFeatures();
  }

  @override
  void didUpdateWidget(covariant SmartField oldWidget) {
    final oldController = _controllerFor(oldWidget);
    for (final feature in _features) {
      feature.unbind();
    }
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller &&
        (widget._supportsMasking || widget._isSearch)) {
      _fieldKey = GlobalKey();
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
    if (_featureKey(oldWidget) != _featureKey(widget)) {
      for (final feature in _features) {
        feature.retire();
      }
      _features = _createFeatures();
    } else {
      for (final feature in _features) {
        feature.didUpdate(oldWidget);
      }
    }
    _bindFeatures();
  }

  void _bindFeatures() {
    for (final feature in _features) {
      feature.bind();
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

  InputDecoration get _effectiveDecoration {
    final decoration = widget.decoration;
    var prefix = decoration.prefixIcon;
    for (final feature in _features) {
      prefix = feature.prefix(prefix);
    }
    final actions = <Widget>[?decoration.suffixIcon];
    for (final feature in _features) {
      feature.addSuffix(actions);
    }
    var composed = decoration.copyWith(
      labelText: decoration.label == null && decoration.labelText == null
          ? widget.label
          : null,
      hintText: decoration.hint == null && decoration.hintText == null
          ? widget.hintText
          : null,
      prefixIcon: prefix,
      suffixIcon: composeSuffixActions(actions),
    );
    for (final feature in _features) {
      composed = feature.decorate(composed);
    }
    var resolved = SmartFieldDesign.resolve(context, composed);
    for (final feature in _features) {
      resolved = feature.present(resolved);
    }
    return resolved;
  }

  SmartValidator get _effectiveValidator {
    final async = _feature<_AsyncFeature>();
    if (async == null || widget._otpConfig != null) {
      return _synchronousValidator;
    }
    return SmartValidators.compose([_synchronousValidator, async.errorFor]);
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
              country: _feature<_PhoneFeature>()?.selectedCountry,
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
    for (final feature in _features) {
      feature.textChanged(value);
    }
    final raw = widget._core.rawValue(value, partial: true);
    if (raw != null) {
      widget.onRawChanged?.call(raw);
    }
  }

  void _handleSubmitted(String value) {
    _feature<_SearchFeature>()?.submitted(value);
  }

  void _handleSaved(String? value) {
    widget.onSaved?.call(value);
    widget.onRawSaved?.call(
      value == null ? null : widget._core.rawValue(value),
    );
  }

  @override
  void dispose() {
    for (final feature in _features) {
      feature.dispose();
    }
    _ownedController?.dispose();
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  Widget _wrapFeatures(Widget child) {
    var wrapped = child;
    for (final feature in _features) {
      wrapped = feature.wrap(wrapped);
    }
    return wrapped;
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
      final async = _feature<_AsyncFeature>();
      final asyncError =
          widget.serverError?.errorText ?? async?.errorFor(async.currentText);
      return _wrapFeatures(
        SmartOtpField(
          configuration: otpConfig,
          source: widget,
          controller: async?.otpController ?? widget.controller,
          onChanged: _handleOtpChanged,
          validator: _synchronousValidator,
          decoration: asyncError == null || widget.decoration.errorText != null
              ? widget.decoration
              : widget.decoration.copyWith(errorText: asyncError),
        ),
      );
    }
    final mask = _feature<_MaskFeature>();
    final showsMask = mask?.shows ?? false;
    final field = TextFormField(
      key: _hasFieldKey ? _fieldKey : null,
      controller: textController,
      focusNode: focusNode,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      readOnly: widget.readOnly || (showsMask && !mask!.config.revealOnFocus),
      keyboardType: widget.keyboardType,
      textCapitalization: widget.textCapitalization,
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.enableSuggestions,
      autofillHints: widget.autofillHints,
      textInputAction: widget.textInputAction,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      expands: widget.expands,
      obscureText: _feature<_PasswordFeature>()?.obscure ?? false,
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
      decoration: _effectiveDecoration,
    );
    return _wrapFeatures(field);
  }

  bool get _hasFieldKey {
    return widget._isPhone ||
        widget._isSearch ||
        widget._supportsMasking ||
        widget.asyncValidation != null ||
        widget._core.matchController != null ||
        widget._core.showWordCount;
  }

  String? get _restorationId {
    if (widget._isPassword ||
        widget._otpConfig != null ||
        _usesOwnedState(widget)) {
      return null;
    }
    return widget.restorationId;
  }
}
