import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('dropdown date + controller + async + Form save agree', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: '15/03/2024');
    final async = SmartFieldAsyncController();
    final seen = <String>[];
    String? saved;
    String? raw;
    addTearDown(controller.dispose);
    addTearDown(async.dispose);
    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField.date(
            controller: controller,
            mode: SmartDateMode.dropdowns,
            firstYear: 2020,
            lastYear: 2030,
            onSaved: (v) => saved = v,
            onRawSaved: (v) => raw = v,
            asyncValidation: SmartAsyncValidation(
              controller: async,
              trigger: SmartAsyncValidationTrigger.manual,
              validator: (value) async {
                seen.add(value);
                return null;
              },
            ),
          ),
        ),
      ),
    );
    expect(await async.validateAsync(), isTrue);
    expect(formKey.currentState!.validate(), isTrue);
    formKey.currentState!.save();
    expect(seen, ['2024-03-15']);
    expect(saved, '15/03/2024');
    expect(raw, '2024-03-15');
    expect(controller.text, '15/03/2024');
  });

  testWidgets('picker field: keyboard open, Clear by tap, Form value follows', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final focus = FocusNode();
    final controller = TextEditingController(text: '15/03/2024');
    final saved = <String?>[];
    addTearDown(focus.dispose);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField.date(
            focusNode: focus,
            controller: controller,
            mode: SmartDateMode.calendar,
            showClearButton: true,
            onSaved: saved.add,
          ),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(controller.text, '15/03/2024');
    expect(focus.hasFocus, isTrue);
    await tester.tap(find.byTooltip('Clear'));
    await tester.pumpAndSettle();
    expect(controller.text, isEmpty);
    formKey.currentState!.save();
    expect(saved.last, anyOf(isNull, isEmpty));
  });

  testWidgets('masked amount keeps raw callbacks, errors and semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final server = SmartServerError();
    final raws = <String>[];
    addTearDown(server.dispose);
    await tester.pumpWidget(
      _app(
        SmartField.amount(
          decimalPlaces: 2,
          mask: true,
          serverError: server,
          onRawChanged: raws.add,
          decoration: const InputDecoration(labelText: 'Invoice total'),
        ),
      ),
    );
    await tester.enterText(find.byType(EditableText), '1234.5');
    await tester.pump();
    server.set('Amount rejected');
    await tester.pump();
    expect(raws.last, '1234.5');
    expect(find.bySemanticsLabel(RegExp('Invoice total')), findsWidgets);
    handle.dispose();
  });
}
