import 'dart:async';

import 'package:country_picker/country_picker.dart' as country_picker;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:smart_field_kit/src/formatting/smart_numeric_formatters.dart';
import 'package:smart_field_kit/src/masking/smart_masking.dart';
import 'package:smart_field_kit/src/models/smart_otp_style.dart';
import 'package:smart_field_kit/src/models/smart_phone_value.dart';
import 'package:smart_field_kit/src/validation/smart_phone_validation.dart';
import 'package:smart_field_kit/src/validation/smart_url_validation.dart';
import 'package:smart_field_kit/src/validation/smart_validators.dart';
import 'package:smart_field_kit/src/widgets/smart_otp_field.dart';

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
    this.minLines,
    this.maxLines = 1,
    this.expands = false,
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
    this.inputFormatters,
  }) : showVisibilityToggle = false,
       onRawChanged = null,
       onRawSaved = null,
       _fieldValidator = null,
       _valueNormalizer = null,
       _minValueValidator = null,
       _maxValueValidator = null,
       _amountFormatter = null,
       _maskConfig = null,
       _phoneConfig = null,
       _otpConfig = null,
       _searchConfig = null,
       _percentageSuffix = null,
       _isPassword = false,
       _isAmount = false,
       assert(minLength == null || minLength >= 0),
       assert(maxLength == null || maxLength >= 0),
       assert(minLength == null || maxLength == null || minLength <= maxLength),
       assert(minLines == null || minLines > 0),
       assert(maxLines == null || maxLines > 0),
       assert(minLines == null || maxLines == null || maxLines >= minLines),
       assert(!expands || (minLines == null && maxLines == null));

  factory SmartField.description({
    Key? key,
    String? label,
    String? hintText,
    TextEditingController? controller,
    FocusNode? focusNode,
    bool autofocus = false,
    bool? enabled,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.multiline,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool autocorrect = true,
    bool enableSuggestions = true,
    Iterable<String>? autofillHints,
    TextInputAction? textInputAction = TextInputAction.newline,
    int? minLines = 3,
    int? maxLines,
    bool expands = false,
    ValueChanged<String>? onChanged,
    FormFieldSetter<String>? onSaved,
    bool isRequired = false,
    String requiredErrorText = 'This field is required.',
    int? minLength,
    String? minLengthErrorText,
    int? maxLength,
    String? maxLengthErrorText,
    FormFieldValidator<String>? validator,
    AutovalidateMode? autovalidateMode,
    InputDecoration decoration = const InputDecoration(),
    List<TextInputFormatter>? inputFormatters,
    SmartTextValidationPreset? validationPreset,
    String? validationPresetErrorText,
  }) {
    return SmartField.text(
      key: key,
      label: label,
      hintText: hintText,
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      enabled: enabled,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      minLines: minLines,
      maxLines: maxLines,
      expands: expands,
      onChanged: onChanged,
      onSaved: onSaved,
      isRequired: isRequired,
      requiredErrorText: requiredErrorText,
      minLength: minLength,
      minLengthErrorText: minLengthErrorText,
      maxLength: maxLength,
      maxLengthErrorText: maxLengthErrorText,
      validator: validator,
      autovalidateMode: autovalidateMode,
      decoration: decoration,
      inputFormatters: inputFormatters,
      validationPreset: validationPreset,
      validationPresetErrorText: validationPresetErrorText,
    );
  }

  SmartField.text({
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
    this.minLines,
    this.maxLines = 1,
    this.expands = false,
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
    this.inputFormatters,
    SmartTextValidationPreset? validationPreset,
    String? validationPresetErrorText,
  }) : showVisibilityToggle = false,
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
       _amountFormatter = null,
       _maskConfig = null,
       _phoneConfig = null,
       _otpConfig = null,
       _searchConfig = null,
       _percentageSuffix = null,
       _isPassword = false,
       _isAmount = false,
       assert(minLength == null || minLength >= 0),
       assert(maxLength == null || maxLength >= 0),
       assert(minLength == null || maxLength == null || minLength <= maxLength),
       assert(minLines == null || minLines > 0),
       assert(maxLines == null || maxLines > 0),
       assert(minLines == null || maxLines == null || maxLines >= minLines),
       assert(!expands || (minLines == null && maxLines == null));

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
       minLines = null,
       maxLines = 1,
       expands = false,
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
       inputFormatters = null,
       _amountFormatter = null,
       _maskConfig = null,
       _phoneConfig = null,
       _otpConfig = null,
       _searchConfig = null,
       _percentageSuffix = null,
       _isPassword = false,
       _isAmount = false,
       assert(minLength == null || minLength >= 0),
       assert(maxLength == null || maxLength >= 0),
       assert(minLength == null || maxLength == null || minLength <= maxLength);

  SmartField.url({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.enabled,
    this.readOnly = false,
    this.textInputAction = TextInputAction.done,
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
    this.inputFormatters,
    Set<String> allowedSchemes = SmartUrlValidation.defaultSchemes,
    bool allowBareDomain = false,
    String urlErrorText = 'Enter a valid URL.',
  }) : keyboardType = TextInputType.url,
       textCapitalization = TextCapitalization.none,
       autocorrect = false,
       enableSuggestions = false,
       autofillHints = const [AutofillHints.url],
       minLines = null,
       maxLines = 1,
       expands = false,
       showVisibilityToggle = false,
       onRawChanged = null,
       onRawSaved = null,
       _fieldValidator = SmartValidators.url(
         allowedSchemes: allowedSchemes,
         allowBareDomain: allowBareDomain,
         message: urlErrorText,
       ),
       _valueNormalizer = null,
       _minValueValidator = null,
       _maxValueValidator = null,
       _amountFormatter = null,
       _maskConfig = null,
       _phoneConfig = null,
       _otpConfig = null,
       _searchConfig = null,
       _percentageSuffix = null,
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
    this.inputFormatters,
    SmartTextValidationPreset? validationPreset,
    String? validationPresetErrorText,
  }) : keyboardType = TextInputType.name,
       textCapitalization = TextCapitalization.words,
       autocorrect = true,
       enableSuggestions = true,
       minLines = null,
       maxLines = 1,
       expands = false,
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
       _amountFormatter = null,
       _maskConfig = null,
       _phoneConfig = null,
       _otpConfig = null,
       _searchConfig = null,
       _percentageSuffix = null,
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
    this.inputFormatters,
    SmartTextValidationPreset? validationPreset,
    String? validationPresetErrorText,
  }) : keyboardType = TextInputType.text,
       textCapitalization = TextCapitalization.none,
       autocorrect = false,
       enableSuggestions = false,
       minLines = null,
       maxLines = 1,
       expands = false,
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
       _amountFormatter = null,
       _maskConfig = null,
       _phoneConfig = null,
       _otpConfig = null,
       _searchConfig = null,
       _percentageSuffix = null,
       _isPassword = false,
       _isAmount = false,
       assert(minLength == null || minLength >= 0),
       assert(maxLength == null || maxLength >= 0),
       assert(minLength == null || maxLength == null || minLength <= maxLength);

  factory SmartField.otp({
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
    ValueChanged<String>? onCompleted,
    FormFieldSetter<String>? onSaved,
    bool isRequired = false,
    String requiredErrorText = 'This field is required.',
    int length = 6,
    int? minLength,
    String? minLengthErrorText,
    int? maxLength,
    String? maxLengthErrorText,
    FormFieldValidator<String>? validator,
    AutovalidateMode? autovalidateMode,
    InputDecoration decoration = const InputDecoration(),
    bool obscureText = false,
    SmartOtpPolicy policy = SmartOtpPolicy.standard,
    String digitErrorText = 'Enter digits only.',
    String? otpLengthErrorText,
    String legacyErrorText = 'Enter a valid verification code.',
    String? errorText,
    bool notifyOnProgrammaticChanges = false,
    SmartOtpStyle style = const SmartOtpStyle(),
  }) {
    if (length <= 0) {
      throw ArgumentError.value(length, 'length');
    }
    if (policy == SmartOtpPolicy.legacy && length != 6) {
      throw ArgumentError.value(
        length,
        'length',
        'The legacy OTP policy requires a length of 6.',
      );
    }
    return SmartField._otp(
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
      onCompleted: onCompleted,
      onSaved: onSaved,
      isRequired: isRequired,
      requiredErrorText: requiredErrorText,
      length: length,
      minLength: minLength,
      minLengthErrorText: minLengthErrorText,
      maxLength: maxLength,
      maxLengthErrorText: maxLengthErrorText,
      validator: validator,
      autovalidateMode: autovalidateMode,
      decoration: decoration,
      obscureText: obscureText,
      policy: policy,
      digitErrorText: digitErrorText,
      otpLengthErrorText: otpLengthErrorText,
      legacyErrorText: legacyErrorText,
      errorText: errorText,
      notifyOnProgrammaticChanges: notifyOnProgrammaticChanges,
      style: style,
    );
  }

  SmartField.search({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.enabled,
    this.readOnly = false,
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
    this.inputFormatters,
    GestureTapCallback? onTap,
    ValueChanged<String>? onSubmitted,
    ValueChanged<String>? onSearch,
    Duration? debounceDuration,
    VoidCallback? onCleared,
    bool showClearButton = true,
    bool isLoading = false,
    Widget? searchIcon = const Icon(Icons.search),
    Widget? clearIcon = const Icon(Icons.clear),
  }) : keyboardType = TextInputType.text,
       textCapitalization = TextCapitalization.none,
       autocorrect = true,
       enableSuggestions = true,
       autofillHints = null,
       textInputAction = TextInputAction.search,
       minLines = null,
       maxLines = 1,
       expands = false,
       showVisibilityToggle = false,
       onRawChanged = null,
       onRawSaved = null,
       _fieldValidator = null,
       _valueNormalizer = null,
       _minValueValidator = null,
       _maxValueValidator = null,
       _amountFormatter = null,
       _maskConfig = null,
       _phoneConfig = null,
       _otpConfig = null,
       _searchConfig = _createSearchConfig(
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
       _percentageSuffix = null,
       _isPassword = false,
       _isAmount = false,
       assert(minLength == null || minLength >= 0),
       assert(maxLength == null || maxLength >= 0),
       assert(minLength == null || maxLength == null || minLength <= maxLength);

  SmartField._otp({
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
    required ValueChanged<String>? onCompleted,
    this.onSaved,
    this.isRequired = false,
    this.requiredErrorText = 'This field is required.',
    required int length,
    this.minLength,
    this.minLengthErrorText,
    this.maxLength,
    this.maxLengthErrorText,
    this.validator,
    this.autovalidateMode,
    this.decoration = const InputDecoration(),
    required bool obscureText,
    required SmartOtpPolicy policy,
    required String digitErrorText,
    required String? otpLengthErrorText,
    required String legacyErrorText,
    required String? errorText,
    required bool notifyOnProgrammaticChanges,
    required SmartOtpStyle style,
  }) : keyboardType = TextInputType.number,
       textCapitalization = TextCapitalization.none,
       autocorrect = false,
       enableSuggestions = false,
       autofillHints = const [AutofillHints.oneTimeCode],
       minLines = null,
       maxLines = 1,
       expands = false,
       showVisibilityToggle = false,
       onRawChanged = null,
       onRawSaved = null,
       _fieldValidator = SmartValidators.otp(
         length: length,
         policy: policy,
         digitMessage: digitErrorText,
         lengthMessage: otpLengthErrorText,
         legacyMessage: legacyErrorText,
       ),
       _valueNormalizer = null,
       _minValueValidator = null,
       _maxValueValidator = null,
       inputFormatters = null,
       _amountFormatter = null,
       _maskConfig = null,
       _phoneConfig = null,
       _otpConfig = SmartOtpConfiguration(
         length: length,
         obscureText: obscureText,
         onCompleted: onCompleted,
         errorText: errorText,
         notifyOnProgrammaticChanges: notifyOnProgrammaticChanges,
         style: style,
       ),
       _searchConfig = null,
       _percentageSuffix = null,
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
  }) : keyboardType = TextInputType.phone,
       textCapitalization = TextCapitalization.none,
       autocorrect = false,
       enableSuggestions = false,
       autofillHints = const [AutofillHints.telephoneNumber],
       minLines = null,
       maxLines = 1,
       expands = false,
       showVisibilityToggle = false,
       onRawChanged = null,
       onRawSaved = null,
       _fieldValidator = null,
       _valueNormalizer = null,
       _minValueValidator = null,
       _maxValueValidator = null,
       inputFormatters = null,
       _amountFormatter = null,
       _maskConfig = _createMaskConfig(
         enabled: mask,
         kind: _SmartMaskKind.phone,
         visibleSuffixDigits: maskVisibleSuffixDigits,
         maskCharacter: maskCharacter,
         revealOnFocus: revealMaskOnFocus,
       ),
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
       _otpConfig = null,
       _searchConfig = null,
       _percentageSuffix = null,
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
       minLines = null,
       maxLines = 1,
       expands = false,
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
       inputFormatters = null,
       _amountFormatter = null,
       _maskConfig = null,
       _phoneConfig = null,
       _otpConfig = null,
       _searchConfig = null,
       _percentageSuffix = null,
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
    bool mask = false,
    int maskVisibleSuffixDigits = 4,
    String maskCharacter = '*',
    bool revealMaskOnFocus = true,
    bool allowNegative = false,
    SmartNumberPolicy policy = SmartNumberPolicy.standard,
    String numberErrorText = 'Enter a valid whole number.',
  }) : keyboardType = TextInputType.numberWithOptions(signed: allowNegative),
       textCapitalization = TextCapitalization.none,
       autocorrect = false,
       enableSuggestions = false,
       autofillHints = null,
       minLines = null,
       maxLines = 1,
       expands = false,
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
       inputFormatters = [
         SmartNumberInputFormatter(allowNegative: allowNegative),
       ],
       _amountFormatter = null,
       _maskConfig = _createMaskConfig(
         enabled: mask,
         kind: _SmartMaskKind.account,
         visibleSuffixDigits: maskVisibleSuffixDigits,
         maskCharacter: maskCharacter,
         revealOnFocus: revealMaskOnFocus,
       ),
       _phoneConfig = null,
       _otpConfig = null,
       _searchConfig = null,
       _percentageSuffix = null,
       _isPassword = false,
       _isAmount = false,
       assert(minLength == null || minLength >= 0),
       assert(maxLength == null || maxLength >= 0),
       assert(minLength == null || maxLength == null || minLength <= maxLength);

  SmartField.percentage({
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
    int? decimalPlaces,
    bool allowNegative = true,
    String? percentSymbol = '%',
    String percentageErrorText = 'Enter a valid percentage.',
  }) : keyboardType = TextInputType.numberWithOptions(
         decimal: true,
         signed: allowNegative,
       ),
       textCapitalization = TextCapitalization.none,
       autocorrect = false,
       enableSuggestions = false,
       autofillHints = null,
       minLines = null,
       maxLines = 1,
       expands = false,
       showVisibilityToggle = false,
       onRawChanged = null,
       onRawSaved = null,
       _fieldValidator = SmartValidators.amount(
         formatter: SmartAmountFormatter(
           decimalPlaces: decimalPlaces,
           allowNegative: allowNegative,
         ),
         message: percentageErrorText,
       ),
       _valueNormalizer = SmartAmountFormatter(
         decimalPlaces: decimalPlaces,
         allowNegative: allowNegative,
       ).normalize,
       _minValueValidator = minValue == null
           ? null
           : SmartValidators.minValue(
               minValue,
               normalizer: SmartAmountFormatter(
                 decimalPlaces: decimalPlaces,
                 allowNegative: allowNegative,
               ).normalize,
               message: minValueErrorText,
             ),
       _maxValueValidator = maxValue == null
           ? null
           : SmartValidators.maxValue(
               maxValue,
               normalizer: SmartAmountFormatter(
                 decimalPlaces: decimalPlaces,
                 allowNegative: allowNegative,
               ).normalize,
               message: maxValueErrorText,
             ),
       inputFormatters = [
         SmartAmountFormatter(
           decimalPlaces: decimalPlaces,
           allowNegative: allowNegative,
         ),
       ],
       _amountFormatter = null,
       _maskConfig = null,
       _phoneConfig = null,
       _otpConfig = null,
       _searchConfig = null,
       _percentageSuffix = percentSymbol,
       _isPassword = false,
       _isAmount = false,
       assert(decimalPlaces == null || decimalPlaces >= 0),
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
    bool mask = false,
    int maskVisibleSuffixDigits = 0,
    String maskCharacter = '*',
    bool revealMaskOnFocus = true,
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
      mask: mask,
      maskVisibleSuffixDigits: maskVisibleSuffixDigits,
      maskCharacter: maskCharacter,
      revealMaskOnFocus: revealMaskOnFocus,
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
    required bool mask,
    required int maskVisibleSuffixDigits,
    required String maskCharacter,
    required bool revealMaskOnFocus,
  }) : keyboardType = TextInputType.numberWithOptions(
         signed: allowNegative,
         decimal: decimalPlaces != 0,
       ),
       textCapitalization = TextCapitalization.none,
       autocorrect = false,
       enableSuggestions = false,
       autofillHints = null,
       minLines = null,
       maxLines = 1,
       expands = false,
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
       inputFormatters = [formatter],
       _amountFormatter = formatter,
       _maskConfig = _createMaskConfig(
         enabled: mask,
         kind: _SmartMaskKind.amount,
         visibleSuffixDigits: maskVisibleSuffixDigits,
         maskCharacter: maskCharacter,
         revealOnFocus: revealMaskOnFocus,
       ),
       _phoneConfig = null,
       _otpConfig = null,
       _searchConfig = null,
       _percentageSuffix = null,
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
  final InputDecoration decoration;
  final bool showVisibilityToggle;
  final SmartValidator? _fieldValidator;
  final SmartValueNormalizer? _valueNormalizer;
  final SmartValidator? _minValueValidator;
  final SmartValidator? _maxValueValidator;
  final List<TextInputFormatter>? inputFormatters;
  final SmartAmountFormatter? _amountFormatter;
  final _SmartMaskConfig? _maskConfig;
  final _SmartPhoneConfig? _phoneConfig;
  final SmartOtpConfiguration? _otpConfig;
  final _SmartSearchConfig? _searchConfig;
  final String? _percentageSuffix;
  final bool _isPassword;
  final bool _isAmount;

  bool get _isPhone => _phoneConfig != null;
  bool get _isSearch => _searchConfig != null;
  bool get _supportsMasking => _maskConfig != null;

  @override
  State<SmartField> createState() => _SmartFieldState();
}

enum _SmartMaskKind { phone, account, amount }

final class _SmartMaskConfig {
  const _SmartMaskConfig({
    required this.enabled,
    required this.kind,
    required this.visibleSuffixDigits,
    required this.maskCharacter,
    required this.revealOnFocus,
  });

  final bool enabled;
  final _SmartMaskKind kind;
  final int visibleSuffixDigits;
  final String maskCharacter;
  final bool revealOnFocus;
}

_SmartMaskConfig _createMaskConfig({
  required bool enabled,
  required _SmartMaskKind kind,
  required int visibleSuffixDigits,
  required String maskCharacter,
  required bool revealOnFocus,
}) {
  maskAccountNumber(
    '',
    visibleSuffixCharacters: visibleSuffixDigits,
    maskCharacter: maskCharacter,
  );
  return _SmartMaskConfig(
    enabled: enabled,
    kind: kind,
    visibleSuffixDigits: visibleSuffixDigits,
    maskCharacter: maskCharacter,
    revealOnFocus: revealOnFocus,
  );
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

final class _SmartSearchConfig {
  const _SmartSearchConfig({
    required this.onTap,
    required this.onSubmitted,
    required this.onSearch,
    required this.debounceDuration,
    required this.onCleared,
    required this.showClearButton,
    required this.isLoading,
    required this.searchIcon,
    required this.clearIcon,
  });

  final GestureTapCallback? onTap;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onSearch;
  final Duration debounceDuration;
  final VoidCallback? onCleared;
  final bool showClearButton;
  final bool isLoading;
  final Widget? searchIcon;
  final Widget? clearIcon;

  bool hasSameDebounceBehavior(_SmartSearchConfig other) {
    return onSearch == other.onSearch &&
        debounceDuration == other.debounceDuration;
  }
}

_SmartSearchConfig _createSearchConfig({
  required GestureTapCallback? onTap,
  required ValueChanged<String>? onSubmitted,
  required ValueChanged<String>? onSearch,
  required Duration? debounceDuration,
  required VoidCallback? onCleared,
  required bool showClearButton,
  required bool isLoading,
  required Widget? searchIcon,
  required Widget? clearIcon,
}) {
  final duration = debounceDuration ?? const Duration(milliseconds: 300);
  if (duration.isNegative) {
    throw ArgumentError.value(debounceDuration, 'debounceDuration');
  }
  return _SmartSearchConfig(
    onTap: onTap,
    onSubmitted: onSubmitted,
    onSearch: onSearch,
    debounceDuration: duration,
    onCleared: onCleared,
    showClearButton: showClearButton,
    isLoading: isLoading,
    searchIcon: searchIcon,
    clearIcon: clearIcon,
  );
}

class _SmartFieldState extends State<SmartField> {
  late bool _obscureText = widget._isPassword;
  TextEditingController? _ownedAmountController;
  FocusNode? _ownedAmountFocusNode;
  TextEditingController? _ownedPhoneController;
  FocusNode? _ownedPhoneFocusNode;
  TextEditingController? _ownedMaskController;
  FocusNode? _ownedMaskFocusNode;
  TextEditingController? _ownedSearchController;
  FocusNode? _ownedSearchFocusNode;
  GlobalKey<FormFieldState<String>> _phoneFieldKey = GlobalKey();
  GlobalKey<FormFieldState<String>> _maskFieldKey = GlobalKey();
  GlobalKey<FormFieldState<String>> _searchFieldKey = GlobalKey();
  final country_picker.CountryService _countryService =
      country_picker.CountryService();
  SmartPhoneCountry? _selectedCountry;
  String? _lastPhoneText;
  bool _updatingAmountText = false;
  Timer? _searchTimer;
  String? _pendingSearchQuery;

  TextEditingController? _controllerFor(SmartField source) {
    if (source._isAmount) {
      return source.controller ?? _ownedAmountController;
    }
    if (source._isPhone) {
      return source.controller ?? _ownedPhoneController;
    }
    if (source._isSearch) {
      return source.controller ?? _ownedSearchController;
    }
    if (source._supportsMasking) {
      return source.controller ?? _ownedMaskController;
    }
    return source.controller;
  }

  FocusNode? _focusNodeFor(SmartField source) {
    if (source._isAmount) {
      return source.focusNode ?? _ownedAmountFocusNode;
    }
    if (source._isPhone) {
      return source.focusNode ?? _ownedPhoneFocusNode;
    }
    if (source._isSearch) {
      return source.focusNode ?? _ownedSearchFocusNode;
    }
    if (source._supportsMasking) {
      return source.focusNode ?? _ownedMaskFocusNode;
    }
    return source.focusNode;
  }

  TextEditingController? get _effectiveController => _controllerFor(widget);

  FocusNode? get _effectiveFocusNode => _focusNodeFor(widget);

  @override
  void initState() {
    super.initState();
    _configureAmountState();
    _configurePhoneState();
    _configureMaskState();
    _configureSearchState();
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
    final oldMaskController = oldWidget._supportsMasking
        ? _controllerFor(oldWidget)
        : null;
    final oldMaskFocusNode = oldWidget._supportsMasking
        ? _focusNodeFor(oldWidget)
        : null;
    final oldSearchController = oldWidget._isSearch
        ? oldWidget.controller ?? _ownedSearchController
        : null;
    oldAmountController?.removeListener(_handleAmountControllerChange);
    oldAmountFocusNode?.removeListener(_handleAmountFocusChange);
    oldPhoneController?.removeListener(_handlePhoneControllerChange);
    oldMaskController?.removeListener(_handleMaskControllerChange);
    oldMaskFocusNode?.removeListener(_handleMaskFocusChange);
    oldSearchController?.removeListener(_handleSearchControllerChange);
    super.didUpdateWidget(oldWidget);

    final oldSearch = oldWidget._searchConfig;
    final search = widget._searchConfig;
    if (oldSearch == null ||
        search == null ||
        oldWidget.controller != widget.controller ||
        !oldSearch.hasSameDebounceBehavior(search) ||
        !_isInteractive) {
      _cancelPendingSearch();
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
    final oldUsesOwnedMaskState =
        oldWidget._supportsMasking &&
        !oldWidget._isAmount &&
        !oldWidget._isPhone;
    final usesOwnedMaskState =
        widget._supportsMasking && !widget._isAmount && !widget._isPhone;
    if (oldUsesOwnedMaskState &&
        oldWidget.controller == null &&
        (!usesOwnedMaskState || widget.controller != null)) {
      _ownedMaskController?.dispose();
      _ownedMaskController = null;
    }
    if (oldUsesOwnedMaskState &&
        oldWidget.focusNode == null &&
        (!usesOwnedMaskState || widget.focusNode != null)) {
      _ownedMaskFocusNode?.dispose();
      _ownedMaskFocusNode = null;
    }
    if (usesOwnedMaskState &&
        widget.controller == null &&
        _ownedMaskController == null) {
      _ownedMaskController = TextEditingController.fromValue(
        oldMaskController?.value,
      );
    }
    if (usesOwnedMaskState &&
        widget.focusNode == null &&
        _ownedMaskFocusNode == null) {
      _ownedMaskFocusNode = FocusNode();
    }
    if (oldWidget._isSearch &&
        oldWidget.controller == null &&
        (!widget._isSearch || widget.controller != null)) {
      _ownedSearchController?.dispose();
      _ownedSearchController = null;
    }
    if (oldWidget._isSearch &&
        oldWidget.focusNode == null &&
        (!widget._isSearch || widget.focusNode != null)) {
      _ownedSearchFocusNode?.dispose();
      _ownedSearchFocusNode = null;
    }
    if (widget._isSearch &&
        widget.controller == null &&
        _ownedSearchController == null) {
      _ownedSearchController = TextEditingController.fromValue(
        oldSearchController?.value,
      );
    }
    if (widget._isSearch &&
        widget.focusNode == null &&
        _ownedSearchFocusNode == null) {
      _ownedSearchFocusNode = FocusNode();
    }
    _configureAmountState();
    _configurePhoneState();
    _configureMaskState();
    _configureSearchState();
  }

  void _configureMaskState() {
    if (!widget._supportsMasking) {
      return;
    }
    if (!widget._isAmount && !widget._isPhone) {
      _ownedMaskController ??= widget.controller == null
          ? TextEditingController()
          : null;
      _ownedMaskFocusNode ??= widget.focusNode == null ? FocusNode() : null;
    }
    _effectiveController?.addListener(_handleMaskControllerChange);
    _effectiveFocusNode?.addListener(_handleMaskFocusChange);
  }

  void _configureSearchState() {
    if (!widget._isSearch) {
      return;
    }
    _ownedSearchController ??= widget.controller == null
        ? TextEditingController()
        : null;
    _ownedSearchFocusNode ??= widget.focusNode == null ? FocusNode() : null;
    _effectiveController?.addListener(_handleSearchControllerChange);
  }

  void _handleSearchControllerChange() {
    _cancelPendingSearch();
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
      suffixText:
          decoration.suffix == null &&
              decoration.suffixText == null &&
              decoration.suffixIcon != null
          ? widget._percentageSuffix
          : null,
      prefixIcon: _searchPrefixIcon(_phonePrefixIcon(decoration.prefixIcon)),
      suffixIcon: _suffixIcon(decoration.suffixIcon),
    );
  }

  Widget? _searchPrefixIcon(Widget? existing) {
    final icon = widget._searchConfig?.searchIcon;
    if (widget._isSearch && existing == null && icon != null) {
      return ExcludeSemantics(child: icon);
    }
    return existing;
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
    if (widget._isSearch) {
      _scheduleSearch(value);
    }
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

  void _scheduleSearch(String query) {
    _cancelPendingSearch();
    final config = widget._searchConfig;
    final callback = config?.onSearch;
    if (callback == null || query.trim().isEmpty || !_isInteractive) {
      return;
    }
    if (config!.debounceDuration == Duration.zero) {
      callback(query);
      return;
    }
    _pendingSearchQuery = query;
    _searchTimer = Timer(config.debounceDuration, () {
      if (!mounted ||
          _pendingSearchQuery != query ||
          _effectiveController?.text != query ||
          !_isInteractive) {
        return;
      }
      _searchTimer = null;
      _pendingSearchQuery = null;
      widget._searchConfig?.onSearch?.call(query);
    });
  }

  void _cancelPendingSearch() {
    _searchTimer?.cancel();
    _searchTimer = null;
    _pendingSearchQuery = null;
  }

  void _handleSubmitted(String value) {
    _cancelPendingSearch();
    widget._searchConfig?.onSubmitted?.call(value);
  }

  void _clearSearch() {
    final controller = _effectiveController;
    final config = widget._searchConfig;
    if (controller == null || controller.text.isEmpty || config == null) {
      return;
    }
    _cancelPendingSearch();
    controller.clear();
    _searchFieldKey.currentState?.didChange('');
    _handleChanged('');
    config.onCleared?.call();
  }

  void _handleSaved(String? value) {
    widget.onSaved?.call(value);
    final formatter = widget._amountFormatter;
    widget.onRawSaved?.call(
      value == null || formatter == null ? null : formatter.normalize(value),
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
    final config = widget._maskConfig!;
    final value = _effectiveController?.text ?? '';
    switch (config.kind) {
      case _SmartMaskKind.phone:
        return maskMobile(
          value,
          visibleSuffixDigits: config.visibleSuffixDigits,
          maskCharacter: config.maskCharacter,
        );
      case _SmartMaskKind.account:
        return maskAccountNumber(
          value,
          visibleSuffixCharacters: config.visibleSuffixDigits,
          maskCharacter: config.maskCharacter,
        );
      case _SmartMaskKind.amount:
        final formatter = widget._amountFormatter!;
        try {
          return maskAmount(
            value,
            visibleSuffixDigits: config.visibleSuffixDigits,
            maskCharacter: config.maskCharacter,
            groupingSeparator: formatter.groupingSeparator,
            decimalSeparator: formatter.decimalSeparator,
          );
        } on FormatException {
          return maskAccountNumber(
            value,
            visibleSuffixCharacters: 0,
            maskCharacter: config.maskCharacter,
            preservedSeparators: {
              ' ',
              '-',
              formatter.groupingSeparator,
              formatter.decimalSeparator,
            },
          );
        }
    }
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
    _cancelPendingSearch();
    if (widget._supportsMasking) {
      _effectiveController?.removeListener(_handleMaskControllerChange);
      _effectiveFocusNode?.removeListener(_handleMaskFocusChange);
    }
    if (widget._isAmount) {
      _effectiveController?.removeListener(_handleAmountControllerChange);
      _effectiveFocusNode?.removeListener(_handleAmountFocusChange);
    }
    if (widget._isPhone) {
      _effectiveController?.removeListener(_handlePhoneControllerChange);
    }
    if (widget._isSearch) {
      _effectiveController?.removeListener(_handleSearchControllerChange);
    }
    _ownedAmountController?.dispose();
    _ownedAmountFocusNode?.dispose();
    _ownedPhoneController?.dispose();
    _ownedPhoneFocusNode?.dispose();
    _ownedMaskController?.dispose();
    _ownedMaskFocusNode?.dispose();
    _ownedSearchController?.dispose();
    _ownedSearchFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final otpConfig = widget._otpConfig;
    if (otpConfig != null) {
      return SmartOtpField(
        configuration: otpConfig,
        label: widget.label,
        hintText: widget.hintText,
        controller: widget.controller,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        textInputAction: widget.textInputAction,
        onChanged: widget.onChanged,
        onSaved: widget.onSaved,
        validator: _effectiveValidator,
        autovalidateMode: widget.autovalidateMode,
        decoration: widget.decoration,
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
      autovalidateMode: widget.autovalidateMode,
      decoration: showsMask
          ? _maskedDecoration(maskedText!)
          : _effectiveDecoration,
    );
    if (!showsMask) {
      return field;
    }
    final enabled = widget.enabled ?? widget.decoration.enabled;
    final canReveal = _isInteractive && widget._maskConfig!.revealOnFocus;
    return Semantics(
      container: true,
      excludeSemantics: true,
      textField: true,
      enabled: enabled,
      readOnly: !canReveal,
      label: widget.label,
      value: maskedText,
      onTap: canReveal ? () => _effectiveFocusNode?.requestFocus() : null,
      child: field,
    );
  }
}
