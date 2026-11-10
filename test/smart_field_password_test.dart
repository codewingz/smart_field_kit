import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  testWidgets('configures native password input behavior', (tester) async {
    await tester.pumpWidget(_app(SmartField.password(autofocus: true)));

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.keyboardType, TextInputType.visiblePassword);
    expect(field.autofillHints, contains(AutofillHints.password));
    expect(field.textCapitalization, TextCapitalization.none);
    expect(field.autocorrect, isFalse);
    expect(field.enableSuggestions, isFalse);
    expect(field.obscureText, isTrue);
    expect(field.autofocus, isTrue);
  });

  testWidgets('has no default policy or length restriction', (tester) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField.password(controller: controller),
        ),
      ),
    );

    expect(formKey.currentState!.validate(), isTrue);
    controller.text = 'x';
    expect(formKey.currentState!.validate(), isTrue);
  });

  testWidgets('supports weak and strong policies', (tester) async {
    final weakKey = GlobalKey<FormState>();
    final strongKey = GlobalKey<FormState>();
    final weakController = TextEditingController();
    final strongController = TextEditingController();
    addTearDown(weakController.dispose);
    addTearDown(strongController.dispose);

    await tester.pumpWidget(
      _app(
        Column(
          children: [
            Form(
              key: weakKey,
              child: SmartField.password(
                controller: weakController,
                policy: SmartPasswordPolicy.weak,
              ),
            ),
            Form(
              key: strongKey,
              child: SmartField.password(
                controller: strongController,
                policy: SmartPasswordPolicy.strong,
              ),
            ),
          ],
        ),
      ),
    );

    weakController.text = '1234';
    strongController.text = 'password';
    expect(weakKey.currentState!.validate(), isFalse);
    expect(strongKey.currentState!.validate(), isFalse);

    weakController.text = '12345';
    strongController.text = 'Abcdef1!';
    expect(weakKey.currentState!.validate(), isTrue);
    expect(strongKey.currentState!.validate(), isTrue);
  });

  testWidgets('validates required policy length custom order', (tester) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var customCalls = 0;

    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField.password(
            controller: controller,
            isRequired: true,
            requiredErrorText: 'Required error',
            policy: SmartPasswordPolicy.strong,
            passwordErrorText: 'Policy error',
            minLength: 10,
            minLengthErrorText: 'Length error',
            validator: (value) {
              customCalls++;
              return value == 'Abcdefgh1!' ? null : 'Custom error';
            },
          ),
        ),
      ),
    );

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Required error'), findsOneWidget);
    expect(customCalls, 0);

    controller.text = 'password';
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Policy error'), findsOneWidget);
    expect(customCalls, 0);

    controller.text = 'Abcdef1!';
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Length error'), findsOneWidget);
    expect(customCalls, 0);

    controller.text = 'Abcdefghi1!';
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Custom error'), findsOneWidget);
    expect(customCalls, 1);

    controller.text = 'Abcdefgh1!';
    expect(formKey.currentState!.validate(), isTrue);
    expect(customCalls, 2);
  });

  testWidgets(
    'preserves text selection controller and focus when toggled',
    skip: kIsWeb,
    (tester) async {
      final controller = TextEditingController(text: 'Abcdef1!');
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        _app(SmartField.password(controller: controller, focusNode: focusNode)),
      );

      focusNode.requestFocus();
      controller.selection = const TextSelection(
        baseOffset: 2,
        extentOffset: 6,
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();

      expect(controller.text, 'Abcdef1!');
      expect(
        controller.selection,
        const TextSelection(baseOffset: 2, extentOffset: 6),
      );
      expect(focusNode.hasFocus, isTrue);
      expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText,
        isFalse,
      );

      await tester.tap(find.byTooltip('Hide password'));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText,
        isTrue,
      );
    },
  );

  testWidgets('visibility control is accessible and can be disabled', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(_app(SmartField.password()));
    expect(find.byTooltip('Show password'), findsOneWidget);
    expect(find.bySemanticsLabel('Show password'), findsOneWidget);

    await tester.pumpWidget(
      _app(SmartField.password(showVisibilityToggle: false)),
    );
    expect(find.byTooltip('Show password'), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isTrue,
    );
    semantics.dispose();
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
          child: SmartField.password(
            controller: controller,
            policy: SmartPasswordPolicy.strong,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onChanged: (value) => changedValue = value,
            onSaved: (value) => savedValue = value,
          ),
        ),
      ),
    );

    const value = 'Abcdef1!';
    await tester.enterText(find.byType(TextFormField), value);
    expect(formKey.currentState!.validate(), isTrue);
    formKey.currentState!.save();

    expect(controller.text, value);
    expect(changedValue, value);
    expect(savedValue, value);
  });
}
