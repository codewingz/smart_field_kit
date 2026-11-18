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

Future<void> _pickPakistan(WidgetTester tester) async {
  await tester.tap(find.text('+1'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).last, 'Pakistan');
  await tester.pumpAndSettle();
  await tester.tap(find.text('Pakistan').last);
  await tester.pumpAndSettle();
}

class _PhoneHarness {
  final formKey = GlobalKey<FormState>();
  final countries = <String>[];
  final phones = <SmartPhoneValue>[];
  final changes = <String>[];
  bool mask = false;
  bool enabled = true;
  SmartServerError? serverError;
  SmartAsyncValidation? asyncValidation;
  TextEditingController? controller;
  FocusNode? focusNode;
  late StateSetter _setState;

  Widget build() => _app(
    StatefulBuilder(
      builder: (context, setState) {
        _setState = setState;
        return Form(
          key: formKey,
          child: SmartField.phone(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            showCountryPicker: true,
            initialCountryCode: 'US',
            policy: SmartPhonePolicy.countryAware,
            mask: mask,
            serverError: serverError,
            asyncValidation: asyncValidation,
            onChanged: changes.add,
            onCountryChanged: (country) =>
                countries.add(country?.isoCode ?? 'none'),
            onPhoneChanged: phones.add,
          ),
        );
      },
    ),
  );

  Future<void> update(WidgetTester tester, VoidCallback change) async {
    _setState(change);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }

  Future<void> start(WidgetTester tester) async {
    await tester.pumpWidget(build());
    await _pickPakistan(tester);
    await tester.enterText(find.byType(TextFormField), '03001234567');
    await tester.pump();
    expect(find.text('+92'), findsOneWidget);
    expect(phones.last.e164, '+923001234567');
    expect(formKey.currentState!.validate(), isTrue);
  }

  void expectPakistan() {
    expect(find.text('+92'), findsOneWidget);
    expect(find.text('+1'), findsNothing);
    expect(formKey.currentState!.validate(), isTrue);
    expect(countries, ['PK']);
  }
}

Future<int> _nativeFormChangesForOneEdit(WidgetTester tester) async {
  var changes = 0;
  final controller = TextEditingController(text: '50000.00');
  await tester.pumpWidget(
    _app(
      Form(
        onChanged: () => changes++,
        child: TextFormField(controller: controller),
      ),
    ),
  );
  await tester.enterText(find.byType(TextFormField), '1234567.89');
  await tester.pump();
  await tester.pumpWidget(_app(const SizedBox()));
  controller.dispose();
  return changes;
}

TextEditingValue _composing(String text, {int start = 0}) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: text.length),
  composing: TextRange(start: start, end: text.length),
);

TextEditingValue _committed(String text) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: text.length),
);

void main() {
  group('19N phone country survives unrelated feature changes', () {
    testWidgets('toggling the mask repeatedly keeps Pakistan', (tester) async {
      final harness = _PhoneHarness();
      await harness.start(tester);
      final phoneEvents = harness.phones.length;
      for (var i = 0; i < 3; i++) {
        await harness.update(tester, () => harness.mask = true);
        expect(harness.formKey.currentState!.validate(), isTrue);
        await harness.update(tester, () => harness.mask = false);
        harness.expectPakistan();
      }
      expect(harness.phones.length, phoneEvents);
      expect(harness.changes, ['03001234567']);
      expect(find.text('03001234567'), findsOneWidget);
    });

    testWidgets('attaching and removing a server error keeps Pakistan', (
      tester,
    ) async {
      final harness = _PhoneHarness();
      final server = SmartServerError();
      addTearDown(server.dispose);
      await harness.start(tester);
      final phoneEvents = harness.phones.length;
      await harness.update(tester, () => harness.serverError = server);
      harness.expectPakistan();
      await harness.update(tester, () => harness.serverError = null);
      harness.expectPakistan();
      expect(harness.phones.length, phoneEvents);
      expect(harness.changes, ['03001234567']);
    });

    testWidgets('enabling and disabling async validation keeps Pakistan', (
      tester,
    ) async {
      final harness = _PhoneHarness();
      final calls = <String>[];
      await harness.start(tester);
      await harness.update(
        tester,
        () => harness.asyncValidation = SmartAsyncValidation(
          debounceDuration: Duration.zero,
          validator: (value) async {
            calls.add(value);
            return null;
          },
        ),
      );
      await tester.pump();
      harness.expectPakistan();
      expect(calls, ['03001234567']);
      await harness.update(tester, () => harness.asyncValidation = null);
      harness.expectPakistan();
      expect(calls, ['03001234567']);
    });

    testWidgets('the next edit is parsed with the kept country', (
      tester,
    ) async {
      final harness = _PhoneHarness();
      final server = SmartServerError();
      addTearDown(server.dispose);
      await harness.start(tester);
      await harness.update(tester, () => harness.mask = true);
      await harness.update(tester, () => harness.mask = false);
      await harness.update(tester, () => harness.serverError = server);
      await tester.enterText(find.byType(TextFormField), '03001234568');
      await tester.pump();
      expect(harness.phones.last.country?.isoCode, 'PK');
      expect(harness.phones.last.e164, '+923001234568');
      expect(harness.phones.last.isValid, isTrue);
      expect(harness.countries, ['PK']);
    });

    testWidgets('controller and focus node replacement keep Pakistan', (
      tester,
    ) async {
      final harness = _PhoneHarness();
      final first = TextEditingController();
      final second = TextEditingController(text: '03001234567');
      final focus = FocusNode();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      addTearDown(focus.dispose);
      harness.controller = first;
      await harness.start(tester);
      await harness.update(tester, () => harness.controller = second);
      harness.expectPakistan();
      await harness.update(tester, () => harness.focusNode = focus);
      harness.expectPakistan();
      await harness.update(tester, () {
        harness.controller = null;
        harness.focusNode = null;
        harness.mask = true;
      });
      await harness.update(tester, () => harness.mask = false);
      harness.expectPakistan();
      expect(find.text('03001234567'), findsOneWidget);
    });

    testWidgets('rebuilds and disable then enable keep Pakistan', (
      tester,
    ) async {
      final harness = _PhoneHarness();
      await harness.start(tester);
      await harness.update(tester, () {});
      await harness.update(tester, () => harness.enabled = false);
      await harness.update(tester, () => harness.mask = true);
      await harness.update(tester, () => harness.mask = false);
      await harness.update(tester, () => harness.enabled = true);
      harness.expectPakistan();
      expect(harness.changes, ['03001234567']);
    });

    testWidgets('focus and selection survive a feature change', (tester) async {
      final harness = _PhoneHarness();
      final controller = TextEditingController();
      final server = SmartServerError();
      addTearDown(controller.dispose);
      addTearDown(server.dispose);
      harness.controller = controller;
      await harness.start(tester);
      await tester.showKeyboard(find.byType(TextFormField));
      controller.selection = const TextSelection(
        baseOffset: 2,
        extentOffset: 5,
      );
      await tester.pump();
      await harness.update(tester, () => harness.serverError = server);
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.focusNode.hasFocus, isTrue);
      expect(
        controller.selection,
        const TextSelection(baseOffset: 2, extentOffset: 5),
      );
      harness.expectPakistan();
    });

    testWidgets('a remounted field starts from its configuration', (
      tester,
    ) async {
      final harness = _PhoneHarness();
      await harness.start(tester);
      await tester.pumpWidget(_app(const SizedBox()));
      await tester.pump(const Duration(seconds: 1));
      final events = harness.phones.length;
      await tester.pumpWidget(harness.build());
      await tester.pump();
      expect(find.text('+1'), findsOneWidget);
      expect(harness.countries, ['PK']);
      expect(harness.phones.length, events);
      expect(harness.changes, ['03001234567']);
    });
  });

  group('19N other feature state survives unrelated changes', () {
    testWidgets('a revealed password stays revealed', (tester) async {
      final server = SmartServerError();
      addTearDown(server.dispose);
      SmartServerError? attached;
      SmartAsyncValidation? asyncValidation;
      var strength = false;
      late StateSetter rebuild;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return SmartField.password(
                serverError: attached,
                asyncValidation: asyncValidation,
                showStrengthIndicator: strength,
              );
            },
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'Secret123');
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      bool obscured() =>
          tester.widget<EditableText>(find.byType(EditableText)).obscureText;
      expect(obscured(), isFalse);

      rebuild(() => attached = server);
      await tester.pump();
      expect(obscured(), isFalse);
      rebuild(
        () => asyncValidation = SmartAsyncValidation(
          trigger: SmartAsyncValidationTrigger.manual,
          validator: (value) async => null,
        ),
      );
      await tester.pump();
      expect(obscured(), isFalse);
      rebuild(() => strength = true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(obscured(), isFalse);
      expect(find.byTooltip('Hide password'), findsOneWidget);
      expect(find.text('Secret123'), findsOneWidget);
    });

    testWidgets('a pending search survives attaching a server error', (
      tester,
    ) async {
      final server = SmartServerError();
      addTearDown(server.dispose);
      final searches = <String>[];
      SmartServerError? attached;
      late StateSetter rebuild;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return SmartField.search(
                serverError: attached,
                onSearch: (query) => searches.add(query),
              );
            },
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'query');
      await tester.pump(const Duration(milliseconds: 100));
      rebuild(() => attached = server);
      await tester.pump(const Duration(milliseconds: 200));
      expect(searches, ['query']);
    });

    testWidgets('an async result survives attaching a server error', (
      tester,
    ) async {
      final server = SmartServerError();
      addTearDown(server.dispose);
      var calls = 0;
      SmartServerError? attached;
      late StateSetter rebuild;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return SmartField.username(
                serverError: attached,
                asyncValidation: SmartAsyncValidation(
                  debounceDuration: Duration.zero,
                  validator: (value) async {
                    calls++;
                    return 'Taken';
                  },
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
      rebuild(() => attached = server);
      await tester.pump();
      await tester.pump();
      expect(find.text('Taken'), findsOneWidget);
      expect(calls, 1);
    });
  });

  group('19N amount display formatting is not a form change', () {
    testWidgets('load, focus and blur do not notify the form', (tester) async {
      var formChanges = 0;
      final changes = <String>[];
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        _app(
          Form(
            onChanged: () => formChanges++,
            child: SmartField.amount(
              focusNode: focus,
              initialValue: '50000',
              useGrouping: true,
              decimalPlaces: 2,
              onChanged: changes.add,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('50,000.00'), findsOneWidget);
      expect(formChanges, 0);
      focus.requestFocus();
      await tester.pump();
      expect(find.text('50000.00'), findsOneWidget);
      expect(formChanges, 0);
      focus.unfocus();
      await tester.pump();
      expect(find.text('50,000.00'), findsOneWidget);
      expect(formChanges, 0);
      expect(changes, isEmpty);
    });

    testWidgets('onUserInteraction shows no error before an edit', (
      tester,
    ) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.amount(
            focusNode: focus,
            initialValue: '5',
            minValue: '10',
            decimalPlaces: 2,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('5.00'), findsOneWidget);
      expect(find.textContaining('at least'), findsNothing);
      focus.requestFocus();
      await tester.pump();
      await tester.pump();
      focus.unfocus();
      await tester.pump();
      await tester.pump();
      expect(find.textContaining('at least'), findsNothing);
      await tester.enterText(find.byType(TextFormField), '6');
      await tester.pump();
      expect(find.textContaining('at least'), findsOneWidget);
    });

    testWidgets('an invalid initial value is left alone without a change', (
      tester,
    ) async {
      var formChanges = 0;
      final controller = TextEditingController(text: '5,000.oo');
      addTearDown(controller.dispose);
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            onChanged: () => formChanges++,
            child: SmartField.amount(
              controller: controller,
              useGrouping: true,
              decimalPlaces: 2,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(controller.text, '5,000.oo');
      expect(formChanges, 0);
      expect(formKey.currentState!.validate(), isFalse);
    });

    testWidgets('an external controller and its replacement stay silent', (
      tester,
    ) async {
      var formChanges = 0;
      final first = TextEditingController(text: '1234');
      final second = TextEditingController(text: '98765.4');
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      Widget build(TextEditingController controller) => _app(
        Form(
          onChanged: () => formChanges++,
          child: SmartField.amount(
            controller: controller,
            useGrouping: true,
            decimalPlaces: 2,
          ),
        ),
      );
      await tester.pumpWidget(build(first));
      await tester.pump();
      expect(first.text, '1,234.00');
      await tester.pumpWidget(build(second));
      await tester.pump();
      await tester.pump();
      expect(second.text, '98,765.40');
      expect(first.text, '1,234.00');
      expect(formChanges, 0);
    });

    testWidgets('real edits notify like a native field and save exact values', (
      tester,
    ) async {
      var formChanges = 0;
      final nativeChanges = await _nativeFormChangesForOneEdit(tester);
      final changes = <String>[];
      final raws = <String>[];
      final saved = <String?>[];
      final rawSaved = <String?>[];
      final formKey = GlobalKey<FormState>();
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            onChanged: () => formChanges++,
            child: SmartField.amount(
              focusNode: focus,
              initialValue: '50000',
              useGrouping: true,
              decimalPlaces: 2,
              onChanged: changes.add,
              onRawChanged: raws.add,
              onSaved: saved.add,
              onRawSaved: rawSaved.add,
            ),
          ),
        ),
      );
      await tester.pump();
      formKey.currentState!.save();
      expect(saved, ['50,000.00']);
      expect(rawSaved, ['50000.00']);

      await tester.showKeyboard(find.byType(TextFormField));
      await tester.pump();
      formKey.currentState!.save();
      expect(saved.last, '50000.00');
      expect(rawSaved.last, '50000.00');
      expect(formChanges, 0);

      await tester.enterText(find.byType(TextFormField), '1234567.89');
      await tester.pump();
      expect(changes.length, 1);
      expect(formChanges, nativeChanges);
      expect(raws.length, 1);
      focus.unfocus();
      await tester.pump();
      expect(formChanges, nativeChanges);
      formKey.currentState!.save();
      expect(rawSaved.last, raws.last);
      expect(
        saved.last,
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      );
    });

    testWidgets('a programmatic controller change notifies the form once', (
      tester,
    ) async {
      var formChanges = 0;
      final controller = TextEditingController(text: '10');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          Form(
            onChanged: () => formChanges++,
            child: SmartField.amount(controller: controller, decimalPlaces: 2),
          ),
        ),
      );
      await tester.pump();
      expect(formChanges, 0);
      controller.text = '777';
      await tester.pump();
      expect(controller.text, '777.00');
      expect(formChanges, 1);
    });

    testWidgets('reset restores the display and clears interaction', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.amount(
              focusNode: focus,
              initialValue: '5',
              minValue: '10',
              decimalPlaces: 2,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), '7');
      await tester.pump();
      expect(find.textContaining('at least'), findsOneWidget);
      focus.unfocus();
      await tester.pump();
      formKey.currentState!.reset();
      await tester.pump();
      await tester.pump();
      expect(find.text('5.00'), findsOneWidget);
      expect(find.textContaining('at least'), findsNothing);
      focus.requestFocus();
      await tester.pump();
      await tester.pump();
      focus.unfocus();
      await tester.pump();
      await tester.pump();
      expect(find.textContaining('at least'), findsNothing);
      expect(formKey.currentState!.validate(), isFalse);
    });
  });

  group('19N a rejected commit restores the text before composition', () {
    test('number formatter drops rejected composed text', () {
      const formatter = SmartNumberInputFormatter();
      expect(
        formatter.formatEditUpdate(_composing('abc'), _committed('abc')),
        _committed(''),
      );
      expect(
        formatter.formatEditUpdate(
          _composing('12ab', start: 2),
          _committed('12ab'),
        ),
        _committed('12'),
      );
      expect(
        formatter.formatEditUpdate(_composing('に'), _committed('日本')),
        _committed(''),
      );
    });

    test('number formatter keeps composition and valid commits', () {
      const formatter = SmartNumberInputFormatter();
      expect(
        formatter.formatEditUpdate(_committed('12'), _composing('12ab')),
        _composing('12ab'),
      );
      expect(
        formatter.formatEditUpdate(_composing('12'), _committed('12')),
        _committed('12'),
      );
      expect(
        formatter.formatEditUpdate(_committed('12'), _committed('12a')),
        _committed('12'),
      );
    });

    test('amount formatter drops rejected composed text', () {
      final formatter = SmartAmountFormatter(decimalPlaces: 2);
      expect(
        formatter.formatEditUpdate(
          _composing('12.5oo', start: 4),
          _committed('12.5oo'),
        ),
        _committed('12.5'),
      );
      expect(
        formatter.formatEditUpdate(_composing('12'), _committed('12')).text,
        '12',
      );
    });

    test('username formatter drops rejected composed text', () {
      const formatter = SmartUsernameFormatter(
        allowedCharacters: SmartUsernameCharacters.letters,
      );
      expect(
        formatter.formatEditUpdate(_composing('ab1'), _committed('ab1 ')),
        _committed(''),
      );
      expect(
        formatter.formatEditUpdate(
          _composing('abc1', start: 2),
          _committed('abc1'),
        ),
        _committed('ab'),
      );
      expect(
        formatter.formatEditUpdate(_composing('にほん'), _committed('日本')),
        _committed('日本'),
      );
      expect(
        formatter.formatEditUpdate(_committed('ab'), _committed('ab1')),
        _committed('ab'),
      );
    });

    test('card and mask formatters drop rejected composed text', () {
      expect(
        const SmartCardNumberFormatter().formatEditUpdate(
          _composing('4111x', start: 4),
          _committed('4111x'),
        ),
        _committed('4111'),
      );
      final mask = SmartMaskFormatter(SmartInputMask('AA'));
      final rejected = mask.formatEditUpdate(
        _composing('a1', start: 1),
        _committed('a1'),
      );
      expect(rejected.text, isNot(contains('1')));
    });

    testWidgets('number field text holds no rejected characters', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.number(controller: controller),
          ),
        ),
      );
      await tester.showKeyboard(find.byType(TextFormField));
      tester.testTextInput.updateEditingValue(_composing('abc'));
      await tester.pump();
      tester.testTextInput.updateEditingValue(_committed('abc'));
      await tester.pump();
      expect(controller.text, '');
      expect(formKey.currentState!.validate(), isTrue);
      tester.testTextInput.updateEditingValue(_composing('12'));
      await tester.pump();
      tester.testTextInput.updateEditingValue(_committed('12'));
      await tester.pump();
      expect(controller.text, '12');
      expect(controller.selection, const TextSelection.collapsed(offset: 2));
    });

    testWidgets('username field text holds no rejected characters', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.username(
            controller: controller,
            allowedCharacters: SmartUsernameCharacters.letters,
          ),
        ),
      );
      await tester.showKeyboard(find.byType(TextFormField));
      tester.testTextInput.updateEditingValue(_committed('ab'));
      await tester.pump();
      tester.testTextInput.updateEditingValue(_composing('abc1', start: 2));
      await tester.pump();
      expect(controller.text, 'abc1');
      tester.testTextInput.updateEditingValue(_committed('abc1 '));
      await tester.pump();
      expect(controller.text, 'ab');
      expect(controller.selection, const TextSelection.collapsed(offset: 2));
    });
  });

  group('19N minimum length and blank values', () {
    test('blank values are treated as not entered', () {
      final validator = SmartValidators.minLength(8);
      for (final blank in [null, '', '   ', ' \t\n', ' 　']) {
        expect(validator(blank), isNull);
      }
      expect(validator('  a  '), isNotNull);
      expect(validator('abcdefg'), isNotNull);
      expect(validator('abcdefgh'), isNull);
      expect(validator('  abcd  '), isNull);
    });

    test('required rejects the same blank values', () {
      final validator = SmartValidators.compose([
        SmartValidators.requiredField(),
        SmartValidators.minLength(8),
      ]);
      for (final blank in [null, '', '   ', ' 　']) {
        expect(validator(blank), isNotNull);
      }
    });

    test('maxLength still counts whitespace-only text', () {
      expect(SmartValidators.maxLength(2)('   '), isNotNull);
    });
  });

  group('19N email value contract', () {
    testWidgets('each consumer receives its documented value', (tester) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      final asyncController = SmartFieldAsyncController();
      addTearDown(controller.dispose);
      addTearDown(asyncController.dispose);
      final changed = <String>[];
      final custom = <String?>[];
      final asyncValues = <String>[];
      final saved = <String?>[];
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.email(
              controller: controller,
              onChanged: changed.add,
              validator: (value) {
                custom.add(value);
                return null;
              },
              asyncValidation: SmartAsyncValidation(
                controller: asyncController,
                trigger: SmartAsyncValidationTrigger.manual,
                validator: (value) async {
                  asyncValues.add(value);
                  return null;
                },
              ),
              onSaved: saved.add,
            ),
          ),
        ),
      );
      const typed = '  User@Example.com ';
      await tester.enterText(find.byType(TextFormField), typed);
      expect(formKey.currentState!.validate(), isTrue);
      expect(await asyncController.validateAsync(), isTrue);
      formKey.currentState!.save();
      expect(controller.text, typed);
      expect(changed, [typed]);
      expect(custom.last, typed);
      expect(asyncValues, ['User@Example.com']);
      expect(saved, ['User@Example.com']);
    });

    test('standard policy stays ASCII and ignores surrounding spaces', () {
      final validator = SmartValidators.email();
      expect(validator(' user@example.com '), isNull);
      expect(validator('USER@EXAMPLE.COM'), isNull);
      expect(validator('user @example.com'), isNotNull);
      expect(validator('user@'), isNotNull);
      expect(validator('josé@example.com'), isNotNull);
      expect(validator('user@münchen.de'), isNotNull);
    });
  });
}
