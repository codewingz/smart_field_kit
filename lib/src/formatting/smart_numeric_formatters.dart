import 'package:flutter/services.dart';

enum SmartCurrencyPosition { prefix, suffix }

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
    if (!newValue.composing.isCollapsed) {
      return newValue;
    }
    final expression = allowNegative ? _signedExpression : _unsignedExpression;
    return expression.hasMatch(newValue.text) ? newValue : oldValue;
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
  }) : assert(decimalPlaces == null || decimalPlaces >= 0),
       assert(groupingSeparator.length == 1),
       assert(decimalSeparator.length == 1),
       assert(groupingSeparator != decimalSeparator),
       assert(currencySymbol == null || currencySymbol != '');

  static final RegExp _digitExpression = RegExp(r'\d');
  static final RegExp _digitsExpression = RegExp(r'^\d+$');
  static final RegExp _optionalDigitsExpression = RegExp(r'^\d*$');
  static final RegExp _threeDigitsExpression = RegExp(r'^\d{3}$');

  final int? decimalPlaces;
  final bool useGrouping;
  final String groupingSeparator;
  final String decimalSeparator;
  final String? currencySymbol;
  final SmartCurrencyPosition currencyPosition;
  final bool allowNegative;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.composing.isCollapsed) {
      return newValue;
    }
    final raw = normalize(newValue.text, allowPartial: true);
    if (raw == null) {
      return oldValue;
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
    if (parts.length > 2 || decimalPlaces == 0 && parts.length == 2) {
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
    return negative ? '-$raw' : raw;
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
    final raw = normalize(value.text, allowPartial: true);
    if (raw == null) {
      return value;
    }
    return _replaceText(value, _editableText(raw));
  }

  TextEditingValue toDisplayValue(TextEditingValue value) {
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
    if (groups.first.isEmpty ||
        groups.first.length > 3 ||
        !_digitsExpression.hasMatch(groups.first)) {
      return null;
    }
    for (final group in groups.skip(1)) {
      if (group.length != 3 || !_threeDigitsExpression.hasMatch(group)) {
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

  int _rawOffset(String text, int displayOffset) {
    var count = 0;
    final limit = displayOffset.clamp(0, text.length);
    for (var index = 0; index < limit; index++) {
      final character = text[index];
      if (_digitExpression.hasMatch(character) ||
          character == '-' ||
          character == decimalSeparator) {
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
    for (var index = 0; index < text.length; index++) {
      final character = text[index];
      if (_digitExpression.hasMatch(character) ||
          character == '-' ||
          character == decimalSeparator) {
        count++;
        if (count == rawOffset) {
          return index + 1;
        }
      }
    }
    return text.length;
  }
}
