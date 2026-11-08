import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(
  Widget child, {
  ThemeData? theme,
  TextDirection textDirection = TextDirection.ltr,
}) {
  return MaterialApp(
    theme: theme,
    home: Directionality(
      textDirection: textDirection,
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('configures a simple unrestricted phone field by default', (
    tester,
  ) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      _app(SmartField.phone(controller: controller, focusNode: focusNode)),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.keyboardType, TextInputType.phone);
    expect(field.autocorrect, isFalse);
    expect(field.enableSuggestions, isFalse);
    expect(field.autofillHints, contains(AutofillHints.telephoneNumber));
    expect(find.byIcon(Icons.public), findsNothing);
    expect(find.byIcon(Icons.contact_phone), findsNothing);

    for (final text in [
      '+923001234567',
      '0300 123-4567',
      '001234567',
      '12',
      '123456789012345678901234567890',
      'invalid paste',
    ]) {
      await tester.enterText(find.byType(TextFormField), text);
      expect(controller.text, text);
    }
  });

  testWidgets('supports required validation and first-error order', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var customCalls = 0;

    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField.phone(
            controller: controller,
            isRequired: true,
            requiredErrorText: 'Required error',
            phoneErrorText: 'Phone error',
            minLength: 10,
            minLengthErrorText: 'Length error',
            validator: (value) {
              customCalls++;
              return value == '+12025550123' ? null : 'Custom error';
            },
          ),
        ),
      ),
    );

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Required error'), findsOneWidget);
    expect(customCalls, 0);

    controller.text = 'letters';
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Phone error'), findsOneWidget);
    expect(customCalls, 0);

    controller.text = '123';
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Length error'), findsOneWidget);
    expect(customCalls, 0);

    controller.text = '1234567890';
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Custom error'), findsOneWidget);
    expect(customCalls, 1);

    controller.text = '+12025550123';
    expect(formKey.currentState!.validate(), isTrue);
    expect(customCalls, 2);
  });

  testWidgets('preserves text callbacks and provides safe parsed values', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    String? changed;
    String? saved;
    SmartPhoneValue? phoneValue;

    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField.phone(
            controller: controller,
            focusNode: focusNode,
            initialCountryCode: 'PK',
            onChanged: (value) => changed = value,
            onSaved: (value) => saved = value,
            onPhoneChanged: (value) => phoneValue = value,
          ),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();
    await tester.enterText(find.byType(TextFormField), '0300 1234567');
    formKey.currentState!.save();

    expect(changed, '0300 1234567');
    expect(saved, '0300 1234567');
    expect(controller.text, '0300 1234567');
    expect(phoneValue?.text, '0300 1234567');
    expect(phoneValue?.country?.isoCode, 'PK');
    expect(phoneValue?.e164, '+923001234567');
    expect(focusNode.hasFocus, isTrue);
  });

  testWidgets('clear keeps country and reports one text change', (
    tester,
  ) async {
    final controller = TextEditingController(text: '03001234567');
    addTearDown(controller.dispose);
    final changed = <String>[];

    await tester.pumpWidget(
      _app(
        SmartField.phone(
          controller: controller,
          initialCountryCode: 'PK',
          showCountryPicker: true,
          showClearButton: true,
          onChanged: changed.add,
        ),
      ),
    );

    expect(find.text('+92'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear phone number'));
    await tester.pump();
    expect(controller.text, isEmpty);
    expect(changed, ['']);
    expect(find.text('+92'), findsOneWidget);
  });

  testWidgets(
    'country picker searches filters and revalidates without rewrite',
    (tester) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController(text: '+12025550123');
      addTearDown(controller.dispose);
      SmartPhoneCountry? changedCountry;

      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.phone(
              controller: controller,
              showCountryPicker: true,
              initialCountryCode: 'PK',
              allowedCountryCodes: const ['PK', 'US'],
              favoriteCountryCodes: const ['US'],
              policy: SmartPhonePolicy.countryAware,
              onCountryChanged: (country) => changedCountry = country,
            ),
          ),
        ),
      );

      expect(formKey.currentState!.validate(), isFalse);
      await tester.tap(find.text('+92'));
      await tester.pumpAndSettle();
      expect(find.text('Search country'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'United States');
      await tester.pumpAndSettle();
      expect(find.textContaining('Canada'), findsNothing);
      await tester.tap(find.text('United States').last);
      await tester.pumpAndSettle();

      expect(changedCountry?.isoCode, 'US');
      expect(controller.text, '+12025550123');
      expect(formKey.currentState!.validate(), isTrue);
      expect(find.text('+1'), findsOneWidget);
    },
  );

  testWidgets('uses a neutral picker for missing or excluded initial country', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            SmartField.phone(showCountryPicker: true, initialCountryCode: 'ZZ'),
            SmartField.phone(
              showCountryPicker: true,
              initialCountryCode: 'PK',
              allowedCountryCodes: const ['US'],
            ),
          ],
        ),
      ),
    );

    expect(find.byIcon(Icons.public), findsNWidgets(2));
    expect(find.text('+92'), findsNothing);
  });

  testWidgets('inherits dark theme and supports RTL picker layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SmartField.phone(showCountryPicker: true, initialCountryCode: 'GB'),
        theme: ThemeData.dark(useMaterial3: true),
        textDirection: TextDirection.rtl,
      ),
    );
    expect(find.text('+44'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'native contact selection updates once and infers unique country',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final controller = TextEditingController(text: 'old');
      addTearDown(controller.dispose);
      final changed = <String>[];
      final countries = <SmartPhoneCountry?>[];

      await tester.pumpWidget(
        _app(
          SmartField.phone(
            controller: controller,
            showCountryPicker: true,
            showContactPicker: true,
            contactPicker: () async => '+923001234567',
            onChanged: changed.add,
            onCountryChanged: countries.add,
          ),
        ),
      );

      await tester.tap(find.byTooltip('Select phone number from contacts'));
      await tester.pumpAndSettle();
      debugDefaultTargetPlatformOverride = null;
      expect(controller.text, '+923001234567');
      expect(controller.selection.baseOffset, controller.text.length);
      expect(changed, ['+923001234567']);
      expect(countries.single?.isoCode, 'PK');
      expect(find.text('+92'), findsOneWidget);
    },
  );

  testWidgets('contact cancel and invalid values preserve existing text', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final controller = TextEditingController(text: '03001234567');
    addTearDown(controller.dispose);
    final errors = <SmartPhonePickerError>[];
    var resultIndex = 0;
    final results = <String?>[null, '', 'bad number', '001234567'];

    await tester.pumpWidget(
      _app(
        SmartField.phone(
          controller: controller,
          showContactPicker: true,
          contactPicker: () async => results[resultIndex++],
          onContactPickerError: errors.add,
        ),
      ),
    );

    for (var index = 0; index < results.length; index++) {
      await tester.tap(find.byTooltip('Select phone number from contacts'));
      await tester.pumpAndSettle();
      expect(controller.text, '03001234567');
    }
    debugDefaultTargetPlatformOverride = null;
    expect(errors.map((error) => error.code), [
      SmartPhonePickerErrorCode.unavailableNumber,
      SmartPhonePickerErrorCode.invalidNumber,
      SmartPhonePickerErrorCode.invalidNumber,
    ]);
  });

  testWidgets('contact selection rejects a uniquely disallowed country', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final controller = TextEditingController(text: 'unchanged');
    addTearDown(controller.dispose);
    SmartPhonePickerError? error;

    await tester.pumpWidget(
      _app(
        SmartField.phone(
          controller: controller,
          showContactPicker: true,
          allowedCountryCodes: const ['PK'],
          contactPicker: () async => '+442079460018',
          onContactPickerError: (value) => error = value,
        ),
      ),
    );

    await tester.tap(find.byTooltip('Select phone number from contacts'));
    await tester.pumpAndSettle();
    debugDefaultTargetPlatformOverride = null;
    expect(controller.text, 'unchanged');
    expect(error?.code, SmartPhonePickerErrorCode.disallowedCountry);
  });

  testWidgets('shared dialing code does not guess a country', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final countries = <SmartPhoneCountry?>[];
    SmartPhoneValue? value;

    await tester.pumpWidget(
      _app(
        SmartField.phone(
          controller: controller,
          showCountryPicker: true,
          showContactPicker: true,
          allowedCountryCodes: const ['US', 'CA'],
          contactPicker: () async => '+12025550123',
          onCountryChanged: countries.add,
          onPhoneChanged: (phone) => value = phone,
        ),
      ),
    );

    await tester.tap(find.byTooltip('Select phone number from contacts'));
    await tester.pumpAndSettle();
    debugDefaultTargetPlatformOverride = null;
    expect(controller.text, '+12025550123');
    expect(countries, isEmpty);
    expect(find.byIcon(Icons.public), findsOneWidget);
    expect(value?.country, isNull);
    expect(value?.e164, '+12025550123');
  });

  testWidgets('contact action is hidden on unsupported platforms', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    await tester.pumpWidget(_app(SmartField.phone(showContactPicker: true)));
    debugDefaultTargetPlatformOverride = null;
    expect(find.byIcon(Icons.contact_phone), findsNothing);
  });

  testWidgets('contact platform errors are reported without text exposure', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final controller = TextEditingController(text: 'unchanged');
    addTearDown(controller.dispose);
    SmartPhonePickerError? error;

    await tester.pumpWidget(
      _app(
        SmartField.phone(
          controller: controller,
          showContactPicker: true,
          contactPicker: () => Future<String?>.error(StateError('failure')),
          onContactPickerError: (value) => error = value,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Select phone number from contacts'));
    await tester.pumpAndSettle();
    debugDefaultTargetPlatformOverride = null;
    expect(controller.text, 'unchanged');
    expect(error?.code, SmartPhonePickerErrorCode.platformFailure);
    expect(error?.message, 'Unable to open the contact picker.');
  });

  testWidgets('async contact result is ignored after disposal', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final completer = Completer<String?>();

    await tester.pumpWidget(
      _app(
        SmartField.phone(
          showContactPicker: true,
          contactPicker: () => completer.future,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Select phone number from contacts'));
    await tester.pump();
    await tester.pumpWidget(_app(const SizedBox()));
    completer.complete('+442079460018');
    await tester.pump();
    debugDefaultTargetPlatformOverride = null;
    expect(tester.takeException(), isNull);
  });

  testWidgets('preserves middle edits selection reset and legacy behavior', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: '1234567');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField.phone(
            controller: controller,
            policy: SmartPhonePolicy.legacy,
          ),
        ),
      ),
    );

    controller.value = const TextEditingValue(
      text: '12304567',
      selection: TextSelection.collapsed(offset: 4),
    );
    await tester.pump();
    expect(controller.text, '12304567');
    expect(controller.selection.baseOffset, 4);
    expect(formKey.currentState!.validate(), isTrue);

    controller.text = '+1234567';
    expect(formKey.currentState!.validate(), isFalse);
    formKey.currentState!.reset();
    await tester.pump();
    expect(controller.text, '1234567');
  });
}
