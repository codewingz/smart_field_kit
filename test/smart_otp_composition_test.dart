import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

Future<void> _composing(WidgetTester tester, String text) async {
  tester.testTextInput.updateEditingValue(
    TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
      composing: TextRange(start: 0, end: text.length),
    ),
  );
  await tester.pump();
}

Future<void> _commit(WidgetTester tester, String text) async {
  tester.testTextInput.updateEditingValue(
    TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    ),
  );
  await tester.pump();
}

void main() {
  group('OTP composition', () {
    testWidgets('committing unchanged composing text notifies once', (
      tester,
    ) async {
      final changes = <String>[];
      final completed = <String>[];
      await tester.pumpWidget(
        _app(
          SmartField.otp(
            length: 4,
            onChanged: changes.add,
            onCompleted: completed.add,
          ),
        ),
      );
      await tester.showKeyboard(find.byType(EditableText));
      await _composing(tester, '1234');
      expect(changes, isEmpty);
      expect(completed, isEmpty);
      await _commit(tester, '1234');
      expect(changes, ['1234']);
      expect(completed, ['1234']);
    });

    testWidgets('partial composing text commits as one change', (tester) async {
      final changes = <String>[];
      final completed = <String>[];
      await tester.pumpWidget(
        _app(
          SmartField.otp(
            length: 4,
            onChanged: changes.add,
            onCompleted: completed.add,
          ),
        ),
      );
      await tester.showKeyboard(find.byType(EditableText));
      await _composing(tester, '1');
      await _composing(tester, '12');
      await _commit(tester, '12');
      expect(changes, ['12']);
      expect(completed, isEmpty);
    });

    testWidgets('a commit that changes the text still notifies once', (
      tester,
    ) async {
      final changes = <String>[];
      final completed = <String>[];
      await tester.pumpWidget(
        _app(
          SmartField.otp(
            length: 4,
            onChanged: changes.add,
            onCompleted: completed.add,
          ),
        ),
      );
      await tester.showKeyboard(find.byType(EditableText));
      await _composing(tester, '123');
      await _commit(tester, '1234');
      expect(changes, ['1234']);
      expect(completed, ['1234']);
    });

    testWidgets('backspacing after a commit notifies the new value only', (
      tester,
    ) async {
      final changes = <String>[];
      final completed = <String>[];
      await tester.pumpWidget(
        _app(
          SmartField.otp(
            length: 4,
            onChanged: changes.add,
            onCompleted: completed.add,
          ),
        ),
      );
      await tester.showKeyboard(find.byType(EditableText));
      await _composing(tester, '1234');
      await _commit(tester, '1234');
      await _commit(tester, '123');
      expect(changes, ['1234', '123']);
      expect(completed, ['1234']);
      await _commit(tester, '1234');
      expect(completed, ['1234', '1234']);
    });

    testWidgets('autofill-style full entry still completes once', (
      tester,
    ) async {
      final completed = <String>[];
      await tester.pumpWidget(
        _app(SmartField.otp(length: 6, onCompleted: completed.add)),
      );
      await tester.enterText(find.byType(EditableText), '123456');
      await tester.pump();
      expect(completed, ['123456']);
    });

    testWidgets('programmatic changes stay silent by default', (tester) async {
      final controller = TextEditingController();
      final changes = <String>[];
      final completed = <String>[];
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.otp(
            controller: controller,
            length: 4,
            onChanged: changes.add,
            onCompleted: completed.add,
          ),
        ),
      );
      controller.text = '4321';
      await tester.pump();
      expect(changes, isEmpty);
      expect(completed, isEmpty);
    });

    testWidgets('a disabled field never notifies', (tester) async {
      final changes = <String>[];
      await tester.pumpWidget(
        _app(SmartField.otp(length: 4, enabled: false, onChanged: changes.add)),
      );
      await tester.enterText(find.byType(EditableText), '1234');
      await tester.pump();
      expect(changes, isEmpty);
    });

    testWidgets('a replaced controller keeps notifying exactly once', (
      tester,
    ) async {
      final first = TextEditingController();
      final second = TextEditingController();
      final changes = <String>[];
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      Widget build(TextEditingController controller) => _app(
        SmartField.otp(
          controller: controller,
          length: 4,
          onChanged: changes.add,
        ),
      );
      await tester.pumpWidget(build(first));
      await tester.pumpWidget(build(second));
      await tester.showKeyboard(find.byType(EditableText));
      await _composing(tester, '12');
      await _commit(tester, '12');
      expect(changes, ['12']);
      expect(second.text, '12');
      expect(first.text, isEmpty);
    });
  });
}
