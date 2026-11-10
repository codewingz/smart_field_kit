import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:smart_field_kit/src/models/smart_phone_value.dart';
import 'package:smart_field_kit/src/validation/smart_phone_separators.dart';
import 'package:smart_field_kit/src/smart_default_texts.dart';

enum SmartPhonePolicy { auto, syntaxOnly, countryAware, legacy }

abstract final class SmartPhoneValidation {
  static const legacyExpression = r'^[0-9]{7,15}$';
  static const legacyComment = '7 to 15 digits';
  static const legacyErrorLabel = 'lbl_phone_8';

  static final RegExp _legacyExpression = RegExp(legacyExpression);
  static final RegExp _digit = RegExp(r'\d');
  static final RegExp _syntaxExpression = RegExp(r'^\+?[0-9 ()-]+$');

  static String? validate(
    String? input, {
    required SmartPhonePolicy policy,
    SmartPhoneCountry? country,
    String message = smartPhoneErrorText,
  }) {
    if (input == null || input.isEmpty) {
      return null;
    }
    if (policy == SmartPhonePolicy.legacy) {
      return _legacyExpression.hasMatch(input) ? null : message;
    }
    final value = smartNormalizePhoneSeparators(input);
    if (!_hasValidSyntax(value)) {
      return message;
    }
    if (policy == SmartPhonePolicy.syntaxOnly) {
      return null;
    }
    if (country == null) {
      if (policy == SmartPhonePolicy.countryAware) {
        return message;
      }
      if (!value.startsWith('+')) {
        return null;
      }
      return _parse(value, null)?.isValid() ?? false ? null : message;
    }
    final parsed = _parse(value, country);
    return parsed != null &&
            parsed.isoCode.name == country.isoCode &&
            parsed.isValid()
        ? null
        : message;
  }

  static SmartPhoneValue parseValue(
    String input, {
    SmartPhoneCountry? country,
  }) {
    final value = smartNormalizePhoneSeparators(input);
    if (value.isEmpty || !_hasValidSyntax(value)) {
      return SmartPhoneValue(
        text: input,
        country: country,
        nationalNumber: null,
        e164: null,
        isValid: false,
      );
    }
    final parsed = _parse(value, country);
    final valid =
        parsed != null &&
        parsed.isValid() &&
        (country == null || parsed.isoCode.name == country.isoCode);
    return SmartPhoneValue(
      text: input,
      country: country,
      nationalNumber: parsed?.nsn,
      e164: valid ? parsed.international : null,
      isValid: valid,
    );
  }

  static String? parsedIsoCode(String input) {
    final value = smartNormalizePhoneSeparators(input);
    if (!_hasValidSyntax(value) || !value.startsWith('+')) {
      return null;
    }
    try {
      final parsed = PhoneNumber.parse(value);
      return parsed.isValid() ? parsed.isoCode.name : null;
    } on Object {
      return null;
    }
  }

  static PhoneNumber? _parse(String value, SmartPhoneCountry? country) {
    try {
      if (country == null) {
        if (!value.startsWith('+')) {
          return null;
        }
        return PhoneNumber.parse(value);
      }
      final isoCode = IsoCode.values.byName(country.isoCode);
      return PhoneNumber.parse(value, destinationCountry: isoCode);
    } on Object {
      return null;
    }
  }

  static bool _hasValidSyntax(String value) {
    if (!_syntaxExpression.hasMatch(value) || !_digit.hasMatch(value)) {
      return false;
    }
    var depth = 0;
    var digitsInParentheses = 0;
    for (final character in value.split('')) {
      if (character == '(') {
        if (depth != 0) {
          return false;
        }
        depth = 1;
        digitsInParentheses = 0;
      } else if (character == ')') {
        if (depth != 1 || digitsInParentheses == 0) {
          return false;
        }
        depth = 0;
      } else if (depth == 1 && _digit.hasMatch(character)) {
        digitsInParentheses++;
      }
    }
    return depth == 0;
  }
}
