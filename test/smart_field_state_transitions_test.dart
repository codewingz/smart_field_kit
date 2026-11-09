import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

EditableText _editable(WidgetTester tester, [int index = 0]) =>
    tester.widget<EditableText>(find.byType(EditableText).at(index));

String _text(WidgetTester tester, [int index = 0]) =>
    _editable(tester, index).controller.text;

Future<void> _type(WidgetTester tester, String text, [int index = 0]) async {
  await tester.enterText(find.byType(EditableText).at(index), text);
  await tester.pump();
}

void main() {
  group('uncontrolled field keeps text when its configuration changes', () {
    testWidgets('password strength indicator toggled on and off', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      String? saved;
      Widget build(bool strength) => _app(
        Form(
          key: formKey,
          child: SmartField.password(
            showStrengthIndicator: strength,
            onSaved: (value) => saved = value,
          ),
        ),
      );
      await tester.pumpWidget(build(false));
      await tester.showKeyboard(find.byType(EditableText));
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'abc12345',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      await tester.pump();
      await tester.pumpWidget(build(true));
      await tester.pump();
      expect(_text(tester), 'abc12345');
      expect(
        _editable(tester).controller.selection,
        const TextSelection.collapsed(offset: 3),
      );
      expect(_editable(tester).focusNode.hasFocus, isTrue);
      formKey.currentState!.save();
      expect(saved, 'abc12345');
      await tester.pumpWidget(build(false));
      await tester.pump();
      expect(_text(tester), 'abc12345');
      formKey.currentState!.reset();
      await tester.pump();
      expect(_text(tester), isEmpty);
    });

    testWidgets('async validation added and removed', (tester) async {
      Widget build(bool async) => _app(
        SmartField(
          asyncValidation: async
              ? SmartAsyncValidation(
                  trigger: SmartAsyncValidationTrigger.manual,
                  validator: (value) async => null,
                )
              : null,
        ),
      );
      await tester.pumpWidget(build(false));
      await _type(tester, 'typed value');
      await tester.pumpWidget(build(true));
      expect(_text(tester), 'typed value');
      await tester.pumpWidget(build(false));
      expect(_text(tester), 'typed value');
    });

    testWidgets('word counter enabled and disabled', (tester) async {
      Widget build(bool counter) =>
          _app(SmartField.description(showWordCount: counter));
      await tester.pumpWidget(build(false));
      await _type(tester, 'three small words');
      await tester.pumpWidget(build(true));
      expect(_text(tester), 'three small words');
      expect(find.text('3 words'), findsOneWidget);
      await tester.pumpWidget(build(false));
      expect(_text(tester), 'three small words');
    });

    testWidgets('masking toggled while mounted', (tester) async {
      Widget build(bool mask) => _app(SmartField.number(mask: mask));
      await tester.pumpWidget(build(false));
      await _type(tester, '123456789');
      await tester.pumpWidget(build(true));
      expect(_text(tester), '123456789');
      await tester.pumpWidget(build(false));
      expect(_text(tester), '123456789');
    });
  });

  group('controller ownership transitions', () {
    testWidgets('developer controller to internal controller', (tester) async {
      final controller = TextEditingController(text: 'kept');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(SmartField.password(controller: controller)),
      );
      await tester.pumpWidget(
        _app(SmartField.password(showStrengthIndicator: true)),
      );
      await tester.pump();
      expect(_text(tester), 'kept');
      controller.text = 'still usable by its owner';
      expect(controller.text, 'still usable by its owner');
    });

    testWidgets('internal controller to developer controller', (tester) async {
      final controller = TextEditingController(text: 'developer text');
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(SmartField.phone()));
      await _type(tester, '0300');
      await tester.pumpWidget(_app(SmartField.phone(controller: controller)));
      expect(_text(tester), 'developer text');
      await tester.pumpWidget(_app(SmartField.phone()));
      await tester.pump();
      expect(_text(tester), 'developer text');
      expect(controller.text, 'developer text');
    });

    testWidgets('one developer controller replaced by another', (tester) async {
      final first = TextEditingController(text: 'first');
      final second = TextEditingController(text: 'second');
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      await tester.pumpWidget(_app(SmartField.search(controller: first)));
      await tester.pumpWidget(_app(SmartField.search(controller: second)));
      expect(_text(tester), 'second');
      first.text = 'untouched listener-free';
      await tester.pump();
      expect(_text(tester), 'second');
      second.text = 'edited';
      await tester.pump();
      expect(_text(tester), 'edited');
    });

    testWidgets('populated date controller removed', (tester) async {
      final controller = TextEditingController(text: '2024-03-05');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.date(
            controller: controller,
            dateFormat: 'yyyy-MM-dd',
            mode: SmartDateMode.manual,
          ),
        ),
      );
      expect(_text(tester), '2024-03-05');
      await tester.pumpWidget(
        _app(
          SmartField.date(dateFormat: 'yyyy-MM-dd', mode: SmartDateMode.manual),
        ),
      );
      await tester.pump();
      expect(_text(tester), '2024-03-05');
      expect(controller.text, '2024-03-05');
    });

    testWidgets('populated credit-card number controller removed', (
      tester,
    ) async {
      final controller = TextEditingController(text: '4111 1111 1111 1111');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(SmartField.creditCard(numberController: controller)),
      );
      expect(_text(tester, 0), '4111 1111 1111 1111');
      await tester.pumpWidget(_app(SmartField.creditCard()));
      await tester.pump();
      expect(_text(tester, 0), '4111 1111 1111 1111');
      expect(controller.text, '4111 1111 1111 1111');
    });

    testWidgets('card values never appear in diagnostics', (tester) async {
      final printed = <String>[];
      final original = debugPrint;
      debugPrint = (message, {wrapWidth}) => printed.add(message ?? '');
      final controller = TextEditingController(text: '4111 1111 1111 1111');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(SmartField.creditCard(numberController: controller)),
      );
      await tester.pumpWidget(_app(SmartField.creditCard()));
      await tester.pump();
      debugPrint = original;
      expect(printed.where((line) => line.contains('4111')), isEmpty);
    });
  });
}
