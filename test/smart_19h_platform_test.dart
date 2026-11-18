import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('URL undo and redo work through text intents', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(SmartField.url(controller: controller)));
    await tester.showKeyboard(find.byType(TextFormField));
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'https://a.com',
        selection: TextSelection.collapsed(offset: 13),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'https://a.com/x',
        selection: TextSelection.collapsed(offset: 15),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    final context = tester.element(
      find
          .descendant(
            of: find.byType(UndoHistory<TextEditingValue>),
            matching: find.byType(Focus),
          )
          .first,
    );
    Actions.invoke(
      context,
      const UndoTextIntent(SelectionChangedCause.keyboard),
    );
    await tester.pump();
    expect(controller.text, 'https://a.com');
    Actions.invoke(
      context,
      const RedoTextIntent(SelectionChangedCause.keyboard),
    );
    await tester.pump();
    expect(controller.text, 'https://a.com/x');
  });

  testWidgets('programmatic focus keeps text on every platform', (
    tester,
  ) async {
    final plain = TextEditingController(text: 'plain text')
      ..selection = const TextSelection.collapsed(offset: 3);
    final password = TextEditingController(text: 'Secret12')
      ..selection = const TextSelection.collapsed(offset: 3);
    final otp = TextEditingController(text: '123456')
      ..selection = const TextSelection.collapsed(offset: 3);
    final plainFocus = FocusNode();
    final passwordFocus = FocusNode();
    final otpFocus = FocusNode();
    for (final item in [plain, password, otp]) {
      addTearDown(item.dispose);
    }
    for (final item in [plainFocus, passwordFocus, otpFocus]) {
      addTearDown(item.dispose);
    }
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            TextField(controller: plain, focusNode: plainFocus),
            SmartField.password(controller: password, focusNode: passwordFocus),
            SmartField.otp(controller: otp, focusNode: otpFocus),
          ],
        ),
      ),
    );
    plainFocus.requestFocus();
    await tester.pump();
    final plainSelection = plain.selection;
    passwordFocus.requestFocus();
    await tester.pump();
    otpFocus.requestFocus();
    await tester.pump();
    expect(password.text, 'Secret12');
    expect(otp.text, '123456');
    expect(otpFocus.hasFocus, isTrue);
    final selectsAll = plainSelection.start == 0 && plainSelection.end == 10;
    expect(selectsAll, kIsWeb);
    expect(password.selection.isCollapsed, !selectsAll);
    expect(otp.selection.isCollapsed, !selectsAll);
  });
}
