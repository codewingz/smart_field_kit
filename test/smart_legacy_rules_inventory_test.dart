import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

typedef _Preset = ({
  SmartTextValidationPreset preset,
  String key,
  String expression,
  String comment,
  String label,
  String message,
  List<String> accepts,
  List<String> rejects,
});

void main() {
  group('legacy text presets are frozen (rules 1-7)', () {
    final presets = <_Preset>[
      (
        preset: SmartTextValidationPreset.loginUsername,
        key: 'login_username',
        expression: r'^[a-zA-Z0-9]{5,}$',
        comment: 'at least 5 chars alphanumeric',
        label: 'lbl_username',
        message: 'Enter at least 5 ASCII letters or numbers.',
        accepts: ['abcde', 'User12345'],
        rejects: ['abcd', 'abc de', 'üser12'],
      ),
      (
        preset: SmartTextValidationPreset.beneficiaryNickname,
        key: 'beneficiary_nickname',
        expression: r'^[a-zA-Z0-9]{3,}$',
        comment: 'At least 3 chars alphanumeric',
        label: 'beneficiary_nickname',
        message: 'Enter at least 3 ASCII letters or numbers.',
        accepts: ['abc', 'A1b2'],
        rejects: ['ab', 'a b', 'ab-c'],
      ),
      (
        preset: SmartTextValidationPreset.minTextField,
        key: 'min_text_field',
        expression: r'^[a-zA-Z]{1,}$',
        comment: 'at least 1 chars',
        label: 'lbl_provide',
        message: 'Enter ASCII letters only.',
        accepts: ['a', 'Hello'],
        rejects: ['a1', 'a b', 'é'],
      ),
      (
        preset: SmartTextValidationPreset.streetName,
        key: 'street_name',
        expression: r'^[a-zA-Z]{1,}$',
        comment: 'at least 1 chars',
        label: 'lbl_provide',
        message: 'Enter ASCII letters only.',
        accepts: ['Main', 'x'],
        rejects: ['Main St', '12', 'Straße'],
      ),
      (
        preset: SmartTextValidationPreset.alphanumeric3,
        key: 'alphanumeric_3',
        expression: r'^[a-zA-Z0-9]{1,}$',
        comment: 'at least 1 chars alphanumeric',
        label: 'lbl_provide',
        message: 'Enter ASCII letters or numbers.',
        accepts: ['a', 'A1', '123'],
        rejects: ['a b', 'a_b'],
      ),
      (
        preset: SmartTextValidationPreset.description,
        key: 'description',
        expression: r'^.{3,}$',
        comment: 'any chars, at least 3',
        label: 'msg_money_transfer_services',
        message: 'Enter at least 3 characters on one line.',
        accepts: ['abc', 'a b!', '☕☕☕'],
        rejects: ['ab', 'abc\ndef'],
      ),
      (
        preset: SmartTextValidationPreset.formfield,
        key: 'formfield',
        expression: r'^.{3,}$',
        comment: 'any chars, at least 3',
        label: 'lbl_provide',
        message: 'Enter at least 3 characters on one line.',
        accepts: ['abc', '12 3'],
        rejects: ['ab', 'a\nbc'],
      ),
    ];

    test('there are exactly seven presets', () {
      expect(SmartTextValidationPreset.values.map((p) => p.name), [
        'loginUsername',
        'beneficiaryNickname',
        'minTextField',
        'streetName',
        'alphanumeric3',
        'description',
        'formfield',
      ]);
    });

    for (final rule in presets) {
      test('${rule.preset.name}: metadata and behavior are unchanged', () {
        expect(rule.preset.key, rule.key);
        expect(rule.preset.expression, rule.expression);
        expect(rule.preset.comment, rule.comment);
        expect(rule.preset.errorLabel, rule.label);
        expect(rule.preset.defaultMessage, rule.message);
        final validator = SmartValidators.textPreset(rule.preset);
        for (final ok in rule.accepts) {
          expect(validator(ok), isNull, reason: ok);
        }
        for (final bad in rule.rejects) {
          expect(validator(bad), rule.message, reason: bad);
        }
        expect(validator(null), isNull);
        expect(validator(''), isNull);
        expect(validator('   '), isNull);
      });
    }
  });

  group('legacy validator constants are frozen (rules 8-14)', () {
    test('email (8)', () {
      expect(
        SmartValidators.legacyEmailExpression,
        r"""^[A-Za-z0-9][A-Za-z0-9.!#$%&'*+\-/=?^_`{|}~]*@[A-Za-z0-9-]+\.[A-Za-z]+$""",
      );
      expect(SmartValidators.legacyEmailComment, 'valid email address');
      expect(SmartValidators.legacyEmailErrorLabel, 'lbl_provide');
      final validator = SmartValidators.email(policy: SmartEmailPolicy.legacy);
      expect(validator('a.b@example.com'), isNull);
      expect(validator('.a@example.com'), isNotNull);
      expect(validator('a@example'), isNotNull);
      expect(validator('a@ex.co1'), isNotNull);
    });

    test(
      'weak password (9): the expression is 5 characters, the comment says 6',
      () {
        expect(SmartValidators.legacyWeakPasswordExpression, r'^.{5,}$');
        expect(
          SmartValidators.legacyWeakPasswordComment,
          'any chars, at least 6',
        );
        expect(
          SmartValidators.legacyWeakPasswordErrorLabel,
          'msg_confirm_password',
        );
        final validator = SmartValidators.password(
          policy: SmartPasswordPolicy.weak,
        );
        expect(validator('12345'), isNull);
        expect(validator('1234'), isNotNull);
      },
    );

    test('strong password (10)', () {
      expect(
        SmartValidators.legacyStrongPasswordExpression,
        r'^(?=.*?[A-Z])(?=(.*[a-z]){1,})(?=(.*[\d]){1,})(?=(.*[\W]){1,})(?!.*\s).{8,}$',
      );
      expect(
        SmartValidators.legacyStrongPasswordErrorLabel,
        'msg_confirm_password',
      );
      final validator = SmartValidators.password(
        policy: SmartPasswordPolicy.strong,
      );
      expect(validator('Abcdef1!'), isNull);
      expect(validator('abcdef1!'), isNotNull);
      expect(validator('Abcdef1 !'), isNotNull);
      expect(validator('Abc1!'), isNotNull);
    });

    test(
      'number (11): the expression is one digit, the comment says 8 digits',
      () {
        expect(SmartValidators.legacyNumberExpression, r'^[0-9]$');
        expect(SmartValidators.legacyNumberComment, '8 digits');
        expect(SmartValidators.legacyNumberErrorLabel, 'lbl_phone_8');
        final validator = SmartValidators.number(
          policy: SmartNumberPolicy.legacy,
        );
        expect(validator('7'), isNull);
        expect(validator('12345678'), isNotNull);
      },
    );

    test('amount (12)', () {
      expect(SmartValidators.legacyAmountExpression, r'^\d+(\.\d{1,2})?$');
      expect(
        SmartValidators.legacyAmountComment,
        'Please enter a valid amount (e.g., 123.45)',
      );
      expect(SmartValidators.legacyAmountErrorLabel, '');
      final validator = SmartValidators.amount(
        formatter: SmartAmountFormatter(decimalPlaces: 2),
        policy: SmartAmountPolicy.legacy,
      );
      expect(validator('123.45'), isNull);
      expect(validator('0.5'), isNull);
      expect(validator('12.345'), isNotNull);
    });

    test('phone (13)', () {
      expect(SmartValidators.legacyPhoneExpression, r'^[0-9]{7,15}$');
      expect(SmartValidators.legacyPhoneComment, '7 to 15 digits');
      expect(SmartValidators.legacyPhoneErrorLabel, 'lbl_phone_8');
      final validator = SmartValidators.phone(policy: SmartPhonePolicy.legacy);
      expect(validator('1234567'), isNull);
      expect(validator('123456'), isNotNull);
      expect(validator('+923001234567'), isNotNull);
    });

    test('otp (14): the key spelling is preserved', () {
      expect(SmartValidators.legacyOtpKey, 'opt_token');
      expect(SmartValidators.legacyOtpExpression, r'^[0-9]{6}$');
      expect(SmartValidators.legacyOtpComment, '6 digits');
      expect(SmartValidators.legacyOtpErrorLabel, 'lbl_token_needed');
      final validator = SmartValidators.otp(
        length: 6,
        policy: SmartOtpPolicy.legacy,
      );
      expect(validator('123456'), isNull);
      expect(validator('12345'), isNotNull);
      expect(
        () => SmartValidators.otp(length: 4, policy: SmartOtpPolicy.legacy),
        throwsArgumentError,
      );
    });
  });

  group('standard validation is independent of legacy policies', () {
    test('standard email, password, number, amount, phone and OTP differ', () {
      expect(SmartValidators.email()('user+tag@sub.example.co.uk'), isNull);
      expect(
        SmartValidators.email(policy: SmartEmailPolicy.legacy)(
          'user+tag@sub.example.co.uk',
        ),
        isNotNull,
      );
      expect(SmartValidators.number()('12345678'), isNull);
      expect(
        SmartValidators.number(policy: SmartNumberPolicy.legacy)('12345678'),
        isNotNull,
      );
      expect(SmartValidators.phone()('+923001234567'), isNull);
      expect(
        SmartValidators.phone(policy: SmartPhonePolicy.legacy)('+923001234567'),
        isNotNull,
      );
      expect(SmartValidators.otp(length: 4)('1234'), isNull);
      expect(SmartValidators.otp(length: 8)('12345678'), isNull);
    });
  });
}
