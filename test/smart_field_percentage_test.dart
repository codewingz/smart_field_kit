import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child, {TextDirection direction = TextDirection.ltr}) {
  return MaterialApp(
    home: Directionality(
      textDirection: direction,
      child: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}

void main() {
  testWidgets('uses decimal signed input and a visual percent suffix', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(SmartField.percentage(controller: controller)),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(
      field.keyboardType,
      const TextInputType.numberWithOptions(decimal: true, signed: true),
    );
    expect(field.maxLines, 1);
    expect(find.text('%'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '-12.50');
    expect(controller.text, '-12.50');
  });

  testWidgets('has no default range precision or length restriction', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField.percentage(controller: controller),
        ),
      ),
    );

    for (final value in [
      '0',
      '12',
      '12.5',
      '12.50',
      '0.125',
      '100',
      '250',
      '-5',
      '000.0000000001',
    ]) {
      controller.text = value;
      expect(formKey.currentState!.validate(), isTrue, reason: value);
    }
  });

  testWidgets(
    'validates required syntax precision ranges and custom rules in order',
    (tester) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.percentage(
              controller: controller,
              isRequired: true,
              requiredErrorText: 'Required',
              decimalPlaces: 2,
              minValue: '0',
              maxValue: '100',
              validator: (value) => value == '50' ? null : 'Custom',
            ),
          ),
        ),
      );

      expect(formKey.currentState!.validate(), isFalse);
      controller.text = '12.345';
      expect(formKey.currentState!.validate(), isFalse);
      controller.text = '-0.01';
      expect(formKey.currentState!.validate(), isFalse);
      controller.text = '100.01';
      expect(formKey.currentState!.validate(), isFalse);
      controller.text = '12.5';
      expect(formKey.currentState!.validate(), isFalse);
      controller.text = '50';
      expect(formKey.currentState!.validate(), isTrue);
    },
  );

  testWidgets(
    'keeps partial states editable but rejects them during validation',
    (tester) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.percentage(controller: controller),
          ),
        ),
      );

      for (final value in ['-', '.', '-.5', '12.']) {
        await tester.enterText(find.byType(TextFormField), value);
        expect(controller.text, value);
      }
      controller.text = '-';
      expect(formKey.currentState!.validate(), isFalse);
      controller.text = '.';
      expect(formKey.currentState!.validate(), isFalse);
    },
  );

  testWidgets('rejects malformed values without silently stripping them', (
    tester,
  ) async {
    final controller = TextEditingController(text: '12.5');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(SmartField.percentage(controller: controller)),
    );

    await tester.enterText(find.byType(TextFormField), '12abc.5');
    expect(controller.text, '12.5');
    await tester.enterText(find.byType(TextFormField), '12.5%');
    expect(controller.text, '12.5');
  });

  testWidgets(
    'supports opt-in nonnegative policy and custom suffix precedence',
    (tester) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              Form(
                key: formKey,
                child: SmartField.percentage(
                  controller: controller,
                  allowNegative: false,
                ),
              ),
              SmartField.percentage(
                decoration: const InputDecoration(suffixText: 'rate'),
              ),
            ],
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField).first, '-5');
      expect(controller.text, isEmpty);
      controller.text = '-5';
      expect(formKey.currentState!.validate(), isFalse);
      expect(find.text('rate'), findsOneWidget);
    },
  );

  testWidgets('keeps callbacks Form saved values and reset raw', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    String? changed;
    String? saved;
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField.percentage(
            controller: controller,
            onChanged: (value) => changed = value,
            onSaved: (value) => saved = value,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), '12.50');
    formKey.currentState!.save();
    expect(changed, '12.50');
    expect(saved, '12.50');
    expect(controller.text, '12.50');
    formKey.currentState!.reset();
    await tester.pump();
    expect(controller.text, isEmpty);
  });

  testWidgets('preserves external focus selection and supports RTL', (
    tester,
  ) async {
    final controller = TextEditingController(text: '250.125');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      _app(
        SmartField.percentage(controller: controller, focusNode: focusNode),
        direction: TextDirection.rtl,
      ),
    );

    await tester.tap(find.byType(TextFormField));
    controller.selection = const TextSelection(baseOffset: 2, extentOffset: 5);
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);
    expect(
      controller.selection,
      const TextSelection(baseOffset: 2, extentOffset: 5),
    );
    expect(find.text('%'), findsOneWidget);
  });

  testWidgets('compares min and max exactly without binary floats', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField.percentage(
            controller: controller,
            minValue: '0',
            maxValue: '100.1',
          ),
        ),
      ),
    );

    for (final value in ['0', '100', '100.1', '0.0000000000000000001']) {
      controller.text = value;
      expect(formKey.currentState!.validate(), isTrue, reason: value);
    }
    for (final value in [
      '-0.0000000000000000001',
      '100.1000000000000000001',
      '250',
      '-5',
    ]) {
      controller.text = value;
      expect(formKey.currentState!.validate(), isFalse, reason: value);
    }
  });

  testWidgets('rejects whitespace and required whitespace', (tester) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField.percentage(
            controller: controller,
            isRequired: true,
          ),
        ),
      ),
    );

    for (final value in [
      ' ',
      '12 5',
      'abc',
      'Infinity',
      'NaN',
      '12%5',
      '12..5',
      '1e5',
    ]) {
      controller.text = value;
      expect(formKey.currentState!.validate(), isFalse, reason: value);
    }
  });

  testWidgets('shows suffix when disabled read-only dark and large text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(2),
            size: Size(200, 600),
          ),
          child: Scaffold(
            body: Column(
              children: [
                SmartField.percentage(enabled: false),
                SmartField.percentage(readOnly: true),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('%'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not touch controller text when rebuilt or refocused', (
    tester,
  ) async {
    final controller = TextEditingController(text: '12.50');
    final focusNode = FocusNode();
    var calls = 0;
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    Widget build() => _app(
      SmartField.percentage(
        controller: controller,
        focusNode: focusNode,
        onChanged: (_) => calls++,
      ),
    );
    await tester.pumpWidget(build());
    focusNode.requestFocus();
    await tester.pump();
    focusNode.unfocus();
    await tester.pumpWidget(build());
    expect(controller.text, '12.50');
    expect(calls, 0);
    expect(find.text('%'), findsOneWidget);
  });
}
