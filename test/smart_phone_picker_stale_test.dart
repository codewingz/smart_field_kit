import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void _stale(String name, Future<void> Function(WidgetTester tester) body) {
  testWidgets(name, (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await body(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

void main() {
  Widget field({
    required TextEditingController controller,
    required Completer<String?> pick,
    required List<String> changes,
    List<SmartPhonePickerError>? errors,
    bool enabled = true,
    bool readOnly = false,
    SmartPhonePolicy policy = SmartPhonePolicy.auto,
    List<String>? allowed,
  }) {
    return SmartField.phone(
      controller: controller,
      showContactPicker: true,
      enabled: enabled,
      readOnly: readOnly,
      policy: policy,
      allowedCountryCodes: allowed,
      showCountryPicker: allowed != null,
      contactPicker: () => pick.future,
      onChanged: changes.add,
      onContactPickerError: errors?.add,
    );
  }

  Future<void> start(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Select phone number from contacts'));
    await tester.pump();
  }

  _stale('result after the field is disabled is discarded', (tester) async {
    final controller = TextEditingController(text: '+16502530000');
    final changes = <String>[];
    final pick = Completer<String?>();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(field(controller: controller, pick: pick, changes: changes)),
    );
    await start(tester);
    await tester.pumpWidget(
      _app(
        field(
          controller: controller,
          pick: pick,
          changes: changes,
          enabled: false,
        ),
      ),
    );
    pick.complete('+923001234567');
    await tester.pump();
    expect(controller.text, '+16502530000');
    expect(changes, isEmpty);
  });

  _stale('result after the field becomes read-only is discarded', (
    tester,
  ) async {
    final controller = TextEditingController(text: '+16502530000');
    final changes = <String>[];
    final pick = Completer<String?>();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(field(controller: controller, pick: pick, changes: changes)),
    );
    await start(tester);
    await tester.pumpWidget(
      _app(
        field(
          controller: controller,
          pick: pick,
          changes: changes,
          readOnly: true,
        ),
      ),
    );
    pick.complete('+923001234567');
    await tester.pump();
    expect(controller.text, '+16502530000');
    expect(changes, isEmpty);
  });

  _stale('result after the controller is replaced is discarded', (
    tester,
  ) async {
    final first = TextEditingController(text: '+16502530000');
    final second = TextEditingController(text: '+442071838750');
    final changes = <String>[];
    final pick = Completer<String?>();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await tester.pumpWidget(
      _app(field(controller: first, pick: pick, changes: changes)),
    );
    await start(tester);
    await tester.pumpWidget(
      _app(field(controller: second, pick: pick, changes: changes)),
    );
    pick.complete('+923001234567');
    await tester.pump();
    expect(first.text, '+16502530000');
    expect(second.text, '+442071838750');
    expect(changes, isEmpty);
  });

  _stale('result after phone behavior changes is discarded', (tester) async {
    final controller = TextEditingController(text: '+16502530000');
    final changes = <String>[];
    final pick = Completer<String?>();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        field(
          controller: controller,
          pick: pick,
          changes: changes,
          allowed: const ['PK', 'US'],
        ),
      ),
    );
    await start(tester);
    await tester.pumpWidget(
      _app(
        field(
          controller: controller,
          pick: pick,
          changes: changes,
          allowed: const ['US'],
        ),
      ),
    );
    pick.complete('+923001234567');
    await tester.pump();
    expect(controller.text, '+16502530000');
    expect(changes, isEmpty);
  });

  _stale('result after the widget is removed does nothing', (tester) async {
    final controller = TextEditingController(text: '+16502530000');
    final changes = <String>[];
    final errors = <SmartPhonePickerError>[];
    final pick = Completer<String?>();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        field(
          controller: controller,
          pick: pick,
          changes: changes,
          errors: errors,
        ),
      ),
    );
    await start(tester);
    await tester.pumpWidget(const SizedBox());
    pick.complete('+923001234567');
    await tester.pump();
    expect(controller.text, '+16502530000');
    expect(changes, isEmpty);
    expect(errors, isEmpty);
    expect(tester.takeException(), isNull);
  });

  _stale('a still-current result is applied exactly once', (tester) async {
    final controller = TextEditingController();
    final changes = <String>[];
    final pick = Completer<String?>();
    addTearDown(controller.dispose);
    Widget build() =>
        _app(field(controller: controller, pick: pick, changes: changes));
    await tester.pumpWidget(build());
    await start(tester);
    await tester.pumpWidget(build());
    pick.complete('+923001234567');
    await tester.pump();
    expect(controller.text, '+923001234567');
    expect(changes, ['+923001234567']);
  });

  _stale('a second tap during a pending pick does not launch another', (
    tester,
  ) async {
    final controller = TextEditingController();
    final changes = <String>[];
    var launches = 0;
    final pick = Completer<String?>();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        SmartField.phone(
          controller: controller,
          showContactPicker: true,
          contactPicker: () {
            launches++;
            return pick.future;
          },
          onChanged: changes.add,
        ),
      ),
    );
    await start(tester);
    await start(tester);
    expect(launches, 1);
    pick.complete(null);
    await tester.pump();
    expect(changes, isEmpty);
  });
}
