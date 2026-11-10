import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

DateTime _clock() => DateTime(2026, 6, 15, 10, 0);

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

int? _dropdownValue(WidgetTester tester, String label) {
  final finder = find.byWidgetPredicate(
    (widget) =>
        widget is DropdownButton<int> &&
        widget.hint is Text &&
        (widget.hint as Text).data == label,
  );
  return tester.widget<DropdownButton<int>>(finder).value;
}

void main() {
  group('19F dropdown dates outside the selectable range', () {
    testWidgets('a stored year before the default list is shown', (
      tester,
    ) async {
      final controller = TextEditingController(text: '01/01/1850');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.date(
            mode: SmartDateMode.dropdowns,
            controller: controller,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(_dropdownValue(tester, 'Year'), 1850);
      expect(controller.text, '01/01/1850');
    });

    testWidgets('a stored future date under pastOnly reports the rule', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController(text: '01/01/2030');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.date(
              mode: SmartDateMode.dropdowns,
              restriction: SmartDateRestriction.pastOnly,
              now: _clock,
              controller: controller,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(_dropdownValue(tester, 'Year'), 2030);
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Choose a date in the past.'), findsOneWidget);
      expect(controller.text, '01/01/2030');
    });

    testWidgets('an initial date outside firstYear and lastYear is invalid', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      String? saved;
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.date(
              mode: SmartDateMode.dropdowns,
              initialDate: DateTime(1990, 5, 4),
              firstYear: 2000,
              lastYear: 2030,
              onSaved: (value) => saved = value,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(_dropdownValue(tester, 'Year'), 1990);
      expect(formKey.currentState!.validate(), isFalse);
      formKey.currentState!.save();
      expect(saved, '04/05/1990');
    });
  });

  group('19F dropdown reset and save', () {
    testWidgets('reset then save agree with the visible value', (tester) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController(text: '01/02/2026');
      addTearDown(controller.dispose);
      String? saved;
      String? savedRaw;
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.date(
              mode: SmartDateMode.dropdowns,
              controller: controller,
              firstYear: 2020,
              lastYear: 2030,
              onSaved: (value) => saved = value,
              onRawSaved: (value) => savedRaw = value,
            ),
          ),
        ),
      );
      controller.text = '09/08/2027';
      await tester.pump();
      expect(_dropdownValue(tester, 'Year'), 2027);
      formKey.currentState!.reset();
      await tester.pump();
      formKey.currentState!.save();
      expect(controller.text, '01/02/2026');
      expect(_dropdownValue(tester, 'Day'), 1);
      expect(_dropdownValue(tester, 'Month'), 2);
      expect(_dropdownValue(tester, 'Year'), 2026);
      expect(saved, controller.text);
      expect(savedRaw, '2026-02-01');
    });

    testWidgets('an empty start resets to empty and saves null', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      String? saved = 'unset';
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.date(
              mode: SmartDateMode.dropdowns,
              controller: controller,
              firstYear: 2020,
              lastYear: 2030,
              onSaved: (value) => saved = value,
            ),
          ),
        ),
      );
      controller.text = '09/08/2027';
      await tester.pump();
      formKey.currentState!.reset();
      await tester.pump();
      formKey.currentState!.save();
      expect(controller.text, isEmpty);
      expect(saved, isNull);
    });
  });

  group('19F stale picker results', () {
    testWidgets('a calendar result does not overwrite a replaced controller', (
      tester,
    ) async {
      final first = TextEditingController(text: '01/02/2026');
      final second = TextEditingController(text: '05/06/2027');
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      Widget build(TextEditingController controller) => _app(
        SmartField.date(
          mode: SmartDateMode.calendar,
          now: _clock,
          controller: controller,
        ),
      );
      await tester.pumpWidget(build(first));
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      await tester.pumpWidget(build(second));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(second.text, '05/06/2027');
      expect(first.text, '01/02/2026');
    });

    testWidgets('a calendar result is dropped when the field was disabled', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final changes = <String>[];
      Widget build(bool enabled) => _app(
        SmartField.date(
          mode: SmartDateMode.calendar,
          now: _clock,
          controller: controller,
          enabled: enabled,
          onChanged: changes.add,
        ),
      );
      await tester.pumpWidget(build(true));
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      await tester.pumpWidget(build(false));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(controller.text, isEmpty);
      expect(changes, isEmpty);
    });

    testWidgets('a normal calendar selection still applies exactly once', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final changes = <String>[];
      await tester.pumpWidget(
        _app(
          SmartField.date(
            mode: SmartDateMode.calendar,
            now: _clock,
            controller: controller,
            onChanged: changes.add,
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(controller.text, '15/06/2026');
      expect(changes, ['15/06/2026']);
    });

    testWidgets('a country selection is dropped when the field was disabled', (
      tester,
    ) async {
      final countries = <SmartPhoneCountry?>[];
      Widget build(bool enabled) => _app(
        SmartField.phone(
          showCountryPicker: true,
          initialCountryCode: 'GB',
          allowedCountryCodes: const ['US', 'GB'],
          enabled: enabled,
          onCountryChanged: countries.add,
        ),
      );
      await tester.pumpWidget(build(true));
      await tester.tap(find.text('+44'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(build(false));
      await tester.tap(find.text('United States').last);
      await tester.pumpAndSettle();
      expect(countries, isEmpty);
    });
  });

  group('19F no controller writes during build', () {
    testWidgets('date seeds an external controller without a build error', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (_, value, _) => Text('echo ${value.text}'),
              ),
              SmartField.date(
                controller: controller,
                initialDate: DateTime(2020, 5, 17),
              ),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(controller.text, '17/05/2020');
      await tester.pump();
      expect(find.text('echo 17/05/2020'), findsOneWidget);
    });

    testWidgets('amount formats an external controller without a build error', (
      tester,
    ) async {
      final controller = TextEditingController(text: '50000');
      addTearDown(controller.dispose);
      Widget build(int places) => _app(
        Column(
          children: [
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, value, _) => Text('echo ${value.text}'),
            ),
            Builder(
              builder: (_) => SmartField.amount(
                controller: controller,
                decimalPlaces: places,
                useGrouping: true,
              ),
            ),
          ],
        ),
      );
      await tester.pumpWidget(build(2));
      expect(tester.takeException(), isNull);
      expect(controller.text, '50,000.00');
      await tester.pumpWidget(build(3));
      expect(tester.takeException(), isNull);
      expect(controller.text, '50,000.000');
      await tester.pump();
      expect(find.text('echo 50,000.000'), findsOneWidget);
    });
  });

  group('19F async validation', () {
    testWidgets('a calendar selection runs automatic async validation', (
      tester,
    ) async {
      final calls = <String>[];
      await tester.pumpWidget(
        _app(
          SmartField.date(
            mode: SmartDateMode.calendar,
            now: _clock,
            asyncValidation: SmartAsyncValidation(
              debounceDuration: Duration.zero,
              validator: (value) async {
                calls.add(value);
                return 'Date is booked';
              },
            ),
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(calls, ['2026-06-15']);
      expect(find.text('Date is booked'), findsOneWidget);
    });

    testWidgets('a read-only picker field stays inactive', (tester) async {
      final calls = <String>[];
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.date(
            mode: SmartDateMode.calendar,
            now: _clock,
            readOnly: true,
            controller: controller,
            asyncValidation: SmartAsyncValidation(
              debounceDuration: Duration.zero,
              validator: (value) async {
                calls.add(value);
                return null;
              },
            ),
          ),
        ),
      );
      controller.text = '15/06/2026';
      await tester.pump(const Duration(seconds: 1));
      expect(calls, isEmpty);
    });

    testWidgets('adding and removing async validation keeps a partial OTP', (
      tester,
    ) async {
      Widget build(bool async) => _app(
        SmartField.otp(
          asyncValidation: async
              ? SmartAsyncValidation(validator: (_) async => null)
              : null,
        ),
      );
      await tester.pumpWidget(build(false));
      await tester.enterText(find.byType(EditableText), '1234');
      await tester.pump();
      await tester.pumpWidget(build(true));
      await tester.pump();
      var input = tester.widget<EditableText>(find.byType(EditableText));
      expect(input.controller.text, '1234');
      await tester.pumpWidget(build(false));
      await tester.pump();
      input = tester.widget<EditableText>(find.byType(EditableText));
      expect(input.controller.text, '1234');
      expect(tester.takeException(), isNull);
    });
  });

  group('19F card security code', () {
    testWidgets('a replaced number controller refreshes the brand error', (
      tester,
    ) async {
      final amex = TextEditingController();
      final visa = TextEditingController(text: '4111 1111 1111 1111');
      final cvv = TextEditingController(text: '123');
      addTearDown(amex.dispose);
      addTearDown(visa.dispose);
      addTearDown(cvv.dispose);
      Widget build(TextEditingController number) => _app(
        SmartField.creditCard(numberController: number, cvvController: cvv),
      );
      await tester.pumpWidget(build(amex));
      amex.text = '3782 822463 10005';
      await tester.pump();
      expect(find.text('Enter the 4-digit security code.'), findsOneWidget);
      await tester.pumpWidget(build(visa));
      await tester.pump();
      expect(find.text('Enter the 4-digit security code.'), findsNothing);
    });
  });

  group('19F validation robustness', () {
    test('an oversized IPv4 component is invalid and does not throw', () {
      expect(SmartUrlValidation.isValid('https://${'9' * 100}.1.1.1'), isFalse);
      expect(SmartUrlValidation.isValid('https://256.1.1.1'), isFalse);
      expect(SmartUrlValidation.isValid('https://255.1.1.1'), isTrue);
      expect(
        SmartValidators.url()('https://${'9' * 400}.1.1.1'),
        'Enter a valid URL.',
      );
    });

    testWidgets('username character rules are enforced by validation', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.username(
              controller: controller,
              allowedCharacters: SmartUsernameCharacters.letters,
            ),
          ),
        ),
      );
      controller.text = 'x9_#';
      expect(formKey.currentState!.validate(), isFalse);
      controller.text = 'Zoë';
      expect(formKey.currentState!.validate(), isTrue);
      controller.text = '';
      expect(formKey.currentState!.validate(), isTrue);
      await tester.tap(find.byType(EditableText));
      await tester.pump();
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'ab1!',
          selection: TextSelection.collapsed(offset: 4),
          composing: TextRange(start: 0, end: 4),
        ),
      );
      await tester.pump();
      expect(formKey.currentState!.validate(), isFalse);
    });

    testWidgets('an unrestricted username accepts any characters', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController(text: 'x9_# 😀');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.username(controller: controller),
          ),
        ),
      );
      expect(formKey.currentState!.validate(), isTrue);
    });
  });
}
