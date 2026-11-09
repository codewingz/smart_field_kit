import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

DateTime _clock() => DateTime(2026, 6, 15, 10, 0);

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

SmartField _dropdown({
  TextEditingController? controller,
  void Function(String?)? onSaved,
  void Function(String?)? onRawSaved,
  void Function(String)? onChanged,
  SmartAsyncValidation? asyncValidation,
  bool isRequired = false,
  SmartDateMode mode = SmartDateMode.dropdowns,
}) {
  return SmartField.date(
    controller: controller,
    mode: mode,
    now: _clock,
    firstYear: 2020,
    lastYear: 2030,
    onSaved: onSaved,
    onRawSaved: onRawSaved,
    onChanged: onChanged,
    asyncValidation: asyncValidation,
    isRequired: isRequired,
  );
}

Finder _part(String label) => find.byWidgetPredicate(
  (widget) =>
      widget is DropdownButton<int> &&
      widget.hint is Text &&
      (widget.hint as Text).data == label,
);

int? _value(WidgetTester tester, String label) =>
    tester.widget<DropdownButton<int>>(_part(label)).value;

Future<void> _choose(WidgetTester tester, String label, String item) async {
  await tester.tap(_part(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(item).last);
  await tester.pumpAndSettle();
}

void main() {
  group('dropdown dates and the controller', () {
    testWidgets('initial controller text selects the dropdown values', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController(text: '15/03/2024');
      String? saved;
      String? raw;
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: _dropdown(
              controller: controller,
              onSaved: (v) => saved = v,
              onRawSaved: (v) => raw = v,
            ),
          ),
        ),
      );
      expect(_value(tester, 'Day'), 15);
      expect(_value(tester, 'Month'), 3);
      expect(_value(tester, 'Year'), 2024);
      formKey.currentState!.save();
      expect(saved, '15/03/2024');
      expect(raw, '2024-03-15');
      expect(formKey.currentState!.validate(), isTrue);
    });

    testWidgets('programmatic controller updates change the dropdowns', (
      tester,
    ) async {
      final controller = TextEditingController(text: '15/03/2024');
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(_dropdown(controller: controller)));
      controller.text = '01/12/2025';
      await tester.pump();
      expect(_value(tester, 'Day'), 1);
      expect(_value(tester, 'Month'), 12);
      expect(_value(tester, 'Year'), 2025);
      controller.clear();
      await tester.pump();
      expect(_value(tester, 'Day'), isNull);
      expect(_value(tester, 'Year'), isNull);
    });

    testWidgets('user selections write the controller and callbacks', (
      tester,
    ) async {
      final controller = TextEditingController();
      final changes = <String>[];
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(_dropdown(controller: controller, onChanged: changes.add)),
      );
      await _choose(tester, 'Year', '2024');
      expect(controller.text, isEmpty);
      await _choose(tester, 'Month', 'March');
      await _choose(tester, 'Day', '5');
      expect(controller.text, '05/03/2024');
      expect(changes.last, '05/03/2024');
    });

    testWidgets('replacing the controller reloads the selection', (
      tester,
    ) async {
      final first = TextEditingController(text: '15/03/2024');
      final second = TextEditingController(text: '09/09/2027');
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      await tester.pumpWidget(_app(_dropdown(controller: first)));
      await tester.pumpWidget(_app(_dropdown(controller: second)));
      expect(_value(tester, 'Day'), 9);
      expect(_value(tester, 'Month'), 9);
      expect(_value(tester, 'Year'), 2027);
      expect(first.text, '15/03/2024');
    });

    testWidgets('removing the external controller keeps the value', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController(text: '15/03/2024');
      String? saved;
      addTearDown(controller.dispose);
      Widget build(TextEditingController? c) => _app(
        Form(
          key: formKey,
          child: _dropdown(controller: c, onSaved: (v) => saved = v),
        ),
      );
      await tester.pumpWidget(build(controller));
      await tester.pumpWidget(build(null));
      await tester.pump();
      expect(_value(tester, 'Day'), 15);
      formKey.currentState!.save();
      expect(saved, '15/03/2024');
      expect(controller.text, '15/03/2024');
    });

    testWidgets('reset restores the initial state and the controller', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: _dropdown(controller: controller),
          ),
        ),
      );
      await _choose(tester, 'Year', '2024');
      await _choose(tester, 'Month', 'March');
      await _choose(tester, 'Day', '5');
      formKey.currentState!.reset();
      await tester.pump();
      expect(_value(tester, 'Day'), isNull);
      expect(controller.text, isEmpty);
    });

    testWidgets('incomplete and unparseable values are reported', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: _dropdown(controller: controller),
          ),
        ),
      );
      await _choose(tester, 'Year', '2024');
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Select a complete date.'), findsOneWidget);
      controller.text = '31/02/2024';
      await tester.pump();
      expect(formKey.currentState!.validate(), isFalse);
    });

    testWidgets('changing the mode while mounted keeps the date', (
      tester,
    ) async {
      final controller = TextEditingController(text: '15/03/2024');
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(_dropdown(controller: controller)));
      await tester.pumpWidget(
        _app(_dropdown(controller: controller, mode: SmartDateMode.manual)),
      );
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        '15/03/2024',
      );
      await tester.pumpWidget(_app(_dropdown(controller: controller)));
      await tester.pump();
      expect(_value(tester, 'Month'), 3);
    });
  });

  group('dropdown dates and async validation', () {
    testWidgets('manual validateAsync runs the shared engine with ISO text', (
      tester,
    ) async {
      final async = SmartFieldAsyncController();
      final seen = <String>[];
      addTearDown(async.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.date(
            mode: SmartDateMode.dropdowns,
            initialDate: DateTime(2024, 3, 15),
            firstYear: 2020,
            lastYear: 2030,
            now: _clock,
            asyncValidation: SmartAsyncValidation(
              controller: async,
              trigger: SmartAsyncValidationTrigger.manual,
              validator: (value) async {
                seen.add(value);
                return value == '2024-03-15' ? 'Date unavailable' : null;
              },
            ),
          ),
        ),
      );
      expect(await async.validateAsync(), isFalse);
      expect(seen, ['2024-03-15']);
      expect(async.status, SmartAsyncValidationStatus.invalid);
      await tester.pump();
      expect(find.text('Date unavailable'), findsOneWidget);
    });

    testWidgets('selecting a date debounces and ignores stale results', (
      tester,
    ) async {
      final async = SmartFieldAsyncController();
      final gates = <String, Completer<String?>>{};
      addTearDown(async.dispose);
      await tester.pumpWidget(
        _app(
          _dropdown(
            asyncValidation: SmartAsyncValidation(
              controller: async,
              debounceDuration: Duration.zero,
              validator: (value) =>
                  (gates[value] = Completer<String?>()).future,
            ),
          ),
        ),
      );
      await _choose(tester, 'Year', '2024');
      await _choose(tester, 'Month', 'March');
      await _choose(tester, 'Day', '5');
      expect(async.status, SmartAsyncValidationStatus.pending);
      await _choose(tester, 'Day', '6');
      gates['2024-03-06']!.complete(null);
      await tester.pump();
      expect(async.status, SmartAsyncValidationStatus.valid);
      gates['2024-03-05']!.complete('Old rejection');
      await tester.pump();
      expect(async.status, SmartAsyncValidationStatus.valid);
      expect(find.text('Old rejection'), findsNothing);
    });

    testWidgets('disposing the field while pending is safe', (tester) async {
      final async = SmartFieldAsyncController();
      final gate = Completer<String?>();
      addTearDown(async.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.date(
            mode: SmartDateMode.dropdowns,
            initialDate: DateTime(2024, 3, 15),
            firstYear: 2020,
            lastYear: 2030,
            now: _clock,
            asyncValidation: SmartAsyncValidation(
              controller: async,
              trigger: SmartAsyncValidationTrigger.manual,
              validator: (value) => gate.future,
            ),
          ),
        ),
      );
      final pending = async.validateAsync();
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      gate.complete('late');
      expect(await pending, isFalse);
      expect(tester.takeException(), isNull);
    });
  });
}
