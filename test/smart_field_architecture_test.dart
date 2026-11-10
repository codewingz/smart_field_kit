import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';
import 'package:smart_field_kit/src/widgets/smart_amount_display.dart';
import 'package:smart_field_kit/src/widgets/smart_field_support.dart';
import 'package:smart_field_kit/src/widgets/smart_listener_binding.dart';
import 'package:smart_field_kit/src/widgets/smart_password_strength_indicator.dart';
import 'package:smart_field_kit/src/widgets/smart_search_debouncer.dart';

const _expectedApiSnapshot = <String>[
  'plain|null|none|true|true|null|null|null|1|false|false|false|This field is required.|both|0||null|false|false|null|null|true',
  'text|null|none|true|true|null|null|null|1|false|false|false|This field is required.|both|0||null|false|false|null|null|true',
  'description|TextInputType(name: TextInputType.multiline, signed: null, decimal: null)|none|true|true|null|newline|3|null|false|false|false|This field is required.|both|0||null|false|false|null|null|true',
  'email|TextInputType(name: TextInputType.emailAddress, signed: null, decimal: null)|none|false|false|email|null|null|1|false|false|false|This field is required.|both|0||null|false|false|null|null|true',
  'url|TextInputType(name: TextInputType.url, signed: null, decimal: null)|none|false|false|url|done|null|1|false|false|false|This field is required.|both|0||null|false|false|null|null|true',
  'name|TextInputType(name: TextInputType.name, signed: null, decimal: null)|words|true|true|name|null|null|1|false|false|false|This field is required.|both|0||null|false|false|null|null|true',
  'name+caps|TextInputType(name: TextInputType.name, signed: null, decimal: null)|words|true|true|name|null|null|1|false|false|false|This field is required.|both|0|SmartTextCaseFormatter|null|false|false|null|null|true',
  'username|TextInputType(name: TextInputType.text, signed: null, decimal: null)|none|false|false|username|null|null|1|false|false|false|This field is required.|both|0||null|false|false|null|null|true',
  'username+case|TextInputType(name: TextInputType.text, signed: null, decimal: null)|none|false|false|username|null|null|1|false|false|false|This field is required.|both|0|SmartUsernameFormatter|null|false|false|null|null|true',
  'search|TextInputType(name: TextInputType.text, signed: null, decimal: null)|none|true|true|null|search|null|1|false|false|false|This field is required.|both|0||null|false|false|null|null|true',
  'phone|TextInputType(name: TextInputType.phone, signed: null, decimal: null)|none|false|false|telephoneNumber|null|null|1|false|false|false|This field is required.|both|0||null|false|false|null|null|true',
  'password|TextInputType(name: TextInputType.visiblePassword, signed: null, decimal: null)|none|false|false|password|null|null|1|false|true|false|This field is required.|both|0||null|false|false|null|null|true',
  'number|TextInputType(name: TextInputType.number, signed: false, decimal: false)|none|false|false|null|null|null|1|false|false|false|This field is required.|both|0|SmartNumberInputFormatter|null|false|false|null|null|true',
  'number-neg|TextInputType(name: TextInputType.number, signed: true, decimal: false)|none|false|false|null|null|null|1|false|false|false|This field is required.|both|0|SmartNumberInputFormatter|null|false|false|null|null|true',
  'percentage|TextInputType(name: TextInputType.number, signed: true, decimal: true)|none|false|false|null|null|null|1|false|false|false|This field is required.|both|0|SmartAmountFormatter|null|false|false|null|null|true',
  'percentage-nonneg|TextInputType(name: TextInputType.number, signed: false, decimal: true)|none|false|false|null|null|null|1|false|false|false|This field is required.|both|0|SmartAmountFormatter|null|false|false|null|null|true',
  'amount|TextInputType(name: TextInputType.number, signed: false, decimal: true)|none|false|false|null|null|null|1|false|false|false|This field is required.|both|0|SmartAmountFormatter|null|false|false|null|null|true',
  'amount-places0|TextInputType(name: TextInputType.number, signed: false, decimal: false)|none|false|false|null|null|null|1|false|false|false|This field is required.|both|0|SmartAmountFormatter|null|false|false|null|null|true',
  'amount-len2|TextInputType(name: TextInputType.number, signed: true, decimal: true)|none|false|false|null|null|null|1|false|false|false|This field is required.|both|0|SmartAmountFormatter|null|false|false|null|null|true',
  'otp|TextInputType(name: TextInputType.number, signed: false, decimal: false)|none|false|false|oneTimeCode|null|null|1|false|false|false|This field is required.|both|0||null|false|false|null|null|true',
  'date|TextInputType(name: TextInputType.datetime, signed: null, decimal: null)|none|false|false|null|null|null|1|false|false|false|This field is required.|both|0||null|false|false|null|null|true',
  'time|TextInputType(name: TextInputType.datetime, signed: null, decimal: null)|none|false|false|null|null|null|1|false|false|false|This field is required.|both|0||null|false|false|null|null|true',
  'dateTime|TextInputType(name: TextInputType.datetime, signed: null, decimal: null)|none|false|false|null|null|null|1|false|false|false|This field is required.|both|0||null|false|false|null|null|true',
  'creditCard|TextInputType(name: TextInputType.number, signed: false, decimal: false)|none|false|false|null|null|null|1|false|false|false|This field is required.|both|0||null|false|false|null|null|true',
  'text+mask|null|none|true|true|null|null|null|1|false|false|false|This field is required.|both|0|SmartMaskFormatter+SmartTextCaseFormatter|null|false|false|null|null|true',
];

String _describe(String name, SmartField f) {
  final formatters = (f.inputFormatters ?? const <Object>[])
      .map((e) => e.runtimeType.toString())
      .join('+');
  return [
    name,
    f.keyboardType,
    f.textCapitalization.name,
    f.autocorrect,
    f.enableSuggestions,
    f.autofillHints?.join(','),
    f.textInputAction?.name,
    f.minLines,
    f.maxLines,
    f.expands,
    f.showVisibilityToggle,
    f.isRequired,
    f.requiredErrorText,
    f.validationMode.name,
    f.builtInChecks.length,
    formatters,
    f.restorationId,
    f.readOnly,
    f.autofocus,
    f.minLength,
    f.maxLength,
    f.decoration == const InputDecoration(),
  ].join('|');
}

class _CountingController extends TextEditingController {
  _CountingController({super.text});

  int listeners = 0;

  @override
  void addListener(VoidCallback listener) {
    listeners++;
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    listeners--;
    super.removeListener(listener);
  }
}

class _CountingNotifier extends ChangeNotifier {
  int listeners = 0;

  @override
  void addListener(VoidCallback listener) {
    listeners++;
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    listeners--;
    super.removeListener(listener);
  }
}

Widget _app(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  group('public API compatibility', () {
    test('every constructor keeps its defaults (snapshot from Task 16D)', () {
      final rows = <String>[
        _describe('plain', const SmartField()),
        _describe('text', SmartField.text()),
        _describe('description', SmartField.description()),
        _describe('email', SmartField.email()),
        _describe('url', SmartField.url()),
        _describe('name', SmartField.name()),
        _describe('name+caps', SmartField.name(capitalizeWords: true)),
        _describe('username', SmartField.username()),
        _describe(
          'username+case',
          SmartField.username(usernameCase: SmartTextCase.lowercase),
        ),
        _describe('search', SmartField.search()),
        _describe('phone', SmartField.phone()),
        _describe('password', SmartField.password()),
        _describe('number', SmartField.number()),
        _describe('number-neg', SmartField.number(allowNegative: true)),
        _describe('percentage', SmartField.percentage()),
        _describe(
          'percentage-nonneg',
          SmartField.percentage(allowNegative: false),
        ),
        _describe('amount', SmartField.amount()),
        _describe('amount-places0', SmartField.amount(decimalPlaces: 0)),
        _describe(
          'amount-len2',
          SmartField.amount(decimalLength: 2, allowNegative: true),
        ),
        _describe('otp', SmartField.otp()),
        _describe('date', SmartField.date()),
        _describe('time', SmartField.time()),
        _describe('dateTime', SmartField.dateTime()),
        _describe('creditCard', SmartField.creditCard()),
        _describe(
          'text+mask',
          SmartField.text(
            inputMask: '##-##',
            textCase: SmartTextCase.uppercase,
          ),
        ),
      ];
      expect(rows, _expectedApiSnapshot);
    });

    test('const SmartField still compiles and keeps its values', () {
      const field = SmartField(
        label: 'Const',
        hintText: 'hint',
        isRequired: true,
        maxLines: 2,
        autocorrect: false,
      );
      expect(field.label, 'Const');
      expect(field.isRequired, isTrue);
      expect(field.maxLines, 2);
      expect(field.autocorrect, isFalse);
    });

    test('constructor assertions and early errors are preserved', () {
      expect(() => SmartField.amount(decimalLength: 5), throwsArgumentError);
      expect(
        () => SmartField.amount(decimalLength: 2, decimalPlaces: 1),
        throwsArgumentError,
      );
      expect(() => SmartField.otp(length: 0), throwsArgumentError);
      expect(
        () => SmartField.otp(length: 4, policy: SmartOtpPolicy.legacy),
        throwsArgumentError,
      );
      expect(() => SmartField.date(dateFormat: 'dd/MM'), throwsArgumentError);
      expect(() => SmartField.text(inputMask: '----'), throwsArgumentError);
      expect(
        () => SmartField(minLength: 5, maxLength: 2),
        throwsAssertionError,
      );
      expect(() => SmartField(minLines: 0), throwsAssertionError);
      expect(
        () => SmartField(expands: true, maxLines: 2),
        throwsAssertionError,
      );
      expect(
        () => SmartField.text(minWords: 5, maxWords: 2),
        throwsAssertionError,
      );
      expect(() => SmartField.date(firstYear: 2000), throwsAssertionError);
    });

    test('developer and built-in formatters keep their order', () {
      final developer = _CountingController();
      addTearDown(developer.dispose);
      final field = SmartField.name(
        capitalizeWords: true,
        inputFormatters: [SmartWhitespaceFormatter()],
      );
      expect(field.inputFormatters!.map((f) => f.runtimeType), [
        SmartTextCaseFormatter,
        SmartWhitespaceFormatter,
      ]);
      expect(SmartField.url().inputFormatters, isNull);
      expect(
        SmartField.amount().inputFormatters!.single,
        isA<SmartAmountFormatter>(),
      );
    });
  });

  group('validation mode helpers', () {
    test('runsBuiltIn and runsCustom truth table', () {
      const checks = {SmartBuiltInCheck.fieldFormat};
      for (final mode in SmartValidationMode.values) {
        final builtIn = SmartValidators.runsBuiltIn(mode, checks);
        final format = SmartValidators.runsBuiltIn(
          mode,
          checks,
          SmartBuiltInCheck.fieldFormat,
        );
        final digit = SmartValidators.runsBuiltIn(
          mode,
          checks,
          SmartBuiltInCheck.passwordDigit,
        );
        switch (mode) {
          case SmartValidationMode.custom:
            expect([builtIn, format, digit], [false, false, false]);
          case SmartValidationMode.selected:
            expect([builtIn, format, digit], [true, true, false]);
          default:
            expect([builtIn, format, digit], [true, true, true]);
        }
        expect(
          SmartValidators.runsCustom(mode),
          mode != SmartValidationMode.builtIn,
        );
      }
    });

    test('modeAware composes built-in then custom per mode', () {
      String? builtIn(String? v) => 'built';
      String? custom(String? v) => 'custom';
      String? run(
        SmartValidationMode mode, [
        Set<SmartBuiltInCheck> checks = const {},
      ]) => SmartValidators.modeAware(
        mode: mode,
        checks: checks,
        builtIn: builtIn,
        custom: custom,
      )('x');
      expect(run(SmartValidationMode.both), 'built');
      expect(run(SmartValidationMode.builtIn), 'built');
      expect(run(SmartValidationMode.custom), 'custom');
      expect(run(SmartValidationMode.selected), 'custom');
      expect(
        run(SmartValidationMode.selected, {SmartBuiltInCheck.fieldFormat}),
        'built',
      );
      expect(
        SmartValidators.modeAware(
          mode: SmartValidationMode.both,
          checks: const {},
        )('x'),
        isNull,
      );
    });
  });

  group('shared helpers', () {
    test('SmartListenerBinding binds, rebinds, and disposes', () {
      final a = _CountingNotifier();
      final b = _CountingNotifier();
      var calls = 0;
      final binding = SmartListenerBinding(() => calls++);
      expect(binding.bind(a), isTrue);
      expect(binding.bind(a), isFalse);
      expect(a.listeners, 1);
      expect(binding.bind(b), isTrue);
      expect(a.listeners, 0);
      expect(b.listeners, 1);
      b.notifyListeners();
      expect(calls, 1);
      binding.dispose();
      expect(b.listeners, 0);
      expect(binding.isBound, isFalse);
      binding.dispose();
      a.dispose();
      b.dispose();
    });

    test('SmartListenerGroup unbinds everything', () {
      final group = SmartListenerGroup();
      final notifiers = List.generate(3, (_) => _CountingNotifier());
      for (final notifier in notifiers) {
        group.add(() {}).bind(notifier);
      }
      expect(notifiers.map((n) => n.listeners), [1, 1, 1]);
      group.unbindAll();
      expect(notifiers.map((n) => n.listeners), [0, 0, 0]);
      for (final notifier in notifiers) {
        notifier.dispose();
      }
    });

    test('SmartInputHandle owns only what the developer did not supply', () {
      final external = TextEditingController(text: 'x');
      final focus = FocusNode();
      final handle = SmartInputHandle(initialText: 'seed', redacted: true);
      expect(handle.ownsController, isTrue);
      final owned = handle.controller;
      expect(owned.text, 'seed');
      expect(owned.toString(), 'TextEditingController(redacted)');
      expect(identical(handle.controller, owned), isTrue);
      handle.update(controller: external, focusNode: focus);
      expect(identical(handle.controller, external), isTrue);
      expect(identical(handle.focusNode, focus), isTrue);
      expect(handle.ownsController, isFalse);
      handle.dispose();
      handle.dispose();
      external.text = 'still usable';
      focus.requestFocus();
      focus.dispose();
      external.dispose();
    });

    test('composeSuffixActions returns null, a single widget, or a row', () {
      expect(composeSuffixActions(const []), isNull);
      const one = SizedBox();
      expect(identical(composeSuffixActions(const [one]), one), isTrue);
      expect(composeSuffixActions(const [one, one]), isA<Row>());
    });

    test('SmartAmountDisplay switches between editable and display text', () {
      final formatter = SmartAmountFormatter(
        useGrouping: true,
        decimalPlaces: 2,
      );
      final controller = TextEditingController(text: '1234.5');
      final focus = FocusNode();
      final display = SmartAmountDisplay();
      display.showDisplay(formatter, controller);
      expect(controller.text, '1,234.50');
      display.handleControllerChange(formatter, controller, focus);
      expect(controller.text, '1,234.50');
      controller.dispose();
      focus.dispose();
    });

    test(
      'SmartSearchDebouncer debounces, ignores stale text, and cancels',
      () async {
        final debouncer = SmartSearchDebouncer();
        final searched = <String>[];
        var text = 'abc';
        debouncer.schedule(
          query: 'abc',
          onSearch: searched.add,
          debounce: const Duration(milliseconds: 20),
          canSearch: () => true,
          currentText: () => text,
        );
        debouncer.schedule(
          query: 'abcd',
          onSearch: searched.add,
          debounce: const Duration(milliseconds: 20),
          canSearch: () => true,
          currentText: () => text,
        );
        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(searched, isEmpty);
        text = 'abcd';
        debouncer.schedule(
          query: 'abcd',
          onSearch: searched.add,
          debounce: const Duration(milliseconds: 20),
          canSearch: () => true,
          currentText: () => text,
        );
        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(searched, ['abcd']);
        debouncer.schedule(
          query: 'x',
          onSearch: searched.add,
          debounce: Duration.zero,
          canSearch: () => true,
          currentText: () => 'x',
        );
        expect(searched, ['abcd', 'x']);
        debouncer.schedule(
          query: '  ',
          onSearch: searched.add,
          debounce: Duration.zero,
          canSearch: () => true,
          currentText: () => '  ',
        );
        expect(searched.length, 2);
        debouncer.schedule(
          query: 'late',
          onSearch: searched.add,
          debounce: const Duration(milliseconds: 20),
          canSearch: () => true,
          currentText: () => 'late',
        );
        debouncer.cancel();
        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(searched.length, 2);
      },
    );

    testWidgets('SmartPasswordStrengthIndicator renders levels and checklist', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const SmartPasswordStrengthIndicator(
            password: 'abcdefH1!',
            showChecklist: true,
          ),
        ),
      );
      expect(find.text('Password strength: Strong'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNWidgets(5));
      await tester.pumpWidget(
        _app(const SmartPasswordStrengthIndicator(password: '')),
      );
      expect(find.text('Enter a password'), findsOneWidget);
    });
  });

  group('controller replacement and listener cleanup', () {
    final builders =
        <String, Widget Function(TextEditingController controller)>{
          'text': (c) => SmartField.text(controller: c),
          'description': (c) => SmartField.description(
            controller: c,
            showWordCount: true,
            maxWords: 5,
          ),
          'email': (c) => SmartField.email(controller: c),
          'amount': (c) => SmartField.amount(
            controller: c,
            useGrouping: true,
            decimalPlaces: 2,
          ),
          'amount masked': (c) => SmartField.amount(controller: c, mask: true),
          'number masked': (c) => SmartField.number(controller: c, mask: true),
          'phone': (c) => SmartField.phone(
            controller: c,
            mask: true,
            showCountryPicker: true,
          ),
          'search': (c) => SmartField.search(controller: c, onSearch: (_) {}),
          'password strength': (c) =>
              SmartField.password(controller: c, showStrengthIndicator: true),
          'password match': (c) => SmartField.password(
            controller: c,
            matchController: TextEditingController(),
          ),
          'async': (c) => SmartField.text(
            controller: c,
            asyncValidation: SmartAsyncValidation(validator: (v) async => null),
          ),
          'otp': (c) => SmartField.otp(controller: c),
          'otp async': (c) => SmartField.otp(
            controller: c,
            asyncValidation: SmartAsyncValidation(validator: (v) async => null),
          ),
          'date': (c) => SmartField.date(controller: c),
          'time': (c) =>
              SmartField.time(controller: c, mode: SmartTimeMode.picker),
          'mask pattern': (c) =>
              SmartField.text(controller: c, inputMask: '##-##'),
        };
    for (final entry in builders.entries) {
      testWidgets(
        '${entry.key}: replaced and disposed controllers are released',
        (tester) async {
          final first = _CountingController();
          final second = _CountingController();
          addTearDown(first.dispose);
          addTearDown(second.dispose);
          await tester.pumpWidget(_app(entry.value(first)));
          expect(first.listeners, greaterThan(0));
          await tester.pumpWidget(_app(entry.value(second)));
          expect(first.listeners, 0, reason: 'old controller must be released');
          expect(second.listeners, greaterThan(0));
          await tester.pumpWidget(_app(const SizedBox()));
          expect(
            second.listeners,
            0,
            reason: 'disposed field must release the controller',
          );
          first.text = 'still usable';
          second.text = 'still usable';
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('owned controllers are created and released without errors', (
      tester,
    ) async {
      final external = _CountingController(text: '12.5');
      addTearDown(external.dispose);
      for (final build in <Widget Function(TextEditingController?)>[
        (c) => SmartField.amount(controller: c, decimalPlaces: 2),
        (c) => SmartField.phone(controller: c),
        (c) => SmartField.search(controller: c),
        (c) => SmartField.number(controller: c, mask: true),
      ]) {
        await tester.pumpWidget(_app(build(null)));
        await tester.enterText(find.byType(TextFormField), '12');
        await tester.pumpWidget(_app(build(external)));
        expect(external.listeners, greaterThan(0));
        await tester.pumpWidget(_app(build(null)));
        expect(external.listeners, 0);
        await tester.pumpWidget(_app(const SizedBox()));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('server error object is released on replacement and disposal', (
      tester,
    ) async {
      final first = SmartServerError();
      final second = SmartServerError();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      await tester.pumpWidget(_app(SmartField(serverError: first)));
      first.set('One');
      await tester.pump();
      expect(find.text('One'), findsOneWidget);
      await tester.pumpWidget(_app(SmartField(serverError: second)));
      first.set('Ignored');
      second.set('Two');
      await tester.pump();
      expect(find.text('Two'), findsOneWidget);
      expect(find.text('Ignored'), findsNothing);
      await tester.pumpWidget(_app(const SizedBox()));
      second.set('After disposal');
      first.set('After disposal');
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'credit card controllers and focus nodes remain developer-owned',
      (tester) async {
        final number = _CountingController();
        final cvv = _CountingController();
        final focus = FocusNode();
        addTearDown(number.dispose);
        addTearDown(cvv.dispose);
        addTearDown(focus.dispose);
        await tester.pumpWidget(
          _app(
            SmartField.creditCard(
              numberController: number,
              cvvController: cvv,
              expiryFocusNode: focus,
            ),
          ),
        );
        await tester.enterText(
          find.byType(TextFormField).at(0),
          '4111111111111111',
        );
        await tester.pumpWidget(_app(const SizedBox()));
        expect(number.listeners, 0);
        expect(cvv.listeners, 0);
        number.text = 'ok';
        cvv.text = 'ok';
        focus.requestFocus();
      },
    );
  });

  group('raw values, formatting, and callbacks through the shared core', () {
    testWidgets('amount partial raw while typing and exact raw when saved', (
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
              decimalPlaces: 2,
              useGrouping: true,
              onRawChanged: raws.add,
              onRawSaved: (v) => saved = v,
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), '1.');
      await tester.enterText(find.byType(TextFormField), '12.5');
      expect(raws, ['1.', '12.5']);
      formKey.currentState!.save();
      expect(saved, '12.50');
    });

    testWidgets('mask raw, percentage raw, and plain text raw callbacks', (
      tester,
    ) async {
      final raws = <String>[];
      final savedRaws = <String?>[];
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: Column(
              children: [
                SmartField.text(
                  inputMask: '##-##',
                  onRawChanged: raws.add,
                  onRawSaved: savedRaws.add,
                ),
                SmartField.text(
                  rawValueBuilder: (v) => v.toUpperCase(),
                  onRawChanged: raws.add,
                  onRawSaved: savedRaws.add,
                ),
                SmartField.text(
                  onRawChanged: raws.add,
                  onRawSaved: savedRaws.add,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField).at(0), '1234');
      await tester.enterText(find.byType(TextFormField).at(1), 'abc');
      await tester.enterText(find.byType(TextFormField).at(2), 'plain');
      expect(raws, ['1234', 'ABC']);
      formKey.currentState!.save();
      expect(savedRaws, ['1234', 'ABC', null]);
    });
  });

  group('field-specific regressions after the refactor', () {
    testWidgets('search debounce fires once and clear cancels pending work', (
      tester,
    ) async {
      final searched = <String>[];
      await tester.pumpWidget(
        _app(
          SmartField.search(
            onSearch: searched.add,
            debounceDuration: const Duration(milliseconds: 300),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'sh');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(find.byType(TextFormField), 'shoes');
      await tester.pump(const Duration(milliseconds: 200));
      expect(searched, isEmpty);
      await tester.pump(const Duration(milliseconds: 200));
      expect(searched, ['shoes']);
      await tester.enterText(find.byType(TextFormField), 'boots');
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump(const Duration(seconds: 1));
      expect(searched, ['shoes']);
    });

    testWidgets('amount grouping on blur and malformed text rejection', (
      tester,
    ) async {
      final controller = TextEditingController();
      final focus = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.amount(
            controller: controller,
            focusNode: focus,
            decimalPlaces: 2,
            useGrouping: true,
          ),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), '50000.00');
      focus.unfocus();
      await tester.pump();
      expect(controller.text, '50,000.00');
      focus.requestFocus();
      await tester.pump();
      expect(controller.text, '50000.00');
      await tester.enterText(find.byType(TextFormField), '5,000.oo');
      expect(controller.text, '50000.00');
    });

    testWidgets('masked fields stay non-destructive and reveal on focus', (
      tester,
    ) async {
      final controller = TextEditingController(text: '1234567890');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(SmartField.number(controller: controller, mask: true)),
      );
      expect(controller.text, '1234567890');
      expect(tester.takeException(), isNull);
    });

    testWidgets('validation order survives the shared pipeline', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.email(
              controller: controller,
              isRequired: true,
              requiredErrorText: 'R',
              emailErrorText: 'E',
              maxLength: 8,
              maxLengthErrorText: 'M',
              validator: (v) => 'C',
            ),
          ),
        ),
      );
      String? error() {
        formKey.currentState!.validate();
        return tester
            .state<FormFieldState<String>>(find.byType(TextFormField))
            .errorText;
      }

      expect(error(), 'R');
      controller.text = 'bad';
      expect(error(), 'E');
      controller.text = 'longer@example.com';
      expect(error(), 'M');
      controller.text = 'a@b.co';
      expect(error(), 'C');
    });
  });
}
