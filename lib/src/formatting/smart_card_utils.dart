import 'package:flutter/services.dart';
import 'package:smart_field_kit/src/formatting/smart_date_utils.dart';

enum SmartCardBrand {
  visa('Visa', {13, 16, 19}, 3),
  mastercard('Mastercard', {16}, 3),
  amex('American Express', {15}, 4),
  discover('Discover', {16, 17, 18, 19}, 3),
  dinersClub('Diners Club', {14, 15, 16, 17, 18, 19}, 3),
  jcb('JCB', {16, 17, 18, 19}, 3),
  unionPay('UnionPay', {16, 17, 18, 19}, 3),
  maestro('Maestro', {12, 13, 14, 15, 16, 17, 18, 19}, 3),
  unknown('Card', {12, 13, 14, 15, 16, 17, 18, 19}, 3);

  const SmartCardBrand(this.displayName, this.lengths, this.cvvLength);

  final String displayName;
  final Set<int> lengths;
  final int cvvLength;

  int get maxLength => lengths.reduce((a, b) => a > b ? a : b);
}

enum SmartExpiryFormat { mmYy, mmYyyy }

final class SmartCardExpiry {
  const SmartCardExpiry(this.month, this.year);

  final int month;
  final int year;

  bool isExpired(DateTime now) {
    final lastDay = SmartDateUtils.daysInMonth(year, month);
    final end = DateTime(year, month, lastDay, 23, 59, 59, 999);
    return now.isAfter(end);
  }
}

abstract final class SmartCardUtils {
  static const int maxCardDigits = 19;

  static final RegExp _nonDigit = RegExp(r'\D');

  static String digitsOnly(String value) => value.replaceAll(_nonDigit, '');

  static bool _inRange(String digits, int length, int low, int high) {
    if (digits.length < length) {
      return false;
    }
    final prefix = int.parse(digits.substring(0, length));
    return prefix >= low && prefix <= high;
  }

  static SmartCardBrand detectBrand(String value) {
    final digits = digitsOnly(value);
    if (digits.isEmpty) {
      return SmartCardBrand.unknown;
    }
    if (digits.startsWith('4')) {
      return SmartCardBrand.visa;
    }
    if (digits.startsWith('34') || digits.startsWith('37')) {
      return SmartCardBrand.amex;
    }
    if (_inRange(digits, 2, 51, 55) || _inRange(digits, 4, 2221, 2720)) {
      return SmartCardBrand.mastercard;
    }
    if (_inRange(digits, 4, 3528, 3589)) {
      return SmartCardBrand.jcb;
    }
    if (digits.startsWith('6011') ||
        digits.startsWith('65') ||
        _inRange(digits, 3, 644, 649) ||
        _inRange(digits, 6, 622126, 622925)) {
      return SmartCardBrand.discover;
    }
    if (digits.startsWith('62')) {
      return SmartCardBrand.unionPay;
    }
    if (_inRange(digits, 3, 300, 305) ||
        digits.startsWith('36') ||
        digits.startsWith('38') ||
        digits.startsWith('39')) {
      return SmartCardBrand.dinersClub;
    }
    for (final prefix in const [
      '5018',
      '5020',
      '5038',
      '5893',
      '6304',
      '6759',
      '6761',
      '6762',
      '6763',
    ]) {
      if (digits.startsWith(prefix)) {
        return SmartCardBrand.maestro;
      }
    }
    return SmartCardBrand.unknown;
  }

  static bool passesLuhn(String value) {
    final digits = digitsOnly(value);
    if (digits.length < 2 ||
        digits.length != value.replaceAll(RegExp(r'[ \-]'), '').length) {
      return false;
    }
    var sum = 0;
    var doubleIt = false;
    for (var index = digits.length - 1; index >= 0; index--) {
      var digit = digits.codeUnitAt(index) - 0x30;
      if (doubleIt) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }
      sum += digit;
      doubleIt = !doubleIt;
    }
    return sum % 10 == 0;
  }

  static List<int> groupSizes(SmartCardBrand brand, int length) {
    if (brand == SmartCardBrand.amex) {
      return const [4, 6, 5];
    }
    if (brand == SmartCardBrand.dinersClub && length <= 14) {
      return const [4, 6, 4];
    }
    return const [4, 4, 4, 4, 3];
  }

  static String format(String value, {SmartCardBrand? brand}) {
    final digits = digitsOnly(value);
    final resolved = brand ?? detectBrand(digits);
    final sizes = groupSizes(resolved, digits.length);
    final buffer = StringBuffer();
    var index = 0;
    var group = 0;
    while (index < digits.length) {
      final size = group < sizes.length ? sizes[group] : 4;
      if (buffer.isNotEmpty) {
        buffer.write(' ');
      }
      final end = index + size > digits.length ? digits.length : index + size;
      buffer.write(digits.substring(index, end));
      index = end;
      group++;
    }
    return buffer.toString();
  }

  static String maskedNumber(String value, {String maskCharacter = '\u2022'}) {
    final digits = digitsOnly(value);
    if (digits.length <= 4) {
      return digits;
    }
    final hidden = maskCharacter * (digits.length - 4);
    final visible = digits.substring(digits.length - 4);
    final brand = detectBrand(digits);
    final sizes = groupSizes(brand, digits.length);
    final all = '$hidden$visible';
    final buffer = StringBuffer();
    var index = 0;
    var group = 0;
    while (index < all.length) {
      final size = group < sizes.length ? sizes[group] : 4;
      if (buffer.isNotEmpty) {
        buffer.write(' ');
      }
      final end = index + size > all.length ? all.length : index + size;
      buffer.write(all.substring(index, end));
      index = end;
      group++;
    }
    return buffer.toString();
  }

  static SmartCardExpiry? tryParseExpiry(
    String text, {
    SmartExpiryFormat format = SmartExpiryFormat.mmYy,
  }) {
    final match = RegExp(
      format == SmartExpiryFormat.mmYy
          ? r'^(\d{2})/(\d{2})$'
          : r'^(\d{2})/(\d{4})$',
    ).firstMatch(text);
    if (match == null) {
      return null;
    }
    final month = int.parse(match.group(1)!);
    var year = int.parse(match.group(2)!);
    if (month < 1 || month > 12) {
      return null;
    }
    if (format == SmartExpiryFormat.mmYy) {
      year += 2000;
    }
    return SmartCardExpiry(month, year);
  }

  static bool isCvvLengthValid(
    String cvv,
    SmartCardBrand brand, {
    Set<int>? allowedLengths,
  }) {
    if (!RegExp(r'^[0-9]+$').hasMatch(cvv)) {
      return false;
    }
    if (allowedLengths != null) {
      return allowedLengths.contains(cvv.length);
    }
    if (brand == SmartCardBrand.unknown) {
      return cvv.length == 3 || cvv.length == 4;
    }
    return cvv.length == brand.cvvLength;
  }
}

final class SmartCardNumberFormatter extends TextInputFormatter {
  const SmartCardNumberFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.composing.isValid && !newValue.composing.isCollapsed) {
      return newValue;
    }
    if (RegExp(r'[^0-9 \-]').hasMatch(newValue.text)) {
      return oldValue;
    }
    final digits = SmartCardUtils.digitsOnly(newValue.text);
    if (digits.length > SmartCardUtils.maxCardDigits) {
      return oldValue;
    }
    final brand = SmartCardUtils.detectBrand(digits);
    if (digits.length > brand.maxLength) {
      return oldValue;
    }
    int digitsBefore(int offset) {
      final clamped = offset.clamp(0, newValue.text.length);
      return SmartCardUtils.digitsOnly(newValue.text.substring(0, clamped))
          .length;
    }

    final oldDigits = SmartCardUtils.digitsOnly(oldValue.text);
    var baseDigits = digitsBefore(newValue.selection.baseOffset);
    var extentDigits = digitsBefore(newValue.selection.extentOffset);
    var finalDigits = digits;
    final deletedSpace =
        newValue.text.length < oldValue.text.length &&
        digits == oldDigits &&
        newValue.selection.isCollapsed &&
        baseDigits > 0;
    if (deletedSpace) {
      finalDigits =
          digits.substring(0, baseDigits - 1) + digits.substring(baseDigits);
      baseDigits--;
      extentDigits = baseDigits;
    }
    final finalDisplay = SmartCardUtils.format(finalDigits);
    if (finalDisplay == newValue.text && !deletedSpace) {
      return newValue;
    }
    int finalOffset(int count) {
      if (count <= 0) {
        return 0;
      }
      var seen = 0;
      for (var index = 0; index < finalDisplay.length; index++) {
        if (finalDisplay[index] != ' ') {
          seen++;
          if (seen == count) {
            return index + 1;
          }
        }
      }
      return finalDisplay.length;
    }

    return TextEditingValue(
      text: finalDisplay,
      selection: TextSelection(
        baseOffset: finalOffset(baseDigits),
        extentOffset: finalOffset(extentDigits),
      ),
    );
  }
}
