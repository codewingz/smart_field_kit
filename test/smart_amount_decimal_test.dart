import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}

Future<String> _blurResult(
  WidgetTester tester,
  SmartField Function(TextEditingController, FocusNode) build,
  String input,
) async {
  final controller = TextEditingController();
  final focusNode = FocusNode();
  addTearDown(controller.dispose);
  addTearDown(focusNode.dispose);
  await tester.pumpWidget(_app(build(controller, focusNode)));
  focusNode.requestFocus();
  await tester.pump();
  await tester.enterText(find.byType(TextFormField), input);
  await tester.pump();
  focusNode.unfocus();
  await tester.pump();
  return controller.text;
}

void main() {
  group('SmartDecimalLength', () {
    test('accepts false, 1, 2, 3 only', () {
      expect(SmartDecimalLength.from(false).places, 0);
      expect(SmartDecimalLength.from(false).hasDecimals, isFalse);
      expect(SmartDecimalLength.from(1).places, 1);
      expect(SmartDecimalLength.from(2).places, 2);
      expect(SmartDecimalLength.from(3).places, 3);
      for (final bad in <Object?>[
        true,
        0,
        4,
        -1,
        2.5,
        1.5,
        0.5,
        double.nan,
        '2',
        null,
        'false',
        Object(),
        <int>[2],
      ]) {
        expect(
          () => SmartDecimalLength.from(bad),
          throwsArgumentError,
          reason: '$bad',
        );
      }
    });

    test('integral doubles follow the platform number model', () {
      final jsNumbers = identical(2, 2.0);
      if (jsNumbers) {
        expect(SmartDecimalLength.from(2.0).places, 2);
      } else {
        expect(() => SmartDecimalLength.from(2.0), throwsArgumentError);
      }
    });

    test('the amount constructor validates decimalLength the same way', () {
      expect(() => SmartField.amount(decimalLength: 4), throwsArgumentError);
      expect(() => SmartField.amount(decimalLength: 2.5), throwsArgumentError);
      expect(() => SmartField.amount(decimalLength: '2'), throwsArgumentError);
      expect(() => SmartField.amount(decimalLength: true), throwsArgumentError);
      for (final ok in <Object>[false, 1, 2, 3]) {
        expect(() => SmartField.amount(decimalLength: ok), returnsNormally);
      }
    });

    test('equality', () {
      expect(const SmartDecimalLength.fixed(2), SmartDecimalLength.from(2));
      expect(const SmartDecimalLength.none(), SmartDecimalLength.from(false));
    });
  });

  group('SmartDecimalUtils.round', () {
    String r(String v, int places, SmartRoundingMode mode) =>
        SmartDecimalUtils.round(v, decimalPlaces: places, mode: mode);

    test('none and short fractions are untouched', () {
      expect(r('12.345', 2, SmartRoundingMode.none), '12.345');
      expect(r('12.3', 2, SmartRoundingMode.halfUp), '12.3');
      expect(r('12', 2, SmartRoundingMode.up), '12');
    });

    test('half up rounds ties away from zero', () {
      expect(r('12.345', 2, SmartRoundingMode.halfUp), '12.35');
      expect(r('12.344', 2, SmartRoundingMode.halfUp), '12.34');
      expect(r('-12.345', 2, SmartRoundingMode.halfUp), '-12.35');
      expect(r('0.995', 2, SmartRoundingMode.halfUp), '1.00');
      expect(r('999.995', 2, SmartRoundingMode.halfUp), '1000.00');
    });

    test('half even uses banker rounding', () {
      expect(r('12.345', 2, SmartRoundingMode.halfEven), '12.34');
      expect(r('12.355', 2, SmartRoundingMode.halfEven), '12.36');
      expect(r('12.3451', 2, SmartRoundingMode.halfEven), '12.35');
      expect(r('0.5', 0, SmartRoundingMode.halfEven), '0');
      expect(r('1.5', 0, SmartRoundingMode.halfEven), '2');
      expect(r('2.5', 0, SmartRoundingMode.halfEven), '2');
    });

    test('down truncates and up goes away from zero', () {
      expect(r('12.999', 2, SmartRoundingMode.down), '12.99');
      expect(r('-12.999', 2, SmartRoundingMode.down), '-12.99');
      expect(r('12.001', 2, SmartRoundingMode.up), '12.01');
      expect(r('-12.001', 2, SmartRoundingMode.up), '-12.01');
      expect(r('12.000', 2, SmartRoundingMode.up), '12.00');
    });

    test('precise and huge values avoid floating point', () {
      expect(
        r('123456789012345678901234567890.125', 2, SmartRoundingMode.halfUp),
        '123456789012345678901234567890.13',
      );
      expect(r('0.1000000000000000055', 2, SmartRoundingMode.halfUp), '0.10');
      expect(r('-0.004', 2, SmartRoundingMode.halfUp), '0.00');
      expect(r('0.004', 0, SmartRoundingMode.up), '1');
    });

    test('rejects malformed input', () {
      expect(
        () => r('abc', 2, SmartRoundingMode.halfUp),
        throwsFormatException,
      );
      expect(
        () => r('1.2.3', 2, SmartRoundingMode.halfUp),
        throwsFormatException,
      );
      expect(() => r('.', 2, SmartRoundingMode.halfUp), throwsFormatException);
      expect(() => r('1', -1, SmartRoundingMode.halfUp), throwsArgumentError);
    });
  });

  group('SmartAmountFormatter', () {
    test('indian grouping formats and parses', () {
      final formatter = SmartAmountFormatter(
        useGrouping: true,
        groupingStyle: SmartGroupingStyle.indian,
        decimalPlaces: 2,
        allowNegative: true,
      );
      expect(formatter.format('1500'), '1,500.00');
      expect(formatter.format('150000'), '1,50,000.00');
      expect(formatter.format('12345678.5'), '1,23,45,678.50');
      expect(formatter.format('-1234567'), '-12,34,567.00');
      expect(formatter.normalize('1,23,45,678.50'), '12345678.50');
      expect(formatter.normalize('12,345,678.50'), isNull);
      expect(formatter.normalize('1,2,345'), isNull);
    });

    test('international grouping is unchanged', () {
      final formatter = SmartAmountFormatter(useGrouping: true);
      expect(formatter.format('1234567'), '1,234,567');
      expect(formatter.normalize('1,23,456'), isNull);
    });

    test('custom separators with grouping and decimals', () {
      final formatter = SmartAmountFormatter(
        useGrouping: true,
        groupingSeparator: '.',
        decimalSeparator: ',',
        decimalPlaces: 2,
      );
      expect(formatter.format('1234,5'), '1.234,50');
      expect(formatter.normalize('1.234,50'), '1234.50');
    });

    test('rounding applies to normalize and format only when selected', () {
      final none = SmartAmountFormatter(decimalPlaces: 2);
      expect(none.normalize('12.345'), isNull);
      final rounded = SmartAmountFormatter(
        decimalPlaces: 2,
        roundingMode: SmartRoundingMode.halfUp,
        useGrouping: true,
        allowNegative: true,
      );
      expect(rounded.normalize('12.345'), '12.35');
      expect(rounded.normalize('12.345', allowPartial: true), '12.345');
      expect(rounded.format('1234.567'), '1,234.57');
      expect(rounded.format('-0.001'), '0.00');
    });
  });

  group('SmartField.amount decimalLength', () {
    for (final row in <(Object, String)>[
      (false, '1,500'),
      (1, '1,500.0'),
      (2, '1,500.00'),
      (3, '1,500.000'),
    ]) {
      testWidgets('decimalLength ${row.$1} shows ${row.$2} after editing', (
        tester,
      ) async {
        final result = await _blurResult(
          tester,
          (controller, focusNode) => SmartField.amount(
            controller: controller,
            focusNode: focusNode,
            useGrouping: true,
            decimalLength: row.$1,
          ),
          '1500',
        );
        expect(result, row.$2);
      });
    }

    testWidgets('false disables decimal typing', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(SmartField.amount(controller: controller, decimalLength: false)),
      );
      await tester.enterText(find.byType(TextFormField), '12');
      await tester.enterText(find.byType(TextFormField), '12.5');
      expect(controller.text, '12');
    });

    testWidgets('partial input is preserved while typing', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.amount(
            controller: controller,
            focusNode: focusNode,
            useGrouping: true,
            decimalLength: 2,
            allowNegative: true,
          ),
        ),
      );
      focusNode.requestFocus();
      await tester.pump();
      for (final value in ['-', '.', '1.', '1.5', '-0.', '1234.5']) {
        await tester.enterText(find.byType(TextFormField), value);
        expect(controller.text, value);
      }
      await tester.enterText(find.byType(TextFormField), '1.234');
      expect(controller.text, '1234.5');
    });

    testWidgets('extra digits are rejected unless rounding is explicit', (
      tester,
    ) async {
      final plain = await _blurResult(
        tester,
        (controller, focusNode) => SmartField.amount(
          controller: controller,
          focusNode: focusNode,
          decimalLength: 2,
        ),
        '12.345',
      );
      expect(plain, isNot('12.35'));
      expect(plain, isNot('12.34'));
      final rounded = await _blurResult(
        tester,
        (controller, focusNode) => SmartField.amount(
          controller: controller,
          focusNode: focusNode,
          decimalLength: 2,
          rounding: SmartRoundingMode.halfUp,
        ),
        '12.345',
      );
      expect(rounded, '12.35');
      final even = await _blurResult(
        tester,
        (controller, focusNode) => SmartField.amount(
          controller: controller,
          focusNode: focusNode,
          decimalLength: 2,
          rounding: SmartRoundingMode.halfEven,
        ),
        '12.345',
      );
      expect(even, '12.34');
      final down = await _blurResult(
        tester,
        (controller, focusNode) => SmartField.amount(
          controller: controller,
          focusNode: focusNode,
          decimalLength: 2,
          rounding: SmartRoundingMode.down,
        ),
        '12.349',
      );
      expect(down, '12.34');
    });

    testWidgets('indian grouping, negative, and large values on blur', (
      tester,
    ) async {
      final result = await _blurResult(
        tester,
        (controller, focusNode) => SmartField.amount(
          controller: controller,
          focusNode: focusNode,
          useGrouping: true,
          groupingStyle: SmartGroupingStyle.indian,
          decimalLength: 2,
          allowNegative: true,
        ),
        '-123456789012.5',
      );
      expect(result, '-1,23,45,67,89,012.50');
    });

    testWidgets('raw values stay ungrouped and exact', (tester) async {
      final raws = <String>[];
      String? savedRaw;
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.amount(
              controller: controller,
              useGrouping: true,
              decimalLength: 2,
              rounding: SmartRoundingMode.halfUp,
              onRawChanged: raws.add,
              onRawSaved: (value) => savedRaw = value,
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), '1500.567');
      expect(raws.last, '1500.567');
      formKey.currentState!.save();
      expect(savedRaw, '1500.57');
    });

    testWidgets('min and max compare the rounded exact value', (tester) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.amount(
              controller: controller,
              decimalLength: 2,
              rounding: SmartRoundingMode.halfUp,
              maxValue: '10.00',
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), '10.004');
      expect(formKey.currentState!.validate(), isTrue);
      await tester.enterText(find.byType(TextFormField), '10.005');
      expect(formKey.currentState!.validate(), isFalse);
    });

    testWidgets('invalid characters are rejected', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(SmartField.amount(controller: controller, decimalLength: 2)),
      );
      await tester.enterText(find.byType(TextFormField), '12');
      await tester.enterText(find.byType(TextFormField), '12a');
      expect(controller.text, '12');
      await tester.enterText(find.byType(TextFormField), '5,000.oo');
      expect(controller.text, '12');
    });

    testWidgets('middle edits keep the caret', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(SmartField.amount(controller: controller, decimalLength: 2)),
      );
      await tester.showKeyboard(find.byType(TextFormField));
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '1250',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      await tester.pump();
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '12.50',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      await tester.pump();
      expect(controller.text, '12.50');
      expect(controller.selection, const TextSelection.collapsed(offset: 3));
    });

    test('conflicting decimalPlaces and decimalLength fail early', () {
      expect(
        () => SmartField.amount(decimalLength: 2, decimalPlaces: 3),
        throwsArgumentError,
      );
      expect(() => SmartField.amount(decimalLength: 5), throwsArgumentError);
      expect(() => SmartField.amount(decimalLength: true), throwsArgumentError);
      expect(
        () => SmartField.amount(decimalLength: 2, decimalPlaces: 2),
        returnsNormally,
      );
    });

    testWidgets('decimalPlaces alone keeps working', (tester) async {
      final result = await _blurResult(
        tester,
        (controller, focusNode) => SmartField.amount(
          controller: controller,
          focusNode: focusNode,
          useGrouping: true,
          decimalPlaces: 2,
        ),
        '50000.00',
      );
      expect(result, '50,000.00');
    });
  });
}
