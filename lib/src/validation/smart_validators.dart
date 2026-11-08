import 'package:characters/characters.dart';
import 'package:smart_field_kit/src/formatting/smart_numeric_formatters.dart';

typedef SmartValidator = String? Function(String? value);
typedef SmartValueNormalizer = String? Function(String value);

enum SmartEmailPolicy { standard, legacy }

enum SmartPasswordPolicy { weak, strong }

enum SmartNumberPolicy { standard, legacy }

enum SmartAmountPolicy { standard, legacy }

abstract final class SmartValidators {
  static const legacyEmailExpression =
      r"""^[A-Za-z0-9][A-Za-z0-9.!#$%&'*+\-/=?^_`{|}~]*@[A-Za-z0-9-]+\.[A-Za-z]+$""";
  static const legacyEmailComment = 'valid email address';
  static const legacyEmailErrorLabel = 'lbl_provide';
  static const legacyWeakPasswordExpression = r'^.{5,}$';
  static const legacyWeakPasswordComment = 'any chars, at least 6';
  static const legacyWeakPasswordErrorLabel = 'msg_confirm_password';
  static const legacyStrongPasswordExpression =
      r'^(?=.*?[A-Z])(?=(.*[a-z]){1,})(?=(.*[\d]){1,})(?=(.*[\W]){1,})(?!.*\s).{8,}$';
  static const legacyStrongPasswordComment =
      'Password should have,at least a upper case letter, a lower case letter, a digit, a special character [@#\$%^&+=] length of at least 4no white space allowed';
  static const legacyStrongPasswordErrorLabel = 'msg_confirm_password';
  static const legacyNumberExpression = r'^[0-9]$';
  static const legacyNumberComment = '8 digits';
  static const legacyNumberErrorLabel = 'lbl_phone_8';
  static const legacyAmountExpression = r'^\d+(\.\d{1,2})?$';
  static const legacyAmountComment =
      'Please enter a valid amount (e.g., 123.45)';
  static const legacyAmountErrorLabel = '';

  static final RegExp _standardEmailExpression = RegExp(
    r"^[A-Za-z0-9!#$%&'*+/=?^_`{|}~.-]+@[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?)+$",
  );
  static final RegExp _legacyEmailExpression = RegExp(legacyEmailExpression);
  static final RegExp _legacyWeakPasswordExpression = RegExp(
    legacyWeakPasswordExpression,
  );
  static final RegExp _legacyStrongPasswordExpression = RegExp(
    legacyStrongPasswordExpression,
  );
  static final RegExp _legacyNumberExpression = RegExp(legacyNumberExpression);
  static final RegExp _legacyAmountExpression = RegExp(legacyAmountExpression);

  static SmartValidator requiredField({
    String message = 'This field is required.',
  }) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return message;
      }
      return null;
    };
  }

  static SmartValidator minLength(
    int length, {
    String? message,
    SmartValueNormalizer? normalizer,
  }) {
    if (length < 0) {
      throw ArgumentError.value(length, 'length');
    }

    return (value) {
      if (_isBlank(value)) {
        return null;
      }
      final checkedValue = normalizer?.call(value!) ?? value!;
      if (checkedValue.characters.length < length) {
        return message ?? 'Enter at least $length characters.';
      }
      return null;
    };
  }

  static SmartValidator maxLength(
    int length, {
    String? message,
    SmartValueNormalizer? normalizer,
  }) {
    if (length < 0) {
      throw ArgumentError.value(length, 'length');
    }

    return (value) {
      if (_isBlank(value)) {
        return null;
      }
      final checkedValue = normalizer?.call(value!) ?? value!;
      if (checkedValue.characters.length > length) {
        return message ?? 'Enter no more than $length characters.';
      }
      return null;
    };
  }

  static SmartValidator email({
    SmartEmailPolicy policy = SmartEmailPolicy.standard,
    String message = 'Enter a valid email address.',
  }) {
    return (value) {
      if (value == null || value.isEmpty) {
        return null;
      }

      final isValid = switch (policy) {
        SmartEmailPolicy.standard => _isStandardEmail(value),
        SmartEmailPolicy.legacy => _legacyEmailExpression.hasMatch(value),
      };
      return isValid ? null : message;
    };
  }

  static SmartValidator password({
    required SmartPasswordPolicy policy,
    String message = 'Password does not meet the selected policy.',
  }) {
    return (value) {
      if (value == null || value.isEmpty) {
        return null;
      }

      final isValid = switch (policy) {
        SmartPasswordPolicy.weak => _legacyWeakPasswordExpression.hasMatch(
          value,
        ),
        SmartPasswordPolicy.strong => _legacyStrongPasswordExpression.hasMatch(
          value,
        ),
      };
      return isValid ? null : message;
    };
  }

  static SmartValidator number({
    SmartNumberPolicy policy = SmartNumberPolicy.standard,
    bool allowNegative = false,
    String message = 'Enter a valid whole number.',
  }) {
    final standardExpression = allowNegative
        ? RegExp(r'^-?\d+$')
        : RegExp(r'^\d+$');
    return (value) {
      if (value == null || value.isEmpty) {
        return null;
      }
      final isValid = switch (policy) {
        SmartNumberPolicy.standard => standardExpression.hasMatch(value),
        SmartNumberPolicy.legacy => _legacyNumberExpression.hasMatch(value),
      };
      return isValid ? null : message;
    };
  }

  static SmartValidator amount({
    required SmartAmountFormatter formatter,
    SmartAmountPolicy policy = SmartAmountPolicy.standard,
    String message = 'Enter a valid amount.',
  }) {
    return (value) {
      if (value == null || value.isEmpty) {
        return null;
      }
      final normalized = formatter.normalize(value);
      if (normalized == null) {
        return message;
      }
      final isValid = switch (policy) {
        SmartAmountPolicy.standard => true,
        SmartAmountPolicy.legacy => _legacyAmountExpression.hasMatch(
          normalized,
        ),
      };
      return isValid ? null : message;
    };
  }

  static SmartValidator minValue(
    String minimum, {
    SmartValueNormalizer? normalizer,
    String? message,
  }) {
    final normalizedMinimum = _normalizeDecimal(minimum);
    if (normalizedMinimum == null) {
      throw ArgumentError.value(minimum, 'minimum');
    }
    return (value) {
      if (_isBlank(value)) {
        return null;
      }
      final normalized = _normalizeDecimal(normalizer?.call(value!) ?? value!);
      if (normalized == null) {
        return null;
      }
      return _compareDecimals(normalized, normalizedMinimum) < 0
          ? message ?? 'Enter a value of at least $minimum.'
          : null;
    };
  }

  static SmartValidator maxValue(
    String maximum, {
    SmartValueNormalizer? normalizer,
    String? message,
  }) {
    final normalizedMaximum = _normalizeDecimal(maximum);
    if (normalizedMaximum == null) {
      throw ArgumentError.value(maximum, 'maximum');
    }
    return (value) {
      if (_isBlank(value)) {
        return null;
      }
      final normalized = _normalizeDecimal(normalizer?.call(value!) ?? value!);
      if (normalized == null) {
        return null;
      }
      return _compareDecimals(normalized, normalizedMaximum) > 0
          ? message ?? 'Enter a value of no more than $maximum.'
          : null;
    };
  }

  static SmartValidator compose(Iterable<SmartValidator> validators) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) {
          return error;
        }
      }
      return null;
    };
  }

  static bool _isBlank(String? value) {
    return value == null || value.trim().isEmpty;
  }

  static bool _isStandardEmail(String value) {
    final separator = value.indexOf('@');
    if (separator <= 0) {
      return false;
    }

    final localPart = value.substring(0, separator);
    if (localPart.startsWith('.') ||
        localPart.endsWith('.') ||
        localPart.contains('..')) {
      return false;
    }
    return _standardEmailExpression.hasMatch(value);
  }

  static String? _normalizeDecimal(String value) {
    if (!RegExp(r'^-?(?:\d+(?:\.\d*)?|\.\d+)$').hasMatch(value)) {
      return null;
    }
    final negative = value.startsWith('-');
    final unsigned = negative ? value.substring(1) : value;
    final parts = unsigned.split('.');
    var integer = parts.first.isEmpty ? '0' : parts.first;
    integer = integer.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    var fraction = parts.length == 2 ? parts.last : '';
    fraction = fraction.replaceFirst(RegExp(r'0+$'), '');
    final isZero = integer == '0' && fraction.isEmpty;
    final normalized = fraction.isEmpty ? integer : '$integer.$fraction';
    return negative && !isZero ? '-$normalized' : normalized;
  }

  static int _compareDecimals(String first, String second) {
    final firstNegative = first.startsWith('-');
    final secondNegative = second.startsWith('-');
    if (firstNegative != secondNegative) {
      return firstNegative ? -1 : 1;
    }

    final firstUnsigned = firstNegative ? first.substring(1) : first;
    final secondUnsigned = secondNegative ? second.substring(1) : second;
    final firstParts = firstUnsigned.split('.');
    final secondParts = secondUnsigned.split('.');
    var result = firstParts.first.length.compareTo(secondParts.first.length);
    if (result == 0) {
      result = firstParts.first.compareTo(secondParts.first);
    }
    if (result == 0) {
      final firstFraction = firstParts.length == 2 ? firstParts.last : '';
      final secondFraction = secondParts.length == 2 ? secondParts.last : '';
      final length = firstFraction.length > secondFraction.length
          ? firstFraction.length
          : secondFraction.length;
      result = firstFraction
          .padRight(length, '0')
          .compareTo(secondFraction.padRight(length, '0'));
    }
    return firstNegative ? -result : result;
  }
}
