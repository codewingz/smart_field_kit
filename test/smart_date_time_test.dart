import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

final DateTime _fixedNow = DateTime(2024, 3, 15, 10, 30);
DateTime _now() => _fixedNow;

Widget _app(
  Widget child, {
  ThemeData? theme,
  TextDirection direction = TextDirection.ltr,
}) {
  return MaterialApp(
    theme: theme,
    home: Directionality(
      textDirection: direction,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    ),
  );
}

String? _validateError(WidgetTester tester) {
  final state = tester.state<FormFieldState<String>>(
    find.byType(TextFormField).first,
  );
  state.validate();
  return state.errorText;
}

void main() {
  group('SmartDateUtils', () {
    test('leap years and month lengths', () {
      expect(SmartDateUtils.isLeapYear(2024), isTrue);
      expect(SmartDateUtils.isLeapYear(1900), isFalse);
      expect(SmartDateUtils.isLeapYear(2000), isTrue);
      expect(SmartDateUtils.isLeapYear(2023), isFalse);
      expect(SmartDateUtils.daysInMonth(2024, 2), 29);
      expect(SmartDateUtils.daysInMonth(2023, 2), 28);
      expect(SmartDateUtils.daysInMonth(2023, 4), 30);
      expect(SmartDateUtils.daysInMonth(2023, 12), 31);
      expect(() => SmartDateUtils.daysInMonth(2023, 13), throwsArgumentError);
    });

    test('isValidDate rejects impossible dates', () {
      expect(SmartDateUtils.isValidDate(2024, 2, 29), isTrue);
      expect(SmartDateUtils.isValidDate(2023, 2, 29), isFalse);
      expect(SmartDateUtils.isValidDate(2024, 2, 30), isFalse);
      expect(SmartDateUtils.isValidDate(2024, 4, 31), isFalse);
      expect(SmartDateUtils.isValidDate(2024, 0, 10), isFalse);
      expect(SmartDateUtils.isValidDate(2024, 13, 10), isFalse);
      expect(SmartDateUtils.isValidDate(2024, 1, 0), isFalse);
    });

    test('ISO serialization has no timezone shift', () {
      final date = DateTime(2024, 1, 5);
      expect(SmartDateUtils.toIsoDate(date), '2024-01-05');
      expect(SmartDateUtils.tryParseIsoDate('2024-01-05'), date);
      expect(SmartDateUtils.tryParseIsoDate('2024-02-30'), isNull);
      expect(SmartDateUtils.tryParseIsoDate('2024-1-5'), isNull);
      expect(SmartDateUtils.tryParseIsoDate('2024-01-05T00:00'), isNull);
      expect(
        SmartDateUtils.toIsoDate(DateTime.utc(2024, 1, 5, 23)),
        '2024-01-05',
      );
      expect(SmartDateUtils.dateOnly(DateTime(2024, 1, 5, 23, 59)), date);
      expect(
        SmartDateUtils.toIsoTime(const TimeOfDay(hour: 7, minute: 5)),
        '07:05',
      );
      expect(SmartDateUtils.tryParseIsoTime('24:00'), isNull);
      final dateTime = DateTime(2024, 1, 5, 14, 30);
      expect(SmartDateUtils.toIsoDateTime(dateTime), '2024-01-05T14:30');
      expect(SmartDateUtils.tryParseIsoDateTime('2024-01-05T14:30'), dateTime);
      expect(SmartDateUtils.tryParseIsoDateTime('2024-01-05 14:30'), isNull);
    });
  });

  group('SmartDateFormat and SmartTimeFormat', () {
    test('formats and strictly parses supported patterns', () {
      final dmy = SmartDateFormat();
      expect(dmy.format(DateTime(2024, 3, 5)), '05/03/2024');
      expect(dmy.tryParse('05/03/2024'), DateTime(2024, 3, 5));
      expect(dmy.tryParse('30/02/2024'), isNull);
      expect(dmy.tryParse('29/02/2024'), DateTime(2024, 2, 29));
      expect(dmy.tryParse('29/02/2023'), isNull);
      expect(dmy.tryParse('5/3/2024'), isNull);
      expect(dmy.tryParse('05-03-2024'), isNull);
      expect(dmy.inputMaskPattern, '##/##/####');
      final iso = SmartDateFormat('yyyy-MM-dd');
      expect(iso.tryParse('2024-03-05'), DateTime(2024, 3, 5));
      expect(iso.inputMaskPattern, '####-##-##');
      final us = SmartDateFormat('MM/dd/yyyy');
      expect(us.tryParse('03/05/2024'), DateTime(2024, 3, 5));
      expect(us.tryParse('13/05/2024'), isNull);
    });

    test('invalid patterns throw', () {
      expect(() => SmartDateFormat('dd/MM'), throwsArgumentError);
      expect(() => SmartDateFormat('dd/dd/yyyy'), throwsArgumentError);
      expect(() => SmartDateFormat('dd#MM#yyyy'), throwsArgumentError);
    });

    test('time formats', () {
      const h24 = SmartTimeFormat();
      expect(h24.format(const TimeOfDay(hour: 7, minute: 5)), '07:05');
      expect(h24.tryParse('23:59'), const TimeOfDay(hour: 23, minute: 59));
      expect(h24.tryParse('24:00'), isNull);
      expect(h24.tryParse('12:60'), isNull);
      const h12 = SmartTimeFormat(use24Hour: false);
      expect(h12.format(const TimeOfDay(hour: 0, minute: 5)), '12:05 AM');
      expect(h12.format(const TimeOfDay(hour: 12, minute: 0)), '12:00 PM');
      expect(h12.format(const TimeOfDay(hour: 15, minute: 45)), '03:45 PM');
      expect(h12.tryParse('12:05 AM'), const TimeOfDay(hour: 0, minute: 5));
      expect(h12.tryParse('12:00 pm'), const TimeOfDay(hour: 12, minute: 0));
      expect(h12.tryParse('03:45 PM'), const TimeOfDay(hour: 15, minute: 45));
      expect(h12.tryParse('13:00 PM'), isNull);
      expect(h12.tryParse('00:30 AM'), isNull);
      expect(h12.tryParse('03:45 XM'), isNull);
    });
  });

  group('SmartField.date manual', () {
    testWidgets('typing applies the mask and parses a typed value', (
      tester,
    ) async {
      final controller = TextEditingController();
      DateTime? typed;
      final raws = <String>[];
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.date(
            controller: controller,
            now: _now,
            onDateChanged: (value) => typed = value,
            onRawChanged: raws.add,
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), '05032024');
      expect(controller.text, '05/03/2024');
      expect(typed, DateTime(2024, 3, 5));
      expect(raws.last, '2024-03-05');
      await tester.enterText(find.byType(TextFormField), '0503');
      expect(typed, isNull);
      await tester.enterText(find.byType(TextFormField), '05/03/20a4');
      expect(controller.text, '05/03');
    });

    testWidgets('validates February 30, leap years, and incomplete values', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          Form(
            child: SmartField.date(controller: controller, now: _now),
          ),
        ),
      );
      controller.text = '30/02/2024';
      expect(_validateError(tester), isNotNull);
      controller.text = '29/02/2024';
      expect(_validateError(tester), isNull);
      controller.text = '29/02/2023';
      expect(_validateError(tester), isNotNull);
      controller.text = '05/03';
      expect(_validateError(tester), isNotNull);
      controller.text = '';
      expect(_validateError(tester), isNull);
    });

    testWidgets('min and max boundaries are inclusive', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.date(
            controller: controller,
            now: _now,
            minDate: DateTime(2024, 1, 10, 18),
            maxDate: DateTime(2024, 1, 20),
            minErrorText: 'Too early',
            maxErrorText: 'Too late',
          ),
        ),
      );
      for (final entry in {
        '09/01/2024': 'Too early',
        '10/01/2024': null,
        '20/01/2024': null,
        '21/01/2024': 'Too late',
      }.entries) {
        controller.text = entry.key;
        expect(_validateError(tester), entry.value, reason: entry.key);
      }
    });

    testWidgets('past-only and future-only use the injected date', (
      tester,
    ) async {
      final past = TextEditingController();
      final future = TextEditingController();
      addTearDown(past.dispose);
      addTearDown(future.dispose);
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              SmartField.date(
                controller: past,
                now: _now,
                restriction: SmartDateRestriction.pastOnly,
              ),
              SmartField.date(
                controller: future,
                now: _now,
                restriction: SmartDateRestriction.futureOnly,
              ),
            ],
          ),
        ),
      );
      String? error(int index) {
        final state = tester.state<FormFieldState<String>>(
          find.byType(TextFormField).at(index),
        );
        state.validate();
        return state.errorText;
      }

      past.text = '14/03/2024';
      expect(error(0), isNull);
      past.text = '15/03/2024';
      expect(error(0), 'Choose a date in the past.');
      past.text = '16/03/2024';
      expect(error(0), 'Choose a date in the past.');
      future.text = '16/03/2024';
      expect(error(1), isNull);
      future.text = '15/03/2024';
      expect(error(1), 'Choose a date in the future.');
      future.text = '14/03/2024';
      expect(error(1), 'Choose a date in the future.');
    });

    testWidgets('required, optional, custom, server error, reset, clear', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      final server = SmartServerError();
      String? savedDisplay;
      String? savedRaw;
      addTearDown(controller.dispose);
      addTearDown(server.dispose);
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.date(
              controller: controller,
              now: _now,
              isRequired: true,
              requiredErrorText: 'Pick a date',
              initialDate: DateTime(2024, 3, 1, 23, 59),
              showClearButton: true,
              serverError: server,
              validator: (value) =>
                  value == '02/03/2024' ? 'Not allowed' : null,
              onSaved: (value) => savedDisplay = value,
              onRawSaved: (value) => savedRaw = value,
            ),
          ),
        ),
      );
      expect(controller.text, '01/03/2024');
      formKey.currentState!.save();
      expect(savedDisplay, '01/03/2024');
      expect(savedRaw, '2024-03-01');
      controller.text = '02/03/2024';
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Not allowed'), findsOneWidget);
      await tester.tap(find.byTooltip('Clear'));
      await tester.pump();
      expect(controller.text, isEmpty);
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Pick a date'), findsOneWidget);
      server.set('Date unavailable');
      await tester.pump();
      expect(find.text('Date unavailable'), findsOneWidget);
      server.clear();
      await tester.pump();
      controller.text = '05/03/2024';
      expect(formKey.currentState!.validate(), isTrue);
      formKey.currentState!.reset();
      await tester.pump();
      expect(controller.text, '01/03/2024');
    });

    testWidgets('validation modes and other date formats', (tester) async {
      final controller = TextEditingController(text: '2024-03-05');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.date(
            controller: controller,
            dateFormat: 'yyyy-MM-dd',
            validationMode: SmartValidationMode.custom,
            validator: (value) => value == '2024-03-05' ? 'custom' : null,
          ),
        ),
      );
      expect(_validateError(tester), 'custom');
      controller.text = 'garbage';
      expect(_validateError(tester), isNull);
    });
  });

  group('SmartField.date calendar and wheel', () {
    testWidgets('calendar opens, selects, and cancels', (tester) async {
      final controller = TextEditingController();
      DateTime? typed;
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.date(
            controller: controller,
            mode: SmartDateMode.calendar,
            now: _now,
            onDateChanged: (value) => typed = value,
          ),
        ),
      );
      expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
      await tester.tap(find.byTooltip('Choose date'));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(controller.text, isEmpty);
      await tester.tap(find.byTooltip('Choose date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('20'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(controller.text, '20/03/2024');
      expect(typed, DateTime(2024, 3, 20));
    });

    testWidgets('calendar honors restrictions and is disabled when read-only', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              SmartField.date(
                controller: controller,
                mode: SmartDateMode.calendar,
                now: _now,
                restriction: SmartDateRestriction.pastOnly,
              ),
              SmartField.date(mode: SmartDateMode.calendar, readOnly: true),
            ],
          ),
        ),
      );
      await tester.tap(find.byTooltip('Choose date').first);
      await tester.pumpAndSettle();
      final dialog = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      expect(dialog.lastDate, DateTime(2024, 3, 14));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      final buttons = tester
          .widgetList<IconButton>(find.byType(IconButton))
          .toList();
      expect(buttons.last.onPressed, isNull);
    });

    testWidgets('wheel selects and cancels', (tester) async {
      final controller = TextEditingController(text: '31/01/2024');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.date(
            controller: controller,
            mode: SmartDateMode.wheel,
            now: _now,
          ),
        ),
      );
      await tester.tap(find.byTooltip('Choose date'));
      await tester.pumpAndSettle();
      expect(find.text('January'), findsWidgets);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(controller.text, '31/01/2024');
      await tester.tap(find.byTooltip('Choose date'));
      await tester.pumpAndSettle();
      await tester.drag(find.text('January').first, const Offset(0, -36));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(controller.text, '29/02/2024');
    });
  });

  group('SmartField.date dropdowns', () {
    Future<void> choose(WidgetTester tester, String hint, String item) async {
      await tester.tap(find.text(hint).first);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(item),
        60,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text(item).last);
      await tester.pumpAndSettle();
    }

    testWidgets('selects day, month and year with a typed value', (
      tester,
    ) async {
      DateTime? typed;
      final formKey = GlobalKey<FormState>();
      String? saved;
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.date(
              mode: SmartDateMode.dropdowns,
              label: 'Birth date',
              now: _now,
              firstYear: 2020,
              lastYear: 2030,
              onDateChanged: (value) => typed = value,
              onRawSaved: (value) => saved = value,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await choose(tester, 'Month', 'February');
      await choose(tester, 'Year', '2024');
      await choose(tester, 'Day', '29');
      expect(typed, DateTime(2024, 2, 29));
      formKey.currentState!.save();
      expect(saved, '2024-02-29');
      await choose(tester, '2024', '2023');
      expect(typed, isNull);
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Select a complete date.'), findsOneWidget);
    });

    testWidgets('limits days to the month and rejects February 30', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SmartField.date(
            mode: SmartDateMode.dropdowns,
            now: _now,
            firstYear: 2023,
            lastYear: 2025,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await choose(tester, 'Month', 'February');
      await choose(tester, 'Year', '2023');
      await tester.tap(find.text('Day').first);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('28'),
        60,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('28'), findsWidgets);
      expect(find.text('29'), findsNothing);
      expect(find.text('30'), findsNothing);
    });

    testWidgets('required, range, reset, and server error', (tester) async {
      final formKey = GlobalKey<FormState>();
      final server = SmartServerError();
      addTearDown(server.dispose);
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.date(
              mode: SmartDateMode.dropdowns,
              now: _now,
              isRequired: true,
              requiredErrorText: 'Required date',
              maxDate: DateTime(2024, 3, 20),
              firstYear: 2024,
              lastYear: 2025,
              initialDate: DateTime(2024, 3, 12),
              serverError: server,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(formKey.currentState!.validate(), isTrue);
      await choose(tester, '12', '25');
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Choose 20/03/2024 or earlier.'), findsOneWidget);
      formKey.currentState!.reset();
      await tester.pump();
      expect(formKey.currentState!.validate(), isTrue);
      server.set('Booked');
      await tester.pump();
      expect(find.text('Booked'), findsOneWidget);
    });
  });

  group('SmartField.time', () {
    testWidgets('manual 24-hour entry and ranges', (tester) async {
      final controller = TextEditingController();
      TimeOfDay? typed;
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.time(
            controller: controller,
            minTime: const TimeOfDay(hour: 9, minute: 0),
            maxTime: const TimeOfDay(hour: 17, minute: 0),
            onTimeChanged: (value) => typed = value,
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), '0930');
      expect(controller.text, '09:30');
      expect(typed, const TimeOfDay(hour: 9, minute: 30));
      expect(_validateError(tester), isNull);
      controller.text = '08:59';
      expect(_validateError(tester), isNotNull);
      controller.text = '17:00';
      expect(_validateError(tester), isNull);
      controller.text = '17:01';
      expect(_validateError(tester), isNotNull);
      controller.text = '25:00';
      expect(_validateError(tester), isNotNull);
    });

    testWidgets('manual 12-hour entry with AM and PM', (tester) async {
      final controller = TextEditingController();
      final raws = <String>[];
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.time(
            controller: controller,
            use24Hour: false,
            onRawChanged: raws.add,
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), '0345PM');
      expect(controller.text, '03:45 PM');
      expect(raws.last, '15:45');
      expect(_validateError(tester), isNull);
      controller.text = '13:00 PM';
      expect(_validateError(tester), isNotNull);
    });

    testWidgets('picker and wheel select a time', (tester) async {
      final picker = TextEditingController(text: '10:15');
      final wheel = TextEditingController(text: '10:15');
      addTearDown(picker.dispose);
      addTearDown(wheel.dispose);
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              SmartField.time(controller: picker, mode: SmartTimeMode.picker),
              SmartField.time(controller: wheel, mode: SmartTimeMode.wheel),
            ],
          ),
        ),
      );
      await tester.tap(find.byTooltip('Choose time').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(picker.text, '10:15');
      await tester.tap(find.byTooltip('Choose time').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(wheel.text, '10:15');
      await tester.tap(find.byTooltip('Choose time').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(wheel.text, '10:15');
    });
  });

  group('SmartField.dateTime', () {
    testWidgets('manual entry parses and validates combined values', (
      tester,
    ) async {
      final controller = TextEditingController();
      DateTime? typed;
      final raws = <String>[];
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.dateTime(
            controller: controller,
            now: _now,
            restriction: SmartDateRestriction.futureOnly,
            onDateTimeChanged: (value) => typed = value,
            onRawChanged: raws.add,
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), '150320241031');
      expect(controller.text, '15/03/2024 10:31');
      expect(typed, DateTime(2024, 3, 15, 10, 31));
      expect(raws.last, '2024-03-15T10:31');
      expect(_validateError(tester), isNull);
      controller.text = '15/03/2024 10:30';
      expect(_validateError(tester), isNotNull);
      controller.text = '15/03/2024 25:00';
      expect(_validateError(tester), isNotNull);
      controller.text = '30/02/2024 10:00';
      expect(_validateError(tester), isNotNull);
    });

    testWidgets('picker chooses date then time and supports cancel', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.dateTime(
            controller: controller,
            mode: SmartTimeMode.picker,
            now: _now,
          ),
        ),
      );
      await tester.tap(find.byTooltip('Choose date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(controller.text, isEmpty);
      await tester.tap(find.byTooltip('Choose date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(controller.text, isEmpty);
      await tester.tap(find.byTooltip('Choose date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(controller.text, '15/03/2024 10:30');
    });
  });

  group('themes, layout and accessibility', () {
    testWidgets('renders in dark mode, RTL, large text, and narrow width', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2),
              size: Size(220, 700),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      SmartField.date(label: 'A long date label'),
                      SmartField.date(
                        label: 'Dropdown date',
                        mode: SmartDateMode.dropdowns,
                        firstYear: 2020,
                        lastYear: 2030,
                      ),
                      SmartField.time(
                        label: 'Time',
                        mode: SmartTimeMode.picker,
                      ),
                      SmartField.dateTime(label: 'Both'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('exposes labels and pickers to semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              SmartField.date(
                label: 'Start date',
                mode: SmartDateMode.calendar,
              ),
              SmartField.date(
                label: 'End date',
                mode: SmartDateMode.dropdowns,
                firstYear: 2020,
                lastYear: 2030,
              ),
            ],
          ),
        ),
      );
      expect(find.bySemanticsLabel(RegExp('Start date')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Day')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Month')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Year')), findsWidgets);
      handle.dispose();
    });
  });
}
