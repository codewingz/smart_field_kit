import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

String _text(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText)).controller.text;

void main() {
  group('formatter instances', () {
    test('amount and percentage fields carry one input formatter', () {
      for (final field in [
        SmartField.amount(minValue: '0', maxValue: '100', decimalLength: 2),
        SmartField.percentage(minValue: '0', maxValue: '100'),
      ]) {
        final formatters = field.inputFormatters!
            .whereType<SmartAmountFormatter>()
            .toList();
        expect(formatters, hasLength(1));
      }
    });
  });

  group('combined amount behavior', () {
    testWidgets('Indian grouping + negative + rounding + exact decimals', (
      tester,
    ) async {
      final focus = FocusNode();
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      final raws = <String>[];
      final saved = <String?>[];
      addTearDown(focus.dispose);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.amount(
              controller: controller,
              focusNode: focus,
              decimalLength: 2,
              useGrouping: true,
              groupingStyle: SmartGroupingStyle.indian,
              allowNegative: true,
              rounding: SmartRoundingMode.halfUp,
              onRawChanged: raws.add,
              onRawSaved: saved.add,
            ),
          ),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      await tester.enterText(find.byType(EditableText), '-1234567.895');
      await tester.pump();
      expect(raws.last, '-1234567.895');
      focus.unfocus();
      await tester.pump();
      expect(controller.text, '-12,34,567.90');
      formKey.currentState!.save();
      expect(saved.last, '-1234567.90');
    });

    testWidgets('masking survives controller replacement', (tester) async {
      final first = TextEditingController(text: '1234.50');
      final second = TextEditingController(text: '99.00');
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      Widget build(TextEditingController c) => _app(
        SmartField.amount(
          controller: c,
          decimalLength: 2,
          useGrouping: true,
          mask: true,
        ),
      );
      await tester.pumpWidget(build(first));
      expect(first.text, '1,234.50');
      await tester.pumpWidget(build(second));
      await tester.pump();
      expect(second.text, '99.00');
      expect(
        tester.widget<TextField>(find.byType(TextField)).decoration?.prefixText,
        isNotNull,
      );
      expect(first.text, '1,234.50');
    });

    testWidgets('async validation receives the exact raw amount', (
      tester,
    ) async {
      final seen = <String>[];
      await tester.pumpWidget(
        _app(
          SmartField.amount(
            decimalLength: 2,
            useGrouping: true,
            asyncValidation: SmartAsyncValidation(
              debounceDuration: Duration.zero,
              validator: (value) async {
                seen.add(value);
                return null;
              },
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), '1234.5');
      await tester.pump();
      expect(seen, ['1234.5']);
    });

    testWidgets('boundaries, large values and malformed input', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.amount(
              decimalLength: 2,
              minValue: '0.01',
              maxValue: '999999999999999999.99',
            ),
          ),
        ),
      );
      await tester.enterText(
        find.byType(EditableText),
        '999999999999999999.99',
      );
      await tester.pump();
      expect(formKey.currentState!.validate(), isTrue);
      await tester.enterText(find.byType(EditableText), '0.00');
      await tester.pump();
      expect(formKey.currentState!.validate(), isFalse);
      await tester.enterText(find.byType(EditableText), '5,000.oo');
      await tester.pump();
      expect(_text(tester), isNot('5,000.oo'));
    });

    testWidgets('displayed, raw and normalized values stay consistent', (
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
      await tester.enterText(find.byType(EditableText), '50000.00');
      await tester.pump();
      focus.unfocus();
      await tester.pump();
      expect(controller.text, '50,000.00');
      expect(raws.last, '50000.00');
      final normalizer = SmartAmountFormatter(
        decimalPlaces: 2,
        useGrouping: true,
      );
      expect(normalizer.normalize(controller.text), raws.last);
    });
  });
}
