import 'package:characters/characters.dart';

typedef SmartValidator = String? Function(String? value);

enum SmartEmailPolicy { standard, legacy }

enum SmartPasswordPolicy { weak, strong }

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

  static SmartValidator minLength(int length, {String? message}) {
    if (length < 0) {
      throw ArgumentError.value(length, 'length');
    }

    return (value) {
      if (_isBlank(value)) {
        return null;
      }
      if (value!.characters.length < length) {
        return message ?? 'Enter at least $length characters.';
      }
      return null;
    };
  }

  static SmartValidator maxLength(int length, {String? message}) {
    if (length < 0) {
      throw ArgumentError.value(length, 'length');
    }

    return (value) {
      if (_isBlank(value)) {
        return null;
      }
      if (value!.characters.length > length) {
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
}
