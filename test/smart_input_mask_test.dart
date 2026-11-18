import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

TextEditingValue _edit(
  SmartMaskFormatter formatter,
  String oldText,
  String newText, {
  int? caret,
  int? base,
}) {
  return formatter.formatEditUpdate(
    TextEditingValue(
      text: oldText,
      selection: TextSelection.collapsed(offset: oldText.length),
    ),
    TextEditingValue(
      text: newText,
      selection: base == null
          ? TextSelection.collapsed(offset: caret ?? newText.length)
          : TextSelection(
              baseOffset: base,
              extentOffset: caret ?? newText.length,
            ),
    ),
  );
}

void main() {
  group('SmartInputMask', () {
    test('digits mask applies and extracts raw values', () {
      final mask = SmartInputMask('####-####');
      expect(mask.capacity, 8);
      expect(mask.display('1'), '1');
      expect(mask.display('1234'), '1234');
      expect(mask.display('12345'), '1234-5');
      expect(mask.display('12345678'), '1234-5678');
      expect(mask.extractRaw('1234-5678'), '12345678');
      expect(mask.extractRaw('1234-56'), '123456');
      expect(mask.extractRaw('12345678'), '12345678');
      expect(mask.extractRaw('12a4'), isNull);
      expect(mask.extractRaw('1234-56789'), isNull);
      expect(mask.isComplete('12345678'), isTrue);
      expect(mask.isComplete('1234'), isFalse);
    });

    test('letter and alphanumeric slots including unicode', () {
      final mask = SmartInputMask('AAA-####');
      expect(mask.extractRaw('abc-1234'), 'abc1234');
      expect(mask.extractRaw('ab1-1234'), isNull);
      expect(mask.extractRaw('äöü-1234'), 'äöü1234');
      final alnum = SmartInputMask('**-**');
      expect(alnum.extractRaw('a1-b2'), 'a1b2');
      expect(alnum.extractRaw('a!-b2'), isNull);
    });

    test('literal prefix and escaped literals', () {
      final phone = SmartInputMask('(###) ###');
      expect(phone.display('12'), '(12');
      expect(phone.display('1234'), '(123) 4');
      expect(phone.extractRaw('(123) 456'), '123456');
      final escaped = SmartInputMask(r'\#####');
      expect(escaped.display('12'), '#12');
    });

    test('invalid patterns throw', () {
      expect(() => SmartInputMask('----'), throwsArgumentError);
    });

    test('acceptsRaw validates slots', () {
      final mask = SmartInputMask('##A');
      expect(mask.acceptsRaw('12a'), isTrue);
      expect(mask.acceptsRaw('1a'), isFalse);
      expect(mask.acceptsRaw('123a'), isFalse);
    });
  });

  group('SmartMaskFormatter', () {
    final formatter = SmartMaskFormatter(SmartInputMask('####-####'));

    test('typing inserts literals lazily and keeps the caret', () {
      expect(_edit(formatter, '123', '1234').text, '1234');
      final fifth = _edit(formatter, '1234', '12345');
      expect(fifth.text, '1234-5');
      expect(fifth.selection.baseOffset, 6);
    });

    test('paste of raw or formatted text', () {
      expect(_edit(formatter, '', '12345678').text, '1234-5678');
      expect(_edit(formatter, '', '1234-5678').text, '1234-5678');
      expect(_edit(formatter, '', '1234-56').text, '1234-56');
    });

    test('invalid characters and overflow reject the edit', () {
      expect(_edit(formatter, '12', '12a').text, '12');
      expect(_edit(formatter, '1234-5678', '1234-56789').text, '1234-5678');
    });

    test('backspace removes characters and the literal boundary', () {
      expect(_edit(formatter, '1234-5', '1234-').text, '1234');
      expect(_edit(formatter, '1234-56', '1234-5').text, '1234-5');
      final deleted = _edit(formatter, '1234-5', '12345', caret: 4);
      expect(deleted.text, '1235');
      expect(deleted.selection.baseOffset, 3);
    });

    test('middle edits keep the caret on the same raw character', () {
      final result = _edit(formatter, '1234-567', '12934-567', caret: 3);
      expect(result.text, '1293-4567');
      expect(result.selection.baseOffset, 3);
    });

    test('selection replacement and composing text', () {
      final replaced = _edit(
        formatter,
        '1234-5678',
        '1234-9',
        caret: 6,
        base: 5,
      );
      expect(replaced.text, '1234-9');
      final composing = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(
          text: 'ab',
          composing: TextRange(start: 0, end: 2),
        ),
      );
      expect(composing.text, 'ab');
    });
  });

  group('SmartField.text inputMask', () {
    Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

    testWidgets('display text and raw value stay separate', (tester) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      final raws = <String>[];
      String? savedRaw;
      String? savedDisplay;
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        app(
          Form(
            key: formKey,
            child: SmartField.text(
              controller: controller,
              inputMask: '####-####',
              inputMaskErrorText: 'Incomplete',
              onRawChanged: raws.add,
              onSaved: (value) => savedDisplay = value,
              onRawSaved: (value) => savedRaw = value,
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), '12345');
      expect(controller.text, '1234-5');
      expect(raws.last, '12345');
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Incomplete'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '12345678');
      expect(controller.text, '1234-5678');
      expect(formKey.currentState!.validate(), isTrue);
      formKey.currentState!.save();
      expect(savedDisplay, '1234-5678');
      expect(savedRaw, '12345678');
      await tester.enterText(find.byType(TextFormField), '');
      expect(formKey.currentState!.validate(), isTrue);
    });

    testWidgets('mask is optional and developer formatters still apply', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        app(
          SmartField.text(
            controller: controller,
            inputMask: 'AAA-####',
            textCase: SmartTextCase.uppercase,
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'abc1234');
      expect(controller.text, 'ABC-1234');
      await tester.enterText(find.byType(TextFormField), 'ab1');
      expect(controller.text, 'ABC-1234');
    });

    testWidgets('mask does not apply privacy masking to the controller', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        app(SmartField.text(controller: controller, inputMask: '####-####')),
      );
      await tester.enterText(find.byType(TextFormField), '12345678');
      expect(controller.text, '1234-5678');
      expect(controller.text, isNot(contains('*')));
    });
  });
}
