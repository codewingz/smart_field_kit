import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

void main() {
  group('all 14 original legacy rules are preserved', () {
    test('seven text presets', () {
      const expected = {
        SmartTextValidationPreset.loginUsername: (
          'login_username',
          r'^[a-zA-Z0-9]{5,}$',
          'at least 5 chars alphanumeric',
          'lbl_username',
        ),
        SmartTextValidationPreset.beneficiaryNickname: (
          'beneficiary_nickname',
          r'^[a-zA-Z0-9]{3,}$',
          'At least 3 chars alphanumeric',
          'beneficiary_nickname',
        ),
        SmartTextValidationPreset.minTextField: (
          'min_text_field',
          r'^[a-zA-Z]{1,}$',
          'at least 1 chars',
          'lbl_provide',
        ),
        SmartTextValidationPreset.streetName: (
          'street_name',
          r'^[a-zA-Z]{1,}$',
          'at least 1 chars',
          'lbl_provide',
        ),
        SmartTextValidationPreset.alphanumeric3: (
          'alphanumeric_3',
          r'^[a-zA-Z0-9]{1,}$',
          'at least 1 chars alphanumeric',
          'lbl_provide',
        ),
        SmartTextValidationPreset.description: (
          'description',
          r'^.{3,}$',
          'any chars, at least 3',
          'msg_money_transfer_services',
        ),
        SmartTextValidationPreset.formfield: (
          'formfield',
          r'^.{3,}$',
          'any chars, at least 3',
          'lbl_provide',
        ),
      };
      expect(SmartTextValidationPreset.values.length, 7);
      for (final entry in expected.entries) {
        final preset = entry.key;
        expect(
          (preset.key, preset.expression, preset.comment, preset.errorLabel),
          entry.value,
          reason: preset.name,
        );
      }
    });

    test('email, passwords, number, amount, phone, and otp', () {
      expect(
        SmartValidators.legacyEmailExpression,
        r"""^[A-Za-z0-9][A-Za-z0-9.!#$%&'*+\-/=?^_`{|}~]*@[A-Za-z0-9-]+\.[A-Za-z]+$""",
      );
      expect(SmartValidators.legacyEmailComment, 'valid email address');
      expect(SmartValidators.legacyEmailErrorLabel, 'lbl_provide');
      expect(SmartValidators.legacyWeakPasswordExpression, r'^.{5,}$');
      expect(
        SmartValidators.legacyWeakPasswordComment,
        'any chars, at least 6',
      );
      expect(
        SmartValidators.legacyWeakPasswordErrorLabel,
        'msg_confirm_password',
      );
      expect(
        SmartValidators.legacyStrongPasswordExpression,
        r'^(?=.*?[A-Z])(?=(.*[a-z]){1,})(?=(.*[\d]){1,})(?=(.*[\W]){1,})(?!.*\s).{8,}$',
      );
      expect(
        SmartValidators.legacyStrongPasswordErrorLabel,
        'msg_confirm_password',
      );
      expect(SmartValidators.legacyNumberExpression, r'^[0-9]$');
      expect(SmartValidators.legacyNumberComment, '8 digits');
      expect(SmartValidators.legacyNumberErrorLabel, 'lbl_phone_8');
      expect(SmartValidators.legacyAmountExpression, r'^\d+(\.\d{1,2})?$');
      expect(
        SmartValidators.legacyAmountComment,
        'Please enter a valid amount (e.g., 123.45)',
      );
      expect(SmartValidators.legacyAmountErrorLabel, '');
      expect(SmartValidators.legacyPhoneExpression, r'^[0-9]{7,15}$');
      expect(SmartValidators.legacyPhoneComment, '7 to 15 digits');
      expect(SmartValidators.legacyPhoneErrorLabel, 'lbl_phone_8');
      expect(SmartValidators.legacyOtpKey, 'opt_token');
      expect(SmartValidators.legacyOtpExpression, r'^[0-9]{6}$');
      expect(SmartValidators.legacyOtpComment, '6 digits');
      expect(SmartValidators.legacyOtpErrorLabel, 'lbl_token_needed');
    });

    test('legacy behavior still validates through the shared system', () {
      expect(
        SmartValidators.email(policy: SmartEmailPolicy.legacy)('a@b.co'),
        isNull,
      );
      expect(
        SmartValidators.email(policy: SmartEmailPolicy.legacy)('a@b'),
        isNotNull,
      );
      expect(
        SmartValidators.password(policy: SmartPasswordPolicy.weak)('12345'),
        isNull,
      );
      expect(
        SmartValidators.password(policy: SmartPasswordPolicy.strong)(
          'Abcdef1!',
        ),
        isNull,
      );
      expect(
        SmartValidators.number(policy: SmartNumberPolicy.legacy)('5'),
        isNull,
      );
      expect(
        SmartValidators.otp(length: 6, policy: SmartOtpPolicy.legacy)('123456'),
        isNull,
      );
      expect(
        SmartPhoneValidation.validate(
          '1234567',
          policy: SmartPhonePolicy.legacy,
        ),
        isNull,
      );
    });
  });

  group('standalone utilities', () {
    test('passwordRules runs only selected checks in order', () {
      final validator = SmartValidators.passwordRules(
        const {
          SmartBuiltInCheck.passwordUppercase,
          SmartBuiltInCheck.passwordLowercase,
          SmartBuiltInCheck.passwordDigit,
          SmartBuiltInCheck.passwordSpecialCharacter,
          SmartBuiltInCheck.passwordNoWhitespace,
        },
        uppercaseMessage: 'U',
        lowercaseMessage: 'L',
        digitMessage: 'D',
        specialCharacterMessage: 'S',
        noWhitespaceMessage: 'W',
      );
      expect(validator(''), isNull);
      expect(validator('abc1!'), 'U');
      expect(validator('ABC1!'), 'L');
      expect(validator('Abc!!'), 'D');
      expect(validator('Abc123'), 'S');
      expect(validator('Abc 1!'), 'W');
      expect(validator('Abc1!'), isNull);
      expect(validator('Äbc1!'), isNull);
      expect(SmartValidators.passwordRules(const {})('x'), isNull);
    });

    test('compose returns the first error', () {
      final validator = SmartValidators.compose([
        (value) => null,
        (value) => 'first',
        (value) => 'second',
      ]);
      expect(validator('x'), 'first');
      expect(SmartValidators.compose(const [])('x'), isNull);
    });

    test('url and phone validators match the widget logic', () {
      expect(SmartValidators.url()('https://a.com'), isNull);
      expect(SmartValidators.url()('a.com'), isNotNull);
      expect(SmartValidators.url(allowBareDomain: true)('a.com'), isNull);
      expect(SmartValidators.phone()('+923001234567'), isNull);
      expect(SmartValidators.phone()('+92300123'), isNotNull);
    });

    test('masks and number formatting', () {
      expect(
        maskMobile('03001234567', visibleSuffixDigits: 4),
        endsWith('4567'),
      );
      expect(
        maskAccountNumber('1234567890', visibleSuffixCharacters: 4),
        endsWith('7890'),
      );
      expect(maskAmount('1,234.50'), isNot(contains('1')));
      expect(formatNumber('1234567', useGrouping: true), '1,234,567');
      expect(
        formatNumber(
          '1234567.891',
          useGrouping: true,
          decimalPlaces: 2,
          groupingStyle: SmartGroupingStyle.indian,
          roundingMode: SmartRoundingMode.halfUp,
        ),
        '12,34,567.89',
      );
    });

    test('amount formatter parses and formats independently', () {
      final formatter = SmartAmountFormatter(
        useGrouping: true,
        decimalPlaces: 2,
        currencySymbol: '\$',
      );
      expect(formatter.format('50000.00'), '\$50,000.00');
      expect(formatter.normalize('\$50,000.00'), '50000.00');
      expect(formatter.normalize('5,000.oo'), isNull);
    });

    test('server error controller basics', () {
      final server = SmartServerError();
      var notified = 0;
      server.addListener(() => notified++);
      server.set('Payment declined');
      expect(server.errorText, 'Payment declined');
      expect(server.hasError, isTrue);
      server.set('Payment declined');
      expect(notified, 1);
      server.set('');
      expect(server.errorText, isNull);
      server.notifyFieldChanged();
      server.dispose();
      server.set('late');
      expect(server.errorText, isNull);
    });
  });
}
