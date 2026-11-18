import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(
  Widget child, {
  Size? size,
  double scale = 1,
  TextDirection? direction,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        textScaler: TextScaler.linear(scale),
        size: size ?? const Size(800, 600),
      ),
      child: Directionality(
        textDirection: direction ?? TextDirection.ltr,
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
}

String _text(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText)).controller.text;

void main() {
  group('O01 supported lengths', () {
    for (final length in [4, 6, 8]) {
      testWidgets('$length digits render and complete once', (tester) async {
        final completed = <String>[];
        await tester.pumpWidget(
          _app(SmartField.otp(length: length, onCompleted: completed.add)),
        );
        expect(find.byType(AnimatedContainer), findsNWidgets(length));
        final code = '1234567890'.substring(0, length);
        await tester.enterText(find.byType(EditableText), code);
        await tester.pump();
        expect(completed, [code]);
        expect(_text(tester), code);
      });
    }
  });

  testWidgets('O02 leading zeros are preserved as text', (tester) async {
    final changes = <String>[];
    final formKey = GlobalKey<FormState>();
    String? saved;
    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField.otp(
            onChanged: changes.add,
            onSaved: (value) => saved = value,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(EditableText), '000123');
    await tester.pump();
    expect(changes.last, '000123');
    formKey.currentState!.save();
    expect(saved, '000123');
  });

  testWidgets('O03 incomplete and wrong-length codes fail validation', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField.otp(otpLengthErrorText: 'Six digits needed'),
        ),
      ),
    );
    expect(formKey.currentState!.validate(), isTrue);
    await tester.enterText(find.byType(EditableText), '123');
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Six digits needed'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), '1234567');
    expect(_text(tester), '123456');
    await tester.enterText(find.byType(EditableText), '123456');
    expect(formKey.currentState!.validate(), isTrue);
  });

  testWidgets('O04 full paste, malformed paste, and unicode digits', (
    tester,
  ) async {
    final completed = <String>[];
    await tester.pumpWidget(_app(SmartField.otp(onCompleted: completed.add)));
    await tester.enterText(find.byType(EditableText), '12a456');
    expect(_text(tester), isEmpty);
    await tester.enterText(find.byType(EditableText), '１２３４５６');
    expect(_text(tester), isEmpty);
    await tester.enterText(find.byType(EditableText), '123 456');
    expect(_text(tester), '123456');
    await tester.enterText(find.byType(EditableText), '');
    await tester.enterText(find.byType(EditableText), '987-654');
    expect(_text(tester), '987654');
    await tester.enterText(find.byType(EditableText), '');
    await tester.enterText(find.byType(EditableText), '12345678');
    expect(_text(tester), '123456');
    await tester.pump();
    expect(completed, ['123456', '987654', '123456']);
  });

  testWidgets('O05 rapid editing fires one completion per transition', (
    tester,
  ) async {
    final completed = <String>[];
    await tester.pumpWidget(_app(SmartField.otp(onCompleted: completed.add)));
    for (final value in [
      '1',
      '12',
      '123',
      '1234',
      '12345',
      '123456',
      '12345',
      '123456',
      '123450',
    ]) {
      await tester.enterText(find.byType(EditableText), value);
    }
    await tester.pump();
    expect(completed, ['123456', '123456', '123450']);
  });

  testWidgets('O06 backspace and middle edits keep focus and caret', (
    tester,
  ) async {
    final controller = TextEditingController(text: '123456');
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(SmartField.otp(controller: controller)));
    await tester.showKeyboard(find.byType(EditableText));
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '12456',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    await tester.pump();
    expect(controller.text, '12456');
    expect(controller.selection, const TextSelection.collapsed(offset: 2));
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '123456',
        selection: TextSelection.collapsed(offset: 3),
      ),
    );
    await tester.pump();
    expect(controller.text, '123456');
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.focusNode.hasFocus, isTrue);
  });

  testWidgets('O07 programmatic changes, reset, and disposal', (tester) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final completed = <String>[];
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField.otp(
            controller: controller,
            onCompleted: completed.add,
          ),
        ),
      ),
    );
    controller.text = '654321';
    await tester.pump();
    expect(completed, isEmpty);
    formKey.currentState!.reset();
    await tester.pump();
    expect(controller.text, isEmpty);
    await tester.enterText(find.byType(EditableText), '111111');
    await tester.pump();
    expect(completed, ['111111']);
    await tester.pumpWidget(const SizedBox());
    controller.text = '000000';
    expect(controller.text, '000000');
    expect(tester.takeException(), isNull);
  });

  testWidgets('O08 enabled, disabled, and read-only states', (tester) async {
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            SmartField.otp(label: 'on'),
            SmartField.otp(label: 'off', enabled: false),
            SmartField.otp(label: 'ro', readOnly: true),
          ],
        ),
      ),
    );
    final inputs = tester
        .widgetList<EditableText>(find.byType(EditableText))
        .toList();
    expect(inputs[0].readOnly, isFalse);
    expect(inputs[2].readOnly, isTrue);
    await tester.tap(find.byType(EditableText).at(1), warnIfMissed: false);
    await tester.pump();
    expect(inputs[1].focusNode.hasFocus, isFalse);
  });

  testWidgets('O09 server messages, resend, and stale responses', (
    tester,
  ) async {
    final server = SmartServerError();
    addTearDown(server.dispose);
    await tester.pumpWidget(_app(SmartField.otp(serverError: server)));
    await tester.enterText(find.byType(EditableText), '111111');
    server.set('Invalid verification code');
    await tester.pump();
    expect(find.text('Invalid verification code'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), '22222');
    await tester.pump();
    expect(find.text('Invalid verification code'), findsNothing);

    final oldResponse = Completer<String?>();
    final newResponse = Completer<String?>();
    final oldApplied = server.track(oldResponse.future);
    final newApplied = server.track(newResponse.future);
    newResponse.complete('Code expired');
    expect(await newApplied, isTrue);
    oldResponse.complete('Invalid verification code');
    expect(await oldApplied, isFalse);
    await tester.pump();
    expect(find.text('Code expired'), findsOneWidget);
    expect(find.text('Invalid verification code'), findsNothing);
  });

  testWidgets('O10 async verification ignores a stale old code', (
    tester,
  ) async {
    final async = SmartFieldAsyncController();
    addTearDown(async.dispose);
    final responses = <String, Completer<String?>>{};
    await tester.pumpWidget(
      _app(
        SmartField.otp(
          asyncValidation: SmartAsyncValidation(
            controller: async,
            debounceDuration: Duration.zero,
            validator: (value) {
              final completer = Completer<String?>();
              responses[value] = completer;
              return completer.future;
            },
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(EditableText), '111111');
    await tester.pump();
    await tester.enterText(find.byType(EditableText), '222222');
    await tester.pump();
    responses['222222']!.complete(null);
    await tester.pump();
    expect(async.status, SmartAsyncValidationStatus.valid);
    responses['111111']!.complete('Wrong code');
    await tester.pump();
    expect(async.status, SmartAsyncValidationStatus.valid);
    expect(find.text('Wrong code'), findsNothing);
  });

  testWidgets('O11 autofill hint, obscuring, semantics, and layouts', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        SmartField.otp(label: 'Verification code', obscureText: true),
        size: const Size(220, 700),
        scale: 2,
        direction: TextDirection.rtl,
      ),
    );
    final input = tester.widget<EditableText>(find.byType(EditableText));
    expect(input.autofillHints, const [AutofillHints.oneTimeCode]);
    await tester.enterText(find.byType(EditableText), '123456');
    await tester.pump();
    expect(find.bySemanticsLabel(RegExp('Verification code')), findsWidgets);
    expect(find.bySemanticsLabel(RegExp('123456')), findsNothing);
    expect(tester.takeException(), isNull);
    handle.dispose();
  });

  testWidgets('O12 nothing is printed while typing a code', (tester) async {
    final printed = <String>[];
    final original = debugPrint;
    debugPrint = (message, {wrapWidth}) => printed.add(message ?? '');
    await tester.pumpWidget(_app(SmartField.otp()));
    await tester.enterText(find.byType(EditableText), '482915');
    await tester.pump();
    debugPrint = original;
    expect(printed.where((line) => line.contains('482915')), isEmpty);
  });

  test(
    'O13 the package does not read SMS or WhatsApp',
    skip: kIsWeb
        ? 'Reads project files through dart:io, which is unavailable in a browser.'
        : null,
    () {
      final manifest = File(
        'example/android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      expect(manifest, isNot(contains('READ_SMS')));
      expect(manifest, isNot(contains('RECEIVE_SMS')));
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, isNot(contains('sms_autofill')));
      expect(pubspec, isNot(contains('telephony')));
      expect(pubspec, isNot(contains('permission_handler')));
    },
  );
}
