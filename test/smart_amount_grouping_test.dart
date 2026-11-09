import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

SmartAmountFormatter _indian({
  int? places,
  String groupingSeparator = ',',
  String decimalSeparator = '.',
  String? currencySymbol,
  bool negative = true,
}) => SmartAmountFormatter(
  useGrouping: true,
  groupingStyle: SmartGroupingStyle.indian,
  decimalPlaces: places,
  groupingSeparator: groupingSeparator,
  decimalSeparator: decimalSeparator,
  currencySymbol: currencySymbol,
  allowNegative: negative,
);

void main() {
  group('Indian grouping boundaries', () {
    final expected = <String, String>{
      '0': '0',
      '1': '1',
      '12': '12',
      '123': '123',
      '1234': '1,234',
      '12345': '12,345',
      '123456': '1,23,456',
      '1234567': '12,34,567',
      '12345678': '1,23,45,678',
      '123456789': '12,34,56,789',
      '1234567890': '1,23,45,67,890',
    };
    for (final entry in expected.entries) {
      test('${entry.key} -> ${entry.value}', () {
        expect(_indian().format(entry.key), entry.value);
      });
    }
  });

  group('grouping keeps signs, decimals, separators and currency', () {
    test('negative values and exact decimals', () {
      final formatter = _indian(places: 2);
      expect(formatter.format('-1234567.5'), '-12,34,567.50');
      expect(formatter.format('-123'), '-123.00');
      expect(formatter.format('0.5'), '0.50');
    });

    test('custom separators', () {
      final formatter = _indian(
        places: 2,
        groupingSeparator: '.',
        decimalSeparator: ',',
      );
      expect(formatter.format('1234567,5'), '12.34.567,50');
    });

    test('currency symbol placement', () {
      final prefix = SmartAmountFormatter(
        useGrouping: true,
        groupingStyle: SmartGroupingStyle.indian,
        currencySymbol: 'Rs ',
      );
      expect(prefix.format('1234567'), 'Rs 12,34,567');
      final suffix = SmartAmountFormatter(
        useGrouping: true,
        groupingStyle: SmartGroupingStyle.indian,
        currencySymbol: ' PKR',
        currencyPosition: SmartCurrencyPosition.suffix,
      );
      expect(suffix.format('1234567'), '12,34,567 PKR');
    });

    test('international grouping is unchanged', () {
      final formatter = SmartAmountFormatter(
        useGrouping: true,
        allowNegative: true,
      );
      expect(formatter.format('1234567'), '1,234,567');
      expect(formatter.format('123456'), '123,456');
      expect(formatter.format('1234'), '1,234');
      expect(formatter.format('-1234567.5'), '-1,234,567.5');
    });

    test('formatted text normalizes back to the exact raw value', () {
      final formatter = _indian(places: 2);
      for (final raw in ['0.00', '12.30', '1234567.89', '-98765432.10']) {
        final display = formatter.format(raw)!;
        expect(formatter.normalize(display), raw);
      }
    });
  });

  group('very long values', () {
    test('a 100,000 digit amount groups correctly in both styles', () {
      final digits = List.generate(100000, (i) => '${i % 9 + 1}').join();
      for (final style in SmartGroupingStyle.values) {
        final formatter = SmartAmountFormatter(
          useGrouping: true,
          groupingStyle: style,
        );
        final display = formatter.format(digits)!;
        expect(display.replaceAll(',', ''), digits);
        final groups = display.split(',');
        final size = style == SmartGroupingStyle.indian ? 2 : 3;
        for (var i = 1; i < groups.length - 1; i++) {
          expect(
            groups[i].length,
            style == SmartGroupingStyle.indian ? 2 : size,
          );
        }
        expect(groups.last.length, 3);
        expect(formatter.normalize(display), digits);
      }
    });

    test('Indian grouping scales roughly linearly', () {
      Duration measure(int count) {
        final formatter = _indian();
        final input = '1' * count;
        final runs = <int>[];
        for (var i = 0; i < 3; i++) {
          final stopwatch = Stopwatch()..start();
          formatter.format(input);
          runs.add(stopwatch.elapsedMicroseconds);
        }
        runs.sort();
        return Duration(microseconds: runs[1] + 1);
      }

      final small = measure(20000);
      final large = measure(200000);
      expect(
        large.inMicroseconds / small.inMicroseconds,
        lessThan(60),
        reason: 'ten times the digits must not cost quadratic time',
      );
    });
  });
}
