import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

final DateTime _now = DateTime(2026, 6, 15, 10, 0);
DateTime _clock() => _now;

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

Widget _stack({
  required FocusNode before,
  required Widget field,
  required FocusNode after,
}) {
  return Column(
    children: [
      TextField(focusNode: before),
      field,
      TextField(focusNode: after),
    ],
  );
}

void main() {
  group('picker fields are reachable and operable by keyboard', () {
    testWidgets('Tab and Shift+Tab visit the calendar field', (tester) async {
      final before = FocusNode();
      final target = FocusNode();
      final after = FocusNode();
      addTearDown(before.dispose);
      addTearDown(target.dispose);
      addTearDown(after.dispose);
      await tester.pumpWidget(
        _app(
          _stack(
            before: before,
            field: SmartField.date(
              focusNode: target,
              mode: SmartDateMode.calendar,
              now: _clock,
            ),
            after: after,
          ),
        ),
      );
      before.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(target.hasFocus, isTrue);
      for (var i = 0; i < 3 && !after.hasFocus; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      expect(after.hasFocus, isTrue);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      for (var i = 0; i < 3 && !target.hasFocus; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(target.hasFocus, isTrue);
    });

    for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.space]) {
      testWidgets(
        '${key.keyLabel.isEmpty ? 'Space' : key.keyLabel} opens the calendar',
        (tester) async {
          final focus = FocusNode();
          addTearDown(focus.dispose);
          await tester.pumpWidget(
            _app(
              SmartField.date(
                focusNode: focus,
                mode: SmartDateMode.calendar,
                now: _clock,
              ),
            ),
          );
          focus.requestFocus();
          await tester.pump();
          await tester.sendKeyEvent(key);
          await tester.pumpAndSettle();
          expect(find.byType(DatePickerDialog), findsOneWidget);
        },
      );
    }

    testWidgets('time picker opens from the keyboard and focus returns', (
      tester,
    ) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.time(
            focusNode: focus,
            mode: SmartTimeMode.picker,
            now: _clock,
          ),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsNothing);
      expect(focus.hasFocus, isTrue);
    });

    testWidgets('dateTime picker opens from the keyboard', (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.dateTime(
            focusNode: focus,
            mode: SmartTimeMode.picker,
            now: _clock,
          ),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('picker-only fields cannot be edited as text', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.date(
            controller: controller,
            mode: SmartDateMode.calendar,
            now: _clock,
          ),
        ),
      );
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).readOnly,
        isTrue,
      );
    });

    testWidgets('disabled and read-only fields ignore tap, Enter and Space', (
      tester,
    ) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      for (final readOnly in [false, true]) {
        await tester.pumpWidget(
          _app(
            SmartField.date(
              focusNode: focus,
              enabled: readOnly ? null : false,
              readOnly: readOnly,
              mode: SmartDateMode.calendar,
              now: _clock,
            ),
          ),
        );
        await tester.tap(find.byType(EditableText), warnIfMissed: false);
        await tester.pumpAndSettle();
        focus.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(find.byType(DatePickerDialog), findsNothing);
      }
    });

    testWidgets('tapping the field opens the calendar', (tester) async {
      await tester.pumpWidget(
        _app(SmartField.date(mode: SmartDateMode.calendar, now: _clock)),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('screen readers get the label and a tap action', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          SmartField.date(
            label: 'Birth date',
            mode: SmartDateMode.calendar,
            now: _clock,
          ),
        ),
      );
      final node = tester.getSemantics(
        find.bySemanticsLabel(RegExp('Birth date')).first,
      );
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      handle.dispose();
    });
  });

  group('Clear button and suffix actions', () {
    testWidgets('Clear clears the value and does not open the picker', (
      tester,
    ) async {
      final controller = TextEditingController(text: '15/03/2024');
      final changes = <String>[];
      final dates = <DateTime?>[];
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.date(
            controller: controller,
            mode: SmartDateMode.calendar,
            showClearButton: true,
            now: _clock,
            onChanged: changes.add,
            onDateChanged: dates.add,
          ),
        ),
      );
      await tester.tap(find.byTooltip('Clear'));
      await tester.pumpAndSettle();
      expect(controller.text, isEmpty);
      expect(find.byType(DatePickerDialog), findsNothing);
      expect(changes.last, '');
      expect(dates.last, isNull);
    });

    testWidgets('a developer suffix action receives its own tap', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          SmartField.date(
            mode: SmartDateMode.calendar,
            now: _clock,
            decoration: InputDecoration(
              suffixIcon: IconButton(
                tooltip: 'Help',
                onPressed: () => taps++,
                icon: const Icon(Icons.help),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Help'));
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(find.byType(DatePickerDialog), findsNothing);
    });

    testWidgets('the calendar button still opens the picker', (tester) async {
      await tester.pumpWidget(
        _app(SmartField.date(mode: SmartDateMode.calendar, now: _clock)),
      );
      await tester.tap(find.byTooltip('Choose date'));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });
  });

  group('dateTime restrictions consider today', () {
    testWidgets('futureOnly allows the current day in the picker', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SmartField.dateTime(
            mode: SmartTimeMode.picker,
            restriction: SmartDateRestriction.futureOnly,
            now: _clock,
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      final calendar = tester.widget<CalendarDatePicker>(
        find.byType(CalendarDatePicker),
      );
      expect(calendar.firstDate, DateTime(2026, 6, 15));
    });

    testWidgets('pastOnly allows the current day in the picker', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SmartField.dateTime(
            mode: SmartTimeMode.picker,
            restriction: SmartDateRestriction.pastOnly,
            now: _clock,
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      final calendar = tester.widget<CalendarDatePicker>(
        find.byType(CalendarDatePicker),
      );
      expect(calendar.lastDate, DateTime(2026, 6, 15));
    });

    testWidgets('date-only restrictions still exclude today', (tester) async {
      await tester.pumpWidget(
        _app(
          SmartField.date(
            mode: SmartDateMode.calendar,
            restriction: SmartDateRestriction.futureOnly,
            now: _clock,
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      final calendar = tester.widget<CalendarDatePicker>(
        find.byType(CalendarDatePicker),
      );
      expect(calendar.firstDate, DateTime(2026, 6, 16));
    });

    testWidgets('validation compares the selected minute', (tester) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController(text: '15/06/2026 10:30');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.dateTime(
              controller: controller,
              restriction: SmartDateRestriction.futureOnly,
              now: _clock,
            ),
          ),
        ),
      );
      expect(formKey.currentState!.validate(), isTrue);
      controller.text = '15/06/2026 09:30';
      await tester.pump();
      expect(formKey.currentState!.validate(), isFalse);
    });
  });
}
