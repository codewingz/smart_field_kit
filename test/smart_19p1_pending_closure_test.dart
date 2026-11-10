import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  ),
);

class _Harness {
  final formKey = GlobalKey<FormState>();
  final calls = <String>[];
  SmartFieldAsyncController asyncController = SmartFieldAsyncController();
  late TextEditingController controller;
  bool enabled = true;
  bool readOnly = false;
  bool isRequired = false;
  Future<String?> Function(String value)? validator;
  late StateSetter _setState;

  Future<String?> _validate(String value) {
    calls.add(value);
    final custom = validator;
    if (custom != null) {
      return custom(value);
    }
    return Future.value(value == 'alice' ? 'Taken' : null);
  }

  Widget build() => _app(
    StatefulBuilder(
      builder: (context, setState) {
        _setState = setState;
        return Form(
          key: formKey,
          child: SmartField.username(
            controller: controller,
            enabled: enabled,
            readOnly: readOnly,
            isRequired: isRequired,
            asyncValidation: SmartAsyncValidation(
              controller: asyncController,
              debounceDuration: Duration.zero,
              validator: (value) => _validate(value),
            ),
          ),
        );
      },
    ),
  );

  Future<void> update(WidgetTester tester, VoidCallback change) async {
    _setState(change);
    await tester.pump();
    await tester.pump();
  }

  Future<void> reject(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField), 'alice');
    await tester.pump();
    await tester.pump();
    expect(find.text('Taken'), findsOneWidget);
    expect(asyncController.status, SmartAsyncValidationStatus.invalid);
  }
}

void main() {
  group('19P.1 async error display follows the engine', () {
    late _Harness harness;
    late TextEditingController first;
    late TextEditingController second;

    setUp(() {
      harness = _Harness();
      first = TextEditingController();
      second = TextEditingController(text: 'bob');
      harness.controller = first;
    });

    tearDown(() {
      first.dispose();
      second.dispose();
      harness.asyncController.dispose();
    });

    testWidgets('replacing the controller after a rejection clears the error', (
      tester,
    ) async {
      await tester.pumpWidget(harness.build());
      await harness.reject(tester);
      await harness.update(tester, () => harness.controller = second);
      expect(find.text('Taken'), findsNothing);
      expect(find.text('bob'), findsOneWidget);
      expect(harness.asyncController.status, SmartAsyncValidationStatus.idle);
      expect(harness.asyncController.errorText, isNull);
      expect(harness.formKey.currentState!.validate(), isTrue);
      expect(harness.calls, ['alice']);
    });

    testWidgets('the new controller shows its own validation state', (
      tester,
    ) async {
      final empty = TextEditingController();
      addTearDown(empty.dispose);
      harness.isRequired = true;
      await tester.pumpWidget(harness.build());
      await harness.reject(tester);
      await harness.update(tester, () => harness.controller = empty);
      expect(find.text('Taken'), findsNothing);
      expect(find.text('This field is required.'), findsOneWidget);
      expect(harness.calls, ['alice']);
    });

    testWidgets('a controller holding the rejected text starts unchecked', (
      tester,
    ) async {
      final same = TextEditingController(text: 'alice');
      addTearDown(same.dispose);
      await tester.pumpWidget(harness.build());
      await harness.reject(tester);
      await harness.update(tester, () => harness.controller = same);
      expect(find.text('Taken'), findsNothing);
      expect(harness.asyncController.status, SmartAsyncValidationStatus.idle);
      expect(harness.calls, ['alice']);
      expect(await harness.asyncController.validateAsync(), isFalse);
      await tester.pump();
      await tester.pump();
      expect(find.text('Taken'), findsOneWidget);
      expect(harness.calls, ['alice', 'alice']);
    });

    testWidgets('replacing the controller during a pending check', (
      tester,
    ) async {
      final gate = Completer<String?>();
      harness.validator = (_) => gate.future;
      await tester.pumpWidget(harness.build());
      await tester.enterText(find.byType(TextFormField), 'alice');
      await tester.pump();
      expect(
        harness.asyncController.status,
        SmartAsyncValidationStatus.pending,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await harness.update(tester, () => harness.controller = second);
      expect(harness.asyncController.status, SmartAsyncValidationStatus.idle);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      gate.complete('Taken');
      await tester.pump();
      await tester.pump();
      expect(find.text('Taken'), findsNothing);
      expect(harness.asyncController.status, SmartAsyncValidationStatus.idle);
      expect(harness.calls, ['alice']);
    });

    testWidgets('replacing the controller after an accepted value', (
      tester,
    ) async {
      await tester.pumpWidget(harness.build());
      await tester.enterText(find.byType(TextFormField), 'carol');
      await tester.pump();
      await tester.pump();
      expect(harness.asyncController.status, SmartAsyncValidationStatus.valid);
      await harness.update(tester, () => harness.controller = second);
      expect(harness.asyncController.status, SmartAsyncValidationStatus.idle);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).decoration?.errorText,
        isNull,
      );
      expect(harness.calls, ['carol']);
    });

    testWidgets('parent rebuilds keep the error for the current value', (
      tester,
    ) async {
      await tester.pumpWidget(harness.build());
      await harness.reject(tester);
      for (var i = 0; i < 4; i++) {
        await harness.update(tester, () {});
      }
      expect(find.text('Taken'), findsOneWidget);
      expect(
        harness.asyncController.status,
        SmartAsyncValidationStatus.invalid,
      );
      expect(harness.formKey.currentState!.validate(), isFalse);
      expect(harness.calls, ['alice']);
    });

    testWidgets('disabling clears the error with the reset engine', (
      tester,
    ) async {
      await tester.pumpWidget(harness.build());
      await harness.reject(tester);
      await harness.update(tester, () => harness.enabled = false);
      expect(harness.asyncController.status, SmartAsyncValidationStatus.idle);
      expect(find.text('Taken'), findsNothing);
      await harness.update(tester, () => harness.enabled = true);
      expect(find.text('Taken'), findsNothing);
      expect(harness.calls, ['alice']);
    });

    testWidgets('read-only keeps the error for the unchanged value', (
      tester,
    ) async {
      await tester.pumpWidget(harness.build());
      await harness.reject(tester);
      await harness.update(tester, () => harness.readOnly = true);
      expect(
        harness.asyncController.status,
        SmartAsyncValidationStatus.invalid,
      );
      expect(find.text('Taken'), findsOneWidget);
      expect(harness.formKey.currentState!.validate(), isFalse);
      expect(harness.calls, ['alice']);
    });

    testWidgets('replacing the async controller keeps the error', (
      tester,
    ) async {
      final replacement = SmartFieldAsyncController();
      addTearDown(replacement.dispose);
      final original = harness.asyncController;
      await tester.pumpWidget(harness.build());
      await harness.reject(tester);
      await harness.update(tester, () => harness.asyncController = replacement);
      expect(find.text('Taken'), findsOneWidget);
      expect(replacement.status, SmartAsyncValidationStatus.invalid);
      expect(original.status, SmartAsyncValidationStatus.idle);
      expect(harness.calls, ['alice']);
      harness.asyncController = original;
    });

    testWidgets('rapid controller swaps settle on the last controller', (
      tester,
    ) async {
      final third = TextEditingController(text: 'dave');
      addTearDown(third.dispose);
      await tester.pumpWidget(harness.build());
      await harness.reject(tester);
      for (final next in [second, first, third, second, third]) {
        harness._setState(() => harness.controller = next);
        await tester.pump();
      }
      await tester.pump();
      expect(find.text('dave'), findsOneWidget);
      expect(find.text('Taken'), findsNothing);
      expect(harness.asyncController.status, SmartAsyncValidationStatus.idle);
      expect(harness.calls, ['alice']);
      expect(tester.takeException(), isNull);
    });

    testWidgets('removing the field right after a swap is safe', (
      tester,
    ) async {
      await tester.pumpWidget(harness.build());
      await harness.reject(tester);
      harness._setState(() => harness.controller = second);
      await tester.pumpWidget(_app(const SizedBox()));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      expect(harness.asyncController.status, SmartAsyncValidationStatus.idle);
    });

    testWidgets('only the swapped field changes in a form', (tester) async {
      final other = TextEditingController();
      addTearDown(other.dispose);
      TextEditingController current = first;
      late StateSetter rebuild;
      Widget field(TextEditingController controller, String label) =>
          SmartField.username(
            label: label,
            controller: controller,
            asyncValidation: SmartAsyncValidation(
              debounceDuration: Duration.zero,
              validator: (value) async => 'Taken $label',
            ),
          );
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return Form(
                child: Column(
                  children: [field(current, 'one'), field(other, 'two')],
                ),
              );
            },
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField).first, 'alice');
      await tester.enterText(find.byType(TextFormField).last, 'alice');
      await tester.pump();
      await tester.pump();
      expect(find.text('Taken one'), findsOneWidget);
      expect(find.text('Taken two'), findsOneWidget);
      rebuild(() => current = second);
      await tester.pump();
      await tester.pump();
      expect(find.text('Taken one'), findsNothing);
      expect(find.text('Taken two'), findsOneWidget);
    });

    testWidgets('a dropdown date drops its result with its controller', (
      tester,
    ) async {
      final dateA = TextEditingController(text: '04/03/2020');
      final dateB = TextEditingController(text: '05/03/2020');
      final controller = SmartFieldAsyncController();
      addTearDown(dateA.dispose);
      addTearDown(dateB.dispose);
      addTearDown(controller.dispose);
      var calls = 0;
      TextEditingController current = dateA;
      late StateSetter rebuild;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return SmartField.date(
                controller: current,
                mode: SmartDateMode.dropdowns,
                asyncValidation: SmartAsyncValidation(
                  controller: controller,
                  trigger: SmartAsyncValidationTrigger.manual,
                  validator: (value) async {
                    calls++;
                    return 'Booked';
                  },
                ),
              );
            },
          ),
        ),
      );
      expect(await controller.validateAsync(), isFalse);
      await tester.pump();
      await tester.pump();
      expect(find.text('Booked'), findsOneWidget);
      rebuild(() => current = dateB);
      await tester.pump();
      await tester.pump();
      expect(find.text('Booked'), findsNothing);
      expect(controller.status, SmartAsyncValidationStatus.idle);
      expect(controller.errorText, isNull);
      expect(calls, 1);
      rebuild(() {});
      await tester.pump();
      await tester.pump();
      expect(find.text('Booked'), findsNothing);
    });
  });

  group('19P.1 minLength and blank text keep the documented contract', () {
    testWidgets('an optional password accepts whitespace-only text', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      Widget build({required bool isRequired}) => _app(
        Form(
          key: formKey,
          child: SmartField.password(minLength: 8, isRequired: isRequired),
        ),
      );
      await tester.pumpWidget(build(isRequired: false));
      for (final blank in ['   ', ' \t ', '\u00a0\u3000']) {
        await tester.enterText(find.byType(TextFormField), blank);
        expect(formKey.currentState!.validate(), isTrue, reason: blank);
      }
      await tester.enterText(find.byType(TextFormField), '  a  ');
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pumpWidget(build(isRequired: true));
      await tester.enterText(find.byType(TextFormField), '   ');
      expect(formKey.currentState!.validate(), isFalse);
    });

    test('legacy presets are unchanged for blank text', () {
      for (final preset in SmartTextValidationPreset.values) {
        final validator = SmartValidators.textPreset(preset);
        expect(validator(null), isNull, reason: preset.name);
        expect(validator(''), isNull, reason: preset.name);
        expect(validator('   '), isNull, reason: preset.name);
      }
    });
  });
}
