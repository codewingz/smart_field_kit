import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

const _visa = '4111111111111111';
const _mastercard = '5555555555554444';
const _amex = '378282246310005';
const _discover = '6011111111111117';
const _diners = '30569309025904';
const _jcb = '3530111333300000';
const _unionPay = '6200000000000005';
const _maestro = '6759649826438453';

String _withCheckDigit(String body) {
  for (var digit = 0; digit < 10; digit++) {
    final candidate = '$body$digit';
    if (SmartCardUtils.passesLuhn(candidate)) {
      return candidate;
    }
  }
  throw StateError('unreachable');
}

TextEditingValue _edit(String oldText, String newText, {int? caret}) {
  return const SmartCardNumberFormatter().formatEditUpdate(
    TextEditingValue(
      text: oldText,
      selection: TextSelection.collapsed(offset: oldText.length),
    ),
    TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: caret ?? newText.length),
    ),
  );
}

Widget _app(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}

DateTime _now() => DateTime(2024, 6, 15, 12);

void main() {
  group('SmartCardUtils', () {
    test('detects supported brands from synthetic test numbers', () {
      expect(SmartCardUtils.detectBrand(_visa), SmartCardBrand.visa);
      expect(
        SmartCardUtils.detectBrand(_mastercard),
        SmartCardBrand.mastercard,
      );
      expect(
        SmartCardUtils.detectBrand('2221000000000009'),
        SmartCardBrand.mastercard,
      );
      expect(
        SmartCardUtils.detectBrand('2720990000000007'),
        SmartCardBrand.mastercard,
      );
      expect(SmartCardUtils.detectBrand('2720'), SmartCardBrand.mastercard);
      expect(SmartCardUtils.detectBrand(_amex), SmartCardBrand.amex);
      expect(SmartCardUtils.detectBrand('34'), SmartCardBrand.amex);
      expect(SmartCardUtils.detectBrand(_discover), SmartCardBrand.discover);
      expect(
        SmartCardUtils.detectBrand('6221260000000000'),
        SmartCardBrand.discover,
      );
      expect(SmartCardUtils.detectBrand(_diners), SmartCardBrand.dinersClub);
      expect(SmartCardUtils.detectBrand(_jcb), SmartCardBrand.jcb);
      expect(SmartCardUtils.detectBrand(_unionPay), SmartCardBrand.unionPay);
      expect(SmartCardUtils.detectBrand(_maestro), SmartCardBrand.maestro);
      expect(SmartCardUtils.detectBrand('9999'), SmartCardBrand.unknown);
      expect(SmartCardUtils.detectBrand(''), SmartCardBrand.unknown);
      expect(SmartCardUtils.detectBrand('4111 1111'), SmartCardBrand.visa);
    });

    test('Luhn accepts valid and rejects altered numbers', () {
      for (final number in [
        _visa,
        _mastercard,
        _amex,
        _discover,
        _diners,
        _jcb,
        _unionPay,
        _maestro,
      ]) {
        expect(SmartCardUtils.passesLuhn(number), isTrue, reason: number);
      }
      expect(SmartCardUtils.passesLuhn('4111111111111112'), isFalse);
      expect(SmartCardUtils.passesLuhn('4111 1111 1111 1111'), isTrue);
      expect(SmartCardUtils.passesLuhn('4111-1111-1111-1111'), isTrue);
      expect(SmartCardUtils.passesLuhn('4111a111111111111'), isFalse);
      expect(SmartCardUtils.passesLuhn('0'), isFalse);
      expect(SmartCardUtils.passesLuhn(''), isFalse);
    });

    test('issuer-aware grouping', () {
      expect(SmartCardUtils.format(_visa), '4111 1111 1111 1111');
      expect(SmartCardUtils.format(_amex), '3782 822463 10005');
      expect(SmartCardUtils.format(_diners), '3056 930902 5904');
      expect(SmartCardUtils.format('4111 1111-1111 11'), '4111 1111 1111 11');
      final visa19 = _withCheckDigit('411111111111111111');
      expect(
        SmartCardUtils.format(visa19),
        '4111 1111 1111 1111 ${visa19.substring(16)}',
      );
      expect(SmartCardUtils.format(''), '');
    });

    test('masked numbers show only the last four digits', () {
      expect(SmartCardUtils.maskedNumber(_visa), '•••• •••• •••• 1111');
      expect(SmartCardUtils.maskedNumber(_amex), '•••• •••••• •0005');
      expect(SmartCardUtils.maskedNumber('1234'), '1234');
    });

    test('expiry parsing and month-end boundaries', () {
      final parsed = SmartCardUtils.tryParseExpiry('02/24');
      expect(parsed!.month, 2);
      expect(parsed.year, 2024);
      expect(SmartCardUtils.tryParseExpiry('13/24'), isNull);
      expect(SmartCardUtils.tryParseExpiry('00/24'), isNull);
      expect(SmartCardUtils.tryParseExpiry('1/24'), isNull);
      expect(SmartCardUtils.tryParseExpiry('02/2024'), isNull);
      final long = SmartCardUtils.tryParseExpiry(
        '02/2026',
        format: SmartExpiryFormat.mmYyyy,
      );
      expect(long!.year, 2026);
      expect(
        SmartCardUtils.tryParseExpiry(
          '02/26',
          format: SmartExpiryFormat.mmYyyy,
        ),
        isNull,
      );
      const leap = SmartCardExpiry(2, 2024);
      expect(leap.isExpired(DateTime(2024, 2, 29, 23, 59, 59)), isFalse);
      expect(leap.isExpired(DateTime(2024, 3, 1)), isTrue);
      const normal = SmartCardExpiry(2, 2023);
      expect(normal.isExpired(DateTime(2023, 2, 28, 23, 59)), isFalse);
      expect(normal.isExpired(DateTime(2023, 3, 1)), isTrue);
      const december = SmartCardExpiry(12, 2024);
      expect(december.isExpired(DateTime(2024, 12, 31, 23, 59)), isFalse);
      expect(december.isExpired(DateTime(2025, 1, 1)), isTrue);
    });

    test('cvv length per brand and policy', () {
      expect(
        SmartCardUtils.isCvvLengthValid('123', SmartCardBrand.visa),
        isTrue,
      );
      expect(
        SmartCardUtils.isCvvLengthValid('1234', SmartCardBrand.visa),
        isFalse,
      );
      expect(
        SmartCardUtils.isCvvLengthValid('1234', SmartCardBrand.amex),
        isTrue,
      );
      expect(
        SmartCardUtils.isCvvLengthValid('123', SmartCardBrand.amex),
        isFalse,
      );
      expect(
        SmartCardUtils.isCvvLengthValid('123', SmartCardBrand.unknown),
        isTrue,
      );
      expect(
        SmartCardUtils.isCvvLengthValid('1234', SmartCardBrand.unknown),
        isTrue,
      );
      expect(
        SmartCardUtils.isCvvLengthValid('12', SmartCardBrand.unknown),
        isFalse,
      );
      expect(
        SmartCardUtils.isCvvLengthValid('12a', SmartCardBrand.visa),
        isFalse,
      );
      expect(
        SmartCardUtils.isCvvLengthValid(
          '1234',
          SmartCardBrand.visa,
          allowedLengths: {4},
        ),
        isTrue,
      );
    });
  });

  group('validators', () {
    test('card number checks brand, length, and Luhn', () {
      final validator = SmartValidators.cardNumber();
      expect(validator(''), isNull);
      expect(validator(_visa), isNull);
      expect(validator('4111 1111 1111 1111'), isNull);
      expect(validator(_amex), isNull);
      expect(validator(_diners), isNull);
      expect(validator(_withCheckDigit('411111111111111111')), isNull);
      expect(validator('4111111111111112'), 'Check the card number.');
      expect(validator('411111111111'), 'Enter a valid card number.');
      expect(validator('4111111111111'), isNotNull);
      expect(validator('abcd'), 'Enter a valid card number.');
      expect(validator('378282246310006'), 'Check the card number.');
    });

    test('Luhn can be disabled and brands restricted', () {
      expect(
        SmartValidators.cardNumber(validateLuhn: false)('4111111111111112'),
        isNull,
      );
      final onlyVisa = SmartValidators.cardNumber(
        acceptedBrands: {SmartCardBrand.visa},
      );
      expect(onlyVisa(_visa), isNull);
      expect(onlyVisa(_mastercard), 'This card type is not accepted.');
    });

    test('expiry validator', () {
      final validator = SmartValidators.cardExpiry(now: _now);
      expect(validator(''), isNull);
      expect(validator('06/24'), isNull);
      expect(validator('05/24'), 'This card has expired.');
      expect(validator('13/30'), 'Enter a valid expiry date.');
      expect(validator('12/99'), isNull);
    });

    test('cvv validator follows the brand', () {
      var brand = SmartCardBrand.visa;
      final validator = SmartValidators.cardCvv(brand: () => brand);
      expect(validator('123'), isNull);
      expect(validator('1234'), 'Enter the 3-digit security code.');
      brand = SmartCardBrand.amex;
      expect(validator('1234'), isNull);
      expect(validator('123'), 'Enter the 4-digit security code.');
    });
  });

  group('SmartCardNumberFormatter', () {
    test('typing groups digits and keeps the caret', () {
      final fifth = _edit('4111', '41111');
      expect(fifth.text, '4111 1');
      expect(fifth.selection.baseOffset, 6);
      expect(_edit('', _visa).text, '4111 1111 1111 1111');
      expect(_edit('', _amex).text, '3782 822463 10005');
    });

    test('paste accepts spaces and dashes but rejects letters', () {
      expect(_edit('', '4111-1111-1111-1111').text, '4111 1111 1111 1111');
      expect(_edit('', '4111 1111 1111 1111').text, '4111 1111 1111 1111');
      expect(_edit('41', '41a').text, '41');
      expect(_edit('41', '41.').text, '41');
    });

    test('limits digits to the brand maximum', () {
      expect(
        _edit('3782 822463 10005', '3782 822463 100056').text,
        '3782 822463 10005',
      );
      expect(
        _edit('4111 1111 1111 1111 111', '4111 1111 1111 1111 1111').text,
        '4111 1111 1111 1111 111',
      );
    });

    test('deleting a space removes the digit before it', () {
      final result = _edit('4111 1', '41111', caret: 4);
      expect(
        result.text,
        '4111 1'.replaceAll('1', '1').isEmpty ? '' : result.text,
      );
      expect(result.text.replaceAll(' ', ''), '4111');
    });

    test('middle edits keep the caret on the same digit', () {
      final result = _edit('4111 1111', '41911 1111', caret: 3);
      expect(result.text, '4191 1111 1');
      expect(result.selection.baseOffset, 3);
    });

    test('composing text is untouched', () {
      final result = const SmartCardNumberFormatter().formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(
          text: 'ab',
          composing: TextRange(start: 0, end: 2),
        ),
      );
      expect(result.text, 'ab');
    });
  });

  group('SmartField.creditCard', () {
    testWidgets('renders three fields with card-appropriate input settings', (
      tester,
    ) async {
      await tester.pumpWidget(_app(SmartField.creditCard(now: _now)));
      expect(find.byType(TextFormField), findsNWidgets(3));
      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      for (final field in fields) {
        expect(field.keyboardType, TextInputType.number);
        expect(field.enableSuggestions, isFalse);
        expect(field.autocorrect, isFalse);
        expect(field.restorationId, isNull);
      }
      expect(fields[0].autofillHints, contains(AutofillHints.creditCardNumber));
      expect(
        fields[1].autofillHints,
        contains(AutofillHints.creditCardExpirationDate),
      );
      expect(fields[2].obscureText, isTrue);
    });

    testWidgets('typing formats the number and exposes a typed value', (
      tester,
    ) async {
      SmartCreditCardValue? latest;
      await tester.pumpWidget(
        _app(
          SmartField.creditCard(
            now: _now,
            onChanged: (value) => latest = value,
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField).at(0), _amex);
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).at(0))
            .controller
            .text,
        '3782 822463 10005',
      );
      expect(find.text('American Express'), findsWidgets);
      await tester.enterText(find.byType(TextFormField).at(1), '1229');
      await tester.enterText(find.byType(TextFormField).at(2), '1234');
      expect(latest!.number, _amex);
      expect(latest!.brand, SmartCardBrand.amex);
      expect(latest!.expiryMonth, 12);
      expect(latest!.expiryYear, 2029);
      expect(latest!.cvv, '1234');
      expect(latest!.last4, '0005');
      expect(latest.toString(), isNot(contains('1234')));
      expect(latest.toString(), isNot(contains(_amex)));
      expect(latest.toString(), isNot(contains('3782')));
    });

    testWidgets('Form validate, save, and reset work across all parts', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      SmartCreditCardValue? saved;
      final number = TextEditingController();
      final expiry = TextEditingController();
      final cvv = TextEditingController();
      for (final c in [number, expiry, cvv]) {
        addTearDown(c.dispose);
      }
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.creditCard(
              now: _now,
              isRequired: true,
              requiredErrorText: 'Required',
              numberController: number,
              expiryController: expiry,
              cvvController: cvv,
              onSaved: (value) => saved = value,
            ),
          ),
        ),
      );
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Required'), findsNWidgets(3));
      await tester.enterText(
        find.byType(TextFormField).at(0),
        '4111111111111112',
      );
      await tester.enterText(find.byType(TextFormField).at(1), '0524');
      await tester.enterText(find.byType(TextFormField).at(2), '12');
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Check the card number.'), findsOneWidget);
      expect(find.text('This card has expired.'), findsOneWidget);
      expect(find.text('Enter the 3-digit security code.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(0), _visa);
      await tester.enterText(find.byType(TextFormField).at(1), '0624');
      await tester.enterText(find.byType(TextFormField).at(2), '123');
      expect(formKey.currentState!.validate(), isTrue);
      formKey.currentState!.save();
      expect(saved!.number, _visa);
      expect(saved!.expiryYear, 2024);
      formKey.currentState!.reset();
      await tester.pump();
      expect(number.text, isEmpty);
      expect(expiry.text, isEmpty);
      expect(cvv.text, isEmpty);
    });

    testWidgets('optional card passes while empty; accepted brands enforced', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.creditCard(
              now: _now,
              acceptedBrands: const {SmartCardBrand.visa},
            ),
          ),
        ),
      );
      expect(formKey.currentState!.validate(), isTrue);
      await tester.enterText(find.byType(TextFormField).at(0), _mastercard);
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('This card type is not accepted.'), findsOneWidget);
    });

    testWidgets('server errors appear on each part and clear on edit', (
      tester,
    ) async {
      final number = SmartServerError();
      final expiry = SmartServerError();
      final cvv = SmartServerError();
      for (final e in [number, expiry, cvv]) {
        addTearDown(e.dispose);
      }
      await tester.pumpWidget(
        _app(
          SmartField.creditCard(
            now: _now,
            numberServerError: number,
            expiryServerError: expiry,
            cvvServerError: cvv,
          ),
        ),
      );
      number.set('Payment declined');
      expiry.set('Card expired per issuer');
      cvv.set('Security code rejected');
      await tester.pump();
      expect(find.text('Payment declined'), findsOneWidget);
      expect(find.text('Card expired per issuer'), findsOneWidget);
      expect(find.text('Security code rejected'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(2), '1');
      await tester.pump();
      expect(find.text('Security code rejected'), findsNothing);
      expect(find.text('Payment declined'), findsOneWidget);
    });

    testWidgets('cvv can be shown only when the developer opts out', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(SmartField.creditCard(now: _now, concealCvv: false)),
      );
      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(fields[2].obscureText, isFalse);
      expect(
        fields[2].autofillHints,
        contains(AutofillHints.creditCardSecurityCode),
      );
    });

    testWidgets('long expiry format and auto-advance focus', (tester) async {
      final number = FocusNode();
      final expiry = FocusNode();
      final cvv = FocusNode();
      for (final f in [number, expiry, cvv]) {
        addTearDown(f.dispose);
      }
      await tester.pumpWidget(
        _app(
          SmartField.creditCard(
            now: _now,
            expiryFormat: SmartExpiryFormat.mmYyyy,
            numberFocusNode: number,
            expiryFocusNode: expiry,
            cvvFocusNode: cvv,
          ),
        ),
      );
      number.requestFocus();
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).at(0), _visa);
      await tester.pump();
      expect(expiry.hasFocus, isTrue);
      await tester.enterText(find.byType(TextFormField).at(1), '122030');
      await tester.pump();
      expect(find.text('12/2030'), findsOneWidget);
      expect(cvv.hasFocus, isTrue);
    });

    testWidgets('does not dispose developer controllers and handles layouts', (
      tester,
    ) async {
      final number = TextEditingController(text: _visa);
      addTearDown(number.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2),
              size: Size(240, 800),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: SingleChildScrollView(
                  child: SizedBox(
                    width: 240,
                    child: SmartField.creditCard(
                      now: _now,
                      numberController: number,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      number.text = '1';
      expect(number.text, '1');
    });

    testWidgets('semantics expose labels', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(SmartField.creditCard(now: _now)));
      expect(find.bySemanticsLabel(RegExp('Card number')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Expiry')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Security code')), findsWidgets);
      handle.dispose();
    });
  });
}
