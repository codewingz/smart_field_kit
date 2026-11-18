import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

const _pk = SmartPhoneCountry(
  isoCode: 'PK',
  name: 'Pakistan',
  dialCode: '+92',
  flagEmoji: '🇵🇰',
);

const _us = SmartPhoneCountry(
  isoCode: 'US',
  name: 'United States',
  dialCode: '+1',
  flagEmoji: '🇺🇸',
);

void main() {
  group('SmartValidators.phone', () {
    test('allows optional empty input and validates required separately', () {
      final validator = SmartValidators.phone();
      expect(validator(null), isNull);
      expect(validator(''), isNull);
      expect(SmartValidators.requiredField()(''), isNotNull);
    });

    test('auto uses syntax without a country and metadata with a country', () {
      final syntax = SmartValidators.phone();
      expect(syntax('+92 300-1234567'), isNull);
      expect(syntax('(0300) 123-4567'), isNull);
      expect(syntax('1'), isNull);
      expect(syntax('phone123'), isNotNull);
      expect(syntax('++923001234567'), isNotNull);
      expect(syntax('92+3001234567'), isNotNull);
      expect(syntax('(0300 1234567'), isNotNull);
      expect(syntax('0300🙂1234567'), isNotNull);

      final countryAware = SmartValidators.phone(country: _pk);
      expect(countryAware('03001234567'), isNull);
      expect(countryAware('+923001234567'), isNull);
      expect(countryAware('+12025550123'), isNotNull);
      expect(countryAware('1'), isNotNull);
      expect(
        SmartPhoneValidation.parseValue('+12025550123', country: _pk).e164,
        isNull,
      );
    });

    test('supports explicit syntax and country-aware policies', () {
      expect(
        SmartValidators.phone(policy: SmartPhonePolicy.syntaxOnly)('12'),
        isNull,
      );
      expect(
        SmartValidators.phone(policy: SmartPhonePolicy.countryAware)(
          '+12025550123',
        ),
        isNotNull,
      );
      expect(
        SmartValidators.phone(
          policy: SmartPhonePolicy.countryAware,
          country: _us,
        )('+12025550123'),
        isNull,
      );
    });

    test('preserves the exact legacy policy and metadata', () {
      expect(SmartValidators.legacyPhoneExpression, r'^[0-9]{7,15}$');
      expect(SmartValidators.legacyPhoneComment, '7 to 15 digits');
      expect(SmartValidators.legacyPhoneErrorLabel, 'lbl_phone_8');
      final legacy = SmartValidators.phone(policy: SmartPhonePolicy.legacy);
      expect(legacy('1234567'), isNull);
      expect(legacy('123456789012345'), isNull);
      expect(legacy('123456'), isNotNull);
      expect(legacy('1234567890123456'), isNotNull);
      expect(legacy('+1234567'), isNotNull);
      expect(legacy('123 4567'), isNotNull);
    });
  });

  group('SmartPhoneValidation', () {
    test('returns safe parsed values without changing input text', () {
      const input = '0300 1234567';
      final parsed = SmartPhoneValidation.parseValue(input, country: _pk);
      expect(parsed.text, input);
      expect(parsed.country, _pk);
      expect(parsed.nationalNumber, '3001234567');
      expect(parsed.e164, '+923001234567');
      expect(parsed.isValid, isTrue);
    });

    test(
      'does not invent E.164 for invalid or uncontextualized local input',
      () {
        final local = SmartPhoneValidation.parseValue('03001234567');
        final invalid = SmartPhoneValidation.parseValue('not a number');
        expect(local.e164, isNull);
        expect(local.isValid, isFalse);
        expect(invalid.e164, isNull);
        expect(invalid.isValid, isFalse);
      },
    );

    test('parses representative international metadata examples', () {
      for (final value in ['+923001234567', '+12025550123', '+442079460018']) {
        final parsed = SmartPhoneValidation.parseValue(value);
        expect(parsed.e164, value);
        expect(parsed.isValid, isTrue);
      }
    });
  });
}
