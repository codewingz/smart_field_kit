import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

void main() {
  group('maskMobile', () {
    test('masks standard and separated phone values', () {
      expect(maskMobile('03001234567'), '*******4567');
      expect(maskMobile('0300-1234567'), '****-***4567');
      expect(maskMobile('+92 (300) 123-4567'), '+** (***) ***-4567');
      expect(maskMobile(''), '');
    });

    test('masks all short values unless explicitly revealed', () {
      expect(maskMobile('1'), '*');
      expect(maskMobile('12'), '**');
      expect(maskMobile('123'), '***');
      expect(maskMobile('1234'), '****');
      expect(maskMobile('123', revealShortValues: true), '123');
      expect(
        maskMobile('123', visibleSuffixDigits: 2, revealShortValues: true),
        '*23',
      );
    });

    test('supports suffix and one-grapheme mask configuration', () {
      expect(maskMobile('0012345678', visibleSuffixDigits: 2), '********78');
      expect(maskMobile('0012345678', maskCharacter: '•'), '••••••5678');
      expect(maskMobile('0012345678', maskCharacter: '🙂'), '🙂🙂🙂🙂🙂🙂5678');
    });

    test('masks non-separator identifier content without disclosure', () {
      expect(maskMobile('CALL-123456'), '****-**3456');
      expect(maskMobile('۱۲۳-123456'), '***-**3456');
    });

    test('rejects invalid configuration', () {
      expect(
        () => maskMobile('12345', visibleSuffixDigits: -1),
        throwsArgumentError,
      );
      expect(() => maskMobile('12345', maskCharacter: ''), throwsArgumentError);
      expect(
        () => maskMobile('12345', maskCharacter: '**'),
        throwsArgumentError,
      );
    });
  });

  group('maskAccountNumber', () {
    test('preserves leading zeros and common grouping separators', () {
      expect(maskAccountNumber('000012345678'), '********5678');
      expect(maskAccountNumber('0000-1234-5678'), '****-****-5678');
      expect(maskAccountNumber('0000 1234 5678'), '**** **** 5678');
      expect(maskAccountNumber(''), '');
    });

    test('masks short and Unicode identifiers safely', () {
      expect(maskAccountNumber('A'), '*');
      expect(maskAccountNumber('AB12'), '****');
      expect(maskAccountNumber('AB🙂-12345'), '***-*2345');
      expect(
        maskAccountNumber(
          'AB12',
          revealShortValues: true,
          visibleSuffixCharacters: 2,
        ),
        '**12',
      );
    });

    test('supports custom separators suffix and mask character', () {
      expect(
        maskAccountNumber(
          '1234/5678/9012',
          preservedSeparators: const {'/'},
          visibleSuffixCharacters: 2,
          maskCharacter: 'x',
        ),
        'xxxx/xxxx/xx12',
      );
    });

    test('rejects invalid configuration', () {
      expect(
        () => maskAccountNumber('12345', visibleSuffixCharacters: -1),
        throwsArgumentError,
      );
      expect(
        () => maskAccountNumber('12345', maskCharacter: 'xx'),
        throwsArgumentError,
      );
    });
  });

  group('maskAmount', () {
    test('masks digits while preserving valid display structure', () {
      expect(maskAmount('12,345.67 PKR'), '**,***.** PKR');
      expect(maskAmount(r'$12,345.67'), r'$**,***.**');
      expect(maskAmount('-12,345.67'), '-**,***.**');
      expect(maskAmount(''), '');
    });

    test('supports visible suffix custom separators and masks', () {
      expect(maskAmount('12,345.67', visibleSuffixDigits: 2), '**,***.67');
      expect(
        maskAmount(
          '12.345,67 EUR',
          groupingSeparator: '.',
          decimalSeparator: ',',
          maskCharacter: 'x',
        ),
        'xx.xxx,xx EUR',
      );
    });

    test('supports explicitly positioned currency output', () {
      expect(
        maskAmount(
          '12345.67',
          currencySymbol: r'$',
          currencyPosition: SmartCurrencyPosition.prefix,
        ),
        r'$*****.**',
      );
      expect(
        maskAmount(
          '12345.67',
          currencySymbol: ' PKR',
          currencyPosition: SmartCurrencyPosition.suffix,
        ),
        '*****.** PKR',
      );
    });

    test('rejects malformed numeric displays without repairing them', () {
      for (final value in [
        '5,000.oo',
        '12,34.56',
        'PKR 12.34 USD',
        'amount',
        '+12.34',
      ]) {
        expect(() => maskAmount(value), throwsFormatException, reason: value);
      }
      expect(
        () => maskAmount(r'$12.34', currencySymbol: r'$'),
        throwsFormatException,
      );
    });

    test('rejects invalid mask and separator configuration', () {
      expect(
        () => maskAmount('12.34', visibleSuffixDigits: -1),
        throwsArgumentError,
      );
      expect(() => maskAmount('12.34', maskCharacter: ''), throwsArgumentError);
      expect(
        () =>
            maskAmount('12.34', groupingSeparator: '.', decimalSeparator: '.'),
        throwsArgumentError,
      );
    });
  });

  group('formatNumber', () {
    test('reuses exact decimal-safe Task 06 formatting', () {
      expect(
        formatNumber('50000.00', decimalPlaces: 2, useGrouping: true),
        '50,000.00',
      );
      expect(
        formatNumber(
          '50000,5',
          decimalPlaces: 2,
          useGrouping: true,
          groupingSeparator: '.',
          decimalSeparator: ',',
          currencySymbol: ' EUR',
          currencyPosition: SmartCurrencyPosition.suffix,
        ),
        '50.000,50 EUR',
      );
    });

    test('returns null for malformed values without sanitizing letters', () {
      expect(
        formatNumber('5,000.oo', decimalPlaces: 2, useGrouping: true),
        isNull,
      );
    });
  });
}
