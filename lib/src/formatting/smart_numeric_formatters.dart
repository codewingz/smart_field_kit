import 'package:flutter/services.dart';
import 'package:smart_field_kit/src/formatting/smart_composing.dart';

enum SmartCurrencyPosition { prefix, suffix }

enum SmartGroupingStyle { international, indian }

enum SmartRoundingMode { none, down, up, halfUp, halfEven }

final class SmartDecimalLength {
  const SmartDecimalLength.none() : places = 0;

  const SmartDecimalLength.fixed(this.places)
    : assert(places >= 1 && places <= 3);

  factory SmartDecimalLength.from(Object? value) {
    if (value is SmartDecimalLength) {
      return value;
    }
    if (value == false) {
      return const SmartDecimalLength.none();
    }
    if (value is int && value >= 1 && value <= 3) {
      return SmartDecimalLength.fixed(value);
    }
    throw ArgumentError.value(
      value,
      'decimalLength',
      'Must be false, 1, 2, or 3.',
    );
  }

  final int places;

  bool get hasDecimals => places > 0;

  @override
  bool operator ==(Object other) {
    return other is SmartDecimalLength && other.places == places;
  }

  @override
  int get hashCode => places.hashCode;
}

abstract final class SmartDecimalUtils {
  static final RegExp _numberExpression = RegExp(r'^-?\d*(\.\d*)?$');

  static String round(
    String value, {
    required int decimalPlaces,
    required SmartRoundingMode mode,
  }) {
    if (decimalPlaces < 0) {
      throw ArgumentError.value(decimalPlaces, 'decimalPlaces');
    }
    if (!_numberExpression.hasMatch(value) || value == '-' || value == '.') {
      throw FormatException('Not a plain decimal number', value);
    }
    final negative = value.startsWith('-');
    final unsigned = negative ? value.substring(1) : value;
    final parts = unsigned.split('.');
    final integer = parts.first.isEmpty ? '0' : parts.first;
    final fraction = parts.length == 2 ? parts.last : '';
    if (mode == SmartRoundingMode.none || fraction.length <= decimalPlaces) {
      return value;
    }
    final kept = fraction.substring(0, decimalPlaces);
    final rest = fraction.substring(decimalPlaces);
    final restIsZero = !rest.contains(RegExp(r'[1-9]'));
    var increment = false;
    if (!restIsZero) {
      switch (mode) {
        case SmartRoundingMode.none:
        case SmartRoundingMode.down:
          increment = false;
        case SmartRoundingMode.up:
          increment = true;
        case SmartRoundingMode.halfUp:
          increment = rest.codeUnitAt(0) >= 0x35;
        case SmartRoundingMode.halfEven:
          final first = rest.codeUnitAt(0);
          final tail = rest.substring(1);
          final tailZero = !tail.contains(RegExp(r'[1-9]'));
          if (first > 0x35 || first == 0x35 && !tailZero) {
            increment = true;
          } else if (first == 0x35) {
            final lastDigit = (kept.isEmpty ? integer : kept).codeUnitAt(
              (kept.isEmpty ? integer.length : kept.length) - 1,
            );
            increment = (lastDigit - 0x30).isOdd;
          }
      }
    }
    var digits = BigInt.parse('$integer$kept');
    if (increment) {
      digits += BigInt.one;
    }
    var text = digits.toString().padLeft(decimalPlaces + 1, '0');
    final integerLength = text.length - decimalPlaces;
    final integerPart = text.substring(0, integerLength);
    final fractionPart = text.substring(integerLength);
    text = decimalPlaces == 0 ? integerPart : '$integerPart.$fractionPart';
    final isZero = !text.contains(RegExp(r'[1-9]'));
    return negative && !isZero ? '-$text' : text;
  }
}

final class SmartNumberInputFormatter extends TextInputFormatter {
  const SmartNumberInputFormatter({this.allowNegative = false});

  static final RegExp _signedExpression = RegExp(r'^-?\d*$');
  static final RegExp _unsignedExpression = RegExp(r'^\d*$');

  final bool allowNegative;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (smartIsComposing(newValue)) {
      return newValue;
    }
    final expression = allowNegative ? _signedExpression : _unsignedExpression;
    return expression.hasMatch(newValue.text)
        ? newValue
        : smartBeforeComposition(oldValue);
  }
}

final class SmartAmountFormatter extends TextInputFormatter {
  SmartAmountFormatter({
    this.decimalPlaces,
    this.useGrouping = false,
    this.groupingSeparator = ',',
    this.decimalSeparator = '.',
    this.currencySymbol,
    this.currencyPosition = SmartCurrencyPosition.prefix,
    this.allowNegative = false,
    this.groupingStyle = SmartGroupingStyle.international,
    this.roundingMode = SmartRoundingMode.none,
  }) : assert(decimalPlaces == null || decimalPlaces >= 0),
       assert(groupingSeparator.length == 1),
       assert(decimalSeparator.length == 1),
       assert(groupingSeparator != decimalSeparator),
       assert(currencySymbol == null || currencySymbol != '');

  static final RegExp _digitExpression = RegExp(r'\d');
  static final RegExp _digitsExpression = RegExp(r'^\d+$');
  static final RegExp _optionalDigitsExpression = RegExp(r'^\d*$');

  final int? decimalPlaces;
  final bool useGrouping;
  final String groupingSeparator;
  final String decimalSeparator;
  final String? currencySymbol;
  final SmartCurrencyPosition currencyPosition;
  final bool allowNegative;
  final SmartGroupingStyle groupingStyle;
  final SmartRoundingMode roundingMode;

  bool get _rounds =>
      roundingMode != SmartRoundingMode.none && decimalPlaces != null;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (smartIsComposing(newValue)) {
      return newValue;
    }
    final raw = normalize(newValue.text, allowPartial: true);
    if (raw == null) {
      return smartBeforeComposition(oldValue);
    }
    final editable = _editableText(raw);
    if (editable == newValue.text) {
      return newValue;
    }
    return _replaceText(newValue, editable);
  }

  String? normalize(String value, {bool allowPartial = false}) {
    if (value.isEmpty) {
      return '';
    }

    var text = value;
    final symbol = currencySymbol;
    if (symbol != null) {
      final hasPrefix = text.startsWith(symbol);
      final hasSuffix = text.endsWith(symbol);
      if (currencyPosition == SmartCurrencyPosition.prefix && hasPrefix) {
        text = text.substring(symbol.length);
      } else if (currencyPosition == SmartCurrencyPosition.suffix &&
          hasSuffix) {
        text = text.substring(0, text.length - symbol.length);
      }
      if (text.contains(symbol)) {
        return null;
      }
    }

    var negative = false;
    if (text.startsWith('-')) {
      if (!allowNegative) {
        return null;
      }
      negative = true;
      text = text.substring(1);
    }
    if (text.contains('-')) {
      return null;
    }

    final parts = text.split(decimalSeparator);
    if (parts.length > 2 ||
        decimalPlaces == 0 && parts.length == 2 && !_rounds) {
      return null;
    }

    final integerPart = parts.first;
    final fractionPart = parts.length == 2 ? parts.last : null;
    final integerDigits = _normalizeInteger(integerPart);
    if (integerDigits == null ||
        fractionPart != null &&
            !_optionalDigitsExpression.hasMatch(fractionPart)) {
      return null;
    }
    if (decimalPlaces != null &&
        !_rounds &&
        fractionPart != null &&
        fractionPart.length > decimalPlaces!) {
      return null;
    }

    final hasDigit =
        integerDigits.isNotEmpty ||
        fractionPart != null && fractionPart.isNotEmpty;
    final hasDecimal = fractionPart != null;
    if (!allowPartial && (!hasDigit || hasDecimal && fractionPart.isEmpty)) {
      return null;
    }

    if (allowPartial && !hasDigit) {
      if (negative && !hasDecimal) {
        return '-';
      }
      if (hasDecimal) {
        return negative ? '-.' : '.';
      }
    }

    var raw = integerDigits;
    if (!allowPartial && raw.isEmpty) {
      raw = '0';
    }
    if (hasDecimal) {
      raw = '$raw.$fractionPart';
    }
    final result = negative ? '-$raw' : raw;
    if (!allowPartial && _rounds) {
      return SmartDecimalUtils.round(
        result,
        decimalPlaces: decimalPlaces!,
        mode: roundingMode,
      );
    }
    return result;
  }

  String? format(String value) {
    final raw = normalize(value);
    if (raw == null || raw.isEmpty) {
      return raw;
    }

    final negative = raw.startsWith('-');
    final unsigned = negative ? raw.substring(1) : raw;
    final parts = unsigned.split('.');
    var integerPart = parts.first;
    var fractionPart = parts.length == 2 ? parts.last : null;
    if (integerPart.isEmpty) {
      integerPart = '0';
    }
    if (useGrouping) {
      integerPart = _group(integerPart);
    }
    if (decimalPlaces != null) {
      fractionPart = (fractionPart ?? '').padRight(decimalPlaces!, '0');
    }

    var display = negative ? '-$integerPart' : integerPart;
    if (fractionPart != null && fractionPart.isNotEmpty) {
      display = '$display$decimalSeparator$fractionPart';
    }
    final symbol = currencySymbol;
    if (symbol != null) {
      display = currencyPosition == SmartCurrencyPosition.prefix
          ? '$symbol$display'
          : '$display$symbol';
    }
    return display;
  }

  TextEditingValue toEditableValue(TextEditingValue value) {
    if (smartIsComposing(value)) {
      return value;
    }
    final raw = normalize(value.text, allowPartial: true);
    if (raw == null) {
      return value;
    }
    return _replaceText(value, _editableText(raw));
  }

  TextEditingValue toDisplayValue(TextEditingValue value) {
    if (smartIsComposing(value)) {
      return value;
    }
    final display = format(value.text);
    if (display == null) {
      return value;
    }
    return _replaceText(value, display);
  }

  String? _normalizeInteger(String value) {
    if (value.isEmpty) {
      return '';
    }
    if (!value.contains(groupingSeparator)) {
      return _digitsExpression.hasMatch(value) ? value : null;
    }
    if (!useGrouping) {
      return null;
    }
    final groups = value.split(groupingSeparator);
    final indian = groupingStyle == SmartGroupingStyle.indian;
    if (groups.first.isEmpty ||
        groups.first.length > (indian ? 2 : 3) ||
        !_digitsExpression.hasMatch(groups.first)) {
      return null;
    }
    for (var index = 1; index < groups.length; index++) {
      final group = groups[index];
      final expected = indian && index < groups.length - 1 ? 2 : 3;
      if (group.length != expected || !_digitsExpression.hasMatch(group)) {
        return null;
      }
    }
    return groups.join();
  }

  String _editableText(String raw) {
    return decimalSeparator == '.'
        ? raw
        : raw.replaceFirst('.', decimalSeparator);
  }

  String _group(String digits) {
    if (groupingStyle == SmartGroupingStyle.indian) {
      return _groupIndian(digits);
    }
    final firstSize = digits.length % 3;
    final buffer = StringBuffer();
    var index = 0;
    if (firstSize != 0) {
      buffer.write(digits.substring(0, firstSize));
      index = firstSize;
    }
    while (index < digits.length) {
      if (buffer.isNotEmpty) {
        buffer.write(groupingSeparator);
      }
      buffer.write(digits.substring(index, index + 3));
      index += 3;
    }
    return buffer.toString();
  }

  String _groupIndian(String digits) {
    final length = digits.length;
    if (length <= 3) {
      return digits;
    }
    final headLength = length - 3;
    final firstSize = headLength.isEven ? 2 : 1;
    final buffer = StringBuffer(digits.substring(0, firstSize));
    for (var index = firstSize; index < headLength; index += 2) {
      buffer
        ..write(groupingSeparator)
        ..write(digits.substring(index, index + 2));
    }
    buffer
      ..write(groupingSeparator)
      ..write(digits.substring(headLength));
    return buffer.toString();
  }

  TextEditingValue _replaceText(TextEditingValue value, String text) {
    if (value.text == text) {
      return value;
    }
    final selection = value.selection.isValid
        ? TextSelection(
            baseOffset: _displayOffset(
              text,
              _rawOffset(value.text, value.selection.baseOffset),
            ),
            extentOffset: _displayOffset(
              text,
              _rawOffset(value.text, value.selection.extentOffset),
            ),
            affinity: value.selection.affinity,
            isDirectional: value.selection.isDirectional,
          )
        : TextSelection.collapsed(offset: text.length);
    return TextEditingValue(text: text, selection: selection);
  }

  (int, int) _numericRange(String text) {
    final symbol = currencySymbol;
    if (symbol == null) {
      return (0, text.length);
    }
    if (currencyPosition == SmartCurrencyPosition.prefix &&
        text.startsWith(symbol)) {
      return (symbol.length, text.length);
    }
    if (currencyPosition == SmartCurrencyPosition.suffix &&
        text.endsWith(symbol)) {
      return (0, text.length - symbol.length);
    }
    return (0, text.length);
  }

  bool _isRawCharacter(String character) {
    return _digitExpression.hasMatch(character) ||
        character == '-' ||
        character == decimalSeparator;
  }

  int _rawOffset(String text, int displayOffset) {
    var count = 0;
    final range = _numericRange(text);
    final limit = displayOffset.clamp(0, range.$2);
    for (var index = range.$1; index < limit; index++) {
      if (_isRawCharacter(text[index])) {
        count++;
      }
    }
    return count;
  }

  int _displayOffset(String text, int rawOffset) {
    if (rawOffset <= 0) {
      final symbol = currencySymbol;
      if (symbol != null &&
          currencyPosition == SmartCurrencyPosition.prefix &&
          text.startsWith(symbol)) {
        return symbol.length;
      }
      return 0;
    }
    var count = 0;
    final range = _numericRange(text);
    for (var index = range.$1; index < range.$2; index++) {
      if (_isRawCharacter(text[index])) {
        count++;
        if (count == rawOffset) {
          return index + 1;
        }
      }
    }
    return range.$2;
  }
}
