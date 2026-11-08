import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

void main() {
  group('requiredField', () {
    final validator = SmartValidators.requiredField();

    test('rejects null empty and whitespace-only values', () {
      expect(validator(null), 'This field is required.');
      expect(validator(''), 'This field is required.');
      expect(validator('  \n\t'), 'This field is required.');
    });

    test('accepts unrestricted non-blank text', () {
      expect(validator("Robert'); DROP TABLE users;-- 😀"), isNull);
    });

    test('supports a custom message', () {
      final custom = SmartValidators.requiredField(message: 'Name required');
      expect(custom(''), 'Name required');
    });
  });

  group('length validators', () {
    test('count user-visible Unicode characters', () {
      final min = SmartValidators.minLength(2);
      final max = SmartValidators.maxLength(1);

      expect(min('👨‍👩‍👦'), 'Enter at least 2 characters.');
      expect(max('👨‍👩‍👦'), isNull);
      expect(max('o\u0308'), isNull);
      expect(min('😀a'), isNull);
    });

    test('skip optional blank values', () {
      expect(SmartValidators.minLength(3)(null), isNull);
      expect(SmartValidators.minLength(3)(''), isNull);
      expect(SmartValidators.minLength(3)('   '), isNull);
      expect(SmartValidators.maxLength(0)('   '), isNull);
    });

    test('support custom messages', () {
      expect(
        SmartValidators.minLength(3, message: 'Too short')('ab'),
        'Too short',
      );
      expect(
        SmartValidators.maxLength(2, message: 'Too long')('abc'),
        'Too long',
      );
    });
  });

  group('text validation presets', () {
    test('preserve all supplied keys expressions and metadata', () {
      expect(
        SmartTextValidationPreset.values
            .map(
              (preset) => (
                preset.key,
                preset.expression,
                preset.comment,
                preset.errorLabel,
              ),
            )
            .toList(),
        [
          (
            'login_username',
            r'^[a-zA-Z0-9]{5,}$',
            'at least 5 chars alphanumeric',
            'lbl_username',
          ),
          (
            'beneficiary_nickname',
            r'^[a-zA-Z0-9]{3,}$',
            'At least 3 chars alphanumeric',
            'beneficiary_nickname',
          ),
          (
            'min_text_field',
            r'^[a-zA-Z]{1,}$',
            'at least 1 chars',
            'lbl_provide',
          ),
          ('street_name', r'^[a-zA-Z]{1,}$', 'at least 1 chars', 'lbl_provide'),
          (
            'alphanumeric_3',
            r'^[a-zA-Z0-9]{1,}$',
            'at least 1 chars alphanumeric',
            'lbl_provide',
          ),
        ],
      );
    });

    test('login username follows the five-character ASCII expression', () {
      final validator = SmartValidators.textPreset(
        SmartTextValidationPreset.loginUsername,
      );
      expect(validator('abcd'), isNotNull);
      expect(validator('abcde'), isNull);
      expect(validator('A1b2C'), isNull);
      expect(validator('abc_1'), isNotNull);
      expect(validator(' José'), isNotNull);
      expect(validator('abcde '), isNotNull);
    });

    test('beneficiary nickname follows the three-character boundary', () {
      final validator = SmartValidators.textPreset(
        SmartTextValidationPreset.beneficiaryNickname,
      );
      expect(validator('ab'), isNotNull);
      expect(validator('abc'), isNull);
      expect(validator('a1B'), isNull);
      expect(validator('a b'), isNotNull);
    });

    test('letter-only presets preserve identical restrictive behavior', () {
      for (final preset in [
        SmartTextValidationPreset.minTextField,
        SmartTextValidationPreset.streetName,
      ]) {
        final validator = SmartValidators.textPreset(preset);
        expect(validator('A'), isNull);
        expect(validator('John'), isNull);
        expect(validator('John Doe'), isNotNull);
        expect(validator("O'Neil"), isNotNull);
        expect(validator('José'), isNotNull);
        expect(validator('Street1'), isNotNull);
      }
    });

    test('alphanumeric 3 accepts one character despite its key', () {
      final validator = SmartValidators.textPreset(
        SmartTextValidationPreset.alphanumeric3,
      );
      expect(validator(''), isNull);
      expect(validator('A'), isNull);
      expect(validator('1'), isNull);
      expect(validator('A1'), isNull);
      expect(validator('_'), isNotNull);
      expect(validator('é'), isNotNull);
    });

    test('skip optional blank values and support custom messages', () {
      final validator = SmartValidators.textPreset(
        SmartTextValidationPreset.loginUsername,
        message: 'Use the legacy format',
      );
      expect(validator(null), isNull);
      expect(validator(''), isNull);
      expect(validator('   '), isNull);
      expect(validator('abc'), 'Use the legacy format');
    });
  });

  group('email validator', () {
    test('preserves the supplied legacy expression and metadata', () {
      expect(
        SmartValidators.legacyEmailExpression,
        r"""^[A-Za-z0-9][A-Za-z0-9.!#$%&'*+\-/=?^_`{|}~]*@[A-Za-z0-9-]+\.[A-Za-z]+$""",
      );
      expect(SmartValidators.legacyEmailComment, 'valid email address');
      expect(SmartValidators.legacyEmailErrorLabel, 'lbl_provide');
    });

    test('standard policy accepts practical email formats', () {
      final validator = SmartValidators.email();

      expect(validator('name+tag@example.com'), isNull);
      expect(validator('user@sub.example.co.uk'), isNull);
      expect(validator("o'hara@example.travel"), isNull);
    });

    test('standard policy rejects malformed values and whitespace', () {
      final validator = SmartValidators.email();

      for (final value in [
        'plainaddress',
        '@example.com',
        'user@',
        'user@@example.com',
        '.user@example.com',
        'user..name@example.com',
        'user@example',
        'user@-example.com',
        'user@example-.com',
        'user @example.com',
        ' user@example.com ',
        '   ',
      ]) {
        expect(validator(value), 'Enter a valid email address.', reason: value);
      }
    });

    test('optional empty values pass and custom errors are supported', () {
      final validator = SmartValidators.email(message: 'Invalid email');

      expect(validator(null), isNull);
      expect(validator(''), isNull);
      expect(validator('invalid'), 'Invalid email');
    });

    test('legacy policy keeps the original narrower behavior', () {
      final validator = SmartValidators.email(policy: SmartEmailPolicy.legacy);

      expect(validator('name+tag@example.com'), isNull);
      expect(
        validator('user@sub.example.co.uk'),
        'Enter a valid email address.',
      );
    });
  });

  group('password validator', () {
    test('preserves the supplied expressions and metadata', () {
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
        SmartValidators.legacyStrongPasswordComment,
        'Password should have,at least a upper case letter, a lower case letter, a digit, a special character [@#\$%^&+=] length of at least 4no white space allowed',
      );
      expect(
        SmartValidators.legacyStrongPasswordErrorLabel,
        'msg_confirm_password',
      );
    });

    test('weak policy follows the five-character expression', () {
      final validator = SmartValidators.password(
        policy: SmartPasswordPolicy.weak,
      );

      expect(validator('1234'), 'Password does not meet the selected policy.');
      expect(validator('12345'), isNull);
      expect(validator('abcde'), isNull);
    });

    test('strong policy enforces every source expression condition', () {
      final validator = SmartValidators.password(
        policy: SmartPasswordPolicy.strong,
      );

      expect(validator('Abcdef1!'), isNull);
      expect(validator('abcdef1!'), isNotNull);
      expect(validator('ABCDEF1!'), isNotNull);
      expect(validator('Abcdefgh!'), isNotNull);
      expect(validator('Abcdef12'), isNotNull);
      expect(validator('Abcd 1!x'), isNotNull);
      expect(validator('Abc1!xy'), isNotNull);
    });

    test('policies allow optional empty values and custom errors', () {
      final validator = SmartValidators.password(
        policy: SmartPasswordPolicy.strong,
        message: 'Use a stronger password',
      );

      expect(validator(null), isNull);
      expect(validator(''), isNull);
      expect(validator('password'), 'Use a stronger password');
    });
  });

  group('number validator', () {
    test('preserves the supplied legacy expression and metadata', () {
      expect(SmartValidators.legacyNumberExpression, r'^[0-9]$');
      expect(SmartValidators.legacyNumberComment, '8 digits');
      expect(SmartValidators.legacyNumberErrorLabel, 'lbl_phone_8');
    });

    test('standard accepts integers and configured negatives', () {
      expect(SmartValidators.number()(''), isNull);
      expect(SmartValidators.number()('000123'), isNull);
      expect(
        SmartValidators.number()('123456789012345678901234567890'),
        isNull,
      );
      expect(SmartValidators.number()('-1'), isNotNull);
      expect(SmartValidators.number(allowNegative: true)('-1'), isNull);
      expect(SmartValidators.number()('1.5'), isNotNull);
    });

    test('legacy accepts exactly one digit despite its comment', () {
      final validator = SmartValidators.number(
        policy: SmartNumberPolicy.legacy,
      );

      expect(validator('8'), isNull);
      expect(validator('88'), isNotNull);
    });
  });

  group('amount validator', () {
    test('preserves the supplied legacy expression and metadata', () {
      expect(SmartValidators.legacyAmountExpression, r'^\d+(\.\d{1,2})?$');
      expect(
        SmartValidators.legacyAmountComment,
        'Please enter a valid amount (e.g., 123.45)',
      );
      expect(SmartValidators.legacyAmountErrorLabel, '');
    });

    test('legacy uses normalized ungrouped text', () {
      final formatter = SmartAmountFormatter(
        decimalPlaces: 2,
        useGrouping: true,
      );
      final validator = SmartValidators.amount(
        formatter: formatter,
        policy: SmartAmountPolicy.legacy,
      );

      expect(validator('50,000.00'), isNull);
      expect(validator('50,000'), isNull);
      expect(validator('50,000.000'), isNotNull);
      expect(validator('5,000.oo'), isNotNull);
    });

    test(
      'standard follows configured precision instead of legacy precision',
      () {
        final formatter = SmartAmountFormatter(decimalPlaces: 3);

        expect(SmartValidators.amount(formatter: formatter)('1.234'), isNull);
        expect(
          SmartValidators.amount(
            formatter: formatter,
            policy: SmartAmountPolicy.legacy,
          )('1.234'),
          isNotNull,
        );
      },
    );
  });

  group('value validators', () {
    test('compare very large integers without precision loss', () {
      final min = SmartValidators.minValue('999999999999999999999999999999');
      final max = SmartValidators.maxValue('1000000000000000000000000000001');

      expect(min('999999999999999999999999999998'), isNotNull);
      expect(min('999999999999999999999999999999'), isNull);
      expect(max('1000000000000000000000000000002'), isNotNull);
      expect(max('1000000000000000000000000000001'), isNull);
    });

    test('compare exact decimals and negative values', () {
      final min = SmartValidators.minValue('-1.20');
      final max = SmartValidators.maxValue('0.1000000000000000000000000001');

      expect(min('-1.2000000000000000001'), isNotNull);
      expect(min('-1.2'), isNull);
      expect(max('0.1000000000000000000000000002'), isNotNull);
      expect(max('0.1'), isNull);
    });
  });

  test('compose returns the first error and stops', () {
    var laterCalls = 0;
    final validator = SmartValidators.compose([
      (_) => 'First error',
      (_) {
        laterCalls++;
        return 'Second error';
      },
    ]);

    expect(validator('value'), 'First error');
    expect(laterCalls, 0);
  });
}
