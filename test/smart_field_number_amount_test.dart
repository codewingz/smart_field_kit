import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('SmartField.number', () {
    testWidgets('accepts multi-digit integers zero and leading zeros', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_app(SmartField.number(controller: controller)));

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.keyboardType, const TextInputType.numberWithOptions());

      for (final value in [
        '0',
        '000123',
        '1234567890123456789012345678901234567890',
      ]) {
        await tester.enterText(find.byType(TextFormField), value);
        expect(controller.text, value);
      }
    });

    testWidgets('supports optional negatives and rejects them by default', (
      tester,
    ) async {
      final unsignedController = TextEditingController();
      final signedController = TextEditingController();
      addTearDown(unsignedController.dispose);
      addTearDown(signedController.dispose);

      await tester.pumpWidget(
        _app(
          Column(
            children: [
              SmartField.number(controller: unsignedController),
              SmartField.number(
                controller: signedController,
                allowNegative: true,
              ),
            ],
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField).first, '-12');
      await tester.enterText(find.byType(TextFormField).last, '-12');
      expect(unsignedController.text, isEmpty);
      expect(signedController.text, '-12');
      final signedField = tester.widget<TextField>(find.byType(TextField).last);
      expect(signedField.keyboardType.signed, isTrue);
    });

    testWidgets('supports optional required length range and custom order', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      var customCalls = 0;

      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.number(
              controller: controller,
              isRequired: true,
              requiredErrorText: 'Required error',
              minLength: 2,
              minLengthErrorText: 'Length error',
              minValue: '10',
              minValueErrorText: 'Minimum error',
              maxValue: '999999999999999999999999999999',
              maxValueErrorText: 'Maximum error',
              validator: (value) {
                customCalls++;
                return value == '42' ? null : 'Custom error';
              },
            ),
          ),
        ),
      );

      expect(formKey.currentState!.validate(), isFalse);
      expect(customCalls, 0);

      controller.text = 'x';
      expect(formKey.currentState!.validate(), isFalse);
      expect(customCalls, 0);

      controller.text = '1';
      expect(formKey.currentState!.validate(), isFalse);
      expect(customCalls, 0);

      controller.text = '09';
      expect(formKey.currentState!.validate(), isFalse);
      expect(customCalls, 0);

      controller.text = '1000000000000000000000000000000';
      expect(formKey.currentState!.validate(), isFalse);
      expect(customCalls, 0);

      controller.text = '41';
      expect(formKey.currentState!.validate(), isFalse);
      expect(customCalls, 1);

      controller.text = '42';
      expect(formKey.currentState!.validate(), isTrue);
      expect(customCalls, 2);
    });

    testWidgets('keeps legacy one-digit policy opt-in', (tester) async {
      final normalKey = GlobalKey<FormState>();
      final legacyKey = GlobalKey<FormState>();
      final normalController = TextEditingController(text: '88');
      final legacyController = TextEditingController(text: '88');
      addTearDown(normalController.dispose);
      addTearDown(legacyController.dispose);

      await tester.pumpWidget(
        _app(
          Column(
            children: [
              Form(
                key: normalKey,
                child: SmartField.number(controller: normalController),
              ),
              Form(
                key: legacyKey,
                child: SmartField.number(
                  controller: legacyController,
                  policy: SmartNumberPolicy.legacy,
                ),
              ),
            ],
          ),
        ),
      );

      expect(normalKey.currentState!.validate(), isTrue);
      expect(legacyKey.currentState!.validate(), isFalse);
    });

    testWidgets('preserves number callbacks and native Form saving', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      String? changed;
      String? saved;

      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.number(
              onChanged: (value) => changed = value,
              onSaved: (value) => saved = value,
            ),
          ),
        ),
      );

      expect(formKey.currentState!.validate(), isTrue);
      await tester.enterText(find.byType(TextFormField), '00042');
      formKey.currentState!.save();
      expect(changed, '00042');
      expect(saved, '00042');
    });
  });

  group('SmartField.amount', () {
    testWidgets(
      'configures decimal keyboard without default formatting limits',
      (tester) async {
        final formKey = GlobalKey<FormState>();
        final controller = TextEditingController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          _app(
            Form(
              key: formKey,
              child: SmartField.amount(controller: controller),
            ),
          ),
        );

        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.keyboardType.decimal, isTrue);
        expect(formKey.currentState!.validate(), isTrue);
        const value = '12345678901234567890.12345678901234567890';
        await tester.enterText(find.byType(TextFormField), value);
        expect(controller.text, value);
        expect(formKey.currentState!.validate(), isTrue);
      },
    );

    testWidgets('formats display on blur and restores editable raw text', (
      tester,
    ) async {
      final controller = TextEditingController(text: '50000.00');
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        _app(
          SmartField.amount(
            controller: controller,
            focusNode: focusNode,
            decimalPlaces: 2,
            useGrouping: true,
          ),
        ),
      );

      expect(controller.text, '50,000.00');
      focusNode.requestFocus();
      await tester.pump();
      expect(controller.text, '50000.00');

      controller.selection = const TextSelection.collapsed(offset: 2);
      focusNode.unfocus();
      await tester.pump();
      expect(controller.text, '50,000.00');
      expect(controller.selection.baseOffset, 2);
    });

    testWidgets('keeps display callbacks and exposes exact raw callbacks', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      String? changed;
      String? rawChanged;
      String? saved;
      String? rawSaved;

      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.amount(
              controller: controller,
              focusNode: focusNode,
              decimalPlaces: 2,
              useGrouping: true,
              currencySymbol: r'$',
              onChanged: (value) => changed = value,
              onRawChanged: (value) => rawChanged = value,
              onSaved: (value) => saved = value,
              onRawSaved: (value) => rawSaved = value,
            ),
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), '50000.00');
      expect(changed, '50000.00');
      expect(rawChanged, '50000.00');

      focusNode.unfocus();
      await tester.pump();
      expect(controller.text, r'$50,000.00');
      expect(formKey.currentState!.validate(), isTrue);
      formKey.currentState!.save();
      expect(saved, r'$50,000.00');
      expect(rawSaved, '50000.00');
    });

    testWidgets('rejects malformed input without sanitizing it', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController(text: '5,000.oo');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.amount(
              controller: controller,
              decimalPlaces: 2,
              useGrouping: true,
            ),
          ),
        ),
      );

      expect(controller.text, '5,000.oo');
      expect(formKey.currentState!.validate(), isFalse);

      await tester.tap(find.byType(TextFormField));
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), '7,000.oo');
      expect(controller.text, '5,000.oo');
    });

    testWidgets('supports partial decimals precision and optional negatives', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.amount(
              controller: controller,
              decimalPlaces: 2,
              allowNegative: true,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), '.5');
      expect(controller.text, '.5');
      expect(formKey.currentState!.validate(), isTrue);

      await tester.enterText(find.byType(TextFormField), '0.');
      expect(controller.text, '0.');
      expect(formKey.currentState!.validate(), isFalse);

      await tester.enterText(find.byType(TextFormField), '-12.34');
      expect(controller.text, '-12.34');
      expect(formKey.currentState!.validate(), isTrue);

      await tester.enterText(find.byType(TextFormField), '-12.345');
      expect(controller.text, '-12.34');

      await tester.enterText(find.byType(TextFormField), '');
      expect(controller.text, isEmpty);
      expect(formKey.currentState!.validate(), isTrue);
    });

    testWidgets('formats programmatic controller updates while unfocused', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _app(
          SmartField.amount(
            controller: controller,
            decimalPlaces: 2,
            useGrouping: true,
          ),
        ),
      );

      controller.text = '9876543.2';
      expect(controller.text, '9,876,543.20');

      controller.text = 'invalid';
      expect(controller.text, 'invalid');
    });

    testWidgets('mounts updates and disposes with owned editing state', (
      tester,
    ) async {
      await tester.pumpWidget(_app(SmartField.amount(useGrouping: true)));
      await tester.enterText(find.byType(TextFormField), '1234');
      expect(find.text('1234'), findsOneWidget);

      await tester.pumpWidget(_app(const SizedBox()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('supports configured separators currency suffix and legacy', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController(text: '50000,5');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.amount(
              controller: controller,
              decimalPlaces: 2,
              useGrouping: true,
              groupingSeparator: '.',
              decimalSeparator: ',',
              currencySymbol: ' USD',
              currencyPosition: SmartCurrencyPosition.suffix,
              policy: SmartAmountPolicy.legacy,
            ),
          ),
        ),
      );

      expect(controller.text, '50.000,50 USD');
      expect(formKey.currentState!.validate(), isTrue);
    });

    testWidgets('preserves selection during middle editing and focus changes', (
      tester,
    ) async {
      final controller = TextEditingController(text: '12345.67');
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        _app(
          SmartField.amount(
            controller: controller,
            focusNode: focusNode,
            decimalPlaces: 2,
            useGrouping: true,
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();
      controller.selection = const TextSelection.collapsed(offset: 2);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '129345.67',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      await tester.pump();
      expect(controller.text, '129345.67');
      expect(controller.selection.baseOffset, 3);

      focusNode.unfocus();
      await tester.pump();
      expect(controller.text, '129,345.67');
      expect(controller.selection.baseOffset, 3);
    });

    testWidgets('supports required range custom validation and Form behavior', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      var customCalls = 0;

      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.amount(
              controller: controller,
              isRequired: true,
              minValue: '0.10',
              maxValue: '999999999999999999999999.99',
              validator: (value) {
                customCalls++;
                return value == '10.00' ? null : 'Custom error';
              },
            ),
          ),
        ),
      );

      expect(formKey.currentState!.validate(), isFalse);
      expect(customCalls, 0);

      controller.text = 'invalid';
      expect(formKey.currentState!.validate(), isFalse);
      expect(customCalls, 0);

      controller.text = '0.09';
      expect(formKey.currentState!.validate(), isFalse);
      expect(customCalls, 0);

      controller.text = '1000000000000000000000000';
      expect(formKey.currentState!.validate(), isFalse);
      expect(customCalls, 0);

      controller.text = '9.99';
      expect(formKey.currentState!.validate(), isFalse);
      expect(customCalls, 1);

      controller.text = '10.00';
      expect(formKey.currentState!.validate(), isTrue);
      expect(customCalls, 2);
    });
  });
}
