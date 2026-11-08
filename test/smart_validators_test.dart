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
