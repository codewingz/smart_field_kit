import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child) {
  return MaterialApp(
    restorationScopeId: 'app',
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}

String? _error(WidgetTester tester, [int index = 0]) {
  final state = tester.state<FormFieldState<String>>(
    find.byType(TextFormField).at(index),
  );
  state.validate();
  return state.errorText;
}

void main() {
  group('validation modes', () {
    testWidgets('built-in only ignores the developer validator', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'a@example.com');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.email(
            controller: controller,
            validationMode: SmartValidationMode.builtIn,
            validator: (_) => 'Custom',
          ),
        ),
      );
      expect(_error(tester), isNull);
      controller.text = 'nope';
      expect(_error(tester), 'Enter a valid email address.');
    });

    testWidgets('custom only skips built-in format but keeps opt-in limits', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'not an email');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.email(
            controller: controller,
            validationMode: SmartValidationMode.custom,
            maxLength: 20,
            maxLengthErrorText: 'Too long',
            validator: (value) => value!.contains(' ') ? 'No spaces' : null,
          ),
        ),
      );
      expect(_error(tester), 'No spaces');
      controller.text = 'x' * 25;
      expect(_error(tester), 'Too long');
      controller.text = 'fine';
      expect(_error(tester), isNull);
    });

    testWidgets('both runs built-in then custom (default)', (tester) async {
      final controller = TextEditingController(text: 'nope');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.email(controller: controller, validator: (_) => 'Custom'),
        ),
      );
      expect(_error(tester), 'Enter a valid email address.');
      controller.text = 'a@example.com';
      expect(_error(tester), 'Custom');
    });

    testWidgets('selected checks run only the chosen password rules', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.password(
            controller: controller,
            policy: SmartPasswordPolicy.strong,
            validationMode: SmartValidationMode.selected,
            builtInChecks: const {
              SmartBuiltInCheck.passwordDigit,
              SmartBuiltInCheck.passwordUppercase,
            },
            validator: (value) =>
                value!.contains('password') ? 'Too common' : null,
          ),
        ),
      );
      controller.text = 'abc';
      expect(_error(tester), 'Include an uppercase letter.');
      controller.text = 'Abc';
      expect(_error(tester), 'Include a digit.');
      controller.text = 'abc1';
      expect(_error(tester), 'Include an uppercase letter.');
      controller.text = 'Abc1';
      expect(_error(tester), isNull);
      controller.text = 'password-A1';
      expect(_error(tester), 'Too common');
    });

    testWidgets('selected mode without fieldFormat skips the field rule', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'nope');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.email(
            controller: controller,
            validationMode: SmartValidationMode.selected,
          ),
        ),
      );
      expect(_error(tester), isNull);
    });

    testWidgets('required and limits stay opt-in and ordered', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(SmartField.email(controller: controller)));
      expect(_error(tester), isNull);
    });
  });

  group('password matching', () {
    testWidgets('confirmation revalidates on programmatic change and reset', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final password = TextEditingController();
      final confirm = TextEditingController();
      addTearDown(password.dispose);
      addTearDown(confirm.dispose);
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: Column(
              children: [
                SmartField.password(controller: password, label: 'Password'),
                SmartField.password(
                  controller: confirm,
                  label: 'Confirm',
                  matchController: password,
                  mismatchErrorText: 'Must match',
                ),
              ],
            ),
          ),
        ),
      );
      password.text = 'secret1';
      await tester.pump();
      expect(find.text('Must match'), findsNothing);
      confirm.text = 'secret1';
      expect(formKey.currentState!.validate(), isTrue);
      password.text = 'secret2';
      await tester.pump();
      expect(find.text('Must match'), findsOneWidget);
      password.text = 'secret1';
      await tester.pump();
      expect(find.text('Must match'), findsNothing);
      confirm.text = 'other';
      expect(formKey.currentState!.validate(), isFalse);
      formKey.currentState!.reset();
      await tester.pump();
      expect(formKey.currentState!.validate(), isTrue);
      expect(find.text('Must match'), findsNothing);
    });

    test('matches validator utility', () {
      final validator = SmartValidators.matches(() => 'abc', message: 'no');
      expect(validator(''), isNull);
      expect(validator('abc'), isNull);
      expect(validator('abd'), 'no');
    });
  });

  group('server errors', () {
    testWidgets('shows exact text through normal error UI and clears on edit', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final server = SmartServerError();
      addTearDown(server.dispose);
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.email(serverError: server),
          ),
        ),
      );
      server.set('Email already registered');
      await tester.pump();
      expect(find.text('Email already registered'), findsOneWidget);
      expect(formKey.currentState!.validate(), isFalse);
      await tester.enterText(find.byType(TextFormField), 'b@example.com');
      await tester.pump();
      expect(find.text('Email already registered'), findsNothing);
      expect(server.hasError, isFalse);
      expect(formKey.currentState!.validate(), isTrue);
    });

    testWidgets('can persist across edits when clearOnChange is false', (
      tester,
    ) async {
      final server = SmartServerError(clearOnChange: false);
      addTearDown(server.dispose);
      await tester.pumpWidget(_app(SmartField(serverError: server)));
      server.set('Payment declined');
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), 'x');
      await tester.pump();
      expect(find.text('Payment declined'), findsOneWidget);
      server.clear();
      await tester.pump();
      expect(find.text('Payment declined'), findsNothing);
    });

    testWidgets('old tracked responses never replace newer state', (
      tester,
    ) async {
      final server = SmartServerError();
      addTearDown(server.dispose);
      final first = Completer<String?>();
      final second = Completer<String?>();
      final firstApplied = server.track(first.future);
      final secondApplied = server.track(second.future);
      second.complete('New error');
      expect(await secondApplied, isTrue);
      first.complete('Old error');
      expect(await firstApplied, isFalse);
      expect(server.errorText, 'New error');
      final third = Completer<String?>();
      final thirdApplied = server.track(third.future);
      server.clear();
      third.complete('Late');
      expect(await thirdApplied, isFalse);
      expect(server.errorText, isNull);
    });

    testWidgets('works for otp and phone with accessible error text', (
      tester,
    ) async {
      final server = SmartServerError();
      addTearDown(server.dispose);
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              SmartField.otp(serverError: server),
              SmartField.phone(serverError: server),
            ],
          ),
        ),
      );
      server.set('Invalid verification code');
      await tester.pump();
      expect(find.text('Invalid verification code'), findsNWidgets(2));
    });
  });

  group('state restoration', () {
    testWidgets('restores nonsensitive text after the screen is recreated', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              SmartField.name(restorationId: 'name'),
              SmartField.email(restorationId: 'email'),
              SmartField.description(restorationId: 'about'),
              SmartField.password(restorationId: 'pw'),
            ],
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField).at(0), 'Zoë');
      await tester.enterText(find.byType(TextFormField).at(1), 'z@example.com');
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'line one\nline two',
      );
      await tester.enterText(find.byType(TextFormField).at(3), 'hunter2');
      await tester.pump();
      await tester.restartAndRestore();
      String textAt(int i) => tester
          .widget<EditableText>(find.byType(EditableText).at(i))
          .controller
          .text;
      expect(textAt(0), 'Zoë');
      expect(textAt(1), 'z@example.com');
      expect(textAt(2), 'line one\nline two');
      expect(textAt(3), isEmpty);
    });

    testWidgets('otp is never restored', (tester) async {
      await tester.pumpWidget(_app(SmartField.otp(restorationId: 'otp')));
      await tester.enterText(find.byType(EditableText), '123456');
      await tester.pump();
      await tester.restartAndRestore();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        isEmpty,
      );
    });
  });
}
