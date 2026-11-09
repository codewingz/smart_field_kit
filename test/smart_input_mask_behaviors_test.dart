import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

String _text(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText)).controller.text;

void main() {
  group('trailing literals in masks', () {
    final mask = SmartInputMask('(##/##/####)');

    test('a complete value includes the closing literal', () {
      expect(mask.apply('15032024').display, '(15/03/2024)');
      expect(mask.display('15032024'), '(15/03/2024)');
    });

    test('partial values do not emit the trailing literal', () {
      expect(mask.display('1503'), '(15/03');
      expect(mask.display(''), '');
      expect(mask.display('1503202'), '(15/03/202');
    });

    test('extraction accepts text with or without the closing literal', () {
      expect(mask.extractRaw('(15/03/2024)'), '15032024');
      expect(mask.extractRaw('(15/03/2024'), '15032024');
      expect(mask.isComplete('15032024'), isTrue);
    });

    test('a mask without trailing literals is unchanged', () {
      final plain = SmartInputMask('##-##');
      expect(plain.display('1234'), '12-34');
      expect(plain.display('12'), '12');
    });

    testWidgets('typing a full value in the widget keeps the closing literal', (
      tester,
    ) async {
      final raws = <String>[];
      await tester.pumpWidget(
        _app(
          SmartField.text(inputMask: '(##/##/####)', onRawChanged: raws.add),
        ),
      );
      await tester.enterText(find.byType(EditableText), '15032024');
      await tester.pump();
      expect(_text(tester), '(15/03/2024)');
      expect(raws.last, '15032024');
    });

    testWidgets('pasting the formatted value is accepted', (tester) async {
      await tester.pumpWidget(_app(SmartField.text(inputMask: '(##/##/####)')));
      await tester.enterText(find.byType(EditableText), '(15/03/2024)');
      await tester.pump();
      expect(_text(tester), '(15/03/2024)');
    });

    testWidgets('backspace over the closing literal removes the last digit', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.text(controller: controller, inputMask: '(##/##/####)'),
        ),
      );
      await tester.enterText(find.byType(EditableText), '15032024');
      await tester.pump();
      await tester.showKeyboard(find.byType(EditableText));
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '(15/03/2024',
          selection: TextSelection.collapsed(offset: 11),
        ),
      );
      await tester.pump();
      expect(controller.text, '(15/03/202');
    });

    testWidgets('a date pattern with a closing literal can be entered', (
      tester,
    ) async {
      final dates = <DateTime?>[];
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.date(
              dateFormat: '(dd/MM/yyyy)',
              mode: SmartDateMode.manual,
              onDateChanged: dates.add,
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), '15032024');
      await tester.pump();
      expect(_text(tester), '(15/03/2024)');
      expect(dates.last, DateTime(2024, 3, 15));
      expect(formKey.currentState!.validate(), isTrue);
    });
  });

  group('raw value conversion has one precedence', () {
    testWidgets('an explicit raw builder wins over mask extraction', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final changed = <String>[];
      final saved = <String?>[];
      final asyncSeen = <String>[];
      final async = SmartFieldAsyncController();
      addTearDown(async.dispose);
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.text(
              inputMask: '##-##',
              rawValueBuilder: (text) => 'custom:$text',
              onRawChanged: changed.add,
              onRawSaved: saved.add,
              asyncValidation: SmartAsyncValidation(
                controller: async,
                debounceDuration: Duration.zero,
                validator: (value) async {
                  asyncSeen.add(value);
                  return null;
                },
              ),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), '1234');
      await tester.pump();
      expect(_text(tester), '12-34');
      expect(changed.last, 'custom:12-34');
      formKey.currentState!.save();
      expect(saved.last, 'custom:12-34');
      expect(asyncSeen, ['custom:12-34']);
    });

    testWidgets('without a builder the mask extraction is used everywhere', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final changed = <String>[];
      final saved = <String?>[];
      final asyncSeen = <String>[];
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.text(
              inputMask: '##-##',
              onRawChanged: changed.add,
              onRawSaved: saved.add,
              asyncValidation: SmartAsyncValidation(
                debounceDuration: Duration.zero,
                validator: (value) async {
                  asyncSeen.add(value);
                  return null;
                },
              ),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), '1234');
      await tester.pump();
      formKey.currentState!.save();
      expect(changed.last, '1234');
      expect(saved.last, '1234');
      expect(asyncSeen, ['1234']);
    });

    testWidgets('the mask still validates completeness with a builder', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.text(
              inputMask: '##-##',
              rawValueBuilder: (text) => 'custom',
              inputMaskErrorText: 'Finish it',
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), '12');
      await tester.pump();
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Finish it'), findsOneWidget);
    });
  });
}
