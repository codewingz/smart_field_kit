import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

void main() {
  const pakistan = SmartPhoneCountry(
    isoCode: 'PK',
    dialCode: '92',
    name: 'Pakistan',
    flagEmoji: '',
  );
  const unitedStates = SmartPhoneCountry(
    isoCode: 'US',
    dialCode: '1',
    name: 'United States',
    flagEmoji: '',
  );

  String? auto(String value, {SmartPhoneCountry? country}) {
    return SmartPhoneValidation.validate(
      value,
      policy: SmartPhonePolicy.auto,
      country: country,
      message: 'bad',
    );
  }

  group('SmartPhonePolicy.auto', () {
    test('selected country uses that country numbering rules', () {
      expect(auto('3001234567', country: pakistan), isNull);
      expect(auto('+923001234567', country: pakistan), isNull);
      expect(auto('300123', country: pakistan), 'bad');
      expect(auto('+16502530000', country: pakistan), 'bad');
      expect(auto('6502530000', country: unitedStates), isNull);
    });

    test(
      'international numbers without a country use the inferred country',
      () {
        expect(auto('+923001234567'), isNull);
        expect(auto('+92 300 1234567'), isNull);
        expect(auto('+16502530000'), isNull);
        expect(auto('+92300123'), 'bad');
        expect(auto('+1234'), 'bad');
        expect(auto('+99999999999'), 'bad');
      },
    );

    test('without country or plus prefix only syntax is checked', () {
      expect(auto('3001234567'), isNull);
      expect(auto('12345'), isNull);
      expect(auto('abc'), 'bad');
      expect(auto('12(3'), 'bad');
      expect(auto(''), isNull);
    });

    test('other policies are unchanged', () {
      String? run(SmartPhonePolicy policy, String value) {
        return SmartPhoneValidation.validate(
          value,
          policy: policy,
          message: 'bad',
        );
      }

      expect(run(SmartPhonePolicy.syntaxOnly, '+92300123'), isNull);
      expect(run(SmartPhonePolicy.countryAware, '+923001234567'), 'bad');
      expect(run(SmartPhonePolicy.legacy, '1234567'), isNull);
      expect(run(SmartPhonePolicy.legacy, '+923001234567'), 'bad');
    });

    test('raw value parsing and E.164 formatting', () {
      final valid = SmartPhoneValidation.parseValue('+92 300 1234567');
      expect(valid.text, '+92 300 1234567');
      expect(valid.isValid, isTrue);
      expect(valid.e164, '+923001234567');
      final invalid = SmartPhoneValidation.parseValue('+92300123');
      expect(invalid.isValid, isFalse);
      expect(invalid.e164, isNull);
    });
  });

  testWidgets('phone field with auto policy integrates with Form', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    final changes = <SmartPhoneValue>[];
    String? saved;
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: SmartField.phone(
              controller: controller,
              onChanged: (_) {},
              onSaved: (value) => saved = value,
              onPhoneChanged: changes.add,
              phoneErrorText: 'Invalid phone',
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), '+92300123');
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Invalid phone'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '+92 300 1234567');
    expect(formKey.currentState!.validate(), isTrue);
    formKey.currentState!.save();
    expect(saved, '+92 300 1234567');
    expect(controller.text, '+92 300 1234567');
    expect(changes.last.e164, '+923001234567');
    await tester.enterText(find.byType(TextFormField), '3001234567');
    expect(formKey.currentState!.validate(), isTrue);
  });
}
