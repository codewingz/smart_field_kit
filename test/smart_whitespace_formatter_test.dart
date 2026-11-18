import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

TextEditingValue _value(String text, [int? cursor]) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: cursor ?? text.length),
);

void main() {
  group('SmartWhitespaceFormatter trimLeading', () {
    test('trims a leading space while preserving the caret', () {
      const formatter = SmartWhitespaceFormatter(trimLeading: true);
      final result = formatter.formatEditUpdate(_value(''), _value(' a', 2));
      expect(result.text, 'a');
      expect(result.selection, const TextSelection.collapsed(offset: 1));
    });

    test('collapses internal runs and also trims leading runs', () {
      const formatter = SmartWhitespaceFormatter(trimLeading: true);
      final result = formatter.formatEditUpdate(_value(''), _value('   a   b'));
      expect(result.text, 'a b');
    });

    test('the default keeps a single leading space', () {
      const formatter = SmartWhitespaceFormatter();
      final result = formatter.formatEditUpdate(_value(''), _value(' a'));
      expect(result.text, ' a');
    });

    test('unicode text and emoji are unchanged', () {
      const formatter = SmartWhitespaceFormatter(trimLeading: true);
      final result = formatter.formatEditUpdate(_value(''), _value('Ærø ☕'));
      expect(result.text, 'Ærø ☕');
    });
  });
}
