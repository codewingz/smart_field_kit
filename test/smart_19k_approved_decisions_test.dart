import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  group('19K async result after a validator change', () {
    testWidgets(
      'a completed result is kept until a forced check applies the rule',
      (tester) async {
        final controller = SmartFieldAsyncController();
        final text = TextEditingController(text: 'alice');
        addTearDown(controller.dispose);
        addTearDown(text.dispose);
        var oldCalls = 0;
        var newCalls = 0;
        Future<String?> oldRule(String value) async {
          oldCalls++;
          return 'Old rule';
        }

        Future<String?> newRule(String value) async {
          newCalls++;
          return null;
        }

        Widget build(SmartAsyncValidator validator) => _app(
          SmartField(
            controller: text,
            asyncValidation: SmartAsyncValidation(
              controller: controller,
              trigger: SmartAsyncValidationTrigger.manual,
              validator: validator,
            ),
          ),
        );
        await tester.pumpWidget(build(oldRule));
        expect(await tester.runAsync(controller.validateAsync), isFalse);
        await tester.pump();
        expect(controller.errorText, 'Old rule');
        await tester.pumpWidget(build(newRule));
        await tester.pump();
        expect(controller.errorText, 'Old rule');
        expect(controller.status, SmartAsyncValidationStatus.invalid);
        expect(find.text('Old rule'), findsOneWidget);
        expect(newCalls, 0);
        expect(await tester.runAsync(controller.validateAsync), isFalse);
        expect(newCalls, 0);
        expect(
          await tester.runAsync(() => controller.validateAsync(force: true)),
          isTrue,
        );
        await tester.pump();
        expect(oldCalls, 1);
        expect(newCalls, 1);
        expect(controller.errorText, isNull);
        expect(find.text('Old rule'), findsNothing);
      },
    );

    testWidgets('the same validator keeps its completed result', (
      tester,
    ) async {
      final controller = SmartFieldAsyncController();
      final text = TextEditingController(text: 'alice');
      addTearDown(controller.dispose);
      addTearDown(text.dispose);
      Future<String?> rule(String value) async => 'Taken';
      Widget build() => _app(
        SmartField(
          controller: text,
          asyncValidation: SmartAsyncValidation(
            controller: controller,
            trigger: SmartAsyncValidationTrigger.manual,
            validator: rule,
          ),
        ),
      );
      await tester.pumpWidget(build());
      await tester.runAsync(controller.validateAsync);
      await tester.pump();
      await tester.pumpWidget(build());
      await tester.pump();
      expect(controller.errorText, 'Taken');
    });
  });

  group('19K raw values', () {
    testWidgets('date onRawChanged reports a cleared or invalid value', (
      tester,
    ) async {
      final raws = <String>[];
      await tester.pumpWidget(_app(SmartField.date(onRawChanged: raws.add)));
      await tester.enterText(find.byType(EditableText), '01/01/2020');
      await tester.enterText(find.byType(EditableText), '01/01/202');
      await tester.enterText(find.byType(EditableText), '01/01/20');
      await tester.enterText(find.byType(EditableText), '');
      await tester.enterText(find.byType(EditableText), '02/01/2020');
      expect(raws, ['2020-01-01', '', '2020-01-02']);
    });

    testWidgets('clearing an initial date reports an empty raw value', (
      tester,
    ) async {
      final raws = <String>[];
      await tester.pumpWidget(
        _app(
          SmartField.date(
            initialDate: DateTime(2020, 3, 4),
            showClearButton: true,
            onRawChanged: raws.add,
          ),
        ),
      );
      await tester.tap(find.byTooltip('Clear'));
      await tester.pump();
      expect(raws, ['']);
    });

    testWidgets('dropdown date reports an empty raw value when cleared', (
      tester,
    ) async {
      final raws = <String>[];
      await tester.pumpWidget(
        _app(
          SmartField.date(
            mode: SmartDateMode.dropdowns,
            initialDate: DateTime(2020, 3, 4),
            showClearButton: true,
            onRawChanged: raws.add,
          ),
        ),
      );
      await tester.tap(find.byTooltip('Clear'));
      await tester.pump();
      expect(raws, ['']);
    });

    testWidgets('amount onRawSaved is the same focused and unfocused', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final rawSaved = <String?>[];
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: Column(
              children: [
                SmartField.amount(
                  useGrouping: true,
                  decimalPlaces: 2,
                  currencySymbol: r'$',
                  onRawSaved: rawSaved.add,
                ),
                const TextField(key: Key('other')),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.byType(EditableText).first);
      await tester.pump();
      await tester.enterText(find.byType(EditableText).first, '50000');
      formKey.currentState!.save();
      await tester.tap(find.byKey(const Key('other')));
      await tester.pump();
      formKey.currentState!.save();
      expect(rawSaved, ['50000.00', '50000.00']);
    });

    testWidgets('amount without fixed decimals keeps its raw text', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      String? raw;
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.amount(onRawSaved: (value) => raw = value),
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), '12.5');
      formKey.currentState!.save();
      expect(raw, '12.5');
    });
  });

  group('19K length, card, phone and email rules', () {
    test('maxLength applies to whitespace-only text', () {
      expect(SmartValidators.maxLength(5)(' ' * 6), isNotNull);
      expect(SmartValidators.maxLength(5)(' ' * 5), isNull);
      expect(SmartValidators.maxLength(5)(''), isNull);
      expect(SmartValidators.minLength(3)('   '), isNull);
    });

    test('strength length counts characters as users see them', () {
      const accent = 'é';
      const family = '👨‍👩‍👧‍👦';
      expect(SmartPasswordCriterion.minLength(2).test(accent), isFalse);
      expect(
        SmartPasswordCriterion.minLength(2).test('$family$family'),
        isTrue,
      );
      expect(SmartPasswordCriterion.minLength(8).test('${family}a'), isFalse);
      expect(SmartValidators.minLength(2)(accent), isNotNull);
    });

    test('legacy rules are unchanged', () {
      expect(SmartValidators.legacyWeakPasswordExpression, r'^.{5,}$');
      expect(SmartValidators.legacyNumberExpression, r'^[0-9]$');
      expect(SmartValidators.legacyOtpKey, 'opt_token');
      expect(
        SmartValidators.email(policy: SmartEmailPolicy.legacy)(' a@b.co '),
        isNotNull,
      );
    });

    test('all-zero card numbers are invalid and other rules are kept', () {
      for (final zeros in ['0' * 12, '0' * 16, '0000 0000 0000 0000']) {
        final result = SmartCardUtils.assessNumber(zeros);
        expect(result.status, SmartCardNumberStatus.invalid);
        expect(result.issue, SmartCardNumberIssue.failsChecksum);
      }
      expect(
        SmartCardUtils.assessNumber('4111111111111111').status,
        SmartCardNumberStatus.valid,
      );
      expect(
        SmartCardUtils.assessNumber('6200000000000000').status,
        SmartCardNumberStatus.valid,
      );
      expect(
        SmartCardUtils.assessNumber(
          '6200000000000000',
          luhnExemptBrands: const {},
        ).status,
        SmartCardNumberStatus.invalid,
      );
      expect(SmartValidators.cardNumber()('0' * 16), 'Check the card number.');
    });

    test('phone separators are normalised without bypassing the country', () {
      const us = SmartPhoneCountry(
        isoCode: 'US',
        name: 'United States',
        dialCode: '+1',
        flagEmoji: '',
      );
      String? check(String value) => SmartPhoneValidation.validate(
        value,
        policy: SmartPhonePolicy.auto,
        country: us,
      );
      expect(check('(415)\u00a0555-2671'), isNull);
      expect(check('415.555.2671'), isNull);
      expect(check('\u202a+1 415 555 2671\u202c'), isNull);
      expect(check('+44\u00a020\u00a07183\u00a08750'), isNotNull);
      expect(check('415.555.26'), isNotNull);
      expect(check('415 555 2671 x12'), isNotNull);
      final value = SmartPhoneValidation.parseValue(
        '(415)\u00a0555-2671',
        country: us,
      );
      expect(value.text, '(415)\u00a0555-2671');
      expect(value.e164, '+14155552671');
      expect(value.isValid, isTrue);
      expect(
        SmartPhoneValidation.validate(
          '4155552671\u00a0',
          policy: SmartPhonePolicy.legacy,
        ),
        isNotNull,
      );
    });

    testWidgets('email ignores surrounding spaces and saves the trimmed text', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      String? saved;
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.email(
              controller: controller,
              onSaved: (value) => saved = value,
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), ' user@example.com ');
      expect(formKey.currentState!.validate(), isTrue);
      formKey.currentState!.save();
      expect(saved, 'user@example.com');
      expect(controller.text, ' user@example.com ');
      await tester.enterText(find.byType(EditableText), 'user @example.com');
      expect(formKey.currentState!.validate(), isFalse);
    });
  });

  group('19K OTP paste and overwrite', () {
    testWidgets('separators are removed and extra digits dropped', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final completed = <String>[];
      await tester.pumpWidget(
        _app(
          SmartField.otp(controller: controller, onCompleted: completed.add),
        ),
      );
      await tester.enterText(find.byType(EditableText), '123 456');
      expect(controller.text, '123456');
      await tester.enterText(find.byType(EditableText), '');
      await tester.enterText(find.byType(EditableText), '12-34');
      expect(controller.text, '1234');
      await tester.enterText(find.byType(EditableText), '987654321');
      expect(controller.text, '987654');
      await tester.enterText(find.byType(EditableText), 'G-123456');
      expect(controller.text, '987654');
      await tester.pump();
      expect(completed, ['123456', '987654']);
    });

    testWidgets('typing on a filled box replaces that digit', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final completed = <String>[];
      await tester.pumpWidget(
        _app(
          SmartField.otp(controller: controller, onCompleted: completed.add),
        ),
      );
      await tester.enterText(find.byType(EditableText), '123456');
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();
      expect(controller.selection.baseOffset, 2);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '1293456',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      await tester.pump();
      expect(controller.text, '129456');
      expect(controller.selection.baseOffset, 3);
      expect(completed, ['123456', '129456']);
      controller.selection = const TextSelection.collapsed(offset: 6);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '1294567',
          selection: TextSelection.collapsed(offset: 7),
        ),
      );
      await tester.pump();
      expect(controller.text, '129456');
      expect(completed, ['123456', '129456']);
    });
  });

  group('19K card labels and decoration', () {
    testWidgets('the security-code toggle has its own labels', (tester) async {
      await tester.pumpWidget(_app(SmartField.creditCard()));
      expect(find.byTooltip('Show security code'), findsOneWidget);
      expect(find.byTooltip('Show password'), findsNothing);
      await tester.tap(find.byTooltip('Show security code'));
      await tester.pump();
      expect(find.byTooltip('Hide security code'), findsOneWidget);
      await tester.pumpWidget(
        _app(
          SmartField.creditCard(
            showCvvLabel: 'Afficher le code',
            hideCvvLabel: 'Masquer le code',
          ),
        ),
      );
      expect(find.byTooltip('Masquer le code'), findsOneWidget);
      await tester.tap(find.byTooltip('Masquer le code'));
      await tester.pump();
      expect(find.byTooltip('Afficher le code'), findsOneWidget);
    });

    testWidgets('a password field keeps its password labels', (tester) async {
      await tester.pumpWidget(_app(SmartField.password()));
      expect(find.byTooltip('Show password'), findsOneWidget);
    });

    testWidgets('shared decoration content appears once', (tester) async {
      await tester.pumpWidget(
        _app(
          SmartField.creditCard(
            decoration: const InputDecoration(
              labelText: 'Card',
              prefixIcon: Icon(Icons.credit_card),
              helperText: 'Helper',
              filled: true,
              fillColor: Color(0xFF112233),
            ),
          ),
        ),
      );
      expect(find.text('Card'), findsOneWidget);
      expect(find.byIcon(Icons.credit_card), findsOneWidget);
      expect(find.text('Expiry'), findsOneWidget);
      expect(find.text('Security code'), findsOneWidget);
      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(fields, hasLength(3));
      for (final field in fields) {
        expect(field.decoration?.filled, isTrue);
        expect(field.decoration?.fillColor, const Color(0xFF112233));
      }
    });
  });

  group('19K standard text-field options', () {
    testWidgets('initialValue seeds plain and formatted fields', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final saved = <String?>[];
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: Column(
              children: [
                SmartField(initialValue: 'hello', onSaved: saved.add),
                SmartField.amount(
                  initialValue: '50000',
                  decimalPlaces: 2,
                  useGrouping: true,
                  onRawSaved: saved.add,
                ),
                SmartField.search(initialValue: 'query'),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('hello'), findsOneWidget);
      expect(find.text('50,000.00'), findsOneWidget);
      expect(find.text('query'), findsOneWidget);
      formKey.currentState!.save();
      expect(saved, ['hello', '50000.00']);
      await tester.enterText(find.byType(EditableText).first, 'changed');
      formKey.currentState!.reset();
      await tester.pump();
      expect(find.text('hello'), findsOneWidget);
    });

    test('initialValue and controller cannot be combined', () {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      expect(
        () => SmartField(controller: controller, initialValue: 'x'),
        throwsAssertionError,
      );
    });

    testWidgets('submit, editing-complete, tap and tap-outside callbacks', (
      tester,
    ) async {
      final events = <String>[];
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              SmartField.email(
                onFieldSubmitted: (value) => events.add('submit:$value'),
                onEditingComplete: () => events.add('complete'),
                onTap: () => events.add('tap'),
                onTapOutside: (_) => events.add('outside'),
              ),
              const SizedBox(height: 200, width: 200),
            ],
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pump();
      await tester.enterText(find.byType(EditableText), 'a@b.co');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.tapAt(const Offset(400, 500));
      await tester.pump();
      expect(events, ['tap', 'complete', 'submit:a@b.co', 'outside']);
    });

    testWidgets('search keeps onSubmitted and its own onTap', (tester) async {
      final events = <String>[];
      await tester.pumpWidget(
        _app(
          SmartField.search(
            onSubmitted: (value) => events.add('search:$value'),
            onTap: () => events.add('tap'),
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'q');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      expect(events, ['tap', 'search:q']);
    });

    testWidgets('style, alignment, direction and obscuring character', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              SmartField.amount(
                style: const TextStyle(fontSize: 31),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
              SmartField.password(obscuringCharacter: '*'),
              const SmartField(),
            ],
          ),
        ),
      );
      final fields = tester
          .widgetList<EditableText>(find.byType(EditableText))
          .toList();
      expect(fields[0].style.fontSize, 31);
      expect(fields[0].textAlign, TextAlign.center);
      expect(fields[0].textDirection, TextDirection.rtl);
      expect(fields[1].obscuringCharacter, '*');
      expect(fields[2].textAlign, TextAlign.start);
      expect(fields[2].obscuringCharacter, '•');
    });
  });

  group('19K text overrides', () {
    testWidgets('word counter, strength title and rule messages', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final password = TextEditingController(text: 'abc');
      addTearDown(password.dispose);
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: Column(
              children: [
                SmartField.description(
                  initialValue: 'un deux',
                  showWordCount: true,
                  maxWords: 5,
                  wordCountBuilder: (count, max) => '$count sur $max mots',
                ),
                SmartField.password(
                  controller: password,
                  showStrengthIndicator: true,
                  strengthTitle: 'Robustesse',
                  validationMode: SmartValidationMode.selected,
                  builtInChecks: const {SmartBuiltInCheck.passwordDigit},
                  digitErrorText: 'Ajoutez un chiffre.',
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('2 sur 5 mots'), findsOneWidget);
      expect(find.textContaining('Robustesse: '), findsOneWidget);
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Ajoutez un chiffre.'), findsOneWidget);
    });

    testWidgets('English defaults are unchanged', (tester) async {
      final formKey = GlobalKey<FormState>();
      final password = TextEditingController(text: 'abc');
      final user = TextEditingController(text: 'a1');
      addTearDown(password.dispose);
      addTearDown(user.dispose);
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: Column(
              children: [
                SmartField.description(
                  initialValue: 'one two',
                  showWordCount: true,
                ),
                SmartField.password(
                  controller: password,
                  showStrengthIndicator: true,
                  validationMode: SmartValidationMode.selected,
                  builtInChecks: const {SmartBuiltInCheck.passwordDigit},
                ),
                SmartField.username(
                  controller: user,
                  allowedCharacters: SmartUsernameCharacters.letters,
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('2 words'), findsOneWidget);
      expect(find.textContaining('Password strength: '), findsOneWidget);
      formKey.currentState!.validate();
      await tester.pump();
      expect(find.text('Include a digit.'), findsOneWidget);
      expect(find.text('Use only the allowed characters.'), findsOneWidget);
    });

    testWidgets('username and contact-picker messages can be replaced', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final user = TextEditingController(text: 'a1');
      addTearDown(user.dispose);
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final errors = <SmartPhonePickerError>[];
      try {
        await tester.pumpWidget(
          _app(
            Form(
              key: formKey,
              child: Column(
                children: [
                  SmartField.username(
                    controller: user,
                    allowedCharacters: SmartUsernameCharacters.letters,
                    allowedCharactersErrorText: 'Lettres uniquement.',
                  ),
                  SmartField.phone(
                    showContactPicker: true,
                    contactPicker: () async => '',
                    contactPickerMessageBuilder: (code) => 'msg:${code.name}',
                    onContactPickerError: errors.add,
                  ),
                ],
              ),
            ),
          ),
        );
        formKey.currentState!.validate();
        await tester.pump();
        expect(find.text('Lettres uniquement.'), findsOneWidget);
        await tester.tap(find.byTooltip('Select phone number from contacts'));
        await tester.pumpAndSettle();
        expect(errors.single.message, 'msg:unavailableNumber');
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    }, skip: kIsWeb);
  });

  group('19K exports', () {
    test('SmartNumberInputFormatter is public', () {
      const formatter = SmartNumberInputFormatter(allowNegative: true);
      final accepted = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '-12'),
      );
      final rejected = formatter.formatEditUpdate(
        accepted,
        const TextEditingValue(text: '-12a'),
      );
      expect(accepted.text, '-12');
      expect(rejected.text, '-12');
    });
  });
}
