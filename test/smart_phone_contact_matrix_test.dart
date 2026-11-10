import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

Future<void> _tapPicker(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Select phone number from contacts'));
  await tester.pumpAndSettle();
}

void main() {
  void matrixTest(
    String name,
    Future<void> Function(WidgetTester tester) body, {
    TargetPlatform platform = TargetPlatform.android,
  }) {
    testWidgets(name, skip: kIsWeb, (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      try {
        await body(tester);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }

  Widget field({
    required TextEditingController controller,
    required Future<String?> Function() picker,
    List<SmartPhoneCountry?>? countries,
    List<SmartPhonePickerError>? errors,
    List<String>? changes,
    bool countryPicker = false,
    List<String>? allowed,
    String? initialCountry,
    bool? enabled,
    bool readOnly = false,
  }) {
    return SmartField.phone(
      controller: controller,
      showContactPicker: true,
      showCountryPicker: countryPicker,
      allowedCountryCodes: allowed,
      initialCountryCode: initialCountry,
      contactPicker: picker,
      enabled: enabled,
      readOnly: readOnly,
      onChanged: changes?.add,
      onCountryChanged: countries?.add,
      onContactPickerError: errors?.add,
    );
  }

  matrixTest('C01 open and select one number updates once', (tester) async {
    final controller = TextEditingController();
    final changes = <String>[];
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        field(
          controller: controller,
          picker: () async => '+923001234567',
          changes: changes,
        ),
      ),
    );
    await _tapPicker(tester);
    expect(controller.text, '+923001234567');
    expect(changes, ['+923001234567']);
  });

  matrixTest('C02-C04 cancel, dismiss, and reopen', (tester) async {
    final controller = TextEditingController(text: '+923001234567');
    final errors = <SmartPhonePickerError>[];
    addTearDown(controller.dispose);
    final results = <String?>[null, null, '+16502530000'];
    var index = 0;
    await tester.pumpWidget(
      _app(
        field(
          controller: controller,
          picker: () async => results[index++],
          errors: errors,
        ),
      ),
    );
    await _tapPicker(tester);
    await _tapPicker(tester);
    expect(controller.text, '+923001234567');
    expect(errors, isEmpty);
    await _tapPicker(tester);
    expect(controller.text, '+16502530000');
  });

  matrixTest(
    'C05 multiple numbers: only the chosen one is applied',
    platform: TargetPlatform.iOS,
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final chosen = ['+923001234567', '+16502530000'];
      var index = 0;
      await tester.pumpWidget(
        _app(
          field(controller: controller, picker: () async => chosen[index++]),
        ),
      );
      await _tapPicker(tester);
      expect(controller.text, '+923001234567');
      await _tapPicker(tester);
      expect(controller.text, '+16502530000');
    },
  );

  matrixTest('C06-C07 contact without a number and empty list', (tester) async {
    final controller = TextEditingController(text: 'keep');
    final errors = <SmartPhonePickerError>[];
    addTearDown(controller.dispose);
    final results = <String?>['', null];
    var index = 0;
    await tester.pumpWidget(
      _app(
        field(
          controller: controller,
          picker: () async => results[index++],
          errors: errors,
        ),
      ),
    );
    await _tapPicker(tester);
    expect(errors.single.code, SmartPhonePickerErrorCode.unavailableNumber);
    await _tapPicker(tester);
    expect(errors.length, 1);
    expect(controller.text, 'keep');
  });

  matrixTest('C08 picker failure is reported without exposing text', (
    tester,
  ) async {
    final controller = TextEditingController(text: '+923001234567');
    final errors = <SmartPhonePickerError>[];
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        field(
          controller: controller,
          picker: () async => throw StateError('contact deleted +923001234567'),
          errors: errors,
        ),
      ),
    );
    await _tapPicker(tester);
    expect(errors.single.code, SmartPhonePickerErrorCode.platformFailure);
    expect(errors.single.message, isNot(contains('+92')));
    expect(controller.text, '+923001234567');
  });

  matrixTest('C09 country mismatch and allowed-country restrictions', (
    tester,
  ) async {
    final restricted = TextEditingController();
    final open = TextEditingController();
    final errors = <SmartPhonePickerError>[];
    final countries = <SmartPhoneCountry?>[];
    addTearDown(restricted.dispose);
    addTearDown(open.dispose);
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            field(
              controller: restricted,
              picker: () async => '+4915123456789',
              allowed: const ['PK'],
              countryPicker: true,
              initialCountry: 'PK',
              errors: errors,
            ),
            field(
              controller: open,
              picker: () async => '+4915123456789',
              countryPicker: true,
              initialCountry: 'PK',
              countries: countries,
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.byTooltip('Select phone number from contacts').first);
    await tester.pumpAndSettle();
    expect(restricted.text, isEmpty);
    expect(errors.single.code, SmartPhonePickerErrorCode.disallowedCountry);
    await tester.tap(find.byTooltip('Select phone number from contacts').last);
    await tester.pumpAndSettle();
    expect(open.text, '+4915123456789');
    expect(countries.single?.isoCode, 'DE');
  });

  matrixTest('C10 prefixes, leading zeros, spaces, and punctuation', (
    tester,
  ) async {
    final controller = TextEditingController();
    final errors = <SmartPhonePickerError>[];
    addTearDown(controller.dispose);
    final numbers = [
      '+92 (300) 123-4567',
      '0300 123 4567',
      '03001234567',
      '0092 300 1234567',
    ];
    var index = 0;
    await tester.pumpWidget(
      _app(
        field(
          controller: controller,
          picker: () async => numbers[index++],
          countryPicker: true,
          initialCountry: 'PK',
          errors: errors,
        ),
      ),
    );
    await _tapPicker(tester);
    expect(controller.text, '+92 (300) 123-4567');
    await _tapPicker(tester);
    expect(controller.text, '0300 123 4567');
    await _tapPicker(tester);
    expect(controller.text, '03001234567');
    await _tapPicker(tester);
    expect(controller.text, '0092 300 1234567');
    expect(errors, isEmpty);
  });

  matrixTest('C11 invalid and too-long numbers are rejected', (tester) async {
    final controller = TextEditingController(text: 'keep');
    final errors = <SmartPhonePickerError>[];
    addTearDown(controller.dispose);
    final numbers = ['+92300', '+9230012345678901234', 'call me', '+1234'];
    var index = 0;
    await tester.pumpWidget(
      _app(
        field(
          controller: controller,
          picker: () async => numbers[index++],
          errors: errors,
        ),
      ),
    );
    for (var i = 0; i < numbers.length; i++) {
      await _tapPicker(tester);
    }
    expect(controller.text, 'keep');
    expect(errors.map((e) => e.code).toSet(), {
      SmartPhonePickerErrorCode.invalidNumber,
    });
    expect(errors.length, numbers.length);
  });

  matrixTest('C12 repeated taps open only one picker at a time', (
    tester,
  ) async {
    final controller = TextEditingController();
    final completer = Completer<String?>();
    var calls = 0;
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        field(
          controller: controller,
          picker: () {
            calls++;
            return completer.future;
          },
        ),
      ),
    );
    final button = find.byTooltip('Select phone number from contacts');
    await tester.tap(button);
    await tester.tap(button);
    await tester.tap(button);
    await tester.pump();
    expect(calls, 1);
    completer.complete('+923001234567');
    await tester.pumpAndSettle();
    expect(controller.text, '+923001234567');
    expect(calls, 1);
  });

  matrixTest(
    'C13 late result after rebuild is applied once; after disposal ignored',
    (tester) async {
      final controller = TextEditingController();
      final changes = <String>[];
      final completer = Completer<String?>();
      addTearDown(controller.dispose);
      Widget build() => _app(
        field(
          controller: controller,
          picker: () => completer.future,
          changes: changes,
        ),
      );
      await tester.pumpWidget(build());
      await tester.tap(find.byTooltip('Select phone number from contacts'));
      await tester.pump();
      await tester.pumpWidget(build());
      completer.complete('+923001234567');
      await tester.pumpAndSettle();
      expect(changes, ['+923001234567']);

      final second = Completer<String?>();
      await tester.pumpWidget(
        _app(
          field(
            controller: controller,
            picker: () => second.future,
            changes: changes,
          ),
        ),
      );
      await tester.tap(find.byTooltip('Select phone number from contacts'));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      second.complete('+16502530000');
      await tester.pumpAndSettle();
      expect(changes, ['+923001234567']);
      expect(tester.takeException(), isNull);
    },
  );

  matrixTest('C14 disabled and read-only fields cannot open the picker', (
    tester,
  ) async {
    var calls = 0;
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            field(
              controller: controller,
              enabled: false,
              picker: () async {
                calls++;
                return null;
              },
            ),
            field(
              controller: TextEditingController(),
              readOnly: true,
              picker: () async {
                calls++;
                return null;
              },
            ),
          ],
        ),
      ),
    );
    final buttons = tester
        .widgetList<IconButton>(find.byType(IconButton))
        .toList();
    expect(buttons.every((button) => button.onPressed == null), isTrue);
    expect(calls, 0);
  });

  matrixTest('C15 RTL, large text, dark theme, narrow width, and semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(2),
            size: Size(240, 700),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: SingleChildScrollView(
                child: SmartField.phone(
                  label: 'هاتف',
                  showContactPicker: true,
                  showCountryPicker: true,
                  initialCountryCode: 'PK',
                  contactPicker: () async => null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Select phone number from contacts'), findsOneWidget);
    final semantics = tester.getSemantics(
      find.byTooltip('Select phone number from contacts'),
    );
    expect(
      '${semantics.label} ${semantics.tooltip}',
      contains('Select phone number from contacts'),
    );
    handle.dispose();
  });

  matrixTest('C16 picker error without a callback shows a SnackBar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SmartField.phone(
          showContactPicker: true,
          contactPicker: () async => '',
        ),
      ),
    );
    await _tapPicker(tester);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  test(
    'C17 no contact or SMS permissions are declared by the example app',
    skip: kIsWeb
        ? 'Reads project files through dart:io, which is unavailable in a browser.'
        : null,
    () {
      final manifest = File(
        'example/android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      expect(manifest, isNot(contains('READ_CONTACTS')));
      expect(manifest, isNot(contains('READ_SMS')));
      expect(manifest, isNot(contains('RECEIVE_SMS')));
      final plist = File('example/ios/Runner/Info.plist').readAsStringSync();
      expect(plist, isNot(contains('NSContactsUsageDescription')));
    },
  );

  test(
    'C18 library code never requests permissions or reads SMS',
    skip: kIsWeb
        ? 'Reads project files through dart:io, which is unavailable in a browser.'
        : null,
    () {
      final sources = Directory(
        'lib',
      ).listSync(recursive: true).whereType<File>();
      for (final file in sources) {
        final text = file.readAsStringSync();
        expect(text, isNot(contains('permission_handler')), reason: file.path);
        expect(text, isNot(contains('READ_SMS')), reason: file.path);
        expect(text, isNot(contains('RECEIVE_SMS')), reason: file.path);
        expect(text, isNot(contains('requestPermission')), reason: file.path);
        expect(text, isNot(contains('sms_autofill')), reason: file.path);
      }
    },
  );
}
