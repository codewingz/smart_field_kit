import 'package:characters/characters.dart';
import 'package:smart_field_kit/src/formatting/smart_card_utils.dart';
import 'package:smart_field_kit/src/formatting/smart_numeric_formatters.dart';
import 'package:smart_field_kit/src/formatting/smart_text_utils.dart';
import 'package:smart_field_kit/src/models/smart_phone_value.dart';
import 'package:smart_field_kit/src/smart_default_texts.dart';
import 'package:smart_field_kit/src/validation/smart_character_classes.dart';
import 'package:smart_field_kit/src/validation/smart_phone_validation.dart';
import 'package:smart_field_kit/src/validation/smart_url_validation.dart';
import 'package:smart_field_kit/src/validation/smart_validation_options.dart';

/// A synchronous validator: returns `null` for a valid value or an error
/// message.
typedef SmartValidator = String? Function(String? value);

/// Converts display text to the raw value a rule should check, or
/// returns `null` when the text has no raw value.
typedef SmartValueNormalizer = String? Function(String value);

/// Email rule. `standard` is a practical ASCII syntax check that ignores
/// surrounding spaces; `legacy` is the original restricted rule.
enum SmartEmailPolicy { standard, legacy }

/// The two original password rules. Neither is applied by default.
enum SmartPasswordPolicy { weak, strong }

/// Number rule: unrestricted digits, or the original legacy rule.
enum SmartNumberPolicy { standard, legacy }

/// Amount rule: any valid amount, or the original legacy rule.
enum SmartAmountPolicy { standard, legacy }

/// OTP rule: digits of the configured length, or the original legacy rule.
enum SmartOtpPolicy { standard, legacy }

/// The original ASCII-only text rules, kept unchanged for compatibility.
/// None is applied by default.
enum SmartTextValidationPreset {
  loginUsername(
    key: 'login_username',
    expression: r'^[a-zA-Z0-9]{5,}$',
    comment: 'at least 5 chars alphanumeric',
    errorLabel: 'lbl_username',
    defaultMessage: 'Enter at least 5 ASCII letters or numbers.',
  ),
  beneficiaryNickname(
    key: 'beneficiary_nickname',
    expression: r'^[a-zA-Z0-9]{3,}$',
    comment: 'At least 3 chars alphanumeric',
    errorLabel: 'beneficiary_nickname',
    defaultMessage: 'Enter at least 3 ASCII letters or numbers.',
  ),
  minTextField(
    key: 'min_text_field',
    expression: r'^[a-zA-Z]{1,}$',
    comment: 'at least 1 chars',
    errorLabel: 'lbl_provide',
    defaultMessage: 'Enter ASCII letters only.',
  ),
  streetName(
    key: 'street_name',
    expression: r'^[a-zA-Z]{1,}$',
    comment: 'at least 1 chars',
    errorLabel: 'lbl_provide',
    defaultMessage: 'Enter ASCII letters only.',
  ),
  alphanumeric3(
    key: 'alphanumeric_3',
    expression: r'^[a-zA-Z0-9]{1,}$',
    comment: 'at least 1 chars alphanumeric',
    errorLabel: 'lbl_provide',
    defaultMessage: 'Enter ASCII letters or numbers.',
  ),
  description(
    key: 'description',
    expression: r'^.{3,}$',
    comment: 'any chars, at least 3',
    errorLabel: 'msg_money_transfer_services',
    defaultMessage: 'Enter at least 3 characters on one line.',
  ),
  formfield(
    key: 'formfield',
    expression: r'^.{3,}$',
    comment: 'any chars, at least 3',
    errorLabel: 'lbl_provide',
    defaultMessage: 'Enter at least 3 characters on one line.',
  );

  const SmartTextValidationPreset({
    required this.key,
    required this.expression,
    required this.comment,
    required this.errorLabel,
    required this.defaultMessage,
  });

  final String key;
  final String expression;
  final String comment;
  final String errorLabel;
  final String defaultMessage;
}

/// Reusable validators that work with or without [SmartField].
///
/// Each builder returns a [SmartValidator]. The format and limit rules
/// accept `null` and empty text so that optional fields stay valid;
/// [requiredField] is the rule that rejects them.
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
  static const legacyPhoneExpression = SmartPhoneValidation.legacyExpression;
  static const legacyPhoneComment = SmartPhoneValidation.legacyComment;
  static const legacyPhoneErrorLabel = SmartPhoneValidation.legacyErrorLabel;
  static const legacyOtpKey = 'opt_token';
  static const legacyOtpExpression = r'^[0-9]{6}$';
  static const legacyOtpComment = '6 digits';
  static const legacyOtpErrorLabel = 'lbl_token_needed';

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
  static final RegExp _whitespaceExpression = RegExp(r'\s');
  static final RegExp _asciiDigitsExpression = RegExp(r'^[0-9]+$');
  static final RegExp _legacyOtpExpression = RegExp(legacyOtpExpression);

  /// Rejects `null`, empty and whitespace-only text.
  static SmartValidator requiredField({String message = smartRequiredText}) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return message;
      }
      return null;
    };
  }

  /// Requires at least [length] user-perceived characters. Blank and
  /// whitespace-only text is treated as not entered and passes.
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

  /// Checks length, brand and the Luhn checksum of a card number locally.
  /// It does not confirm that the card exists.
  static SmartValidator cardNumber({
    Set<SmartCardBrand>? acceptedBrands,
    bool validateLuhn = true,
    Set<SmartCardBrand> luhnExemptBrands = const {SmartCardBrand.unionPay},
    String message = 'Enter a valid card number.',
    String? brandMessage,
    String? luhnMessage,
  }) {
    return (value) {
      if (value == null || value.isEmpty) {
        return null;
      }
      final assessment = SmartCardUtils.assessNumber(
        value,
        acceptedBrands: acceptedBrands,
        validateLuhn: validateLuhn,
        luhnExemptBrands: luhnExemptBrands,
      );
      if (assessment.isLocallyValid) {
        return null;
      }
      switch (assessment.issue) {
        case SmartCardNumberIssue.brandNotAccepted:
          return brandMessage ?? 'This card type is not accepted.';
        case SmartCardNumberIssue.failsChecksum:
          return luhnMessage ?? 'Check the card number.';
        default:
          return message;
      }
    };
  }

  /// Checks that an expiry is well formed and not in the past.
  static SmartValidator cardExpiry({
    SmartExpiryFormat format = SmartExpiryFormat.mmYy,
    DateTime Function() now = DateTime.now,
    String message = 'Enter a valid expiry date.',
    String expiredMessage = 'This card has expired.',
  }) {
    return (value) {
      if (value == null || value.isEmpty) {
        return null;
      }
      final expiry = SmartCardUtils.tryParseExpiry(value, format: format);
      if (expiry == null) {
        return message;
      }
      return expiry.isExpired(now()) ? expiredMessage : null;
    };
  }

  /// Checks the security-code length for the card brand.
  static SmartValidator cardCvv({
    required SmartCardBrand Function() brand,
    Set<int>? allowedLengths,
    String? message,
  }) {
    return (value) {
      if (value == null || value.isEmpty) {
        return null;
      }
      final resolved = brand();
      if (SmartCardUtils.isCvvLengthValid(
        value,
        resolved,
        allowedLengths: allowedLengths,
      )) {
        return null;
      }
      final lengths =
          allowedLengths ??
          (resolved == SmartCardBrand.unknown
              ? const {3, 4}
              : {resolved.cvvLength});
      final text = (lengths.toList()..sort()).join(' or ');
      return message ?? 'Enter the $text-digit security code.';
    };
  }

  /// Requires at least [count] words.
  static SmartValidator minWords(int count, {String? message}) {
    if (count < 0) {
      throw ArgumentError.value(count, 'count');
    }
    return (value) {
      if (_isBlank(value)) {
        return null;
      }
      return SmartTextUtils.countWords(value!) < count
          ? message ?? 'Enter at least $count words.'
          : null;
    };
  }

  /// Allows at most [count] words.
  static SmartValidator maxWords(int count, {String? message}) {
    if (count < 0) {
      throw ArgumentError.value(count, 'count');
    }
    return (value) {
      if (value == null) {
        return null;
      }
      return SmartTextUtils.countWords(value) > count
          ? message ?? 'Enter no more than $count words.'
          : null;
    };
  }

  /// Allows at most [length] user-perceived characters, counting
  /// whitespace. It reports an error and does not truncate input.
  static SmartValidator maxLength(
    int length, {
    String? message,
    SmartValueNormalizer? normalizer,
  }) {
    if (length < 0) {
      throw ArgumentError.value(length, 'length');
    }

    return (value) {
      if (value == null || value.isEmpty) {
        return null;
      }
      final checkedValue = normalizer?.call(value) ?? value;
      if (checkedValue.characters.length > length) {
        return message ?? 'Enter no more than $length characters.';
      }
      return null;
    };
  }

  /// Checks email syntax. It does not confirm that the address exists.
  static SmartValidator email({
    SmartEmailPolicy policy = SmartEmailPolicy.standard,
    String message = smartEmailErrorText,
  }) {
    return (value) {
      if (value == null || value.isEmpty) {
        return null;
      }

      final trimmed = value.trim();
      final isValid = switch (policy) {
        SmartEmailPolicy.standard => _isStandardEmail(trimmed),
        SmartEmailPolicy.legacy => _legacyEmailExpression.hasMatch(value),
      };
      return isValid ? null : message;
    };
  }

  /// Checks that text is a complete URL with an allowed scheme.
  static SmartValidator url({
    Set<String> allowedSchemes = SmartUrlValidation.defaultSchemes,
    bool allowBareDomain = false,
    String message = 'Enter a valid URL.',
  }) {
    return (value) {
      if (value == null || value.isEmpty) {
        return null;
      }
      return SmartUrlValidation.isValid(
            value,
            allowedSchemes: allowedSchemes,
            allowBareDomain: allowBareDomain,
          )
          ? null
          : message;
    };
  }

  /// Applies only the selected password character checks.
  static SmartValidator passwordRules(
    Set<SmartBuiltInCheck> checks, {
    String uppercaseMessage = smartUppercaseRuleText,
    String lowercaseMessage = smartLowercaseRuleText,
    String digitMessage = smartDigitRuleText,
    String specialCharacterMessage = smartSpecialRuleText,
    String noWhitespaceMessage = smartWhitespaceRuleText,
  }) {
    return (value) {
      if (value == null || value.isEmpty) {
        return null;
      }
      if (checks.contains(SmartBuiltInCheck.passwordUppercase) &&
          !smartUppercaseExpression.hasMatch(value)) {
        return uppercaseMessage;
      }
      if (checks.contains(SmartBuiltInCheck.passwordLowercase) &&
          !smartLowercaseExpression.hasMatch(value)) {
        return lowercaseMessage;
      }
      if (checks.contains(SmartBuiltInCheck.passwordDigit) &&
          !smartDigitExpression.hasMatch(value)) {
        return digitMessage;
      }
      if (checks.contains(SmartBuiltInCheck.passwordSpecialCharacter) &&
          !smartSpecialExpression.hasMatch(value)) {
        return specialCharacterMessage;
      }
      if (checks.contains(SmartBuiltInCheck.passwordNoWhitespace) &&
          _whitespaceExpression.hasMatch(value)) {
        return noWhitespaceMessage;
      }
      return null;
    };
  }

  /// Requires the value to equal the text returned by the callback, for
  /// example a confirm-password field.
  static SmartValidator matches(
    String? Function() other, {
    String message = 'Values do not match.',
  }) {
    return (value) {
      if (value == null || value.isEmpty) {
        return null;
      }
      return value == (other() ?? '') ? null : message;
    };
  }

  /// Applies one of the original password policies.
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

  /// Checks that text is a number made of ASCII digits.
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

  /// Checks that text is a valid amount for the given formatter.
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

  /// Checks that text is exactly [length] ASCII digits.
  static SmartValidator otp({
    required int length,
    SmartOtpPolicy policy = SmartOtpPolicy.standard,
    String digitMessage = 'Enter digits only.',
    String? lengthMessage,
    String legacyMessage = 'Enter a valid verification code.',
  }) {
    if (length <= 0) {
      throw ArgumentError.value(length, 'length');
    }
    if (policy == SmartOtpPolicy.legacy && length != 6) {
      throw ArgumentError.value(
        length,
        'length',
        'The legacy OTP policy requires a length of 6.',
      );
    }
    return (value) {
      if (value == null || value.isEmpty) {
        return null;
      }
      if (!_asciiDigitsExpression.hasMatch(value)) {
        return digitMessage;
      }
      if (value.length != length) {
        return lengthMessage ?? 'Enter exactly $length digits.';
      }
      if (policy == SmartOtpPolicy.legacy &&
          !_legacyOtpExpression.hasMatch(value)) {
        return legacyMessage;
      }
      return null;
    };
  }

  /// Checks a phone number with the chosen policy. Country-aware checks
  /// need a country or an international prefix.
  static SmartValidator phone({
    SmartPhonePolicy policy = SmartPhonePolicy.auto,
    SmartPhoneCountry? country,
    String message = smartPhoneErrorText,
  }) {
    return (value) => SmartPhoneValidation.validate(
      value,
      policy: policy,
      country: country,
      message: message,
    );
  }

  /// Applies one of the original text presets.
  static SmartValidator textPreset(
    SmartTextValidationPreset preset, {
    String? message,
  }) {
    final expression = RegExp(preset.expression);
    return (value) {
      if (_isBlank(value)) {
        return null;
      }
      return expression.hasMatch(value!)
          ? null
          : message ?? preset.defaultMessage;
    };
  }

  /// Requires a decimal value of at least the given limit, compared exactly.
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

  /// Requires a decimal value of at most the given limit, compared exactly.
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

  static bool runsBuiltIn(
    SmartValidationMode mode,
    Set<SmartBuiltInCheck> checks, [
    SmartBuiltInCheck? check,
  ]) {
    switch (mode) {
      case SmartValidationMode.custom:
        return false;
      case SmartValidationMode.selected:
        return check == null || checks.contains(check);
      case SmartValidationMode.builtIn:
      case SmartValidationMode.both:
        return true;
    }
  }

  static bool runsCustom(SmartValidationMode mode) {
    return mode != SmartValidationMode.builtIn;
  }

  static SmartValidator modeAware({
    required SmartValidationMode mode,
    required Set<SmartBuiltInCheck> checks,
    SmartValidator? builtIn,
    SmartValidator? custom,
    SmartBuiltInCheck? check = SmartBuiltInCheck.fieldFormat,
  }) {
    return compose([
      if (builtIn != null && runsBuiltIn(mode, checks, check)) builtIn,
      if (custom != null && runsCustom(mode)) custom,
    ]);
  }

  /// Runs validators in order and returns the first error.
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
