import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

String _text(WidgetTester tester, int index) => tester
    .widget<EditableText>(find.byType(EditableText).at(index))
    .controller
    .text;

void main() {
  testWidgets('several SmartFields share one Form: validate, save, reset', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final saved = <String?>[];
    final raw = <String?>[];
    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: Column(
            children: [
              SmartField.name(isRequired: true, onSaved: saved.add),
              SmartField.email(isRequired: true, onSaved: saved.add),
              SmartField.amount(
                decimalLength: 2,
                useGrouping: true,
                onSaved: saved.add,
                onRawSaved: raw.add,
              ),
            ],
          ),
        ),
      ),
    );
    expect(formKey.currentState!.validate(), isFalse);
    await tester.enterText(find.byType(EditableText).at(0), 'Zoë');
    await tester.enterText(find.byType(EditableText).at(1), 'z@example.com');
    await tester.enterText(find.byType(EditableText).at(2), '50000.00');
    await tester.pump();
    expect(formKey.currentState!.validate(), isTrue);
    formKey.currentState!.save();
    expect(saved.take(2), ['Zoë', 'z@example.com']);
    expect(raw, ['50000.00']);
    formKey.currentState!.reset();
    await tester.pump();
    expect(_text(tester, 0), isEmpty);
    expect(_text(tester, 1), isEmpty);
    expect(_text(tester, 2), isEmpty);
  });

  testWidgets('removing a field while its async check is pending is safe', (
    tester,
  ) async {
    final pending = Completer<String?>();
    final async = SmartFieldAsyncController();
    addTearDown(async.dispose);
    await tester.pumpWidget(
      _app(
        SmartField(
          asyncValidation: SmartAsyncValidation(
            controller: async,
            debounceDuration: Duration.zero,
            validator: (value) => pending.future,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(EditableText), 'abc');
    await tester.pump();
    expect(async.status, SmartAsyncValidationStatus.pending);
    await tester.pumpWidget(_app(const SizedBox()));
    pending.complete('Too late');
    await tester.pump();
    expect(async.status, SmartAsyncValidationStatus.idle);
    expect(async.errorText, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('focus moving during amount editing keeps raw value stable', (
    tester,
  ) async {
    final focus = FocusNode();
    final raws = <String>[];
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            SmartField.amount(
              focusNode: focus,
              decimalLength: 2,
              useGrouping: true,
              onRawChanged: raws.add,
            ),
            const SmartField(label: 'other'),
          ],
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    await tester.enterText(find.byType(EditableText).at(0), '1234567.5');
    await tester.pump();
    expect(raws.last, '1234567.5');
    await tester.tap(find.byType(EditableText).at(1));
    await tester.pump();
    expect(_text(tester, 0), '1,234,567.50');
    expect(focus.hasFocus, isFalse);
    focus.requestFocus();
    await tester.pump();
    expect(_text(tester, 0), '1234567.50');
    expect(raws.last, '1234567.5');
  });

  testWidgets('the same constructor keeps working after a config update', (
    tester,
  ) async {
    final changes = <String>[];
    Widget build({required bool required}) => _app(
      Form(
        autovalidateMode: AutovalidateMode.always,
        child: SmartField.email(
          isRequired: required,
          onChanged: changes.add,
          requiredErrorText: required ? 'Needed' : 'unused',
        ),
      ),
    );
    await tester.pumpWidget(build(required: false));
    await tester.enterText(find.byType(EditableText), 'a@b.co');
    await tester.pump();
    await tester.pumpWidget(build(required: true));
    await tester.enterText(find.byType(EditableText), '');
    await tester.pump();
    expect(find.text('Needed'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'again@example.com');
    await tester.pump();
    expect(find.text('Needed'), findsNothing);
    expect(changes, ['a@b.co', '', 'again@example.com']);
  });

  testWidgets('an uncontrolled field becomes controlled without losing text', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    String? saved;
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    Widget build(TextEditingController? c) => _app(
      Form(
        key: formKey,
        child: SmartField(controller: c, onSaved: (v) => saved = v),
      ),
    );
    await tester.pumpWidget(build(null));
    await tester.enterText(find.byType(EditableText), 'draft');
    await tester.pump();
    controller.text = 'draft';
    await tester.pumpWidget(build(controller));
    expect(_text(tester, 0), 'draft');
    formKey.currentState!.save();
    expect(saved, 'draft');
  });
}
