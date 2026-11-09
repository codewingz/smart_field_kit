import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

EditableText _field(WidgetTester tester, int index) =>
    tester.widget<EditableText>(find.byType(EditableText).at(index));

void main() {
  testWidgets('a concealed CVV is hidden but not classified as a password', (
    tester,
  ) async {
    await tester.pumpWidget(_app(SmartField.creditCard()));
    final cvv = _field(tester, 2);
    expect(cvv.obscureText, isTrue);
    expect(cvv.autofillHints, const [AutofillHints.creditCardSecurityCode]);
    expect(cvv.autocorrect, isFalse);
    expect(cvv.enableSuggestions, isFalse);
  });

  testWidgets('the visible CVV variant keeps the same hint', (tester) async {
    await tester.pumpWidget(_app(SmartField.creditCard(concealCvv: false)));
    final cvv = _field(tester, 2);
    expect(cvv.obscureText, isFalse);
    expect(cvv.autofillHints, const [AutofillHints.creditCardSecurityCode]);
  });

  testWidgets('number and expiry hints are unchanged', (tester) async {
    await tester.pumpWidget(_app(SmartField.creditCard()));
    expect(_field(tester, 0).autofillHints, const [
      AutofillHints.creditCardNumber,
    ]);
    expect(_field(tester, 1).autofillHints, const [
      AutofillHints.creditCardExpirationDate,
    ]);
  });

  testWidgets('real password fields keep the password hint', (tester) async {
    await tester.pumpWidget(_app(SmartField.password()));
    expect(_field(tester, 0).autofillHints, const [AutofillHints.password]);
  });

  testWidgets('the CVV toggle, validation and brand length checks still work', (
    tester,
  ) async {
    final values = <SmartCreditCardValue>[];
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField.creditCard(
            now: () => DateTime(2024, 6, 15),
            onChanged: values.add,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(EditableText).at(0), '4111111111111111');
    await tester.enterText(find.byType(EditableText).at(1), '1229');
    await tester.enterText(find.byType(EditableText).at(2), '123');
    await tester.pump();
    expect(values.last.cvv, '123');
    expect(formKey.currentState!.validate(), isTrue);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(_field(tester, 2).obscureText, isFalse);
  });

  testWidgets('the CVV is never printed or restored', (tester) async {
    final printed = <String>[];
    final original = debugPrint;
    debugPrint = (message, {wrapWidth}) => printed.add(message ?? '');
    await tester.pumpWidget(
      MaterialApp(
        restorationScopeId: 'app',
        home: Scaffold(
          body: SingleChildScrollView(child: SmartField.creditCard()),
        ),
      ),
    );
    await tester.enterText(find.byType(EditableText).at(2), '987');
    await tester.pump();
    await tester.restartAndRestore();
    debugPrint = original;
    expect(_field(tester, 2).controller.text, isEmpty);
    expect(printed.where((line) => line.contains('987')), isEmpty);
  });
}
