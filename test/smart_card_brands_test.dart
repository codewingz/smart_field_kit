import 'dart:io';

import 'package:flutter/foundation.dart';
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

class _Case {
  const _Case(this.brand, this.prefixes, this.lengths, this.cvv);

  final SmartCardBrand brand;
  final List<String> prefixes;
  final List<int> lengths;
  final int cvv;
}

const _cases = [
  _Case(SmartCardBrand.visa, ['4'], [16, 18, 19], 3),
  _Case(
    SmartCardBrand.mastercard,
    [
      '51',
      '55',
      '2221',
      '2229',
      '223',
      '2299',
      '23',
      '24',
      '25',
      '26',
      '270',
      '271',
      '2720',
    ],
    [16],
    3,
  ),
  _Case(SmartCardBrand.amex, ['34', '37'], [15], 4),
  _Case(
    SmartCardBrand.dinersClub,
    ['300', '305', '36', '38', '39'],
    [14, 16, 19],
    3,
  ),
  _Case(SmartCardBrand.discover, ['6011', '644', '649'], [16, 17, 18, 19], 3),
  _Case(
    SmartCardBrand.jcb,
    ['3528', '3589', '2131', '1800'],
    [16, 17, 18, 19],
    3,
  ),
  _Case(
    SmartCardBrand.unionPay,
    ['620', '62100', '623', '626', '6282', '810', '8164'],
    [14, 15, 16, 17, 18, 19],
    3,
  ),
  _Case(
    SmartCardBrand.maestro,
    ['493698', '500000', '504174', '56', '59', '63', '67'],
    [12, 13, 14, 15, 16, 17, 18, 19],
    3,
  ),
  _Case(
    SmartCardBrand.troy,
    ['9792', '650052', '650083', '65083700', '65880900'],
    [16],
    3,
  ),
  _Case(
    SmartCardBrand.elo,
    ['401178', '438935', '504175', '506699', '627780', '650031', '655058'],
    [16],
    3,
  ),
  _Case(SmartCardBrand.mir, ['2200', '2204'], [16, 17, 18, 19], 3),
  _Case(SmartCardBrand.hiper, ['637095', '63737423', '637612'], [16], 3),
  _Case(SmartCardBrand.hipercard, ['606282'], [16], 3),
  _Case(SmartCardBrand.naranja, ['589562', '402918', '527572'], [16], 3),
  _Case(
    SmartCardBrand.verve,
    ['506099', '506150', '507865', '507941'],
    [16, 18, 19],
    3,
  ),
];

Widget _app(
  Widget child, {
  ThemeData? theme,
  TextDirection? direction,
  double scale = 1,
  Size? size,
}) {
  return MaterialApp(
    theme: theme,
    home: MediaQuery(
      data: MediaQueryData(
        textScaler: TextScaler.linear(scale),
        size: size ?? const Size(800, 900),
      ),
      child: Directionality(
        textDirection: direction ?? TextDirection.ltr,
        child: Scaffold(
          body: SingleChildScrollView(
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      ),
    ),
  );
}

DateTime _now() => DateTime(2024, 6, 15, 12);

String _fieldText(WidgetTester tester, int index) => tester
    .widget<EditableText>(find.byType(EditableText).at(index))
    .controller
    .text;

void main() {
  group('verified brand metadata', () {
    for (final item in _cases) {
      test('${item.brand.displayName}: prefixes, lengths, code size', () {
        expect(item.brand.lengths, item.lengths.toSet());
        expect(item.brand.cvvLength, item.cvv);
        for (final prefix in item.prefixes) {
          final number = _complete(prefix, item.brand.primaryLength);
          final match = SmartCardUtils.matchBrand(number);
          expect(match.brand, item.brand, reason: '$prefix -> ${match.brand}');
          expect(match.isCertain, isTrue);
          expect(
            SmartCardUtils.assessNumber(number).status,
            SmartCardNumberStatus.valid,
            reason: prefix,
          );
        }
      });

      test(
        '${item.brand.displayName}: every valid length passes, others do not',
        () {
          final prefix = item.prefixes.first;
          for (final length in item.lengths) {
            final number = _complete(prefix, length);
            final assessment = SmartCardUtils.assessNumber(number);
            expect(
              assessment.status,
              SmartCardNumberStatus.valid,
              reason: '$length',
            );
            expect(SmartValidators.cardNumber()(number), isNull);
          }
          final shortest = item.lengths.reduce((a, b) => a < b ? a : b);
          final tooShort = _complete(
            prefix,
            shortest,
          ).substring(0, shortest - 1);
          expect(
            SmartCardUtils.assessNumber(tooShort).status,
            SmartCardNumberStatus.incomplete,
          );
          expect(SmartValidators.cardNumber()(tooShort), isNotNull);
          final longest = item.lengths.reduce((a, b) => a > b ? a : b);
          final tooLong = '${_complete(prefix, longest)}0';
          final assessment = SmartCardUtils.assessNumber(tooLong);
          expect(assessment.status, SmartCardNumberStatus.invalid);
          expect(assessment.issue, SmartCardNumberIssue.wrongLength);
          final missing = [
            for (var length = shortest; length <= longest; length++)
              if (!item.lengths.contains(length)) length,
          ];
          for (final length in missing) {
            final number = _complete(prefix, length);
            expect(
              SmartValidators.cardNumber()(number),
              isNotNull,
              reason: '$length digits',
            );
          }
        },
      );

      test('${item.brand.displayName}: CVV length is ${item.cvv}', () {
        final brand = item.brand;
        for (var length = 2; length <= 5; length++) {
          expect(
            SmartCardUtils.isCvvLengthValid('1' * length, brand),
            length == item.cvv,
            reason: '$length digits',
          );
        }
      });
    }

    test('bundled brand list covers all requested networks', () {
      final names = SmartCardBrand.values.map((brand) => brand.name).toSet();
      for (final name in [
        'visa',
        'mastercard',
        'amex',
        'discover',
        'jcb',
        'dinersClub',
        'unionPay',
        'maestro',
        'mir',
        'elo',
        'troy',
        'verve',
        'hipercard',
      ]) {
        expect(names, contains(name));
      }
      expect(names, isNot(contains('rupay')));
    });
  });

  group('overlapping and ambiguous prefixes', () {
    test('short prefixes stay uncertain instead of forcing a brand', () {
      for (final digits in [
        '4',
        '40',
        '401',
        '4011',
        '40117',
        '6',
        '5',
        '50',
        '65',
        '3',
        '2',
        '22',
        '62',
        '650',
      ]) {
        final match = SmartCardUtils.matchBrand(digits);
        expect(match.isCertain, isFalse, reason: digits);
        expect(
          SmartCardUtils.detectBrand(digits),
          SmartCardBrand.unknown,
          reason: digits,
        );
      }
      final four = SmartCardUtils.matchBrand('4');
      expect(four.likelyBrand, SmartCardBrand.visa);
      expect(
        four.candidates,
        containsAll([
          SmartCardBrand.visa,
          SmartCardBrand.elo,
          SmartCardBrand.naranja,
        ]),
      );
    });

    test('brand resolves as soon as the prefix is unambiguous', () {
      expect(SmartCardUtils.detectBrand('41'), SmartCardBrand.visa);
      expect(SmartCardUtils.detectBrand('4111'), SmartCardBrand.visa);
      expect(SmartCardUtils.detectBrand('401178'), SmartCardBrand.elo);
      expect(SmartCardUtils.detectBrand('402918'), SmartCardBrand.naranja);
      expect(SmartCardUtils.detectBrand('34'), SmartCardBrand.amex);
      expect(SmartCardUtils.detectBrand('37'), SmartCardBrand.amex);
      expect(SmartCardUtils.detectBrand('51'), SmartCardBrand.mastercard);
      expect(SmartCardUtils.detectBrand('2221'), SmartCardBrand.mastercard);
      expect(SmartCardUtils.detectBrand('2720'), SmartCardBrand.mastercard);
      expect(SmartCardUtils.detectBrand('2200'), SmartCardBrand.mir);
      expect(SmartCardUtils.detectBrand('6011'), SmartCardBrand.discover);
      expect(SmartCardUtils.detectBrand('650052'), SmartCardBrand.troy);
      expect(SmartCardUtils.detectBrand('650031'), SmartCardBrand.elo);
      expect(SmartCardUtils.detectBrand('6500520'), SmartCardBrand.troy);
      expect(SmartCardUtils.detectBrand('506099'), SmartCardBrand.verve);
      expect(SmartCardUtils.detectBrand('506699'), SmartCardBrand.elo);
      expect(SmartCardUtils.detectBrand('504175'), SmartCardBrand.elo);
      expect(SmartCardUtils.detectBrand('504176'), SmartCardBrand.maestro);
      expect(SmartCardUtils.detectBrand('606282'), SmartCardBrand.hipercard);
      expect(SmartCardUtils.detectBrand('637095'), SmartCardBrand.hiper);
      expect(SmartCardUtils.detectBrand('3095'), SmartCardBrand.unknown);
    });

    test('Mastercard 2-series boundaries', () {
      expect(SmartCardUtils.detectBrand('2220 0000'), SmartCardBrand.unknown);
      expect(
        SmartCardUtils.detectBrand('2221 0000'),
        SmartCardBrand.mastercard,
      );
      expect(
        SmartCardUtils.detectBrand('2720 9900'),
        SmartCardBrand.mastercard,
      );
      expect(SmartCardUtils.detectBrand('2721 0000'), SmartCardBrand.unknown);
    });

    test('network co-branding is resolved by the verified table', () {
      expect(SmartCardUtils.detectBrand('622126'), SmartCardBrand.unionPay);
      expect(SmartCardUtils.detectBrand('622925'), SmartCardBrand.unionPay);
    });

    test('unknown brands get generic documented limits', () {
      expect(SmartCardUtils.detectBrand('9999 9999'), SmartCardBrand.unknown);
      final number = _complete('9999', 16);
      expect(
        SmartCardUtils.assessNumber(number).status,
        SmartCardNumberStatus.valid,
      );
      expect(
        SmartCardUtils.assessNumber(_complete('9999', 12)).status,
        SmartCardNumberStatus.valid,
      );
      expect(
        SmartCardUtils.assessNumber(_complete('9999', 19)).status,
        SmartCardNumberStatus.valid,
      );
      expect(
        SmartCardUtils.assessNumber('99999999999').status,
        SmartCardNumberStatus.incomplete,
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
    });

    test('accepted brands restrict, including unknown cards', () {
      const onlyVisa = {SmartCardBrand.visa};
      final mc = _complete('51', 16);
      final assessment = SmartCardUtils.assessNumber(
        mc,
        acceptedBrands: onlyVisa,
      );
      expect(assessment.issue, SmartCardNumberIssue.brandNotAccepted);
      expect(
        SmartCardUtils.assessNumber('5555', acceptedBrands: onlyVisa).status,
        SmartCardNumberStatus.invalid,
      );
      expect(
        SmartCardUtils.assessNumber('4', acceptedBrands: onlyVisa).status,
        SmartCardNumberStatus.incomplete,
      );
      expect(
        SmartCardUtils.assessNumber(
          _complete('9999', 16),
          acceptedBrands: onlyVisa,
        ).issue,
        SmartCardNumberIssue.brandNotAccepted,
      );
      expect(
        SmartCardUtils.assessNumber(
          _complete('4', 16),
          acceptedBrands: onlyVisa,
        ).status,
        SmartCardNumberStatus.valid,
      );
    });
  });

  group('instant local Luhn assessment', () {
    test('empty, incomplete with guidance, valid, and invalid', () {
      expect(
        SmartCardUtils.assessNumber('').status,
        SmartCardNumberStatus.empty,
      );
      final partial = SmartCardUtils.assessNumber('4111 1111');
      expect(partial.status, SmartCardNumberStatus.incomplete);
      expect(partial.issue, SmartCardNumberIssue.none);
      expect(partial.remainingDigits, 8);
      expect(
        SmartCardUtils.assessNumber('4111 1111 1111 1111').status,
        SmartCardNumberStatus.valid,
      );
      final bad = SmartCardUtils.assessNumber('4111 1111 1111 1112');
      expect(bad.status, SmartCardNumberStatus.invalid);
      expect(bad.issue, SmartCardNumberIssue.failsChecksum);
      expect(
        SmartCardUtils.assessNumber('4111x').issue,
        SmartCardNumberIssue.invalidCharacters,
      );
    });

    test('every single-digit change breaks a valid Visa and Amex number', () {
      for (final number in [
        _complete('4111', 16),
        _complete('37', 15),
        _complete('5555', 16),
      ]) {
        for (var index = 0; index < number.length; index++) {
          for (var digit = 0; digit < 10; digit++) {
            if (digit.toString() == number[index]) {
              continue;
            }
            final changed = number.replaceRange(index, index + 1, '$digit');
            final brand = SmartCardUtils.detectBrand(changed);
            if (brand != SmartCardUtils.detectBrand(number)) {
              continue;
            }
            expect(
              SmartCardUtils.passesLuhn(changed),
              isFalse,
              reason: '$index $digit',
            );
            expect(SmartValidators.cardNumber()(changed), isNotNull);
          }
        }
      }
    });

    test(
      'multi-length brands only flag failures at the primary or maximum length',
      () {
        final failing16 =
            _complete('4111', 16).replaceRange(15, 16, '0') ==
                _complete('4111', 16)
            ? _complete('4111', 16).replaceRange(15, 16, '1')
            : _complete('4111', 16).replaceRange(15, 16, '0');
        expect(
          SmartCardUtils.assessNumber(failing16).status,
          SmartCardNumberStatus.invalid,
        );
        final maestro13 = _complete('6759', 13);
        final bad13 = maestro13.replaceRange(
          12,
          13,
          maestro13[12] == '0' ? '1' : '0',
        );
        expect(
          SmartCardUtils.assessNumber(bad13).status,
          SmartCardNumberStatus.incomplete,
        );
        expect(SmartValidators.cardNumber()(bad13), isNotNull);
      },
    );

    test('Luhn can be disabled or exempted per brand', () {
      final bad =
          _complete('620', 16).replaceRange(15, 16, '1') == _complete('620', 16)
          ? _complete('620', 16).replaceRange(15, 16, '2')
          : _complete('620', 16).replaceRange(15, 16, '1');
      expect(SmartCardUtils.passesLuhn(bad), isFalse);
      expect(
        SmartCardUtils.assessNumber(bad).status,
        SmartCardNumberStatus.valid,
      );
      expect(SmartValidators.cardNumber()(bad), isNull);
      expect(
        SmartCardUtils.assessNumber(bad, luhnExemptBrands: const {}).status,
        SmartCardNumberStatus.invalid,
      );
      expect(
        SmartValidators.cardNumber(luhnExemptBrands: const {})(bad),
        isNotNull,
      );
      expect(
        SmartCardUtils.assessNumber(bad, validateLuhn: false).status,
        SmartCardNumberStatus.valid,
      );
    });

    test(
      'UnionPay skips Luhn by default; every other brand still needs it',
      () {
        for (final item in _cases) {
          final brand = item.brand;
          if (brand == SmartCardBrand.unionPay) {
            continue;
          }
          final prefix = item.prefixes.first;
          final length = brand.primaryLength;
          final good = _complete(prefix, length);
          final last = int.parse(good[length - 1]);
          final bad = '${good.substring(0, length - 1)}${(last + 1) % 10}';
          expect(SmartCardUtils.passesLuhn(bad), isFalse, reason: brand.name);
          expect(
            SmartCardUtils.assessNumber(bad).status,
            isNot(SmartCardNumberStatus.valid),
            reason: brand.name,
          );
        }
        expect(
          SmartCardUtils.assessNumber(_complete('620', 16)).status,
          SmartCardNumberStatus.valid,
        );
      },
    );

    test('assessment is pure, fast, and printable without digits', () {
      final watch = Stopwatch()..start();
      for (var i = 0; i < 5000; i++) {
        SmartCardUtils.assessNumber('4111 1111 1111 1111');
      }
      watch.stop();
      expect(watch.elapsedMilliseconds, lessThan(2000));
      expect(
        SmartCardUtils.assessNumber('4111 1111 1111 1111').toString(),
        isNot(contains('4111')),
      );
    });
  });

  group('grouping', () {
    test('brand-specific grouping from verified gaps', () {
      expect(
        SmartCardUtils.format(_complete('4', 16)),
        matches(RegExp(r'^\d{4} \d{4} \d{4} \d{4}$')),
      );
      expect(
        SmartCardUtils.format(_complete('37', 15)),
        matches(RegExp(r'^\d{4} \d{6} \d{5}$')),
      );
      expect(
        SmartCardUtils.format(_complete('36', 14)),
        matches(RegExp(r'^\d{4} \d{6} \d{4}$')),
      );
      expect(
        SmartCardUtils.format(_complete('36', 16)),
        matches(RegExp(r'^\d{4} \d{6} \d{6}$')),
      );
      expect(
        SmartCardUtils.format(_complete('4', 19)),
        matches(RegExp(r'^\d{4} \d{4} \d{4} \d{4} \d{3}$')),
      );
      expect(
        SmartCardUtils.format(_complete('2200', 19)),
        matches(RegExp(r'^\d{4} \d{4} \d{4} \d{4} \d{3}$')),
      );
      expect(SmartCardUtils.format('3782'), '3782');
      expect(SmartCardUtils.format('37828'), '3782 8');
      expect(SmartCardUtils.format('1234567890123456'), '1234 5678 9012 3456');
    });

    test('format never changes digits', () {
      for (final item in _cases) {
        final number = _complete(item.prefixes.first, item.brand.primaryLength);
        expect(
          SmartCardUtils.digitsOnly(SmartCardUtils.format(number)),
          number,
        );
      }
    });
  });

  group('number formatter editing', () {
    const formatter = SmartCardNumberFormatter();
    TextEditingValue edit(
      String oldText,
      String newText, {
      int? caret,
      int? base,
    }) {
      return formatter.formatEditUpdate(
        TextEditingValue(
          text: oldText,
          selection: TextSelection.collapsed(offset: oldText.length),
        ),
        TextEditingValue(
          text: newText,
          selection: base == null
              ? TextSelection.collapsed(offset: caret ?? newText.length)
              : TextSelection(
                  baseOffset: base,
                  extentOffset: caret ?? newText.length,
                ),
        ),
      );
    }

    test('typing from start to finish', () {
      final number = _complete('4111', 16);
      var text = '';
      for (var index = 0; index < number.length; index++) {
        text = edit(text, text + number[index]).text;
      }
      expect(text, SmartCardUtils.format(number));
      expect(SmartCardUtils.digitsOnly(text), number);
    });

    test('brand change while typing regroups', () {
      var text = edit('', '3').text;
      expect(text, '3');
      text = edit(text, '37').text;
      text = edit(text, '378').text;
      text = edit(text, '3782').text;
      text = edit(text, '37828').text;
      expect(text, '3782 8');
      text = edit(text, '3782 82').text;
      for (final digit in '246310005'.split('')) {
        text = edit(text, text + digit).text;
      }
      expect(text, '3782 822463 10005');
      final dinersFirst = edit('', '36').text;
      expect(dinersFirst, '36');
    });

    test('delete the middle digit and replace a selection', () {
      final deleted = edit(
        '4111 1111 1111 1111',
        '4111 111 1111 1111',
        caret: 7,
      );
      expect(SmartCardUtils.digitsOnly(deleted.text), '411111111111111');
      expect(deleted.selection.baseOffset, 7);
      final replaced = edit(
        '4111 1111 1111 1111',
        '4111 9 1111 1111',
        caret: 6,
        base: 5,
      );
      expect(SmartCardUtils.digitsOnly(replaced.text), '4111911111111');
    });

    test('paste with spaces, dashes, and mixed separators', () {
      final number = _complete('5555', 16);
      expect(SmartCardUtils.digitsOnly(edit('', number).text), number);
      expect(edit('', '4111-1111-1111-1111').text, '4111 1111 1111 1111');
      expect(edit('', '4111 1111-1111 1111').text, '4111 1111 1111 1111');
      expect(edit('4', '4abc').text, '4');
      expect(edit('4', '4_').text, '4');
      expect(edit('', '4111\n1111').text, '');
    });

    test('backspace across a formatting space and caret position', () {
      final across = edit('4111 1', '41111', caret: 4);
      expect(across.text.replaceAll(' ', ''), '4111');
      final middle = edit('4111 1111', '41911 1111', caret: 3);
      expect(middle.selection.baseOffset, 3);
      expect(
        middle.text.replaceAll(' ', ''),
        '419111111'.padRight(9, '1').substring(0, 9),
      );
    });
  });

  group('expiry boundaries', () {
    final validator = SmartValidators.cardExpiry(now: _now);
    test('months 01 to 12 valid, 00 and 13 invalid, incomplete invalid', () {
      for (var month = 1; month <= 12; month++) {
        final text = '${month.toString().padLeft(2, '0')}/30';
        expect(validator(text), isNull, reason: text);
      }
      expect(validator('00/30'), 'Enter a valid expiry date.');
      expect(validator('13/30'), 'Enter a valid expiry date.');
      expect(validator('1/30'), 'Enter a valid expiry date.');
      expect(validator('12/3'), 'Enter a valid expiry date.');
      expect(validator('1230'), 'Enter a valid expiry date.');
      expect(validator('ab/cd'), 'Enter a valid expiry date.');
    });

    test('current month is valid through its last moment', () {
      final expiry = SmartCardUtils.tryParseExpiry('06/24')!;
      expect(expiry.isExpired(DateTime(2024, 6, 1)), isFalse);
      expect(expiry.isExpired(DateTime(2024, 6, 30, 23, 59, 59, 999)), isFalse);
      expect(expiry.isExpired(DateTime(2024, 7, 1)), isTrue);
      expect(
        SmartValidators.cardExpiry(now: () => DateTime(2024, 6, 30, 23, 59))(
          '06/24',
        ),
        isNull,
      );
      expect(
        SmartValidators.cardExpiry(now: () => DateTime(2024, 7, 1))('06/24'),
        'This card has expired.',
      );
    });

    test('December to January year change and February', () {
      final december = SmartCardUtils.tryParseExpiry('12/24')!;
      expect(december.isExpired(DateTime(2024, 12, 31, 23, 59, 59)), isFalse);
      expect(december.isExpired(DateTime(2025, 1, 1)), isTrue);
      final february = SmartCardUtils.tryParseExpiry('02/24')!;
      expect(february.isExpired(DateTime(2024, 2, 29, 23, 59)), isFalse);
      expect(february.isExpired(DateTime(2024, 3, 1)), isTrue);
      expect(
        SmartCardUtils.tryParseExpiry('02/23')!
            .isExpired(DateTime(2023, 2, 28, 23, 59)),
        isFalse,
      );
    });

    test('MM/YYYY and two-digit year interpretation', () {
      expect(SmartCardUtils.tryParseExpiry('06/24')!.year, 2024);
      expect(SmartCardUtils.tryParseExpiry('06/99')!.year, 2099);
      expect(SmartCardUtils.tryParseExpiry('06/00')!.year, 2000);
      final long = SmartValidators.cardExpiry(
        format: SmartExpiryFormat.mmYyyy,
        now: _now,
      );
      expect(long('06/2024'), isNull);
      expect(long('05/2024'), 'This card has expired.');
      expect(long('06/24'), 'Enter a valid expiry date.');
    });
  });

  group('CVV validation', () {
    test('lengths per brand switch with the brand', () {
      var brand = SmartCardBrand.visa;
      final validator = SmartValidators.cardCvv(brand: () => brand);
      for (final entry in {
        '': null,
        '1': 'x',
        '12': 'x',
        '123': null,
        '1234': 'x',
        '12345': 'x',
        'abc': 'x',
        '12a': 'x',
      }.entries) {
        expect(
          validator(entry.key) == null,
          entry.value == null,
          reason: entry.key,
        );
      }
      brand = SmartCardBrand.amex;
      expect(validator('123'), isNotNull);
      expect(validator('1234'), isNull);
      brand = SmartCardBrand.unknown;
      expect(validator('123'), isNull);
      expect(validator('1234'), isNull);
      expect(validator('12'), isNotNull);
    });

    test('developer policy overrides brand rules', () {
      final validator = SmartValidators.cardCvv(
        brand: () => SmartCardBrand.visa,
        allowedLengths: {4},
        message: 'four only',
      );
      expect(validator('123'), 'four only');
      expect(validator('1234'), isNull);
    });
  });

  group('SmartField.creditCard instant validation', () {
    testWidgets(
      'typing shows neutral guidance, then valid or invalid immediately',
      (tester) async {
        final number = TextEditingController();
        addTearDown(number.dispose);
        await tester.pumpWidget(
          _app(SmartField.creditCard(now: _now, numberController: number)),
        );
        await tester.enterText(find.byType(TextFormField).at(0), '4111 1111');
        await tester.pump();
        expect(find.text('Visa · 8 more digits'), findsOneWidget);
        expect(find.text('Check the card number.'), findsNothing);
        await tester.enterText(
          find.byType(TextFormField).at(0),
          '4111 1111 1111 1112',
        );
        await tester.pump();
        expect(find.text('Check the card number.'), findsOneWidget);
        expect(find.textContaining('format looks valid'), findsNothing);
        await tester.enterText(
          find.byType(TextFormField).at(0),
          '4111 1111 1111 1111',
        );
        await tester.pump();
        expect(find.text('Check the card number.'), findsNothing);
        expect(find.text('Visa · Number format looks valid'), findsOneWidget);
        await tester.enterText(
          find.byType(TextFormField).at(0),
          '4111 1111 1111 111',
        );
        await tester.pump();
        expect(find.text('Visa · Number format looks valid'), findsNothing);
        expect(find.text('Visa · 1 more digit'), findsOneWidget);
      },
    );

    testWidgets('programmatic changes, clear, and reset update the state', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final number = TextEditingController();
      final values = <SmartCreditCardValue>[];
      addTearDown(number.dispose);
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.creditCard(
              now: _now,
              numberController: number,
              onChanged: values.add,
            ),
          ),
        ),
      );
      number.text = '4111 1111 1111 1111';
      await tester.pump();
      expect(find.textContaining('format looks valid'), findsOneWidget);
      expect(values.last.numberStatus, SmartCardNumberStatus.valid);
      number.text = '4111 1111 1111 1112';
      await tester.pump();
      expect(find.text('Check the card number.'), findsOneWidget);
      expect(values.last.numberStatus, SmartCardNumberStatus.invalid);
      number.clear();
      await tester.pump();
      expect(find.text('Check the card number.'), findsNothing);
      expect(values.last.numberStatus, SmartCardNumberStatus.empty);
      number.text = '4111 1111 1111 1112';
      await tester.pump();
      formKey.currentState!.reset();
      await tester.pump();
      expect(number.text, isEmpty);
      expect(find.text('Check the card number.'), findsNothing);
    });

    testWidgets('callbacks are not duplicated per change', (tester) async {
      final values = <SmartCreditCardValue>[];
      await tester.pumpWidget(
        _app(SmartField.creditCard(now: _now, onChanged: values.add)),
      );
      await tester.enterText(find.byType(TextFormField).at(0), '4');
      await tester.enterText(find.byType(TextFormField).at(0), '41');
      expect(values.length, 2);
    });

    testWidgets('paste works and brand restrictions apply immediately', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SmartField.creditCard(
            now: _now,
            acceptedBrands: const {SmartCardBrand.visa},
          ),
        ),
      );
      await tester.enterText(
        find.byType(TextFormField).at(0),
        '5555-5555-5555-4444',
      );
      await tester.pump();
      expect(_fieldText(tester, 0), '5555 5555 5555 4444');
      expect(find.text('This card type is not accepted.'), findsOneWidget);
    });

    testWidgets('developer overrides: status builder, texts, exemptions', (
      tester,
    ) async {
      final bad =
          _complete('620', 16).replaceRange(15, 16, '7') == _complete('620', 16)
          ? _complete('620', 16).replaceRange(15, 16, '8')
          : _complete('620', 16).replaceRange(15, 16, '7');
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              SmartField.creditCard(
                now: _now,
                luhnErrorText: 'Digits look wrong',
                numberStatusBuilder: (a) =>
                    a.isLocallyValid ? 'Looks fine' : null,
              ),
              SmartField.creditCard(
                now: _now,
                luhnExemptBrands: const {SmartCardBrand.unionPay},
              ),
            ],
          ),
        ),
      );
      await tester.enterText(
        find.byType(TextFormField).at(0),
        '4111111111111111',
      );
      await tester.pump();
      expect(find.text('Looks fine'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        '4111111111111112',
      );
      await tester.pump();
      expect(find.text('Digits look wrong'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(3), bad);
      await tester.pump();
      expect(find.text('Check the card number.'), findsNothing);
    });

    testWidgets('server errors take priority and clear on edit', (
      tester,
    ) async {
      final server = SmartServerError();
      addTearDown(server.dispose);
      await tester.pumpWidget(
        _app(SmartField.creditCard(now: _now, numberServerError: server)),
      );
      await tester.enterText(
        find.byType(TextFormField).at(0),
        '4111111111111112',
      );
      await tester.pump();
      server.set('Payment declined');
      await tester.pump();
      expect(find.text('Payment declined'), findsOneWidget);
      expect(find.text('Check the card number.'), findsNothing);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        '4111111111111111',
      );
      await tester.pump();
      expect(find.text('Payment declined'), findsNothing);
      expect(server.hasError, isFalse);
    });

    testWidgets('switching brand after entering a CVV revalidates it', (
      tester,
    ) async {
      final cvv = TextEditingController();
      addTearDown(cvv.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.creditCard(
            now: _now,
            cvvController: cvv,
            autoAdvance: false,
          ),
        ),
      );
      await tester.enterText(
        find.byType(TextFormField).at(0),
        '4111111111111111',
      );
      await tester.enterText(find.byType(TextFormField).at(2), '123');
      await tester.pump();
      expect(find.text('Enter the 4-digit security code.'), findsNothing);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        '378282246310005',
      );
      await tester.pump();
      expect(find.text('Enter the 4-digit security code.'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        '4111111111111111',
      );
      await tester.pump();
      expect(find.text('Enter the 4-digit security code.'), findsNothing);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        '378282246310005',
      );
      await tester.enterText(find.byType(TextFormField).at(2), '1234');
      await tester.pump();
      expect(find.text('Enter the 4-digit security code.'), findsNothing);
    });

    testWidgets('multiple card fields stay independent', (tester) async {
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
      await tester.enterText(
        find.byType(TextFormField).at(0),
        '4111111111111112',
      );
      await tester.enterText(
        find.byType(TextFormField).at(3),
        '378282246310005',
      );
      await tester.pump();
      expect(find.text('Check the card number.'), findsOneWidget);
      expect(find.text('American Express'), findsWidgets);
      expect(_fieldText(tester, 0), '4111 1111 1111 1112');
      expect(_fieldText(tester, 3), '3782 822463 10005');
    });

    testWidgets('light and dark themes, RTL, large text, narrow width', (
      tester,
    ) async {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        await tester.pumpWidget(
          _app(
            SmartField.creditCard(now: _now),
            theme: ThemeData(brightness: brightness),
            direction: TextDirection.rtl,
            scale: 2,
            size: const Size(260, 900),
          ),
        );
        await tester.enterText(
          find.byType(TextFormField).at(0),
          '4111111111111112',
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('keyboard traversal and accessibility labels', (tester) async {
      final handle = tester.ensureSemantics();
      final focus = [FocusNode(), FocusNode(), FocusNode()];
      for (final node in focus) {
        addTearDown(node.dispose);
      }
      await tester.pumpWidget(
        _app(
          SmartField.creditCard(
            now: _now,
            autoAdvance: false,
            numberFocusNode: focus[0],
            expiryFocusNode: focus[1],
            cvvFocusNode: focus[2],
          ),
        ),
      );
      focus[0].requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focus[1].hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focus[2].hasFocus, isTrue);
      expect(find.bySemanticsLabel(RegExp('Card number')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Expiry')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Security code')), findsWidgets);
      handle.dispose();
    });
  });

  group('sensitive data and network', () {
    testWidgets('digits never appear in diagnostics, toString, or logs', (
      tester,
    ) async {
      final printed = <String>[];
      final original = debugPrint;
      debugPrint = (message, {wrapWidth}) => printed.add(message ?? '');
      SmartCreditCardValue? value;
      await tester.pumpWidget(
        _app(SmartField.creditCard(now: _now, onChanged: (v) => value = v)),
      );
      await tester.enterText(
        find.byType(TextFormField).at(0),
        '4111111111111111',
      );
      await tester.enterText(find.byType(TextFormField).at(1), '1229');
      await tester.enterText(find.byType(TextFormField).at(2), '987');
      await tester.pump();
      final dump = tester.binding.rootElement!.toStringDeep();
      debugPrint = original;
      expect(dump, isNot(contains('4111111111111111')));
      expect(dump, isNot(contains('4111 1111 1111 1111')));
      expect(dump, isNot(contains('TextEditingValue(text')));
      expect(RegExp(r'┤987├|text: 987').hasMatch(dump), isFalse);
      expect(printed.join(), isNot(contains('4111')));
      expect(value.toString(), isNot(contains('4111')));
      expect(value.toString(), isNot(contains('987')));
      expect(value.toString(), isNot(contains('1229')));
      expect(
        tester.widget<TextField>(find.byType(TextField).at(2)).obscureText,
        isTrue,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).at(2)).restorationId,
        isNull,
      );
    });

    testWidgets('card data is not restored after the screen is recreated', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          restorationScopeId: 'app',
          home: Scaffold(body: SmartField.creditCard(now: _now)),
        ),
      );
      await tester.enterText(
        find.byType(TextFormField).at(0),
        '4111111111111111',
      );
      await tester.enterText(find.byType(TextFormField).at(2), '123');
      await tester.pump();
      await tester.restartAndRestore();
      expect(_fieldText(tester, 0), isEmpty);
      expect(_fieldText(tester, 2), isEmpty);
    });

    testWidgets('no network connection is attempted during validation', (
      tester,
    ) async {
      final overrides = _TrackingHttpOverrides();
      await HttpOverrides.runZoned(() async {
        await tester.pumpWidget(_app(SmartField.creditCard(now: _now)));
        for (final text in [
          '4',
          '4111',
          '4111111111111111',
          '4111111111111112',
        ]) {
          await tester.enterText(find.byType(TextFormField).at(0), text);
          await tester.pump();
        }
        await tester.enterText(find.byType(TextFormField).at(1), '1229');
        await tester.enterText(find.byType(TextFormField).at(2), '123');
        await tester.pump(const Duration(seconds: 2));
      }, createHttpClient: overrides.create);
      expect(overrides.created, 0);
    });

    test(
      'source contains no network, logging, or storage code for cards',
      skip: kIsWeb,
      () {
        for (final path in [
          'lib/src/widgets/smart_credit_card_field.dart',
          'lib/src/formatting/smart_card_utils.dart',
        ]) {
          final source = File(path).readAsStringSync();
          for (final banned in [
            'dart:io',
            'package:http',
            'HttpClient',
            'print(',
            'debugPrint',
            'developer.log',
            'SharedPreferences',
            'restorationId',
          ]) {
            expect(
              source.contains(banned),
              isFalse,
              reason: '$path contains $banned',
            );
          }
        }
      },
    );
  });
}

class _TrackingHttpOverrides {
  int created = 0;

  HttpClient create(SecurityContext? context) {
    created++;
    throw StateError('network access attempted');
  }
}
