import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  testWidgets('configures native email input behavior', (tester) async {
    await tester.pumpWidget(_app(SmartField.email(autofocus: true)));

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.keyboardType, TextInputType.emailAddress);
    expect(field.autofillHints, contains(AutofillHints.email));
    expect(field.textCapitalization, TextCapitalization.none);
    expect(field.autocorrect, isFalse);
    expect(field.autofocus, isTrue);
  });

  testWidgets('supports standard and legacy email policies', (tester) async {
    final standardKey = GlobalKey<FormState>();
    final legacyKey = GlobalKey<FormState>();
    final standardController = TextEditingController();
    final legacyController = TextEditingController();
    addTearDown(standardController.dispose);
    addTearDown(legacyController.dispose);

    await tester.pumpWidget(
      _app(
        Column(
          children: [
            Form(
              key: standardKey,
              child: SmartField.email(controller: standardController),
            ),
            Form(
              key: legacyKey,
              child: SmartField.email(
                controller: legacyController,
                policy: SmartEmailPolicy.legacy,
              ),
            ),
          ],
        ),
      ),
    );

    standardController.text = 'user@sub.example.co.uk';
    legacyController.text = 'user@sub.example.co.uk';
    expect(standardKey.currentState!.validate(), isTrue);
    expect(legacyKey.currentState!.validate(), isFalse);

    legacyController.text = 'name+tag@example.com';
    expect(legacyKey.currentState!.validate(), isTrue);
  });

  testWidgets('supports optional and required empty email fields', (
    tester,
  ) async {
    final optionalKey = GlobalKey<FormState>();
    final requiredKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      _app(
        Column(
          children: [
            Form(key: optionalKey, child: SmartField.email()),
            Form(
              key: requiredKey,
              child: SmartField.email(
                isRequired: true,
                requiredErrorText: 'Email required',
              ),
            ),
          ],
        ),
      ),
    );

    expect(optionalKey.currentState!.validate(), isTrue);
    expect(requiredKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Email required'), findsOneWidget);
  });

  testWidgets('validates required email length custom order', (tester) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var customCalls = 0;

    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField.email(
            controller: controller,
            isRequired: true,
            requiredErrorText: 'Required error',
            emailErrorText: 'Email error',
            minLength: 10,
            minLengthErrorText: 'Length error',
            validator: (value) {
              customCalls++;
              return value == 'valid@example.com' ? null : 'Custom error';
            },
          ),
        ),
      ),
    );

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Required error'), findsOneWidget);
    expect(customCalls, 0);

    controller.text = 'bad';
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Email error'), findsOneWidget);
    expect(customCalls, 0);

    controller.text = 'a@b.co';
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Length error'), findsOneWidget);
    expect(customCalls, 0);

    controller.text = 'other@example.com';
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Custom error'), findsOneWidget);
    expect(customCalls, 1);

    controller.text = 'valid@example.com';
    expect(formKey.currentState!.validate(), isTrue);
    expect(customCalls, 2);
  });

  testWidgets('preserves callbacks Form behavior and original value', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    String? changedValue;
    String? savedValue;

    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField.email(
            controller: controller,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onChanged: (value) => changedValue = value,
            onSaved: (value) => savedValue = value,
          ),
        ),
      ),
    );

    const value = 'Name+Tag@Example.com';
    await tester.enterText(find.byType(TextFormField), value);
    expect(formKey.currentState!.validate(), isTrue);
    formKey.currentState!.save();

    expect(controller.text, value);
    expect(changedValue, value);
    expect(savedValue, value);

    const spacedValue = ' Name+Tag@Example.com ';
    await tester.enterText(find.byType(TextFormField), spacedValue);
    expect(formKey.currentState!.validate(), isFalse);
    expect(controller.text, spacedValue);
  });
}
