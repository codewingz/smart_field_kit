part of 'smart_field.dart';

bool _hasValidLengthRange(int? minLength, int? maxLength) {
  return (minLength == null || minLength >= 0) &&
      (maxLength == null || maxLength >= 0) &&
      (minLength == null || maxLength == null || minLength <= maxLength);
}

typedef _ValueLimits = ({SmartValidator? min, SmartValidator? max});

_ValueLimits _valueLimits({
  String? minValue,
  String? minValueErrorText,
  String? maxValue,
  String? maxValueErrorText,
  SmartValueNormalizer? normalizer,
}) {
  return (
    min: minValue == null
        ? null
        : SmartValidators.minValue(
            minValue,
            normalizer: normalizer,
            message: minValueErrorText,
          ),
    max: maxValue == null
        ? null
        : SmartValidators.maxValue(
            maxValue,
            normalizer: normalizer,
            message: maxValueErrorText,
          ),
  );
}

_SmartFieldCore _numberCore({
  String? minValue,
  String? minValueErrorText,
  String? maxValue,
  String? maxValueErrorText,
  required bool mask,
  required int maskVisibleSuffixDigits,
  required String maskCharacter,
  required bool revealMaskOnFocus,
  required bool allowNegative,
  required SmartNumberPolicy policy,
  required String errorText,
}) {
  final limits = _valueLimits(
    minValue: minValue,
    minValueErrorText: minValueErrorText,
    maxValue: maxValue,
    maxValueErrorText: maxValueErrorText,
  );
  return _SmartFieldCore(
    fieldValidator: SmartValidators.number(
      policy: policy,
      allowNegative: allowNegative,
      message: errorText,
    ),
    minValueValidator: limits.min,
    maxValueValidator: limits.max,
    maskConfig: _createMaskConfig(
      enabled: mask,
      kind: _SmartMaskKind.account,
      visibleSuffixDigits: maskVisibleSuffixDigits,
      maskCharacter: maskCharacter,
      revealOnFocus: revealMaskOnFocus,
    ),
    formatters: [SmartNumberInputFormatter(allowNegative: allowNegative)],
    ltrContent: true,
  );
}

SmartValidator _usernameCharactersValidator(
  SmartUsernameCharacters allowedCharacters,
  String message,
) {
  final formatter = SmartUsernameFormatter(
    allowedCharacters: allowedCharacters,
  );
  return (value) {
    if (value == null || value.isEmpty || formatter.allows(value)) {
      return null;
    }
    return message;
  };
}

_SmartFieldCore _textCore({
  SmartTextCase textCase = SmartTextCase.none,
  bool collapseWhitespace = false,
  String? inputMask,
  String inputMaskErrorText = smartInputMaskErrorText,
  SmartValueNormalizer? rawValueBuilder,
  int? minWords,
  int? maxWords,
  bool showWordCount = false,
  String Function(int count, int? maxWords)? wordCountBuilder,
  String? minWordsErrorText,
  String? maxWordsErrorText,
  SmartTextValidationPreset? validationPreset,
  String? validationPresetErrorText,
  List<TextInputFormatter> extraFormatters = const [],
  SmartUsernameCharacters allowedCharacters = SmartUsernameCharacters.any,
  String allowedCharactersErrorText = smartAllowedCharactersText,
}) {
  final mask = inputMask == null ? null : SmartInputMask(inputMask);
  final preset = validationPreset == null
      ? null
      : SmartValidators.textPreset(
          validationPreset,
          message: validationPresetErrorText,
        );
  final characters = allowedCharacters == SmartUsernameCharacters.any
      ? null
      : _usernameCharactersValidator(
          allowedCharacters,
          allowedCharactersErrorText,
        );
  return _SmartFieldCore(
    fieldValidator: characters == null
        ? preset
        : SmartValidators.compose([characters, ?preset]),
    inputMask: mask,
    inputMaskMessage: inputMaskErrorText,
    valueNormalizer: rawValueBuilder ?? mask?.extractRaw,
    minWords: minWords,
    maxWords: maxWords,
    showWordCount: showWordCount,
    wordCountBuilder: wordCountBuilder,
    minWordsMessage: minWordsErrorText,
    maxWordsMessage: maxWordsErrorText,
    formatters: [
      if (mask != null) SmartMaskFormatter(mask),
      if (textCase != SmartTextCase.none) SmartTextCaseFormatter(textCase),
      if (collapseWhitespace) const SmartWhitespaceFormatter(),
      ...extraFormatters,
    ],
  );
}

_SmartFieldCore _percentageCore({
  String? minValue,
  String? minValueErrorText,
  String? maxValue,
  String? maxValueErrorText,
  int? decimalPlaces,
  required bool allowNegative,
  String? percentSymbol,
  required String errorText,
}) {
  final formatter = SmartAmountFormatter(
    decimalPlaces: decimalPlaces,
    allowNegative: allowNegative,
  );
  final limits = _valueLimits(
    minValue: minValue,
    minValueErrorText: minValueErrorText,
    maxValue: maxValue,
    maxValueErrorText: maxValueErrorText,
    normalizer: formatter.normalize,
  );
  return _SmartFieldCore(
    fieldValidator: SmartValidators.amount(
      formatter: formatter,
      message: errorText,
    ),
    valueNormalizer: formatter.normalize,
    minValueValidator: limits.min,
    maxValueValidator: limits.max,
    percentageSuffix: percentSymbol,
    formatters: [formatter],
    ltrContent: true,
  );
}

int? _amountPlaces(Object? decimalLength, int? decimalPlaces) {
  final length = decimalLength == null
      ? null
      : SmartDecimalLength.from(decimalLength);
  if (length != null &&
      decimalPlaces != null &&
      decimalPlaces != length.places) {
    throw ArgumentError(
      'decimalPlaces ($decimalPlaces) conflicts with decimalLength '
      '($decimalLength). Provide only one.',
    );
  }
  return length?.places ?? decimalPlaces;
}

_SmartFieldCore _amountCore({
  String? minValue,
  String? minValueErrorText,
  String? maxValue,
  String? maxValueErrorText,
  int? decimalPlaces,
  Object? decimalLength,
  required SmartRoundingMode rounding,
  required SmartGroupingStyle groupingStyle,
  required bool useGrouping,
  required String groupingSeparator,
  required String decimalSeparator,
  String? currencySymbol,
  required SmartCurrencyPosition currencyPosition,
  required bool allowNegative,
  required bool mask,
  required int maskVisibleSuffixDigits,
  required String maskCharacter,
  required bool revealMaskOnFocus,
  required SmartAmountPolicy policy,
  required String errorText,
}) {
  final formatter = SmartAmountFormatter(
    decimalPlaces: _amountPlaces(decimalLength, decimalPlaces),
    useGrouping: useGrouping,
    groupingSeparator: groupingSeparator,
    decimalSeparator: decimalSeparator,
    currencySymbol: currencySymbol,
    currencyPosition: currencyPosition,
    allowNegative: allowNegative,
    groupingStyle: groupingStyle,
    roundingMode: rounding,
  );
  final limits = _valueLimits(
    minValue: minValue,
    minValueErrorText: minValueErrorText,
    maxValue: maxValue,
    maxValueErrorText: maxValueErrorText,
    normalizer: formatter.normalize,
  );
  return _SmartFieldCore(
    fieldValidator: SmartValidators.amount(
      formatter: formatter,
      policy: policy,
      message: errorText,
    ),
    valueNormalizer: formatter.normalize,
    minValueValidator: limits.min,
    maxValueValidator: limits.max,
    amountFormatter: formatter,
    maskConfig: _createMaskConfig(
      enabled: mask,
      kind: _SmartMaskKind.amount,
      visibleSuffixDigits: maskVisibleSuffixDigits,
      maskCharacter: maskCharacter,
      revealOnFocus: revealMaskOnFocus,
    ),
    isAmount: true,
    formatters: [formatter],
    ltrContent: true,
  );
}

_SmartFieldCore _otpCore({
  ValueChanged<String>? onCompleted,
  required int length,
  required bool obscureText,
  required SmartOtpPolicy policy,
  required String digitErrorText,
  String? otpLengthErrorText,
  required String legacyErrorText,
  String? errorText,
  required bool notifyOnProgrammaticChanges,
  required SmartOtpStyle style,
}) {
  return _SmartFieldCore(
    fieldValidator: SmartValidators.otp(
      length: length,
      policy: policy,
      digitMessage: digitErrorText,
      lengthMessage: otpLengthErrorText,
      legacyMessage: legacyErrorText,
    ),
    otpConfig: SmartOtpConfiguration(
      length: length,
      obscureText: obscureText,
      onCompleted: onCompleted,
      errorText: errorText,
      notifyOnProgrammaticChanges: notifyOnProgrammaticChanges,
      style: style,
    ),
  );
}

final class _SmartFieldCore {
  const _SmartFieldCore({
    this.fieldValidator,
    this.valueNormalizer,
    this.minValueValidator,
    this.maxValueValidator,
    this.amountFormatter,
    this.maskConfig,
    this.phoneConfig,
    this.otpConfig,
    this.searchConfig,
    this.percentageSuffix,
    this.isPassword = false,
    this.isAmount = false,
    this.formatters = const [],
    this.matchController,
    this.mismatchMessage = smartMismatchText,
    this.showPasswordLabel = smartShowPasswordText,
    this.hidePasswordLabel = smartHidePasswordText,
    this.strength,
    this.dateTimeConfig,
    this.cardConfig,
    this.inputMask,
    this.inputMaskMessage = smartInputMaskErrorText,
    this.minWords,
    this.maxWords,
    this.showWordCount = false,
    this.minWordsMessage,
    this.maxWordsMessage,
    this.ltrContent = false,
    this.trimOnSave = false,
    this.wordCountBuilder,
    this.passwordRuleMessages = const (
      uppercase: smartUppercaseRuleText,
      lowercase: smartLowercaseRuleText,
      digit: smartDigitRuleText,
      special: smartSpecialRuleText,
      whitespace: smartWhitespaceRuleText,
    ),
  });

  final SmartValidator? fieldValidator;
  final SmartValueNormalizer? valueNormalizer;
  final SmartValidator? minValueValidator;
  final SmartValidator? maxValueValidator;
  final SmartAmountFormatter? amountFormatter;
  final _SmartMaskConfig? maskConfig;
  final _SmartPhoneConfig? phoneConfig;
  final SmartOtpConfiguration? otpConfig;
  final _SmartSearchConfig? searchConfig;
  final String? percentageSuffix;
  final bool isPassword;
  final bool isAmount;
  final List<TextInputFormatter> formatters;
  final TextEditingController? matchController;
  final String mismatchMessage;
  final String showPasswordLabel;
  final String hidePasswordLabel;
  final _SmartStrengthConfig? strength;
  final SmartDateTimeConfig? dateTimeConfig;
  final SmartCreditCardConfig? cardConfig;
  final SmartInputMask? inputMask;
  final String inputMaskMessage;
  final int? minWords;
  final int? maxWords;
  final bool showWordCount;
  final String? minWordsMessage;
  final String? maxWordsMessage;
  final bool ltrContent;
  final bool trimOnSave;
  final String Function(int count, int? maxWords)? wordCountBuilder;
  final ({
    String uppercase,
    String lowercase,
    String digit,
    String special,
    String whitespace,
  })
  passwordRuleMessages;

  String? rawValue(String text, {bool partial = false}) {
    final formatter = amountFormatter;
    if (formatter != null) {
      return formatter.normalize(text, allowPartial: partial);
    }
    return valueNormalizer?.call(text);
  }
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

  String render(String value, SmartAmountFormatter? amountFormatter) {
    switch (kind) {
      case _SmartMaskKind.phone:
        return maskMobile(
          value,
          visibleSuffixDigits: visibleSuffixDigits,
          maskCharacter: maskCharacter,
        );
      case _SmartMaskKind.account:
        return maskAccountNumber(
          value,
          visibleSuffixCharacters: visibleSuffixDigits,
          maskCharacter: maskCharacter,
        );
      case _SmartMaskKind.amount:
        final formatter = amountFormatter!;
        try {
          return maskAmount(
            value,
            visibleSuffixDigits: visibleSuffixDigits,
            maskCharacter: maskCharacter,
            groupingSeparator: formatter.groupingSeparator,
            decimalSeparator: formatter.decimalSeparator,
          );
        } on FormatException {
          return maskAccountNumber(
            value,
            visibleSuffixCharacters: 0,
            maskCharacter: maskCharacter,
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
    this.contactPickerMessageBuilder,
    required this.contactPicker,
    required this.countryTextStyle,
    required this.countryPlaceholder,
    required this.countryPadding,
    this.selectCountryLabel = smartSelectCountryText,
    this.changeCountryLabelBuilder,
    this.contactPickerLabel = smartContactPickerText,
    this.clearLabel = smartClearPhoneText,
    this.countrySearchHint = smartCountrySearchText,
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
  final String Function(SmartPhonePickerErrorCode code)?
  contactPickerMessageBuilder;
  final SmartPhoneContactPicker? contactPicker;
  final TextStyle? countryTextStyle;
  final Widget? countryPlaceholder;
  final EdgeInsetsGeometry? countryPadding;
  final String selectCountryLabel;
  final String Function(SmartPhoneCountry country)? changeCountryLabelBuilder;
  final String contactPickerLabel;
  final String clearLabel;
  final String countrySearchHint;
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
    this.clearLabel = smartClearSearchText,
    this.loadingLabel = smartLoadingSearchText,
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
  final String clearLabel;
  final String loadingLabel;

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
  String clearLabel = smartClearSearchText,
  String loadingLabel = smartLoadingSearchText,
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
    clearLabel: clearLabel,
    loadingLabel: loadingLabel,
  );
}

final class _SmartStrengthConfig {
  const _SmartStrengthConfig({
    required this.criteria,
    required this.labels,
    required this.showChecklist,
    this.title = smartStrengthTitleText,
  });

  final String title;

  final List<SmartPasswordCriterion>? criteria;
  final Map<SmartPasswordStrengthLevel, String>? labels;
  final bool showChecklist;
}
