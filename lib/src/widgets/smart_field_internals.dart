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
  );
}

_SmartFieldCore _textCore({
  SmartTextCase textCase = SmartTextCase.none,
  bool collapseWhitespace = false,
  String? inputMask,
  String inputMaskErrorText = 'Complete the value.',
  SmartValueNormalizer? rawValueBuilder,
  int? minWords,
  int? maxWords,
  bool showWordCount = false,
  String? minWordsErrorText,
  String? maxWordsErrorText,
  SmartTextValidationPreset? validationPreset,
  String? validationPresetErrorText,
  List<TextInputFormatter> extraFormatters = const [],
}) {
  final mask = inputMask == null ? null : SmartInputMask(inputMask);
  return _SmartFieldCore(
    fieldValidator: validationPreset == null
        ? null
        : SmartValidators.textPreset(
            validationPreset,
            message: validationPresetErrorText,
          ),
    inputMask: mask,
    inputMaskMessage: inputMaskErrorText,
    valueNormalizer: rawValueBuilder ?? mask?.extractRaw,
    minWords: minWords,
    maxWords: maxWords,
    showWordCount: showWordCount,
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
    this.mismatchMessage = 'Passwords do not match.',
    this.strength,
    this.dateTimeConfig,
    this.cardConfig,
    this.inputMask,
    this.inputMaskMessage = 'Complete the value.',
    this.minWords,
    this.maxWords,
    this.showWordCount = false,
    this.minWordsMessage,
    this.maxWordsMessage,
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

  String? rawValue(String text, {bool partial = false}) {
    final formatter = amountFormatter;
    if (formatter != null) {
      return formatter.normalize(text, allowPartial: partial);
    }
    final mask = inputMask;
    if (mask != null) {
      return mask.extractRaw(text);
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

final class _SmartStrengthConfig {
  const _SmartStrengthConfig({
    required this.criteria,
    required this.labels,
    required this.showChecklist,
  });

  final List<SmartPasswordCriterion>? criteria;
  final Map<SmartPasswordStrengthLevel, String>? labels;
  final bool showChecklist;
}
