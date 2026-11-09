part of 'smart_field.dart';

bool _hasValidLengthRange(int? minLength, int? maxLength) {
  return (minLength == null || minLength >= 0) &&
      (maxLength == null || maxLength >= 0) &&
      (minLength == null || maxLength == null || minLength <= maxLength);
}

List<TextInputFormatter>? _composeFormatters(
  List<TextInputFormatter> own,
  List<TextInputFormatter>? developer,
) {
  final all = [...own, ...?developer];
  return all.isEmpty ? null : all;
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
