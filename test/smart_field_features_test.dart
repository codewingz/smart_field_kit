import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';
import 'support/masked_prefix.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  _strengthAndMaskIndependent();
  _maskFeatureTests();
  _asyncFeatureTests();
  testWidgets('switching field kinds keeps the developer controller alive', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'abc');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    final kinds = <SmartField>[
      SmartField.phone(controller: controller, focusNode: focusNode),
      SmartField.search(controller: controller, focusNode: focusNode),
      SmartField.amount(controller: controller, focusNode: focusNode),
      SmartField.password(controller: controller, focusNode: focusNode),
      SmartField.text(controller: controller, focusNode: focusNode),
    ];
    for (final kind in kinds) {
      await tester.pumpWidget(_app(kind));
      await tester.pump();
    }
    await tester.pumpWidget(const SizedBox());
    controller.text = 'still usable';
    focusNode.requestFocus();
    expect(controller.text, 'still usable');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'password visibility survives rebuilds and resets on kind change',
    (tester) async {
      await tester.pumpWidget(_app(SmartField.password()));
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      await tester.pumpWidget(_app(SmartField.password(label: 'Changed')));
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      await tester.pumpWidget(_app(SmartField.text()));
      expect(find.byIcon(Icons.visibility_off), findsNothing);
      expect(find.byIcon(Icons.visibility), findsNothing);
    },
  );

  testWidgets('async validation can be attached and removed at runtime', (
    tester,
  ) async {
    final async = SmartFieldAsyncController();
    addTearDown(async.dispose);
    final completer = Completer<String?>();
    await tester.pumpWidget(_app(SmartField.text()));
    await tester.pumpWidget(
      _app(
        SmartField.text(
          asyncValidation: SmartAsyncValidation(
            controller: async,
            debounceDuration: Duration.zero,
            validator: (_) => completer.future,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'x');
    await tester.pump();
    await tester.pumpWidget(_app(SmartField.text()));
    completer.complete(null);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('search clear button empties the field and notifies once', (
    tester,
  ) async {
    final changes = <String>[];
    var cleared = 0;
    await tester.pumpWidget(
      _app(
        SmartField.search(onChanged: changes.add, onCleared: () => cleared++),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'milk');
    await tester.pump();
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();
    expect(changes.last, '');
    expect(cleared, 1);
    expect(find.byTooltip('Clear search'), findsNothing);
  });
}

void _strengthAndMaskIndependent() {
  testWidgets('password strength indicator renders without a mask', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(SmartField.password(showStrengthIndicator: true)),
    );
    await tester.enterText(find.byType(TextFormField), 'Abcdef1!');
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsWidgets);
  });

  testWidgets('masked number shows masked text and no strength indicator', (
    tester,
  ) async {
    await tester.pumpWidget(_app(SmartField.number(mask: true)));
    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(Column), findsNothing);
  });
}

TextField _textField(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField));

void _maskFeatureTests() {
  testWidgets('mask feature can be switched off and on while mounted', (
    tester,
  ) async {
    final controller = TextEditingController(text: '0012345678');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    Widget build(bool mask) => _app(
      SmartField.number(
        controller: controller,
        focusNode: focusNode,
        mask: mask,
      ),
    );
    await tester.pumpWidget(build(true));
    expect(maskedPrefixOf(_textField(tester).decoration), '******5678');
    await tester.pumpWidget(build(false));
    expect(maskedPrefixOf(_textField(tester).decoration), isNull);
    controller.text = '1';
    await tester.pump();
    await tester.pumpWidget(build(true));
    expect(maskedPrefixOf(_textField(tester).decoration), isNotNull);
    expect(controller.text, '1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('masked presentation never alters raw callbacks or saves', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final raws = <String>[];
    String? saved;
    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField.amount(
            mask: true,
            onRawChanged: raws.add,
            onRawSaved: (value) => saved = value,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), '9876543210');
    await tester.pump();
    formKey.currentState!.save();
    expect(raws.last, '9876543210');
    expect(saved, '9876543210');
  });

  testWidgets('masked field exposes masked value to semantics only', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final controller = TextEditingController(text: '0012345678');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        SmartField.number(label: 'Account', controller: controller, mask: true),
      ),
    );
    expect(find.bySemanticsLabel(RegExp('0012345678')), findsNothing);
    handle.dispose();
  });
}

void _asyncFeatureTests() {
  testWidgets('async validation ignores a stale result for an older value', (
    tester,
  ) async {
    final async = SmartFieldAsyncController();
    addTearDown(async.dispose);
    final responses = <String, Completer<String?>>{};
    await tester.pumpWidget(
      _app(
        SmartField.text(
          asyncValidation: SmartAsyncValidation(
            controller: async,
            debounceDuration: Duration.zero,
            validator: (value) =>
                (responses[value] = Completer<String?>()).future,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'old');
    await tester.pump();
    await tester.enterText(find.byType(TextFormField), 'new');
    await tester.pump();
    responses['new']!.complete(null);
    await tester.pump();
    expect(async.status, SmartAsyncValidationStatus.valid);
    responses['old']!.complete('Taken');
    await tester.pump();
    expect(async.status, SmartAsyncValidationStatus.valid);
    expect(find.text('Taken'), findsNothing);
  });

  testWidgets('async validation resets when the field becomes disabled', (
    tester,
  ) async {
    final async = SmartFieldAsyncController();
    addTearDown(async.dispose);
    final completer = Completer<String?>();
    Widget build(bool enabled) => _app(
      SmartField.text(
        enabled: enabled,
        asyncValidation: SmartAsyncValidation(
          controller: async,
          debounceDuration: Duration.zero,
          validator: (_) => completer.future,
        ),
      ),
    );
    await tester.pumpWidget(build(true));
    await tester.enterText(find.byType(TextFormField), 'abc');
    await tester.pump();
    expect(async.status, SmartAsyncValidationStatus.pending);
    await tester.pumpWidget(build(false));
    expect(async.status, SmartAsyncValidationStatus.idle);
    completer.complete('Late error');
    await tester.pump();
    expect(async.status, SmartAsyncValidationStatus.idle);
    expect(find.text('Late error'), findsNothing);
  });

  testWidgets('OTP async validation owns and releases its own controller', (
    tester,
  ) async {
    final async = SmartFieldAsyncController();
    addTearDown(async.dispose);
    await tester.pumpWidget(
      _app(
        SmartField.otp(
          asyncValidation: SmartAsyncValidation(
            controller: async,
            debounceDuration: Duration.zero,
            validator: (_) async => null,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(EditableText), '123456');
    await tester.pump();
    expect(async.status, SmartAsyncValidationStatus.valid);
    await tester.pumpWidget(_app(SmartField.otp()));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('async validation keeps a developer controller undisposed', (
    tester,
  ) async {
    final async = SmartFieldAsyncController();
    final controller = TextEditingController();
    addTearDown(async.dispose);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        SmartField.text(
          controller: controller,
          asyncValidation: SmartAsyncValidation(
            controller: async,
            debounceDuration: Duration.zero,
            validator: (_) async => null,
          ),
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    controller.text = 'still alive';
    expect(controller.text, 'still alive');
  });
}
