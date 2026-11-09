import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

SmartAmountFormatter _grouped() => SmartAmountFormatter(
  useGrouping: true,
  decimalPlaces: 2,
  allowNegative: true,
);

TextEditingValue _composing(String text, {int? cursor}) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: cursor ?? text.length),
  composing: TextRange(start: 0, end: text.length),
);

void main() {
  group('formatter conversions leave active composition alone', () {
    test('toDisplayValue returns the composing value unchanged', () {
      final value = _composing('1234');
      expect(_grouped().toDisplayValue(value), value);
    });

    test('toEditableValue returns the composing value unchanged', () {
      final value = _composing('1,234.00');
      expect(_grouped().toEditableValue(value), value);
    });

    test('committed values convert as before and keep the caret', () {
      final committed = TextEditingValue(
        text: '1234',
        selection: const TextSelection.collapsed(offset: 2),
      );
      final display = _grouped().toDisplayValue(committed);
      expect(display.text, '1,234.00');
      expect(display.selection, const TextSelection.collapsed(offset: 3));
      expect(display.composing, TextRange.empty);
      expect(_grouped().toEditableValue(display).text, '1234.00');
    });

    test('partial values stay editable states', () {
      final formatter = _grouped();
      for (final partial in ['-', '.', '0.', '-.5']) {
        final value = TextEditingValue(
          text: partial,
          selection: TextSelection.collapsed(offset: partial.length),
        );
        expect(formatter.toEditableValue(value).text, partial);
      }
    });

    test('formatEditUpdate still defers while composing', () {
      final formatter = _grouped();
      final composing = _composing('12abc');
      expect(
        formatter.formatEditUpdate(TextEditingValue.empty, composing),
        composing,
      );
    });
  });

  group('amount field with composition', () {
    testWidgets('composing text is not rewritten while focused', (
      tester,
    ) async {
      final controller = TextEditingController();
      final focus = FocusNode();
      final raws = <String>[];
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.amount(
            controller: controller,
            focusNode: focus,
            decimalLength: 2,
            useGrouping: true,
            onRawChanged: raws.add,
          ),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      await tester.showKeyboard(find.byType(EditableText));
      tester.testTextInput.updateEditingValue(_composing('1234'));
      await tester.pump();
      expect(controller.text, '1234');
      expect(controller.value.composing, const TextRange(start: 0, end: 4));
      expect(raws.last, '1234');
    });

    testWidgets('committing the same text keeps the editable value', (
      tester,
    ) async {
      final controller = TextEditingController();
      final focus = FocusNode();
      final raws = <String>[];
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.amount(
            controller: controller,
            focusNode: focus,
            decimalLength: 2,
            useGrouping: true,
            onRawChanged: raws.add,
          ),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      await tester.showKeyboard(find.byType(EditableText));
      tester.testTextInput.updateEditingValue(_composing('1234'));
      await tester.pump();
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '1234',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      await tester.pump();
      expect(controller.text, '1234');
      expect(controller.value.composing, TextRange.empty);
      expect(raws.last, '1234');
      focus.unfocus();
      await tester.pump();
      expect(controller.text, '1,234.00');
    });

    testWidgets('blur while composing converts once composition has ended', (
      tester,
    ) async {
      final controller = TextEditingController();
      final focus = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.amount(
            controller: controller,
            focusNode: focus,
            decimalLength: 2,
            useGrouping: true,
          ),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      await tester.showKeyboard(find.byType(EditableText));
      tester.testTextInput.updateEditingValue(_composing('1234'));
      await tester.pump();
      focus.unfocus();
      await tester.pump();
      expect(controller.value.composing, TextRange.empty);
      expect(controller.text, '1,234.00');
    });

    testWidgets('negative, paste, backspace and cursor edits still work', (
      tester,
    ) async {
      final controller = TextEditingController();
      final focus = FocusNode();
      final raws = <String>[];
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.amount(
            controller: controller,
            focusNode: focus,
            decimalLength: 2,
            useGrouping: true,
            allowNegative: true,
            onRawChanged: raws.add,
          ),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      await tester.showKeyboard(find.byType(EditableText));
      for (final step in ['-', '-1', '-12', '-123.4']) {
        tester.testTextInput.updateEditingValue(
          TextEditingValue(
            text: step,
            selection: TextSelection.collapsed(offset: step.length),
          ),
        );
        await tester.pump();
      }
      expect(controller.text, '-123.4');
      expect(raws.last, '-123.4');
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '-123.',
          selection: TextSelection.collapsed(offset: 5),
        ),
      );
      await tester.pump();
      expect(controller.text, '-123.');
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '-9876543.21',
          selection: TextSelection.collapsed(offset: 11),
        ),
      );
      await tester.pump();
      expect(raws.last, '-9876543.21');
      focus.unfocus();
      await tester.pump();
      expect(controller.text, '-9,876,543.21');
    });

    testWidgets('external controller updates are displayed when unfocused', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.amount(
            controller: controller,
            decimalLength: 2,
            useGrouping: true,
          ),
        ),
      );
      controller.text = '50000';
      await tester.pump();
      expect(controller.text, '50,000.00');
    });
  });
}
