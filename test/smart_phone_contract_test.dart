import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  group('auto policy versus the structured phone value', () {
    testWidgets('local syntax passes validation but is not country-verified', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final values = <SmartPhoneValue>[];
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.phone(onPhoneChanged: values.add),
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), '12345');
      await tester.pump();
      expect(formKey.currentState!.validate(), isTrue);
      expect(values.last.text, '12345');
      expect(values.last.isValid, isFalse);
      expect(values.last.e164, isNull);
      expect(values.last.country, isNull);
    });

    testWidgets('an international number is verified and gets an E.164 value', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final values = <SmartPhoneValue>[];
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.phone(onPhoneChanged: values.add),
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), '+923001234567');
      await tester.pump();
      expect(formKey.currentState!.validate(), isTrue);
      expect(values.last.isValid, isTrue);
      expect(values.last.e164, '+923001234567');
    });

    testWidgets('a selected country makes validation and the value agree', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final values = <SmartPhoneValue>[];
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.phone(
              showCountryPicker: true,
              initialCountryCode: 'PK',
              onPhoneChanged: values.add,
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), '03001234567');
      await tester.pump();
      expect(formKey.currentState!.validate(), isTrue);
      expect(values.last.isValid, isTrue);
      expect(values.last.e164, '+923001234567');
      await tester.enterText(find.byType(EditableText), '12345');
      await tester.pump();
      expect(formKey.currentState!.validate(), isFalse);
      expect(values.last.isValid, isFalse);
      expect(values.last.e164, isNull);
    });

    test('validation and parsing keep the documented relationship', () {
      expect(
        SmartPhoneValidation.validate('12345', policy: SmartPhonePolicy.auto),
        isNull,
      );
      expect(SmartPhoneValidation.parseValue('12345').isValid, isFalse);
      expect(
        SmartPhoneValidation.validate(
          '12345',
          policy: SmartPhonePolicy.countryAware,
        ),
        isNotNull,
      );
    });
  });

  group('contact picker permissions', () {
    test('the example apps declare no contacts permission', () {
      final manifest = File('example/android/app/src/main/AndroidManifest.xml')
          .readAsStringSync();
      expect(manifest, isNot(contains('READ_CONTACTS')));
      final plist = File('example/ios/Runner/Info.plist').readAsStringSync();
      expect(plist, isNot(contains('NSContactsUsageDescription')));
    });
  });
}
