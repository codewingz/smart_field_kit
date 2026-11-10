import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoPicker;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: SingleChildScrollView(
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      ),
    );

class _KeyHarness {
  _KeyHarness({
    this.trigger = SmartAsyncValidationTrigger.onChanged,
    this.debounce = Duration.zero,
  });

  final SmartAsyncValidationTrigger trigger;
  final Duration debounce;
  final controller = SmartFieldAsyncController();
  final formKey = GlobalKey<FormState>();
  final calls = <String>[];
  Object? key = 'tenant-a';
  String blocked = 'alice';
  Future<String?> Function(String value)? override;
  TextEditingController? text;
  late StateSetter _setState;

  Widget build() => _app(
    StatefulBuilder(
      builder: (context, setState) {
        _setState = setState;
        return Form(
          key: formKey,
          child: SmartField.username(
            controller: text,
            asyncValidation: SmartAsyncValidation(
              controller: controller,
              trigger: trigger,
              debounceDuration: debounce,
              revalidationKey: key,
              validator: (value) {
                calls.add('$key:$value');
                final custom = override;
                if (custom != null) {
                  return custom(value);
                }
                return Future.value(value == blocked ? 'Taken' : null);
              },
            ),
          ),
        );
      },
    ),
  );

  void change(VoidCallback update) => _setState(update);

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }
}

TextEditingValue _value(String text, {int? offset, TextRange? composing}) {
  return TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: offset ?? text.length),
    composing: composing ?? TextRange.empty,
  );
}

String _text(WidgetTester tester, [int index = 0]) {
  return tester
      .widget<EditableText>(find.byType(EditableText).at(index))
      .controller
      .text;
}

void main() {
  group('19P.2 revalidationKey', () {
    testWidgets('an unchanged key keeps the result across rebuilds', (
      tester,
    ) async {
      final harness = _KeyHarness();
      addTearDown(harness.controller.dispose);
      await tester.pumpWidget(harness.build());
      await tester.enterText(find.byType(TextFormField), 'alice');
      await harness.settle(tester);
      expect(find.text('Taken'), findsOneWidget);
      for (var i = 0; i < 4; i++) {
        harness.change(() {});
        await harness.settle(tester);
      }
      expect(find.text('Taken'), findsOneWidget);
      expect(harness.calls, ['tenant-a:alice']);
    });

    testWidgets('a null key behaves as before', (tester) async {
      final harness = _KeyHarness()..key = null;
      addTearDown(harness.controller.dispose);
      await tester.pumpWidget(harness.build());
      await tester.enterText(find.byType(TextFormField), 'alice');
      await harness.settle(tester);
      harness.change(() => harness.blocked = 'bob');
      await harness.settle(tester);
      expect(find.text('Taken'), findsOneWidget);
      expect(harness.calls.length, 1);
      expect(await harness.controller.validateAsync(force: true), isTrue);
      expect(harness.calls.length, 2);
    });

    testWidgets('a key change after a rejection checks again once', (
      tester,
    ) async {
      final harness = _KeyHarness();
      addTearDown(harness.controller.dispose);
      await tester.pumpWidget(harness.build());
      await tester.enterText(find.byType(TextFormField), 'alice');
      await harness.settle(tester);
      expect(find.text('Taken'), findsOneWidget);
      harness.change(() {
        harness.key = 'tenant-b';
        harness.blocked = 'bob';
      });
      await tester.pump();
      expect(find.text('Taken'), findsNothing);
      await harness.settle(tester);
      expect(harness.calls, ['tenant-a:alice', 'tenant-b:alice']);
      expect(harness.controller.status, SmartAsyncValidationStatus.valid);
      expect(harness.formKey.currentState!.validate(), isTrue);
    });

    testWidgets('an accepted result is not reused after a key change', (
      tester,
    ) async {
      final harness = _KeyHarness(trigger: SmartAsyncValidationTrigger.manual);
      addTearDown(harness.controller.dispose);
      await tester.pumpWidget(harness.build());
      await tester.enterText(find.byType(TextFormField), 'bob');
      expect(await harness.controller.validateAsync(), isTrue);
      expect(await harness.controller.validateAsync(), isTrue);
      expect(harness.calls, ['tenant-a:bob']);
      harness.change(() {
        harness.key = 'tenant-b';
        harness.blocked = 'bob';
      });
      await tester.pump();
      expect(harness.controller.status, SmartAsyncValidationStatus.idle);
      expect(harness.calls, ['tenant-a:bob']);
      expect(await harness.controller.validateAsync(), isFalse);
      expect(harness.calls, ['tenant-a:bob', 'tenant-b:bob']);
      await harness.settle(tester);
      expect(find.text('Taken'), findsOneWidget);
    });

    testWidgets('a manual field drops a rejection without a request', (
      tester,
    ) async {
      final harness = _KeyHarness(trigger: SmartAsyncValidationTrigger.manual);
      addTearDown(harness.controller.dispose);
      await tester.pumpWidget(harness.build());
      await tester.enterText(find.byType(TextFormField), 'alice');
      expect(await harness.controller.validateAsync(), isFalse);
      await harness.settle(tester);
      expect(find.text('Taken'), findsOneWidget);
      harness.change(() => harness.key = 'tenant-b');
      await tester.pump();
      expect(find.text('Taken'), findsNothing);
      await harness.settle(tester);
      expect(harness.controller.status, SmartAsyncValidationStatus.idle);
      expect(harness.controller.errorText, isNull);
      expect(harness.calls, ['tenant-a:alice']);
    });

    testWidgets('a key change replaces a pending check', (tester) async {
      final harness = _KeyHarness();
      addTearDown(harness.controller.dispose);
      final gates = <Completer<String?>>[];
      harness.override = (_) {
        final gate = Completer<String?>();
        gates.add(gate);
        return gate.future;
      };
      await tester.pumpWidget(harness.build());
      await tester.enterText(find.byType(TextFormField), 'alice');
      await tester.pump();
      expect(harness.controller.status, SmartAsyncValidationStatus.pending);
      harness.change(() => harness.key = 'tenant-b');
      await harness.settle(tester);
      expect(harness.calls, ['tenant-a:alice', 'tenant-b:alice']);
      expect(harness.controller.status, SmartAsyncValidationStatus.pending);
      gates.first.complete('Old reply');
      await harness.settle(tester);
      expect(find.text('Old reply'), findsNothing);
      expect(harness.controller.status, SmartAsyncValidationStatus.pending);
      gates.last.complete('New reply');
      await harness.settle(tester);
      expect(find.text('New reply'), findsOneWidget);
      expect(harness.calls.length, 2);
    });

    testWidgets('a pending manual check is dropped and returns false', (
      tester,
    ) async {
      final harness = _KeyHarness(trigger: SmartAsyncValidationTrigger.manual);
      addTearDown(harness.controller.dispose);
      final gate = Completer<String?>();
      harness.override = (_) => gate.future;
      await tester.pumpWidget(harness.build());
      await tester.enterText(find.byType(TextFormField), 'alice');
      final obsolete = harness.controller.validateAsync();
      await tester.pump();
      harness.change(() => harness.key = 'tenant-b');
      await harness.settle(tester);
      expect(harness.controller.status, SmartAsyncValidationStatus.idle);
      gate.complete(null);
      expect(await obsolete, isFalse);
      expect(harness.calls.length, 1);
    });

    testWidgets('the new check waits for the debounce', (tester) async {
      final harness = _KeyHarness(debounce: const Duration(milliseconds: 400));
      addTearDown(harness.controller.dispose);
      await tester.pumpWidget(harness.build());
      await tester.enterText(find.byType(TextFormField), 'alice');
      await tester.pump(const Duration(milliseconds: 400));
      await harness.settle(tester);
      expect(harness.calls.length, 1);
      harness.change(() => harness.key = 'tenant-b');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 399));
      expect(harness.calls.length, 1);
      await tester.pump(const Duration(milliseconds: 1));
      await harness.settle(tester);
      expect(harness.calls.length, 2);
    });

    testWidgets('a status listener that rebuilds does not loop', (
      tester,
    ) async {
      final harness = _KeyHarness();
      addTearDown(harness.controller.dispose);
      harness.controller.addListener(() => harness.change(() {}));
      await tester.pumpWidget(harness.build());
      await tester.enterText(find.byType(TextFormField), 'alice');
      await harness.settle(tester);
      harness.change(() => harness.key = 'tenant-b');
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(harness.calls, ['tenant-a:alice', 'tenant-b:alice']);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty text and no earlier check need nothing', (tester) async {
      final harness = _KeyHarness();
      addTearDown(harness.controller.dispose);
      await tester.pumpWidget(harness.build());
      harness.change(() => harness.key = 'tenant-b');
      await harness.settle(tester);
      expect(harness.calls, isEmpty);
      expect(harness.controller.status, SmartAsyncValidationStatus.idle);
    });

    testWidgets('removing the field right after a key change is safe', (
      tester,
    ) async {
      final harness = _KeyHarness();
      addTearDown(harness.controller.dispose);
      await tester.pumpWidget(harness.build());
      await tester.enterText(find.byType(TextFormField), 'alice');
      await harness.settle(tester);
      harness.change(() => harness.key = 'tenant-b');
      await tester.pumpWidget(_app(const SizedBox()));
      await tester.pump(const Duration(seconds: 1));
      expect(harness.calls.length, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a key change with a controller swap makes no request', (
      tester,
    ) async {
      final first = TextEditingController();
      final second = TextEditingController(text: 'bob');
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      final harness = _KeyHarness()..text = first;
      addTearDown(harness.controller.dispose);
      await tester.pumpWidget(harness.build());
      await tester.enterText(find.byType(TextFormField), 'alice');
      await harness.settle(tester);
      expect(find.text('Taken'), findsOneWidget);
      harness.change(() {
        harness.key = 'tenant-b';
        harness.text = second;
      });
      await tester.pump();
      expect(find.text('Taken'), findsNothing);
      await harness.settle(tester);
      expect(harness.controller.status, SmartAsyncValidationStatus.idle);
      expect(harness.calls.length, 1);
    });

    testWidgets('a dropdown date drops its result on a key change', (
      tester,
    ) async {
      final controller = SmartFieldAsyncController();
      addTearDown(controller.dispose);
      var calls = 0;
      Object key = 1;
      late StateSetter rebuild;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return SmartField.date(
                mode: SmartDateMode.dropdowns,
                initialDate: DateTime(2020, 3, 4),
                asyncValidation: SmartAsyncValidation(
                  controller: controller,
                  trigger: SmartAsyncValidationTrigger.manual,
                  revalidationKey: key,
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
      rebuild(() => key = 2);
      await tester.pump();
      expect(find.text('Booked'), findsNothing);
      await tester.pump();
      expect(controller.status, SmartAsyncValidationStatus.idle);
      expect(calls, 1);
    });
  });

  group('19P.2 stale message is removed within the frame', () {
    testWidgets('controller swap and disabling', (tester) async {
      final first = TextEditingController();
      final second = TextEditingController(text: 'bob');
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      var current = first;
      var enabled = true;
      late StateSetter rebuild;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return SmartField.username(
                controller: current,
                enabled: enabled,
                asyncValidation: SmartAsyncValidation(
                  debounceDuration: Duration.zero,
                  validator: (value) async => value == 'alice' ? 'Taken' : null,
                ),
              );
            },
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'alice');
      await tester.pump();
      await tester.pump();
      expect(find.text('Taken'), findsOneWidget);
      rebuild(() => current = second);
      await tester.pump();
      expect(find.text('Taken'), findsNothing);
      rebuild(() => current = first);
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), 'alic');
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), 'alice');
      await tester.pump();
      await tester.pump();
      expect(find.text('Taken'), findsOneWidget);
      rebuild(() => enabled = false);
      await tester.pump();
      expect(find.text('Taken'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('19P.2 standard email passes the trimmed address to async', () {
    testWidgets('async, saved and cached values agree', (tester) async {
      final formKey = GlobalKey<FormState>();
      final text = TextEditingController();
      final controller = SmartFieldAsyncController();
      addTearDown(text.dispose);
      addTearDown(controller.dispose);
      final asyncValues = <String>[];
      final custom = <String?>[];
      final changed = <String>[];
      final saved = <String?>[];
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.email(
              controller: text,
              onChanged: changed.add,
              onSaved: saved.add,
              validator: (value) {
                custom.add(value);
                return null;
              },
              asyncValidation: SmartAsyncValidation(
                controller: controller,
                debounceDuration: Duration.zero,
                validator: (value) async {
                  asyncValues.add(value);
                  return value == 'Taken@Example.com' ? 'In use' : null;
                },
              ),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), ' Free@Example.com');
      await tester.pump();
      await tester.pump();
      expect(asyncValues, ['Free@Example.com']);
      await tester.enterText(find.byType(TextFormField), ' Free@Example.com ');
      await tester.pump();
      await tester.pump();
      expect(asyncValues, ['Free@Example.com']);
      expect(controller.status, SmartAsyncValidationStatus.valid);
      expect(await controller.validateAsync(), isTrue);
      expect(asyncValues.length, 1);
      formKey.currentState!.save();
      expect(saved, ['Free@Example.com']);
      expect(text.text, ' Free@Example.com ');
      expect(changed.last, ' Free@Example.com ');
      expect(custom.last, ' Free@Example.com ');

      await tester.enterText(
        find.byType(TextFormField),
        '  Taken@Example.com ',
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(asyncValues.last, 'Taken@Example.com');
      expect(find.text('In use'), findsOneWidget);
      expect(formKey.currentState!.validate(), isFalse);
      expect(await controller.validateAsync(), isFalse);
    });

    testWidgets('invalid and blank text is never sent', (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(
        _app(
          SmartField.email(
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
      for (final text in ['   ', ' not-an-email ', 'user @example.com']) {
        await tester.enterText(find.byType(TextFormField), text);
        await tester.pump();
      }
      expect(calls, isEmpty);
    });

    testWidgets('legacy email and other fields still pass typed text', (
      tester,
    ) async {
      final calls = <String>[];
      SmartAsyncValidation check() => SmartAsyncValidation(
        debounceDuration: Duration.zero,
        validator: (value) async {
          calls.add(value);
          return null;
        },
      );
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              SmartField.email(
                policy: SmartEmailPolicy.legacy,
                asyncValidation: check(),
              ),
              SmartField.username(asyncValidation: check()),
            ],
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField).first, 'a@b.co');
      await tester.enterText(find.byType(TextFormField).first, ' a@b.co');
      await tester.enterText(find.byType(TextFormField).last, ' user ');
      await tester.pump();
      expect(calls, ['a@b.co', ' user ']);
    });
  });

  group('19P.2 normalizeDigits', () {
    const arabic = '١٢٣٤';
    const persian = '۱۲۳۴';
    const fullwidth = '１２３４';

    test('only the three decimal-digit ranges are mapped', () {
      expect(
        SmartTextUtils.normalizeDigits('$arabic $persian $fullwidth'),
        '1234 1234 1234',
      );
      expect(SmartTextUtils.normalizeDigits('٠٩۰۹０９'), '090909');
      for (final untouched in ['१२३', 'Ⅻ', '²', '٫٬', 'abc 123', '', '一二三']) {
        expect(SmartTextUtils.normalizeDigits(untouched), untouched);
      }
    });

    test('the formatter keeps length, caret, selection and composition', () {
      const formatter = SmartDigitNormalizationFormatter();
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: 'a١٢٣b',
          selection: TextSelection(baseOffset: 1, extentOffset: 3),
        ),
      );
      expect(result.text, 'a123b');
      expect(
        result.selection,
        const TextSelection(baseOffset: 1, extentOffset: 3),
      );
      final composing = _value(
        '١٢',
        composing: const TextRange(start: 0, end: 2),
      );
      expect(
        formatter.formatEditUpdate(TextEditingValue.empty, composing),
        composing,
      );
      final ascii = _value('123');
      expect(
        identical(
          formatter.formatEditUpdate(TextEditingValue.empty, ascii),
          ascii,
        ),
        isTrue,
      );
    });

    testWidgets('digit fields accept the three digit sets when enabled', (
      tester,
    ) async {
      for (final digits in [arabic, persian, fullwidth]) {
        final fields = <String, Widget>{
          'number': SmartField.number(normalizeDigits: true),
          'amount': SmartField.amount(normalizeDigits: true),
          'percentage': SmartField.percentage(normalizeDigits: true),
          'otp': SmartField.otp(length: 4, normalizeDigits: true),
          'phone': SmartField.phone(normalizeDigits: true),
          'card': SmartField.creditCard(normalizeDigits: true),
        };
        for (final field in fields.entries) {
          await tester.pumpWidget(_app(field.value));
          await tester.enterText(find.byType(EditableText).first, digits);
          await tester.pump();
          expect(_text(tester), '1234', reason: '${field.key} $digits');
          await tester.pumpWidget(const SizedBox());
        }
      }
    });

    testWidgets('the default is unchanged', (tester) async {
      await tester.pumpWidget(_app(SmartField.number()));
      await tester.enterText(find.byType(EditableText), arabic);
      expect(_text(tester), isEmpty);
    });

    testWidgets('date, time and card parts are normalised', (tester) async {
      final dates = <String>[];
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              SmartField.date(normalizeDigits: true, onRawChanged: dates.add),
              SmartField.time(normalizeDigits: true),
              SmartField.creditCard(normalizeDigits: true),
            ],
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText).at(0), '٠٤٠٣٢٠٢٠');
      await tester.enterText(find.byType(EditableText).at(1), '۰۹۳۰');
      await tester.enterText(
        find.byType(EditableText).at(2),
        '４１１１１１１１１１１１１１１１',
      );
      await tester.enterText(find.byType(EditableText).at(3), '١٢٣٠');
      await tester.enterText(find.byType(EditableText).at(4), '۱۲۳');
      await tester.pump();
      expect(_text(tester, 0), '04/03/2020');
      expect(dates.last, '2020-03-04');
      expect(_text(tester, 1), '09:30');
      expect(_text(tester, 2), '4111 1111 1111 1111');
      expect(_text(tester, 3), '12/30');
      expect(_text(tester, 4), '123');
    });

    testWidgets('callbacks, raw values and validation see ASCII digits', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final changes = <String>[];
      final raws = <String>[];
      final completed = <String>[];
      final phones = <SmartPhoneValue>[];
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: Column(
              children: [
                SmartField.amount(
                  normalizeDigits: true,
                  allowNegative: true,
                  decimalPlaces: 2,
                  onChanged: changes.add,
                  onRawChanged: raws.add,
                ),
                SmartField.otp(
                  length: 4,
                  normalizeDigits: true,
                  onCompleted: completed.add,
                ),
                SmartField.phone(
                  normalizeDigits: true,
                  initialCountryCode: 'PK',
                  showCountryPicker: true,
                  policy: SmartPhonePolicy.countryAware,
                  onPhoneChanged: phones.add,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText).at(0), '-٠٠١٢.٥');
      await tester.enterText(find.byType(EditableText).at(1), '۱۲۳۴');
      await tester.enterText(find.byType(EditableText).at(2), '۰۳۰۰۱۲۳۴۵۶۷');
      await tester.pump();
      expect(changes, ['-0012.5']);
      expect(raws, ['-0012.5']);
      expect(completed, ['1234']);
      expect(phones.last.e164, '+923001234567');
      expect(formKey.currentState!.validate(), isTrue);
    });

    testWidgets('caret, mixed paste and committed composition', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(SmartField.number(controller: controller, normalizeDigits: true)),
      );
      await tester.showKeyboard(find.byType(TextFormField));
      tester.testTextInput.updateEditingValue(_value('١٢3٤٥', offset: 2));
      await tester.pump();
      expect(controller.text, '12345');
      expect(controller.selection, const TextSelection.collapsed(offset: 2));
      tester.testTextInput.updateEditingValue(
        _value('12345٦', composing: const TextRange(start: 5, end: 6)),
      );
      await tester.pump();
      expect(controller.text, '12345٦');
      tester.testTextInput.updateEditingValue(_value('12345٦'));
      await tester.pump();
      expect(controller.text, '123456');
      tester.testTextInput.updateEditingValue(_value('123456x'));
      await tester.pump();
      expect(controller.text, '123456');
    });
  });

  group('19P.2 acceptDotAsDecimal', () {
    SmartAmountFormatter formatter({
      bool accept = true,
      String grouping = ' ',
      bool useGrouping = false,
      bool allowNegative = true,
      String? currencySymbol,
    }) => SmartAmountFormatter(
      decimalPlaces: 2,
      decimalSeparator: ',',
      groupingSeparator: grouping,
      useGrouping: useGrouping,
      allowNegative: allowNegative,
      currencySymbol: currencySymbol,
      acceptDotAsDecimal: accept,
    );

    TextEditingValue type(
      SmartAmountFormatter formatter,
      String from,
      String to, {
      int? offset,
    }) {
      return formatter.formatEditUpdate(
        _value(from),
        _value(to, offset: offset),
      );
    }

    test('a typed dot becomes the configured comma', () {
      final f = formatter();
      expect(type(f, '12', '12.').text, '12,');
      expect(type(f, '12,', '12,5').text, '12,5');
      expect(type(f, '', '12.5').text, '12,5');
      expect(type(f, '', '-12.5').text, '-12,5');
      expect(type(f, '', '.5').text, ',5');
      expect(type(f, '', '1234.56').text, '1234,56');
      expect(f.normalize('12,5'), '12.5');
      expect(f.format('12,5'), '12,50');
    });

    test('the caret is kept', () {
      final result = type(formatter(), '125', '12.5', offset: 3);
      expect(result.text, '12,5');
      expect(result.selection, const TextSelection.collapsed(offset: 3));
    });

    test('ambiguous or malformed input is not reinterpreted', () {
      final grouped = formatter(grouping: '.', useGrouping: true);
      expect(type(grouped, '12', '12.').text, '12');
      expect(type(grouped, '12', '12.5').text, '12');
      final f = formatter();
      expect(type(f, '12', '1.2.5').text, '12');
      expect(type(f, '1,2', '1,2.5').text, '1,2');
      expect(type(f, '12', '12.345').text, '12');
      expect(type(f, '12', '12.a').text, '12');
    });

    test('the default and the dot separator are unchanged', () {
      expect(type(formatter(accept: false), '12', '12.5').text, '12');
      final dot = SmartAmountFormatter(
        decimalPlaces: 2,
        acceptDotAsDecimal: true,
      );
      expect(type(dot, '12', '12.5').text, '12.5');
      expect(type(dot, '12', '12,5').text, '12');
    });

    test('currency text and exact values are preserved', () {
      final f = formatter(currencySymbol: '€');
      expect(type(f, '', '€12.5').text, '12,5');
      final long = formatter();
      expect(
        long.normalize(type(long, '', '1234567890123456789012345.67').text),
        '1234567890123456789012345.67',
      );
    });

    testWidgets('the amount field forwards the option', (tester) async {
      final raws = <String>[];
      final focus = FocusNode();
      addTearDown(focus.dispose);
      Widget build({required bool accept, String grouping = ' '}) => _app(
        SmartField.amount(
          key: ValueKey('$accept$grouping'),
          focusNode: focus,
          decimalPlaces: 2,
          decimalSeparator: ',',
          groupingSeparator: grouping,
          useGrouping: true,
          acceptDotAsDecimal: accept,
          onRawChanged: raws.add,
        ),
      );
      await tester.pumpWidget(build(accept: true));
      await tester.enterText(find.byType(TextFormField), '1234.5');
      await tester.pump();
      expect(_text(tester), '1234,5');
      expect(raws.last, '1234.5');
      focus.unfocus();
      await tester.pump();
      expect(_text(tester), '1 234,50');
      await tester.pumpWidget(build(accept: false));
      await tester.enterText(find.byType(TextFormField), '12.5');
      expect(_text(tester), isEmpty);
      await tester.pumpWidget(build(accept: true, grouping: '.'));
      await tester.enterText(find.byType(TextFormField), '12.5');
      expect(_text(tester), isNot(contains(',')));
    });
  });

  group('19P.2 AM and PM labels', () {
    const arabic = SmartTimeFormat(
      use24Hour: false,
      amLabel: 'ص',
      pmLabel: 'م',
    );

    test('defaults are unchanged', () {
      const format = SmartTimeFormat(use24Hour: false);
      expect(format.format(const TimeOfDay(hour: 15, minute: 5)), '03:05 PM');
      expect(format.tryParse('03:05 pm'), const TimeOfDay(hour: 15, minute: 5));
      expect(format.tryParse('12:00 Am'), const TimeOfDay(hour: 0, minute: 0));
      expect(format.tryParse('03:05 XM'), isNull);
      expect(format.tryParse('13:05 PM'), isNull);
      expect(format.inputMaskPattern, '##:## AA');
      expect(const SmartTimeFormat().inputMaskPattern, '##:##');
    });

    test('custom labels format and parse', () {
      expect(arabic.format(const TimeOfDay(hour: 15, minute: 5)), '03:05 م');
      expect(arabic.format(const TimeOfDay(hour: 0, minute: 30)), '12:30 ص');
      expect(arabic.tryParse('03:05 م'), const TimeOfDay(hour: 15, minute: 5));
      expect(arabic.tryParse('12:30 ص'), const TimeOfDay(hour: 0, minute: 30));
      expect(arabic.tryParse('03:05 PM'), isNull);
      expect(arabic.inputMaskPattern, '##:## A');
      expect(arabic.labelsFitInputMask, isTrue);
      const dotted = SmartTimeFormat(
        use24Hour: false,
        amLabel: 'a.m.',
        pmLabel: 'p.m.',
      );
      expect(dotted.labelsFitInputMask, isFalse);
      expect(
        dotted.tryParse('03:05 P.M.'),
        const TimeOfDay(hour: 15, minute: 5),
      );
    });

    test('manual 12-hour entry rejects labels that cannot be typed', () {
      expect(
        () =>
            SmartField.time(use24Hour: false, amLabel: 'a.m.', pmLabel: 'p.m.'),
        throwsAssertionError,
      );
      expect(
        () => SmartField.time(
          use24Hour: false,
          mode: SmartTimeMode.picker,
          amLabel: 'a.m.',
          pmLabel: 'p.m.',
        ),
        returnsNormally,
      );
      expect(
        () => SmartField.time(amLabel: 'a.m.', pmLabel: 'p.m.'),
        returnsNormally,
      );
    });

    for (final direction in TextDirection.values) {
      testWidgets('manual entry and raw value in ${direction.name}', (
        tester,
      ) async {
        final formKey = GlobalKey<FormState>();
        final times = <TimeOfDay?>[];
        final rawSaved = <String?>[];
        await tester.pumpWidget(
          _app(
            Form(
              key: formKey,
              child: SmartField.time(
                use24Hour: false,
                amLabel: 'ص',
                pmLabel: 'م',
                initialTime: const TimeOfDay(hour: 15, minute: 5),
                onTimeChanged: times.add,
                onRawSaved: rawSaved.add,
              ),
            ),
            direction: direction,
          ),
        );
        await tester.pump();
        expect(find.text('03:05 م'), findsOneWidget);
        expect(
          tester.widget<EditableText>(find.byType(EditableText)).textDirection,
          TextDirection.ltr,
        );
        formKey.currentState!.save();
        expect(rawSaved.last, '15:05');
        await tester.enterText(find.byType(EditableText), '0930ص');
        await tester.pump();
        expect(_text(tester), '09:30 ص');
        expect(times.last, const TimeOfDay(hour: 9, minute: 30));
        expect(formKey.currentState!.validate(), isTrue);
        formKey.currentState!.save();
        expect(rawSaved.last, '09:30');
      });
    }

    testWidgets('the wheel shows and returns the labels', (tester) async {
      final controller = TextEditingController(text: '10:15 ص');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.time(
            controller: controller,
            mode: SmartTimeMode.wheel,
            use24Hour: false,
            amLabel: 'ص',
            pmLabel: 'م',
          ),
        ),
      );
      await tester.tap(find.byTooltip('Choose time'));
      await tester.pumpAndSettle();
      expect(find.text('ص'), findsWidgets);
      expect(find.text('م'), findsWidgets);
      expect(find.text('AM'), findsNothing);
      await tester.drag(
        find.byType(CupertinoPicker).last,
        const Offset(0, -36),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(controller.text, '10:15 م');
    });

    testWidgets('date-time uses the labels', (tester) async {
      final raws = <String?>[];
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.dateTime(
              use24Hour: false,
              amLabel: 'ص',
              pmLabel: 'م',
              initialDateTime: DateTime(2024, 3, 4, 15, 5),
              onRawSaved: raws.add,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('04/03/2024 03:05 م'), findsOneWidget);
      formKey.currentState!.save();
      expect(raws.last, '2024-03-04T15:05');
    });
  });
}
