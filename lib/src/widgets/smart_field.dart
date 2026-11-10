import 'dart:async';

import 'package:country_picker/country_picker.dart' as country_picker;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:smart_field_kit/src/formatting/smart_card_utils.dart';
import 'package:smart_field_kit/src/formatting/smart_composing.dart';
import 'package:smart_field_kit/src/formatting/smart_date_utils.dart';
import 'package:smart_field_kit/src/formatting/smart_input_mask.dart';
import 'package:smart_field_kit/src/formatting/smart_numeric_formatters.dart';
import 'package:smart_field_kit/src/formatting/smart_text_formatters.dart';
import 'package:smart_field_kit/src/formatting/smart_text_utils.dart';
import 'package:smart_field_kit/src/masking/smart_masking.dart';
import 'package:smart_field_kit/src/models/smart_otp_style.dart';
import 'package:smart_field_kit/src/models/smart_phone_value.dart';
import 'package:smart_field_kit/src/smart_default_texts.dart';
import 'package:smart_field_kit/src/validation/smart_async_validation.dart';
import 'package:smart_field_kit/src/validation/smart_password_strength.dart';
import 'package:smart_field_kit/src/validation/smart_phone_separators.dart';
import 'package:smart_field_kit/src/validation/smart_phone_validation.dart';
import 'package:smart_field_kit/src/validation/smart_url_validation.dart';
import 'package:smart_field_kit/src/validation/smart_validation_options.dart';
import 'package:smart_field_kit/src/validation/smart_validators.dart';
import 'package:smart_field_kit/src/widgets/smart_amount_display.dart';
import 'package:smart_field_kit/src/widgets/smart_credit_card_field.dart';
import 'package:smart_field_kit/src/widgets/smart_date_time_field.dart';
import 'package:smart_field_kit/src/widgets/smart_field_design.dart';
import 'package:smart_field_kit/src/widgets/smart_field_support.dart';
import 'package:smart_field_kit/src/widgets/smart_listener_binding.dart';
import 'package:smart_field_kit/src/widgets/smart_otp_field.dart';
import 'package:smart_field_kit/src/widgets/smart_password_strength_indicator.dart';
import 'package:smart_field_kit/src/widgets/smart_search_debouncer.dart';

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
    this.requiredErrorText = smartRequiredText,
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
    this.initialValue,
    this.onFieldSubmitted,
    this.onEditingComplete,
    this.onTap,
    this.onTapOutside,
    this.style,
    this.textAlign,
    this.textDirection,
    this.obscuringCharacter = '•',
    List<TextInputFormatter>? inputFormatters,
  }) : _developerFormatters = inputFormatters,
       assert(initialValue == null || controller == null),
       assert(obscuringCharacter.length == 1),
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
  final String? initialValue;
  final ValueChanged<String>? onFieldSubmitted;
  final VoidCallback? onEditingComplete;
  final GestureTapCallback? onTap;
  final TapRegionCallback? onTapOutside;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final String obscuringCharacter;

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
    super.initialValue,
    super.onEditingComplete,
    super.onTapOutside,
    super.style,
    super.textAlign,
    super.textDirection,
    super.onFieldSubmitted,
    super.onTap,
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
    super.initialValue,
    super.onEditingComplete,
    super.onTapOutside,
    super.style,
    super.textAlign,
    super.textDirection,
    super.onFieldSubmitted,
    super.onTap,
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
    String Function(int count, int? maxWords)? wordCountBuilder,
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
           wordCountBuilder: wordCountBuilder,
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
    super.initialValue,
    super.onEditingComplete,
    super.onTapOutside,
    super.style,
    super.textAlign,
    super.textDirection,
    super.onFieldSubmitted,
    super.onTap,
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
    String inputMaskErrorText = smartInputMaskErrorText,
    int? minWords,
    int? maxWords,
    bool showWordCount = false,
    String Function(int count, int? maxWords)? wordCountBuilder,
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
           wordCountBuilder: wordCountBuilder,
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
    super.initialValue,
    super.onEditingComplete,
    super.onTapOutside,
    super.style,
    super.textAlign,
    super.textDirection,
    super.onFieldSubmitted,
    super.onTap,
    SmartEmailPolicy policy = SmartEmailPolicy.standard,
    String emailErrorText = smartEmailErrorText,
  }) : super(
         _SmartFieldCore(
           fieldValidator: SmartValidators.email(
             policy: policy,
             message: emailErrorText,
           ),
           trimOnSave: policy == SmartEmailPolicy.standard,
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
    super.initialValue,
    super.onEditingComplete,
    super.onTapOutside,
    super.style,
    super.textAlign,
    super.textDirection,
    super.onFieldSubmitted,
    super.onTap,
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
    super.initialValue,
    super.onEditingComplete,
    super.onTapOutside,
    super.style,
    super.textAlign,
    super.textDirection,
    super.onFieldSubmitted,
    super.onTap,
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
    super.initialValue,
    super.onEditingComplete,
    super.onTapOutside,
    super.style,
    super.textAlign,
    super.textDirection,
    super.onFieldSubmitted,
    super.onTap,
    super.autofillHints = const [AutofillHints.username],
    super.inputFormatters,
    SmartTextCase usernameCase = SmartTextCase.none,
    SmartUsernameCharacters allowedCharacters = SmartUsernameCharacters.any,
    String allowedCharactersErrorText = smartAllowedCharactersText,
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
           allowedCharacters: allowedCharacters,
           allowedCharactersErrorText: allowedCharactersErrorText,
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
    super.initialValue,
    super.onEditingComplete,
    super.onTapOutside,
    super.style,
    super.textAlign,
    super.textDirection,
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
    String clearLabel = smartClearSearchText,
    String loadingLabel = smartLoadingSearchText,
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
             clearLabel: clearLabel,
             loadingLabel: loadingLabel,
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
    super.initialValue,
    super.onEditingComplete,
    super.onTapOutside,
    super.style,
    super.textAlign,
    super.textDirection,
    super.onFieldSubmitted,
    super.onTap,
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
    String phoneErrorText = smartPhoneErrorText,
    SmartPhoneCountryChanged? onCountryChanged,
    SmartPhoneChanged? onPhoneChanged,
    ValueChanged<SmartPhonePickerError>? onContactPickerError,
    String Function(SmartPhonePickerErrorCode code)?
    contactPickerMessageBuilder,
    SmartPhoneContactPicker? contactPicker,
    TextStyle? countryTextStyle,
    Widget? countryPlaceholder,
    EdgeInsetsGeometry? countryPadding,
    String selectCountryLabel = smartSelectCountryText,
    String Function(SmartPhoneCountry country)? changeCountryLabelBuilder,
    String contactPickerLabel = smartContactPickerText,
    String clearLabel = smartClearPhoneText,
    String countrySearchHint = smartCountrySearchText,
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
             contactPickerMessageBuilder: contactPickerMessageBuilder,
             contactPicker: contactPicker,
             countryTextStyle: countryTextStyle,
             countryPlaceholder: countryPlaceholder,
             countryPadding: countryPadding,
             selectCountryLabel: selectCountryLabel,
             changeCountryLabelBuilder: changeCountryLabelBuilder,
             contactPickerLabel: contactPickerLabel,
             clearLabel: clearLabel,
             countrySearchHint: countrySearchHint,
           ),
           ltrContent: true,
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
    super.initialValue,
    super.onEditingComplete,
    super.onTapOutside,
    super.style,
    super.textAlign,
    super.textDirection,
    super.onFieldSubmitted,
    super.onTap,
    super.obscuringCharacter,
    super.showVisibilityToggle = true,
    super.keyboardType = TextInputType.visiblePassword,
    super.inputFormatters,
    SmartPasswordPolicy? policy,
    String passwordErrorText = 'Password does not meet the selected policy.',
    TextEditingController? matchController,
    String mismatchErrorText = smartMismatchText,
    bool showStrengthIndicator = false,
    List<SmartPasswordCriterion>? strengthCriteria,
    Map<SmartPasswordStrengthLevel, String>? strengthLabels,
    bool showStrengthChecklist = false,
    String strengthTitle = smartStrengthTitleText,
    String showPasswordLabel = smartShowPasswordText,
    String hidePasswordLabel = smartHidePasswordText,
    String uppercaseErrorText = smartUppercaseRuleText,
    String lowercaseErrorText = smartLowercaseRuleText,
    String digitErrorText = smartDigitRuleText,
    String specialCharacterErrorText = smartSpecialRuleText,
    String noWhitespaceErrorText = smartWhitespaceRuleText,
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
           showPasswordLabel: showPasswordLabel,
           hidePasswordLabel: hidePasswordLabel,
           passwordRuleMessages: (
             uppercase: uppercaseErrorText,
             lowercase: lowercaseErrorText,
             digit: digitErrorText,
             special: specialCharacterErrorText,
             whitespace: noWhitespaceErrorText,
           ),
           strength: showStrengthIndicator
               ? _SmartStrengthConfig(
                   criteria: strengthCriteria,
                   labels: strengthLabels,
                   showChecklist: showStrengthChecklist,
                   title: strengthTitle,
                 )
               : null,
         ),
         autofillHints: const [AutofillHints.password],
       );

  SmartField._securityCode({
    required String showLabel,
    required String hideLabel,
    super.label,
    super.hintText,
    super.controller,
    super.focusNode,
    super.enabled,
    super.readOnly,
    super.keyboardType,
    super.inputFormatters,
    super.textInputAction,
    super.onChanged,
    super.isRequired,
    super.requiredErrorText,
    super.validator,
    super.autovalidateMode,
    super.serverError,
    super.decoration,
  }) : super(
         _SmartFieldCore(
           isPassword: true,
           showPasswordLabel: showLabel,
           hidePasswordLabel: hideLabel,
           ltrContent: true,
         ),
         showVisibilityToggle: true,
         autofillHints: const [AutofillHints.creditCardSecurityCode],
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
    super.initialValue,
    super.onEditingComplete,
    super.onTapOutside,
    super.style,
    super.textAlign,
    super.textDirection,
    super.onFieldSubmitted,
    super.onTap,
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
    super.initialValue,
    super.onEditingComplete,
    super.onTapOutside,
    super.style,
    super.textAlign,
    super.textDirection,
    super.onFieldSubmitted,
    super.onTap,
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
    super.initialValue,
    super.onEditingComplete,
    super.onTapOutside,
    super.style,
    super.textAlign,
    super.textDirection,
    super.onFieldSubmitted,
    super.onTap,
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
    String clearLabel = 'Clear',
    String? pickerLabel,
    String dayLabel = 'Day',
    String monthLabel = 'Month',
    String yearLabel = 'Year',
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
             clearLabel: clearLabel,
             pickerTooltip: pickerLabel,
             dayLabel: dayLabel,
             monthLabel: monthLabel,
             yearLabel: yearLabel,
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
    String clearLabel = 'Clear',
    String? pickerLabel,
    String hourLabel = 'Hour',
    String minuteLabel = 'Minute',
    String periodLabel = 'AM or PM',
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
             clearLabel: clearLabel,
             pickerTooltip: pickerLabel,
             hourLabel: hourLabel,
             minuteLabel: minuteLabel,
             periodLabel: periodLabel,
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
    String clearLabel = 'Clear',
    String? pickerLabel,
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
             clearLabel: clearLabel,
             pickerTooltip: pickerLabel,
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
    Set<SmartCardBrand> luhnExemptBrands = const {SmartCardBrand.unionPay},
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
    String showCvvLabel = smartShowSecurityCodeText,
    String hideCvvLabel = smartHideSecurityCodeText,
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
             showCvvLabel: showCvvLabel,
             hideCvvLabel: hideCvvLabel,
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
  bool _initialized = false;
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

  List<_FieldFeature> _createFeatures([
    List<_FieldFeature> existing = const [],
  ]) {
    final source = widget;
    T keep<T extends _FieldFeature>(T Function() create) {
      for (final feature in existing) {
        if (feature is T) {
          return feature;
        }
      }
      return create();
    }

    return [
      if (source._percentageSuffix != null)
        keep<_PercentageFeature>(() => _PercentageFeature(this)),
      if (source._maskConfig?.enabled ?? false)
        keep<_MaskFeature>(() => _MaskFeature(this)),
      if (source._asyncActive)
        keep<_AsyncFeature>(
          () => _AsyncFeature(this, observeExisting: _initialized),
        ),
      if (source._isPassword)
        keep<_PasswordFeature>(() => _PasswordFeature(this)),
      if (source._isPhone) keep<_PhoneFeature>(() => _PhoneFeature(this)),
      if (source._isSearch) keep<_SearchFeature>(() => _SearchFeature(this)),
      if (source._isAmount) keep<_AmountFeature>(() => _AmountFeature(this)),
      if (source._core.showWordCount)
        keep<_WordCountFeature>(() => _WordCountFeature(this)),
      if (source._core.strength != null)
        keep<_StrengthFeature>(() => _StrengthFeature(this)),
      if (source._core.matchController != null)
        keep<_MatchFeature>(() => _MatchFeature(this)),
      if (source.serverError != null)
        keep<_RebuildFeature>(
          () => _RebuildFeature(this, () => widget.serverError),
        ),
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
  bool get isEnabled => smartResolveEnabled(widget.enabled, widget.decoration);

  @override
  bool get isInteractive => isEnabled && !widget.readOnly;

  @override
  String get currentText =>
      textController?.text ??
      _fieldKey.currentState?.value ??
      widget.initialValue ??
      '';

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
  TextEditingValue? get currentEditingValue =>
      textController?.value ?? _innerEditable()?.widget.controller.value;

  @override
  TextEditingController? get currentEditingController =>
      textController ?? _innerEditable()?.widget.controller;

  @override
  bool get showsMask => _feature<_MaskFeature>()?.shows ?? false;

  @override
  bool get pickerInteractive {
    final scope = context.getInheritedWidgetOfExactType<SmartPickerScope>();
    return scope?.interactive ?? false;
  }

  @override
  void initState() {
    super.initState();
    _ensureOwnedState(null);
    _bindFeatures();
    _initialized = true;
  }

  EditableTextState? _innerEditable() {
    EditableTextState? found;
    void visit(Element element) {
      if (found != null) {
        return;
      }
      if (element is StatefulElement && element.state is EditableTextState) {
        found = element.state as EditableTextState;
        return;
      }
      element.visitChildren(visit);
    }

    final context = _fieldKey.currentContext ?? (mounted ? this.context : null);
    if (context is Element) {
      context.visitChildren(visit);
    }
    return found;
  }

  @override
  void didUpdateWidget(covariant SmartField oldWidget) {
    final inner = _innerEditable();
    final oldController = _controllerFor(oldWidget);
    final carried = oldController?.value ?? inner?.widget.controller.value;
    final restoreFocus =
        _focusNodeFor(oldWidget) == null &&
        (inner?.widget.focusNode.hasFocus ?? false);
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
    _ensureOwnedState(carried);
    if (restoreFocus && _ownedFocusNode != null) {
      final node = _ownedFocusNode!;
      final selection = carried?.selection;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && identical(node, _ownedFocusNode)) {
          node.requestFocus();
          if (selection != null && selection.isValid) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final controller = _ownedController;
              if (mounted &&
                  controller != null &&
                  node.hasFocus &&
                  selection.end <= controller.text.length) {
                controller.selection = selection;
              }
            });
          }
        }
      });
    }
    final previous = _features;
    if (_featureKey(oldWidget) != _featureKey(widget)) {
      _features = _createFeatures(previous);
    }
    for (final feature in previous) {
      if (_features.contains(feature)) {
        feature.didUpdate(oldWidget);
      } else {
        feature.retire();
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
      final seed = widget.initialValue;
      _ownedController ??= TextEditingController.fromValue(
        initialValue ?? (seed == null ? null : TextEditingValue(text: seed)),
      );
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
    final base = async == null || widget._otpConfig != null
        ? _synchronousValidator
        : SmartValidators.compose([_synchronousValidator, async.errorFor]);
    if (_feature<_MaskFeature>() == null) {
      return base;
    }
    return (value) {
      final error = base(value);
      if (error != _announcedError) {
        _announcedError = error;
        scheduleMicrotask(rebuild);
      }
      return error;
    };
  }

  String? _announcedError;

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
        SmartValidators.passwordRules(
          checks,
          uppercaseMessage: core.passwordRuleMessages.uppercase,
          lowercaseMessage: core.passwordRuleMessages.lowercase,
          digitMessage: core.passwordRuleMessages.digit,
          specialCharacterMessage: core.passwordRuleMessages.special,
          noWhitespaceMessage: core.passwordRuleMessages.whitespace,
        ),
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
    widget.onFieldSubmitted?.call(value);
    _feature<_SearchFeature>()?.submitted(value);
  }

  void _handleSaved(String? value) {
    final core = widget._core;
    widget.onSaved?.call(core.trimOnSave ? value?.trim() : value);
    if (value == null) {
      widget.onRawSaved?.call(null);
      return;
    }
    final formatter = core.amountFormatter;
    final settled = formatter == null
        ? value
        : formatter.format(value) ?? value;
    widget.onRawSaved?.call(core.rawValue(settled));
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
      final otp = SmartOtpField(
        configuration: otpConfig,
        source: widget,
        controller: async?.otpController ?? widget.controller,
        onChanged: _handleOtpChanged,
        validator: _synchronousValidator,
        decoration: asyncError == null || widget.decoration.errorText != null
            ? widget.decoration
            : widget.decoration.copyWith(errorText: asyncError),
      );
      return _wrapFeatures(async == null ? smartPassiveFocus(child: otp) : otp);
    }
    final mask = _feature<_MaskFeature>();
    final ltrContent =
        widget._core.ltrContent || SmartLtrContentScope.isActive(context);
    final ambientRtl = Directionality.of(context) == TextDirection.rtl;
    final field = TextFormField(
      key: _fieldKey,
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
      initialValue: textController == null ? widget.initialValue : null,
      textDirection:
          widget.textDirection ?? (ltrContent ? TextDirection.ltr : null),
      textAlign:
          widget.textAlign ??
          (ltrContent && ambientRtl ? TextAlign.right : TextAlign.start),
      obscuringCharacter: widget.obscuringCharacter,
      onEditingComplete: widget.onEditingComplete,
      onTapOutside: widget.onTapOutside,
      obscureText: _feature<_PasswordFeature>()?.obscure ?? false,
      style: showsMask
          ? const TextStyle(color: Colors.transparent)
          : widget.style,
      showCursor: showsMask ? false : null,
      enableInteractiveSelection: !showsMask,
      inputFormatters: widget.inputFormatters,
      onTap: widget.onTap ?? widget._searchConfig?.onTap,
      onChanged: _handleChanged,
      onFieldSubmitted: widget._isSearch || widget.onFieldSubmitted != null
          ? _handleSubmitted
          : null,
      onSaved: _handleSaved,
      validator: _effectiveValidator,
      forceErrorText: widget.serverError?.errorText,
      restorationId: _restorationId,
      autovalidateMode: widget.autovalidateMode,
      decoration: _effectiveDecoration,
    );
    return _wrapFeatures(field);
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

SmartField smartConcealedSecurityCodeField({
  String? label,
  String? hintText,
  TextEditingController? controller,
  FocusNode? focusNode,
  bool? enabled,
  bool readOnly = false,
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
  TextInputAction? textInputAction,
  ValueChanged<String>? onChanged,
  bool isRequired = false,
  String requiredErrorText = smartRequiredText,
  FormFieldValidator<String>? validator,
  AutovalidateMode? autovalidateMode,
  SmartServerError? serverError,
  InputDecoration decoration = const InputDecoration(),
  String showLabel = smartShowSecurityCodeText,
  String hideLabel = smartHideSecurityCodeText,
}) {
  return SmartField._securityCode(
    showLabel: showLabel,
    hideLabel: hideLabel,
    label: label,
    hintText: hintText,
    controller: controller,
    focusNode: focusNode,
    enabled: enabled,
    readOnly: readOnly,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    textInputAction: textInputAction,
    onChanged: onChanged,
    isRequired: isRequired,
    requiredErrorText: requiredErrorText,
    validator: validator,
    autovalidateMode: autovalidateMode,
    serverError: serverError,
    decoration: decoration,
  );
}
