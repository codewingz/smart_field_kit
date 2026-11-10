import 'package:characters/characters.dart';
import 'package:smart_field_kit/src/formatting/smart_numeric_formatters.dart';

/// Masks the digits of a phone number except the last
/// [visibleSuffixDigits]. `+`, spaces, hyphens and parentheses are kept.
/// This is a visual aid, not encryption.
String maskMobile(
  String value, {
  int visibleSuffixDigits = 4,
  String maskCharacter = '*',
  bool revealShortValues = false,
}) {
  _validateMaskOptions(visibleSuffixDigits, maskCharacter);
  if (value.isEmpty) {
    return '';
  }
  final graphemes = value.characters.toList(growable: false);
  final digitIndexes = <int>[
    for (var index = 0; index < graphemes.length; index++)
      if (_isAsciiDigit(graphemes[index])) index,
  ];
  final visibleCount = _visibleSuffixCount(
    digitIndexes.length,
    visibleSuffixDigits,
    revealShortValues,
  );
  final visibleIndexes = digitIndexes
      .skip(digitIndexes.length - visibleCount)
      .toSet();
  final output = StringBuffer();
  for (var index = 0; index < graphemes.length; index++) {
    final grapheme = graphemes[index];
    if (_isPhoneSeparator(grapheme) || visibleIndexes.contains(index)) {
      output.write(grapheme);
    } else {
      output.write(maskCharacter);
    }
  }
  return output.toString();
}

/// Masks an account number except its last [visibleSuffixCharacters].
/// The listed separators are kept. This is a visual aid, not encryption.
String maskAccountNumber(
  String value, {
  int visibleSuffixCharacters = 4,
  String maskCharacter = '*',
  bool revealShortValues = false,
  Set<String> preservedSeparators = const {' ', '-'},
}) {
  _validateMaskOptions(visibleSuffixCharacters, maskCharacter);
  if (value.isEmpty) {
    return '';
  }
  final graphemes = value.characters.toList(growable: false);
  final sensitiveIndexes = <int>[
    for (var index = 0; index < graphemes.length; index++)
      if (!_isPreservedSeparator(graphemes[index], preservedSeparators)) index,
  ];
  final visibleCount = _visibleSuffixCount(
    sensitiveIndexes.length,
    visibleSuffixCharacters,
    revealShortValues,
  );
  final visibleIndexes = sensitiveIndexes
      .skip(sensitiveIndexes.length - visibleCount)
      .toSet();
  final output = StringBuffer();
  for (var index = 0; index < graphemes.length; index++) {
    final grapheme = graphemes[index];
    if (_isPreservedSeparator(grapheme, preservedSeparators) ||
        visibleIndexes.contains(index)) {
      output.write(grapheme);
    } else {
      output.write(maskCharacter);
    }
  }
  return output.toString();
}

/// Masks the digits of a formatted amount and keeps its sign, separators
/// and currency text. This is a visual aid, not encryption.
String maskAmount(
  String value, {
  int visibleSuffixDigits = 0,
  String maskCharacter = '*',
  String groupingSeparator = ',',
  String decimalSeparator = '.',
  String? currencySymbol,
  SmartCurrencyPosition currencyPosition = SmartCurrencyPosition.prefix,
}) {
  _validateMaskOptions(visibleSuffixDigits, maskCharacter);
  _validateNumericSeparators(groupingSeparator, decimalSeparator);
  if (currencySymbol != null && currencySymbol.isEmpty) {
    throw ArgumentError.value(currencySymbol, 'currencySymbol');
  }
  if (value.isEmpty) {
    return '';
  }

  final parts = _amountParts(value, groupingSeparator, decimalSeparator);
  if (currencySymbol != null &&
      (parts.prefix.trim().isNotEmpty || parts.suffix.trim().isNotEmpty)) {
    throw FormatException('The amount already contains a currency value.');
  }
  final formatter = SmartAmountFormatter(
    useGrouping: true,
    groupingSeparator: groupingSeparator,
    decimalSeparator: decimalSeparator,
    allowNegative: true,
  );
  if (formatter.normalize(parts.numeric) == null) {
    throw FormatException('Invalid amount value.');
  }

  final numericGraphemes = parts.numeric.characters.toList(growable: false);
  final digitIndexes = <int>[
    for (var index = 0; index < numericGraphemes.length; index++)
      if (_isAsciiDigit(numericGraphemes[index])) index,
  ];
  final visibleCount = visibleSuffixDigits.clamp(0, digitIndexes.length);
  final visibleIndexes = digitIndexes
      .skip(digitIndexes.length - visibleCount)
      .toSet();
  final maskedNumeric = StringBuffer();
  for (var index = 0; index < numericGraphemes.length; index++) {
    final grapheme = numericGraphemes[index];
    maskedNumeric.write(
      _isAsciiDigit(grapheme) && !visibleIndexes.contains(index)
          ? maskCharacter
          : grapheme,
    );
  }

  if (currencySymbol != null) {
    return currencyPosition == SmartCurrencyPosition.prefix
        ? '$currencySymbol$maskedNumeric'
        : '$maskedNumeric$currencySymbol';
  }
  return '${parts.prefix}$maskedNumeric${parts.suffix}';
}

/// Formats a decimal string for display, or returns `null` when it is
/// not a valid number for the given options. Uses exact string arithmetic.
String? formatNumber(
  String value, {
  int? decimalPlaces,
  bool useGrouping = false,
  String groupingSeparator = ',',
  String decimalSeparator = '.',
  String? currencySymbol,
  SmartCurrencyPosition currencyPosition = SmartCurrencyPosition.prefix,
  bool allowNegative = false,
  SmartGroupingStyle groupingStyle = SmartGroupingStyle.international,
  SmartRoundingMode roundingMode = SmartRoundingMode.none,
}) {
  return SmartAmountFormatter(
    decimalPlaces: decimalPlaces,
    groupingStyle: groupingStyle,
    roundingMode: roundingMode,
    useGrouping: useGrouping,
    groupingSeparator: groupingSeparator,
    decimalSeparator: decimalSeparator,
    currencySymbol: currencySymbol,
    currencyPosition: currencyPosition,
    allowNegative: allowNegative,
  ).format(value);
}

({String prefix, String numeric, String suffix}) _amountParts(
  String value,
  String groupingSeparator,
  String decimalSeparator,
) {
  final graphemes = value.characters.toList(growable: false);
  final firstDigit = graphemes.indexWhere(_isAsciiDigit);
  final lastDigit = graphemes.lastIndexWhere(_isAsciiDigit);
  if (firstDigit < 0 || lastDigit < 0) {
    throw FormatException('The amount must contain ASCII digits.');
  }
  final numericStart = firstDigit > 0 && graphemes[firstDigit - 1] == '-'
      ? firstDigit - 1
      : firstDigit;
  final prefix = graphemes.take(numericStart).join();
  final numeric = graphemes.sublist(numericStart, lastDigit + 1).join();
  final suffix = graphemes.skip(lastDigit + 1).join();
  for (final outside in [prefix, suffix]) {
    if (outside.contains(groupingSeparator) ||
        outside.contains(decimalSeparator) ||
        outside.contains('-') ||
        outside.contains('+') ||
        outside.characters.any(_isAsciiDigit)) {
      throw FormatException('Invalid amount value.');
    }
  }
  if (prefix.trim().isNotEmpty && suffix.trim().isNotEmpty) {
    throw FormatException(
      'Currency text must appear on one side of the amount.',
    );
  }
  return (prefix: prefix, numeric: numeric, suffix: suffix);
}

void _validateMaskOptions(int visibleSuffix, String maskCharacter) {
  if (visibleSuffix < 0) {
    throw ArgumentError.value(visibleSuffix, 'visibleSuffix');
  }
  if (maskCharacter.characters.length != 1) {
    throw ArgumentError.value(maskCharacter, 'maskCharacter');
  }
}

void _validateNumericSeparators(
  String groupingSeparator,
  String decimalSeparator,
) {
  if (groupingSeparator.characters.length != 1) {
    throw ArgumentError.value(groupingSeparator, 'groupingSeparator');
  }
  if (decimalSeparator.characters.length != 1) {
    throw ArgumentError.value(decimalSeparator, 'decimalSeparator');
  }
  if (groupingSeparator == decimalSeparator) {
    throw ArgumentError.value(decimalSeparator, 'decimalSeparator');
  }
}

int _visibleSuffixCount(
  int sensitiveCount,
  int requestedCount,
  bool revealShortValues,
) {
  if (sensitiveCount <= 4 && !revealShortValues) {
    return 0;
  }
  return requestedCount.clamp(0, sensitiveCount);
}

bool _isAsciiDigit(String grapheme) {
  return grapheme.length == 1 &&
      grapheme.codeUnitAt(0) >= 0x30 &&
      grapheme.codeUnitAt(0) <= 0x39;
}

bool _isPhoneSeparator(String grapheme) {
  return grapheme == '+' ||
      grapheme == '-' ||
      grapheme == '(' ||
      grapheme == ')' ||
      grapheme.trim().isEmpty;
}

bool _isPreservedSeparator(String grapheme, Set<String> preservedSeparators) {
  return grapheme.trim().isEmpty || preservedSeparators.contains(grapheme);
}
