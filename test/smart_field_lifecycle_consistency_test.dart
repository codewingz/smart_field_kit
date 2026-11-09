import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

typedef _Build = SmartField Function(TextEditingController, FocusNode);

void main() {
  final builders = <String, _Build>{
    'text': (c, f) => SmartField(controller: c, focusNode: f),
    'date manual': (c, f) => SmartField.date(
      controller: c,
      focusNode: f,
      mode: SmartDateMode.manual,
    ),
    'date calendar': (c, f) => SmartField.date(
      controller: c,
      focusNode: f,
      mode: SmartDateMode.calendar,
    ),
    'date dropdowns': (c, f) => SmartField.date(
      controller: c,
      focusNode: f,
      mode: SmartDateMode.dropdowns,
    ),
    'time picker': (c, f) => SmartField.time(
      controller: c,
      focusNode: f,
      mode: SmartTimeMode.picker,
    ),
    'otp': (c, f) => SmartField.otp(controller: c, focusNode: f),
    'amount': (c, f) => SmartField.amount(controller: c, focusNode: f),
    'phone': (c, f) => SmartField.phone(controller: c, focusNode: f),
    'search': (c, f) => SmartField.search(controller: c, focusNode: f),
    'password+strength': (c, f) => SmartField.password(
      controller: c,
      focusNode: f,
      showStrengthIndicator: true,
    ),
    'credit card number': (c, f) =>
        SmartField.creditCard(numberController: c, numberFocusNode: f),
  };

  for (final entry in builders.entries) {
    testWidgets('${entry.key}: developer-owned resources survive unmount', (
      tester,
    ) async {
      final controller = TextEditingController();
      final focus = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      await tester.pumpWidget(_app(entry.value(controller, focus)));
      await tester.pumpWidget(const SizedBox());
      controller.text = '12';
      focus.requestFocus();
      expect(controller.text, '12');
      expect(tester.takeException(), isNull);
    });

    testWidgets('${entry.key}: repeated mount and unmount is clean', (
      tester,
    ) async {
      final controller = TextEditingController();
      final focus = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      for (var i = 0; i < 5; i++) {
        await tester.pumpWidget(_app(entry.value(controller, focus)));
        await tester.pumpWidget(const SizedBox());
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'removing an external controller keeps text for every shared handle',
    (tester) async {
      final dateController = TextEditingController(text: '15/03/2024');
      final otpController = TextEditingController(text: '123456');
      addTearDown(dateController.dispose);
      addTearDown(otpController.dispose);
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              SmartField.date(
                controller: dateController,
                mode: SmartDateMode.manual,
              ),
              SmartField.otp(controller: otpController),
            ],
          ),
        ),
      );
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              SmartField.date(mode: SmartDateMode.manual),
              SmartField.otp(),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).at(0))
            .controller
            .text,
        '15/03/2024',
      );
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).at(1))
            .controller
            .text,
        '123456',
      );
      await tester.pumpWidget(const SizedBox());
      expect(dateController.text, '15/03/2024');
      expect(otpController.text, '123456');
    },
  );
}
