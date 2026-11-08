import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

void main() {
  group('SmartAmountFormatter', () {
    test('formats grouping and configured decimal places exactly', () {
      final formatter = SmartAmountFormatter(
        decimalPlaces: 2,
        useGrouping: true,
      );

      expect(formatter.format('50000.00'), '50,000.00');
      expect(formatter.format('50000'), '50,000.00');
      expect(formatter.format('.5'), '0.50');
      expect(formatter.format('0'), '0.00');
      expect(formatter.format('123.4'), '123.40');
    });

    test('preserves unlimited precision when no precision is configured', () {
      final formatter = SmartAmountFormatter(useGrouping: true);
      const value = '123456789012345678901234567890.12345678901234567890';

      expect(
        formatter.format(value),
        '123,456,789,012,345,678,901,234,567,890.12345678901234567890',
      );
      expect(formatter.normalize(formatter.format(value)!), value);
    });

    test('rejects malformed text without silently removing characters', () {
      final formatter = SmartAmountFormatter(
        decimalPlaces: 2,
        useGrouping: true,
      );

      expect(formatter.normalize('5,000.oo'), isNull);
      expect(formatter.normalize('1,,000.00'), isNull);
      expect(formatter.normalize('12.345'), isNull);
      expect(formatter.format('5,000.oo'), isNull);
    });

    test('supports custom separators currency position and negatives', () {
      final formatter = SmartAmountFormatter(
        decimalPlaces: 2,
        useGrouping: true,
        groupingSeparator: '.',
        decimalSeparator: ',',
        currencySymbol: ' EUR',
        currencyPosition: SmartCurrencyPosition.suffix,
        allowNegative: true,
      );

      expect(formatter.format('-50000,5'), '-50.000,50 EUR');
      expect(formatter.normalize('-50.000,50 EUR'), '-50000.50');
    });

    test('preserves partial editing states', () {
      final formatter = SmartAmountFormatter(decimalPlaces: 2);

      expect(formatter.normalize('.', allowPartial: true), '.');
      expect(formatter.normalize('0.', allowPartial: true), '0.');
      expect(formatter.normalize('-.', allowPartial: true), isNull);
      expect(formatter.normalize('.5'), '0.5');
      expect(formatter.normalize('0.'), isNull);
    });

    test('preserves logical selection while grouping and ungrouping', () {
      final formatter = SmartAmountFormatter(
        decimalPlaces: 2,
        useGrouping: true,
        currencySymbol: r'$',
      );
      const rawValue = TextEditingValue(
        text: '50000.00',
        selection: TextSelection.collapsed(offset: 2),
      );

      final display = formatter.toDisplayValue(rawValue);
      expect(display.text, r'$50,000.00');
      expect(display.selection.baseOffset, 3);

      final editable = formatter.toEditableValue(display);
      expect(editable.text, '50000.00');
      expect(editable.selection.baseOffset, 2);
    });

    test('accepts configured formatted paste and rejects invalid paste', () {
      final formatter = SmartAmountFormatter(
        decimalPlaces: 2,
        useGrouping: true,
        currencySymbol: r'$',
      );
      const oldValue = TextEditingValue.empty;
      const pasted = TextEditingValue(
        text: r'$50,000.00',
        selection: TextSelection.collapsed(offset: 10),
      );
      const invalid = TextEditingValue(
        text: '5,000.oo',
        selection: TextSelection.collapsed(offset: 8),
      );

      expect(formatter.formatEditUpdate(oldValue, pasted).text, '50000.00');
      expect(formatter.formatEditUpdate(oldValue, invalid), oldValue);
    });

    test('does not modify active composing text', () {
      final formatter = SmartAmountFormatter(decimalPlaces: 2);
      const value = TextEditingValue(
        text: '12a',
        selection: TextSelection.collapsed(offset: 3),
        composing: TextRange(start: 0, end: 3),
      );

      expect(formatter.formatEditUpdate(TextEditingValue.empty, value), value);
    });
  });
}
