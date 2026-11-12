import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

String _complete(String prefix, int length) {
  final body = prefix.padRight(length - 1, '0').substring(0, length - 1);
  for (var digit = 0; digit < 10; digit++) {
    final candidate = '$body$digit';
    if (SmartCardUtils.passesLuhn(candidate)) {
      return candidate;
    }
  }
  throw StateError('no check digit');
}

String _spoil(String number) {
  final last = int.parse(number[number.length - 1]);
  return '${number.substring(0, number.length - 1)}${(last + 1) % 10}';
}

final String _visa16 = _complete('4111', 16);
final String _visa18 = _complete(_visa16, 18);
final String _visa19 = _complete(_visa18, 19);
final String _mastercard = _complete('5555', 16);
final String _amex = _complete('3782', 15);

DateTime _now() => DateTime(2024, 6, 15, 12);

Widget _app(Widget child, {TextDirection direction = TextDirection.ltr}) {
  return MaterialApp(
    home: Directionality(
      textDirection: direction,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    ),
  );
}

Finder _input(int index) => find.byType(EditableText).at(index);

bool _focused(WidgetTester tester, int index) =>
    tester.widget<EditableText>(_input(index)).focusNode.hasFocus;

String _text(WidgetTester tester, int index) =>
    tester.widget<EditableText>(_input(index)).controller.text;

String _digits(WidgetTester tester) => _text(tester, 0).replaceAll(' ', '');

Future<void> _type(WidgetTester tester, String digits, {int from = 0}) async {
  for (var count = from + 1; count <= digits.length; count++) {
    if (!_focused(tester, 0)) {
      return;
    }
    await tester.enterText(_input(0), digits.substring(0, count));
    await tester.pump();
  }
}

Future<void> _focusNumber(WidgetTester tester) async {
  await tester.showKeyboard(_input(0));
  await tester.pump();
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

void main() {
  group('19T brand identification', () {
    const identified = <String, SmartCardBrand>{
      '4111': SmartCardBrand.visa,
      '51': SmartCardBrand.mastercard,
      '55': SmartCardBrand.mastercard,
      '2221': SmartCardBrand.mastercard,
      '25': SmartCardBrand.mastercard,
      '2720': SmartCardBrand.mastercard,
      '34': SmartCardBrand.amex,
      '37': SmartCardBrand.amex,
      '6011': SmartCardBrand.discover,
      '644': SmartCardBrand.discover,
      '649': SmartCardBrand.discover,
      '620': SmartCardBrand.unionPay,
      '622126': SmartCardBrand.unionPay,
      '8171': SmartCardBrand.unionPay,
      '501800': SmartCardBrand.maestro,
      '6759': SmartCardBrand.maestro,
      '3528': SmartCardBrand.jcb,
      '3589': SmartCardBrand.jcb,
      '2131': SmartCardBrand.jcb,
      '1800': SmartCardBrand.jcb,
      '300': SmartCardBrand.dinersClub,
      '36': SmartCardBrand.dinersClub,
      '38': SmartCardBrand.dinersClub,
      '2200': SmartCardBrand.mir,
      '2204': SmartCardBrand.mir,
      '9792': SmartCardBrand.troy,
      '401178': SmartCardBrand.elo,
      '509000': SmartCardBrand.elo,
      '637095': SmartCardBrand.hiper,
      '606282': SmartCardBrand.hipercard,
      '589562': SmartCardBrand.naranja,
      '506099': SmartCardBrand.verve,
    };

    for (final entry in identified.entries) {
      test('${entry.key} is ${entry.value.displayName}', () {
        final match = SmartCardUtils.matchBrand(entry.key);
        expect(match.brand, entry.value);
        expect(match.detection, SmartCardBrandDetection.identified);
        final number = _complete(entry.key, entry.value.maxLength);
        expect(SmartCardUtils.detectBrand(number), entry.value);
        expect(
          SmartCardUtils.assessNumber(number).status,
          SmartCardNumberStatus.valid,
        );
      });
    }

    test('every brand has a prefix that identifies it', () {
      final covered = identified.values.toSet();
      for (final brand in SmartCardBrand.values) {
        if (brand != SmartCardBrand.unknown) {
          expect(covered, contains(brand));
        }
      }
    });

    test('overlapping prefixes stay ambiguous until they are settled', () {
      final four = SmartCardUtils.matchBrand('4');
      expect(four.detection, SmartCardBrandDetection.ambiguous);
      expect(four.brand, SmartCardBrand.unknown);
      expect(four.likelyBrand, SmartCardBrand.visa);
      expect(
        four.candidates,
        containsAll([
          SmartCardBrand.visa,
          SmartCardBrand.elo,
          SmartCardBrand.naranja,
        ]),
      );
      expect(SmartCardUtils.detectBrand('41'), SmartCardBrand.visa);
      expect(
        SmartCardUtils.matchBrand('40117').detection,
        SmartCardBrandDetection.ambiguous,
      );
      expect(SmartCardUtils.detectBrand('401170'), SmartCardBrand.visa);
      expect(SmartCardUtils.detectBrand('401178'), SmartCardBrand.elo);
      final two = SmartCardUtils.matchBrand('22');
      expect(two.detection, SmartCardBrandDetection.ambiguous);
      expect(
        two.candidates,
        containsAll([SmartCardBrand.mastercard, SmartCardBrand.mir]),
      );
      final six = SmartCardUtils.matchBrand('62');
      expect(six.detection, SmartCardBrandDetection.ambiguous);
      expect(six.likelyBrand, SmartCardBrand.maestro);
      expect(six.candidates, contains(SmartCardBrand.unionPay));
      final discover = SmartCardUtils.matchBrand('6500');
      expect(discover.detection, SmartCardBrandDetection.ambiguous);
      expect(discover.likelyBrand, SmartCardBrand.discover);
      expect(SmartCardUtils.detectBrand('65003100'), SmartCardBrand.elo);
      expect(SmartCardUtils.detectBrand('650052'), SmartCardBrand.troy);
      expect(SmartCardUtils.detectBrand('650000'), SmartCardBrand.discover);
    });

    test('four digits do not always identify a brand', () {
      for (final prefix in ['4011', '4389', '5067', '6500', '6277']) {
        expect(
          SmartCardUtils.matchBrand(prefix).detection,
          SmartCardBrandDetection.ambiguous,
          reason: prefix,
        );
      }
    });

    test('a single unconfirmed candidate is not reported as the brand', () {
      final match = SmartCardUtils.matchBrand('35');
      expect(match.brand, SmartCardBrand.unknown);
      expect(match.candidates, [SmartCardBrand.jcb]);
      expect(match.detection, SmartCardBrandDetection.ambiguous);
      expect(SmartCardUtils.detectBrand('3528'), SmartCardBrand.jcb);
      expect(
        SmartCardUtils.matchBrand('3500').detection,
        SmartCardBrandDetection.unknown,
      );
    });

    test('unknown prefixes and empty text match nothing', () {
      for (final prefix in ['', '0', '7', '19', '99', '2205', 'abc']) {
        final match = SmartCardUtils.matchBrand(prefix);
        expect(
          match.detection,
          SmartCardBrandDetection.unknown,
          reason: prefix,
        );
        expect(match.brand, SmartCardBrand.unknown);
        expect(match.candidates, isEmpty);
      }
    });

    test('detection ignores separators and digits after the eighth', () {
      expect(SmartCardUtils.detectBrand('40-11 78'), SmartCardBrand.elo);
      expect(
        SmartCardUtils.detectBrand('${'65003100'}99999999'),
        SmartCardBrand.elo,
      );
    });

    test('security code names and sizes come from the brand', () {
      const names = {
        SmartCardBrand.visa: 'CVV',
        SmartCardBrand.mastercard: 'CVC',
        SmartCardBrand.amex: 'CID',
        SmartCardBrand.dinersClub: 'CVV',
        SmartCardBrand.discover: 'CID',
        SmartCardBrand.jcb: 'CVV',
        SmartCardBrand.unionPay: 'CVN',
        SmartCardBrand.maestro: 'CVC',
        SmartCardBrand.troy: 'CVV',
        SmartCardBrand.elo: 'CVE',
        SmartCardBrand.mir: 'CVP2',
        SmartCardBrand.hiper: 'CVC',
        SmartCardBrand.hipercard: 'CVC',
        SmartCardBrand.naranja: 'CVV',
        SmartCardBrand.verve: 'CVV',
        SmartCardBrand.unknown: 'CVV',
      };
      for (final brand in SmartCardBrand.values) {
        expect(brand.securityCodeName, names[brand], reason: brand.name);
        expect(brand.cvvLength, brand == SmartCardBrand.amex ? 4 : 3);
      }
    });
  });

  group('19T lengths', () {
    const prefixes = <SmartCardBrand, String>{
      SmartCardBrand.visa: '4111',
      SmartCardBrand.mastercard: '5555',
      SmartCardBrand.amex: '3782',
      SmartCardBrand.dinersClub: '3056',
      SmartCardBrand.discover: '6011',
      SmartCardBrand.jcb: '3530',
      SmartCardBrand.unionPay: '6200',
      SmartCardBrand.maestro: '6759',
      SmartCardBrand.troy: '9792',
      SmartCardBrand.elo: '401178',
      SmartCardBrand.mir: '2200',
      SmartCardBrand.hiper: '637095',
      SmartCardBrand.hipercard: '606282',
      SmartCardBrand.naranja: '589562',
      SmartCardBrand.verve: '506099',
    };

    for (final entry in prefixes.entries) {
      test('${entry.key.displayName} from 12 to 20 digits', () {
        final brand = entry.key;
        for (var length = 12; length <= 20; length++) {
          final number = _complete(entry.value, length);
          final assessment = SmartCardUtils.assessNumber(number);
          final reason = '${brand.name} $length';
          expect(assessment.brand, brand, reason: reason);
          expect(assessment.digitCount, length, reason: reason);
          if (length > brand.maxLength) {
            expect(
              assessment.status,
              SmartCardNumberStatus.invalid,
              reason: reason,
            );
            expect(assessment.issue, SmartCardNumberIssue.wrongLength);
          } else if (brand.lengths.contains(length)) {
            expect(
              assessment.status,
              SmartCardNumberStatus.valid,
              reason: reason,
            );
            expect(
              assessment.canBeLonger,
              length < brand.maxLength,
              reason: reason,
            );
            expect(assessment.isFinal, length == brand.maxLength);
          } else {
            expect(
              assessment.status,
              SmartCardNumberStatus.incomplete,
              reason: reason,
            );
            final next = brand.lengths.where((value) => value > length);
            expect(
              assessment.remainingDigits,
              next.reduce((a, b) => a < b ? a : b) - length,
              reason: reason,
            );
          }
        }
      });
    }

    test('a valid Visa number can grow from 16 to 18 and 19 digits', () {
      for (final number in [_visa16, _visa18, _visa19]) {
        expect(
          SmartCardUtils.assessNumber(number).status,
          SmartCardNumberStatus.valid,
          reason: '${number.length}',
        );
      }
      final seventeen = SmartCardUtils.assessNumber(_visa18.substring(0, 17));
      expect(seventeen.status, SmartCardNumberStatus.incomplete);
      expect(seventeen.remainingDigits, 1);
      expect(SmartCardUtils.assessNumber(_visa16).isFinal, isFalse);
      expect(SmartCardUtils.assessNumber(_visa18).isFinal, isFalse);
      expect(SmartCardUtils.assessNumber(_visa19).isFinal, isTrue);
      expect(SmartCardUtils.assessNumber(_mastercard).isFinal, isTrue);
      expect(SmartCardUtils.assessNumber(_amex).isFinal, isTrue);
    });

    test('an unknown brand is never final', () {
      final assessment = SmartCardUtils.assessNumber(_complete('9999', 19));
      expect(assessment.status, SmartCardNumberStatus.valid);
      expect(assessment.isFinal, isFalse);
    });
  });

  group('19T number validation', () {
    test('a correct checksum is valid and a wrong one is not', () {
      expect(SmartCardUtils.passesLuhn(_mastercard), isTrue);
      expect(SmartCardUtils.passesLuhn(_spoil(_mastercard)), isFalse);
      final bad = SmartCardUtils.assessNumber(_spoil(_mastercard));
      expect(bad.status, SmartCardNumberStatus.invalid);
      expect(bad.issue, SmartCardNumberIssue.failsChecksum);
      expect(
        SmartCardUtils.assessNumber(_spoil(_amex)).status,
        SmartCardNumberStatus.invalid,
      );
    });

    test('a failing checksum is final only at the longest length', () {
      for (final number in [_spoil(_visa16), _spoil(_visa18)]) {
        final assessment = SmartCardUtils.assessNumber(number);
        expect(assessment.status, SmartCardNumberStatus.incomplete);
        expect(assessment.issue, SmartCardNumberIssue.failsChecksum);
        expect(assessment.remainingDigits, number.length == 16 ? 2 : 1);
        expect(SmartValidators.cardNumber()(number), 'Check the card number.');
      }
      final last = SmartCardUtils.assessNumber(_spoil(_visa19));
      expect(last.status, SmartCardNumberStatus.invalid);
      expect(last.issue, SmartCardNumberIssue.failsChecksum);
    });

    test('UnionPay is exempt from the checksum by default', () {
      for (var length = 14; length <= 19; length++) {
        final number = _spoil(_complete('6200', length));
        expect(SmartCardUtils.passesLuhn(number), isFalse);
        expect(
          SmartCardUtils.assessNumber(number).status,
          SmartCardNumberStatus.valid,
          reason: '$length',
        );
      }
      expect(
        SmartCardUtils.assessNumber(
          _spoil(_complete('6200', 19)),
          luhnExemptBrands: const {},
        ).status,
        SmartCardNumberStatus.invalid,
      );
    });

    test('incomplete and ambiguous numbers are not errors', () {
      for (final partial in ['4', '41', '4111 1111', '5', '62', '3']) {
        final assessment = SmartCardUtils.assessNumber(partial);
        expect(
          assessment.status,
          SmartCardNumberStatus.incomplete,
          reason: partial,
        );
        expect(assessment.issue, SmartCardNumberIssue.none);
      }
    });

    test('an accepted-brand list rejects as soon as no brand can match', () {
      const onlyVisa = {SmartCardBrand.visa};
      SmartCardNumberAssessment assess(String value) =>
          SmartCardUtils.assessNumber(value, acceptedBrands: onlyVisa);
      expect(assess('4').status, SmartCardNumberStatus.incomplete);
      expect(assess('40117').status, SmartCardNumberStatus.incomplete);
      expect(assess(_visa16).status, SmartCardNumberStatus.valid);
      for (final value in ['5', '34', '99', '401178', _mastercard]) {
        expect(assess(value).status, SmartCardNumberStatus.invalid);
        expect(
          assess(value).issue,
          SmartCardNumberIssue.brandNotAccepted,
          reason: value,
        );
      }
      expect(
        SmartCardUtils.assessNumber(
          '4',
          acceptedBrands: const {SmartCardBrand.elo},
        ).status,
        SmartCardNumberStatus.incomplete,
      );
      expect(
        SmartCardUtils.assessNumber(
          '41',
          acceptedBrands: const {SmartCardBrand.elo},
        ).issue,
        SmartCardNumberIssue.brandNotAccepted,
      );
    });

    test('empty text, separators and other characters', () {
      expect(
        SmartCardUtils.assessNumber('').status,
        SmartCardNumberStatus.empty,
      );
      final spaced =
          '${_visa16.substring(0, 4)}-${_visa16.substring(4, 8)} '
          '${_visa16.substring(8, 12)} ${_visa16.substring(12)}';
      expect(
        SmartCardUtils.assessNumber(spaced).status,
        SmartCardNumberStatus.valid,
      );
      expect(SmartCardUtils.assessNumber(spaced).digitCount, 16);
      for (final value in [
        ' ',
        '-',
        '4111x',
        '4111 1111',
        '4111.1111',
        '４１１１',
        '4111\n1111',
      ]) {
        final assessment = SmartCardUtils.assessNumber(value);
        expect(assessment.status, SmartCardNumberStatus.invalid);
        expect(
          assessment.issue,
          SmartCardNumberIssue.invalidCharacters,
          reason: value.codeUnits.toString(),
        );
      }
      expect(SmartCardUtils.passesLuhn('4111x'), isFalse);
      expect(SmartCardUtils.passesLuhn('0'), isFalse);
      expect(SmartCardUtils.digitsOnly('4a1-1 1１'), '4111');
    });

    test('the same text always gives the same result', () {
      final inputs = [
        '',
        '4',
        _visa16,
        _spoil(_visa16),
        _visa19,
        _mastercard,
        _spoil(_mastercard),
        '99',
      ];
      String describe(String value) {
        final assessment = SmartCardUtils.assessNumber(value);
        return '${assessment.status.name}/${assessment.issue.name}/'
            '${assessment.brand.name}/${assessment.remainingDigits}/'
            '${assessment.match.candidates.map((b) => b.name).join(',')}';
      }

      final first = [for (final value in inputs) describe(value)];
      final reversed = [for (final value in inputs.reversed) describe(value)];
      expect(reversed.reversed.toList(), first);
      for (var round = 0; round < 3; round++) {
        expect([for (final value in inputs) describe(value)], first);
      }
    });

    test('assessments do not print the number', () {
      final text = SmartCardUtils.assessNumber(_visa16).toString();
      expect(text, isNot(contains(_visa16)));
      expect(text, isNot(contains(_visa16.substring(12))));
    });
  });

  group('19T number formatting', () {
    test('groups follow the brand and longer numbers keep every digit', () {
      expect(SmartCardUtils.format(_visa16), matches(r'^\d{4}( \d{4}){3}$'));
      expect(SmartCardUtils.format(_amex), matches(r'^\d{4} \d{6} \d{5}$'));
      expect(
        SmartCardUtils.format(_complete('3056', 14)),
        matches(r'^\d{4} \d{6} \d{4}$'),
      );
      final long = SmartCardUtils.format(_visa19);
      expect(long, matches(r'^\d{4}( \d{4}){3} \d{3}$'));
      expect(long.replaceAll(' ', ''), _visa19);
      expect(SmartCardUtils.groupSizes(SmartCardBrand.visa, 19), [
        4,
        4,
        4,
        4,
        3,
      ]);
    });

    test('a very long digit string is grouped in linear time', () {
      final digits = '4' * 100000;
      final watch = Stopwatch()..start();
      final shown = SmartCardUtils.format(digits);
      final masked = SmartCardUtils.maskedNumber(digits);
      watch.stop();
      expect(watch.elapsedMilliseconds, lessThan(2000));
      expect(shown.length, 124999);
      expect(shown.replaceAll(' ', ''), digits);
      expect(masked.length, shown.length);
      expect(masked.endsWith('4444'), isTrue);
      expect(SmartCardUtils.format('4' * 23), '4444 4444 4444 4444 4444 444');
      expect(
        SmartCardUtils.maskedNumber('4111111111111111'),
        '\u2022\u2022\u2022\u2022 \u2022\u2022\u2022\u2022 \u2022\u2022\u2022\u2022 1111',
      );
    });

    test('typing one digit at a time keeps the caret at the end', () {
      var value = TextEditingValue.empty;
      for (final digit in _visa19.split('')) {
        final next = '${value.text}$digit';
        value = const SmartCardNumberFormatter().formatEditUpdate(
          value,
          TextEditingValue(
            text: next,
            selection: TextSelection.collapsed(offset: next.length),
          ),
        );
        expect(value.selection.baseOffset, value.text.length);
      }
      expect(value.text.replaceAll(' ', ''), _visa19);
    });

    test('a paste with spaces or hyphens is regrouped and not shortened', () {
      final pasted = _visa19.replaceAllMapped(
        RegExp(r'\d{4}'),
        (m) => '${m[0]}-',
      );
      final result = _edit('', pasted);
      expect(result.text.replaceAll(' ', ''), _visa19);
      expect(result.text, SmartCardUtils.format(_visa19));
    });

    test('too many digits or other characters leave the text unchanged', () {
      final shown = SmartCardUtils.format(_mastercard);
      expect(_edit(shown, '${shown}1').text, shown);
      expect(_edit('', '${_visa19}1').text, '');
      expect(_edit(shown, '${shown}x').text, shown);
      expect(_edit('', '4111 1111').text, '');
    });

    test('backspace over a space removes the digit before it', () {
      final result = _edit('4111 1', '41111', caret: 4);
      expect(result.text, '4111');
      expect(result.selection.baseOffset, 3);
    });

    test('an edit in the middle keeps the caret beside the edit', () {
      final shown = SmartCardUtils.format(_visa16);
      final edited = '${shown.substring(0, 2)}9${shown.substring(2)}';
      final result = _edit(shown, edited, caret: 3);
      expect(
        result.text.replaceAll(' ', ''),
        '${_visa16.substring(0, 2)}9${_visa16.substring(2)}',
      );
      expect(result.selection.baseOffset, 3);
    });

    test('a selection is mapped onto the regrouped text', () {
      const formatter = SmartCardNumberFormatter();
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '41111111',
          selection: TextSelection(baseOffset: 2, extentOffset: 6),
        ),
      );
      expect(result.text, '4111 1111');
      expect(result.selection.baseOffset, 2);
      expect(result.selection.extentOffset, 7);
    });

    test('text under composition is not changed', () {
      const composing = TextEditingValue(
        text: '41111',
        selection: TextSelection.collapsed(offset: 5),
        composing: TextRange(start: 0, end: 5),
      );
      final result = const SmartCardNumberFormatter().formatEditUpdate(
        TextEditingValue.empty,
        composing,
      );
      expect(result, composing);
    });

    test('changing a prefix regroups for the new brand', () {
      final asAmex = _edit('', _amex);
      expect(asAmex.text, matches(r'^\d{4} \d{6} \d{5}$'));
      final digits = '5${_amex.substring(1)}';
      final asMastercard = _edit(asAmex.text, digits);
      expect(asMastercard.text, matches(r'^\d{4} \d{4} \d{4} \d{3}$'));
      expect(asMastercard.text.replaceAll(' ', ''), digits);
    });
  });

  group('19T auto-advance', () {
    testWidgets('a Mastercard number advances at 16 valid digits', (
      tester,
    ) async {
      await tester.pumpWidget(_app(SmartField.creditCard(now: _now)));
      await _focusNumber(tester);
      await _type(tester, _mastercard.substring(0, 15));
      expect(_focused(tester, 0), isTrue);
      await _type(tester, _mastercard, from: 15);
      expect(_digits(tester), _mastercard);
      expect(_focused(tester, 1), isTrue);
    });

    testWidgets('an American Express number advances at 15 valid digits', (
      tester,
    ) async {
      await tester.pumpWidget(_app(SmartField.creditCard(now: _now)));
      await _focusNumber(tester);
      await _type(tester, _amex);
      expect(_digits(tester), _amex);
      expect(_focused(tester, 1), isTrue);
    });

    testWidgets('a Visa number waits at 16 and 18 and advances at 19', (
      tester,
    ) async {
      await tester.pumpWidget(_app(SmartField.creditCard(now: _now)));
      await _focusNumber(tester);
      await _type(tester, _visa16);
      expect(_focused(tester, 0), isTrue);
      expect(find.textContaining('Number format looks valid'), findsOneWidget);
      await _type(tester, _visa18, from: 16);
      expect(_digits(tester), _visa18);
      expect(_focused(tester, 0), isTrue);
      expect(find.textContaining('Number format looks valid'), findsOneWidget);
      await _type(tester, _visa19, from: 18);
      expect(_digits(tester), _visa19);
      expect(_focused(tester, 1), isTrue);
    });

    testWidgets('a 16-digit Visa number with a wrong digit shows guidance', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.creditCard(now: _now),
          ),
        ),
      );
      await _focusNumber(tester);
      await _type(tester, _spoil(_visa16));
      expect(_focused(tester, 0), isTrue);
      expect(find.text('Check the card number.'), findsNothing);
      expect(
        find.text('Visa · Check the number or enter 2 more digits'),
        findsOneWidget,
      );
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Check the card number.'), findsOneWidget);
    });

    testWidgets('a UnionPay number advances only at 19 digits', (tester) async {
      final number = _spoil(_complete('6200', 19));
      await tester.pumpWidget(_app(SmartField.creditCard(now: _now)));
      await _focusNumber(tester);
      await _type(tester, number.substring(0, 18));
      expect(_digits(tester), number.substring(0, 18));
      expect(_focused(tester, 0), isTrue);
      await _type(tester, number, from: 18);
      expect(_digits(tester), number);
      expect(_focused(tester, 1), isTrue);
    });

    for (final entry in const {
      'Discover': '6011',
      'Diners Club': '3056',
      'JCB': '3530',
      'Maestro': '6759',
      'Mir': '2200',
      'Verve': '506099',
    }.entries) {
      testWidgets('${entry.key} waits at shorter valid lengths', (
        tester,
      ) async {
        final brand = SmartCardUtils.detectBrand(entry.value);
        expect(brand.displayName, entry.key);
        final lengths = brand.lengths.toList()..sort();
        for (final length in lengths) {
          await tester.pumpWidget(_app(SmartField.creditCard(now: _now)));
          await _focusNumber(tester);
          final number = _complete(entry.value, length);
          await tester.enterText(_input(0), number);
          await tester.pump();
          expect(_digits(tester), number);
          expect(
            _focused(tester, 1),
            length == brand.maxLength,
            reason: '${entry.key} $length',
          );
          await tester.pumpWidget(const SizedBox());
        }
      });
    }

    testWidgets('a pasted number follows the same rule as a typed one', (
      tester,
    ) async {
      final expected = {
        _mastercard: true,
        _amex: true,
        _visa16: false,
        _visa18: false,
        _visa19: true,
        _spoil(_mastercard): false,
        _spoil(_visa19): false,
      };
      for (final entry in expected.entries) {
        final statuses = <SmartCardNumberStatus>[];
        await tester.pumpWidget(
          _app(
            SmartField.creditCard(
              now: _now,
              onChanged: (card) => statuses.add(card.numberStatus),
            ),
          ),
        );
        await _focusNumber(tester);
        await tester.enterText(_input(0), entry.key);
        await tester.pump();
        expect(_digits(tester), entry.key);
        expect(_focused(tester, 1), entry.value, reason: entry.key);
        final pasted = statuses.last;
        await tester.pumpWidget(const SizedBox());
        statuses.clear();
        await tester.pumpWidget(
          _app(
            SmartField.creditCard(
              now: _now,
              autoAdvance: false,
              onChanged: (card) => statuses.add(card.numberStatus),
            ),
          ),
        );
        await _focusNumber(tester);
        await _type(tester, entry.key);
        expect(statuses.last, pasted, reason: entry.key);
        expect(
          statuses.last,
          SmartCardUtils.assessNumber(entry.key).status,
          reason: entry.key,
        );
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('a wrong checksum never advances and shows the error', (
      tester,
    ) async {
      await tester.pumpWidget(_app(SmartField.creditCard(now: _now)));
      await _focusNumber(tester);
      await _type(tester, _spoil(_mastercard));
      expect(_focused(tester, 0), isTrue);
      expect(find.text('Check the card number.'), findsOneWidget);
    });

    testWidgets('an unknown brand does not advance', (tester) async {
      await tester.pumpWidget(_app(SmartField.creditCard(now: _now)));
      await _focusNumber(tester);
      await tester.enterText(_input(0), _complete('9999', 19));
      await tester.pump();
      expect(_focused(tester, 0), isTrue);
    });

    testWidgets('Next moves to the expiry and focus stays there', (
      tester,
    ) async {
      await tester.pumpWidget(_app(SmartField.creditCard(now: _now)));
      await _focusNumber(tester);
      await _type(tester, _visa16);
      expect(_focused(tester, 0), isTrue);
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(_focused(tester, 1), isTrue);
      await tester.pump(const Duration(seconds: 1));
      expect(_focused(tester, 1), isTrue);
      await tester.enterText(_input(1), '1230');
      await tester.pump();
      expect(_text(tester, 1), '12/30');
      expect(_focused(tester, 0), isFalse);
      expect(_digits(tester), _visa16);
    });

    testWidgets('Tab moves to the expiry', (tester) async {
      await tester.pumpWidget(_app(SmartField.creditCard(now: _now)));
      await _focusNumber(tester);
      await _type(tester, _visa16);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_focused(tester, 1), isTrue);
      expect(_digits(tester), _visa16);
    });

    testWidgets('a parent rebuild does not move focus', (tester) async {
      late StateSetter rebuild;
      var label = 'Card number';
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return SmartField.creditCard(now: _now, numberLabel: label);
            },
          ),
        ),
      );
      await _focusNumber(tester);
      await _type(tester, _mastercard);
      expect(_focused(tester, 1), isTrue);
      await _focusNumber(tester);
      expect(_focused(tester, 0), isTrue);
      rebuild(() => label = 'Number');
      await tester.pump();
      await tester.pump();
      expect(_focused(tester, 0), isTrue);
      expect(_digits(tester), _mastercard);
    });

    testWidgets('replacing the controller does not move focus', (tester) async {
      final first = TextEditingController();
      final second = TextEditingController(
        text: SmartCardUtils.format(_mastercard),
      );
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      late StateSetter rebuild;
      var controller = first;
      final values = <SmartCreditCardValue>[];
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return SmartField.creditCard(
                now: _now,
                numberController: controller,
                onChanged: values.add,
              );
            },
          ),
        ),
      );
      await _focusNumber(tester);
      await _type(tester, '4111');
      rebuild(() => controller = second);
      await tester.pump();
      await tester.pump();
      expect(_digits(tester), _mastercard);
      expect(_focused(tester, 1), isFalse);
      expect(find.text('Mastercard'), findsOneWidget);
      expect(first.text, '4111');
    });

    testWidgets('autoAdvance false never moves focus', (tester) async {
      await tester.pumpWidget(
        _app(SmartField.creditCard(now: _now, autoAdvance: false)),
      );
      await _focusNumber(tester);
      await _type(tester, _mastercard);
      expect(_focused(tester, 0), isTrue);
    });
  });

  group('19T form integrity', () {
    testWidgets('validate, save and reset', (tester) async {
      final formKey = GlobalKey<FormState>();
      final saved = <SmartCreditCardValue>[];
      final changed = <SmartCreditCardValue>[];
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.creditCard(
              now: _now,
              isRequired: true,
              autoAdvance: false,
              onChanged: changed.add,
              onSaved: (value) => saved.add(value!),
            ),
          ),
        ),
      );
      expect(formKey.currentState!.validate(), isFalse);
      await tester.enterText(_input(0), _visa16);
      await tester.enterText(_input(1), '1230');
      await tester.enterText(_input(2), '123');
      await tester.pump();
      expect(formKey.currentState!.validate(), isTrue);
      formKey.currentState!.save();
      expect(saved.single.number, _visa16);
      expect(saved.single.brand, SmartCardBrand.visa);
      expect(saved.single.numberStatus, SmartCardNumberStatus.valid);
      expect(saved.single.expiryMonth, 12);
      expect(saved.single.expiryYear, 2030);
      expect(saved.single.cvv, '123');
      expect(saved.single.toString(), isNot(contains(_visa16)));
      expect(saved.single.toString(), isNot(contains('123,')));
      await tester.enterText(_input(0), _visa18.substring(0, 17));
      await tester.pump();
      expect(changed.last.numberStatus, SmartCardNumberStatus.incomplete);
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Enter a valid card number.'), findsOneWidget);
      formKey.currentState!.reset();
      await tester.pump();
      expect(_text(tester, 0), '');
      expect(_text(tester, 1), '');
      expect(_text(tester, 2), '');
      expect(find.text('Enter a valid card number.'), findsNothing);
      expect(find.textContaining('more digit'), findsNothing);
      saved.clear();
      formKey.currentState!.save();
      expect(saved.single.number, '');
      expect(saved.single.numberStatus, SmartCardNumberStatus.empty);
      expect(saved.single.brand, SmartCardBrand.unknown);
    });

    testWidgets('an empty optional card is valid', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.creditCard(now: _now),
          ),
        ),
      );
      expect(formKey.currentState!.validate(), isTrue);
      expect(find.byType(EditableText), findsNWidgets(3));
      expect(_text(tester, 0), '');
    });

    testWidgets('a valid shorter number edited into a longer one stays whole', (
      tester,
    ) async {
      final values = <SmartCreditCardValue>[];
      await tester.pumpWidget(
        _app(SmartField.creditCard(now: _now, onChanged: values.add)),
      );
      await _focusNumber(tester);
      await _type(tester, _visa16);
      expect(values.last.numberStatus, SmartCardNumberStatus.valid);
      await _type(tester, _visa18, from: 16);
      expect(values.last.number, _visa18);
      expect(values.last.numberStatus, SmartCardNumberStatus.valid);
      expect(
        values[values.length - 2].numberStatus,
        SmartCardNumberStatus.incomplete,
      );
    });

    testWidgets('an external controller swap is reflected in the saved value', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final first = TextEditingController(text: _mastercard);
      final second = TextEditingController(text: _amex);
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      final saved = <SmartCreditCardValue>[];
      Widget build(TextEditingController controller) => _app(
        Form(
          key: formKey,
          child: SmartField.creditCard(
            now: _now,
            numberController: controller,
            onSaved: (value) => saved.add(value!),
          ),
        ),
      );
      await tester.pumpWidget(build(first));
      expect(find.text('Mastercard'), findsOneWidget);
      await tester.pumpWidget(build(second));
      await tester.pump();
      expect(find.text('American Express'), findsOneWidget);
      formKey.currentState!.save();
      expect(saved.single.number, _amex);
      expect(saved.single.brand, SmartCardBrand.amex);
      expect(first.text, _mastercard);
    });

    testWidgets('two card fields keep their own brand and focus', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              SmartField.creditCard(now: _now),
              SmartField.creditCard(now: _now),
            ],
          ),
        ),
      );
      await tester.enterText(_input(3), _amex);
      await tester.pump();
      await tester.showKeyboard(_input(0));
      await tester.pump();
      await tester.enterText(_input(0), _mastercard);
      await tester.pump();
      expect(_focused(tester, 1), isTrue);
      expect(_focused(tester, 4), isFalse);
      expect(find.text('Mastercard'), findsOneWidget);
      expect(find.text('American Express'), findsOneWidget);
      expect(find.text('CVC'), findsOneWidget);
      expect(find.text('CID'), findsOneWidget);
    });

    testWidgets('a brand change keeps the security code and re-checks it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(SmartField.creditCard(now: _now, autoAdvance: false)),
      );
      await tester.enterText(_input(0), _amex);
      await tester.pump();
      expect(find.text('American Express'), findsOneWidget);
      expect(find.text('CID'), findsOneWidget);
      await tester.enterText(_input(2), '1234');
      await tester.pump();
      expect(find.textContaining('digit security code'), findsNothing);
      await tester.enterText(_input(0), _visa16);
      await tester.pump();
      expect(find.text('Visa'), findsOneWidget);
      expect(find.text('CVV'), findsOneWidget);
      expect(_text(tester, 2), '1234');
      expect(find.text('Enter the 3-digit security code.'), findsOneWidget);
      await tester.enterText(_input(0), _amex);
      await tester.pump();
      expect(find.text('Enter the 3-digit security code.'), findsNothing);
      expect(_text(tester, 2), '1234');
      await tester.enterText(_input(0), '');
      await tester.pump();
      expect(find.text('CID'), findsNothing);
      expect(find.text('CVV'), findsNothing);
    });

    testWidgets('cvvHint replaces the brand code name', (tester) async {
      await tester.pumpWidget(
        _app(SmartField.creditCard(now: _now, cvvHint: 'Code')),
      );
      await tester.enterText(_input(0), _mastercard);
      await tester.pump();
      expect(find.text('Code'), findsOneWidget);
      expect(find.text('CVC'), findsNothing);
    });

    testWidgets('expiry and security code changes are reported', (
      tester,
    ) async {
      final values = <SmartCreditCardValue>[];
      await tester.pumpWidget(
        _app(
          SmartField.creditCard(
            now: _now,
            autoAdvance: false,
            onChanged: values.add,
          ),
        ),
      );
      await tester.enterText(_input(0), _mastercard);
      await tester.enterText(_input(1), '0131');
      await tester.pump();
      expect(values.last.expiryMonth, 1);
      expect(values.last.expiryYear, 2031);
      await tester.enterText(_input(2), '987');
      await tester.pump();
      expect(values.last.cvv, '987');
      expect(values.last.number, _mastercard);
      expect(values.last.brand, SmartCardBrand.mastercard);
      await tester.enterText(_input(1), '01');
      await tester.pump();
      expect(values.last.expiryMonth, isNull);
    });

    testWidgets('a right-to-left page keeps the digits in typed order', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(SmartField.creditCard(now: _now), direction: TextDirection.rtl),
      );
      await _focusNumber(tester);
      await _type(tester, _visa19);
      expect(tester.takeException(), isNull);
      expect(_text(tester, 0), SmartCardUtils.format(_visa19));
      expect(_focused(tester, 1), isTrue);
      expect(
        tester.widget<EditableText>(_input(0)).textDirection,
        TextDirection.ltr,
      );
    });
  });
}
