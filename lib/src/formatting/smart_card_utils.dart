import 'package:flutter/services.dart';
import 'package:smart_field_kit/src/formatting/smart_date_utils.dart';
import 'package:smart_field_kit/src/formatting/smart_composing.dart';

enum SmartCardBrand {
  visa('Visa', {16, 18, 19}, 3, 16, [4, 8, 12]),
  mastercard('Mastercard', {16}, 3, 16, [4, 8, 12]),
  amex('American Express', {15}, 4, 15, [4, 10]),
  dinersClub('Diners Club', {14, 16, 19}, 3, 14, [4, 10]),
  discover('Discover', {16, 17, 18, 19}, 3, 16, [4, 8, 12]),
  jcb('JCB', {16, 17, 18, 19}, 3, 16, [4, 8, 12]),
  unionPay('UnionPay', {14, 15, 16, 17, 18, 19}, 3, 16, [4, 8, 12]),
  maestro('Maestro', {12, 13, 14, 15, 16, 17, 18, 19}, 3, 16, [4, 8, 12]),
  troy('Troy', {16}, 3, 16, [4, 8, 12]),
  elo('Elo', {16}, 3, 16, [4, 8, 12]),
  mir('Mir', {16, 17, 18, 19}, 3, 16, [4, 8, 12]),
  hiper('Hiper', {16}, 3, 16, [4, 8, 12]),
  hipercard('Hipercard', {16}, 3, 16, [4, 8, 12]),
  naranja('Naranja', {16}, 3, 16, [4, 8, 12]),
  verve('Verve', {16, 18, 19}, 3, 16, [4, 8, 12]),
  unknown('Card', {12, 13, 14, 15, 16, 17, 18, 19}, 3, 16, [4, 8, 12]);

  const SmartCardBrand(
    this.displayName,
    this.lengths,
    this.cvvLength,
    this.primaryLength,
    this.gaps,
  );

  final String displayName;
  final Set<int> lengths;
  final int cvvLength;
  final int primaryLength;
  final List<int> gaps;

  int get maxLength => lengths.reduce((a, b) => a > b ? a : b);

  int get minLength => lengths.reduce((a, b) => a < b ? a : b);
}

enum SmartExpiryFormat { mmYy, mmYyyy }

enum SmartCardNumberStatus { empty, incomplete, valid, invalid }

enum SmartCardNumberIssue {
  none,
  invalidCharacters,
  brandNotAccepted,
  wrongLength,
  failsChecksum,
}

final class SmartCardBrandMatch {
  const SmartCardBrandMatch({
    required this.brand,
    required this.likelyBrand,
    required this.candidates,
  });

  final SmartCardBrand brand;
  final SmartCardBrand? likelyBrand;
  final List<SmartCardBrand> candidates;

  bool get isCertain => brand != SmartCardBrand.unknown;
}

final class SmartCardNumberAssessment {
  const SmartCardNumberAssessment({
    required this.status,
    required this.issue,
    required this.match,
    required this.digitCount,
    required this.remainingDigits,
  });

  final SmartCardNumberStatus status;
  final SmartCardNumberIssue issue;
  final SmartCardBrandMatch match;
  final int digitCount;
  final int? remainingDigits;

  SmartCardBrand get brand => match.brand;

  bool get isLocallyValid => status == SmartCardNumberStatus.valid;

  @override
  String toString() {
    return 'SmartCardNumberAssessment(status: ${status.name}, '
        'issue: ${issue.name}, brand: ${brand.name}, digits: $digitCount)';
  }
}

final class _Pattern {
  const _Pattern(this.low, this.high, this.length);

  final int low;
  final int high;
  final int length;
}

_Pattern _p(int value) => _Pattern(value, value, value.toString().length);

_Pattern _r(int low, int high) => _Pattern(low, high, low.toString().length);

final Map<SmartCardBrand, List<_Pattern>> _brandPatterns = {
  SmartCardBrand.visa: [_p(4)],
  SmartCardBrand.mastercard: [
    _r(51, 55),
    _r(2221, 2229),
    _r(223, 229),
    _r(23, 26),
    _r(270, 271),
    _p(2720),
  ],
  SmartCardBrand.amex: [_p(34), _p(37)],
  SmartCardBrand.dinersClub: [_r(300, 305), _p(36), _p(38), _p(39)],
  SmartCardBrand.troy: [
    _p(9792),
    _p(650052),
    _r(650082, 650083),
    _p(650092),
    _p(650161),
    _p(650170),
    _p(650173),
    _p(650175),
    _p(650268),
    _p(650271),
    _r(650273, 650274),
    _r(650456, 650457),
    _p(650836),
    _r(650846, 650850),
    _p(650923),
    _p(650987),
    _p(650990),
    _p(654997),
    _p(657366),
    _p(657998),
    _p(658758),
    _r(658767, 658768),
    _r(65083700, 65083704),
    _r(65085800, 65085804),
    _r(65085900, 65085901),
    _p(65086000),
    _r(65086100, 65086105),
    _r(65086200, 65086203),
    _r(65875000, 65875003),
    _p(65875009),
    _r(65875101, 65875104),
    _p(65875200),
    _p(65875501),
    _p(65875601),
    _p(65875900),
    _r(65876000, 65876002),
    _r(65876100, 65876103),
    _p(65876110),
    _r(65876115, 65876116),
    _r(65876200, 65876201),
    _p(65876500),
    _r(65876504, 65876505),
    _r(65876600, 65876602),
    _r(65877100, 65877101),
    _r(65877600, 65877602),
    _p(65877700),
    _r(65877801, 65877802),
    _r(65878200, 65878202),
    _r(65878300, 65878311),
    _r(65878400, 65878405),
    _r(65878500, 65878505),
    _r(65878600, 65878601),
    _p(65879800),
    _p(65880800),
    _p(65880900),
  ],
  SmartCardBrand.discover: [_p(6011), _r(644, 649), _p(65)],
  SmartCardBrand.jcb: [_p(2131), _p(1800), _r(3528, 3589)],
  SmartCardBrand.unionPay: [
    _p(620),
    _r(62100, 62182),
    _r(62184, 62187),
    _r(62185, 62197),
    _r(62200, 62205),
    _r(622010, 622999),
    _p(622018),
    _r(62207, 62209),
    _r(623, 626),
    _p(6270),
    _p(6272),
    _p(6276),
    _r(627700, 627779),
    _r(627781, 627799),
    _r(6282, 6289),
    _p(6291),
    _p(6292),
    _p(810),
    _r(8110, 8131),
    _r(8132, 8151),
    _r(8152, 8163),
    _r(8164, 8171),
  ],
  SmartCardBrand.maestro: [
    _p(493698),
    _r(500000, 504174),
    _r(504176, 506698),
    _r(506779, 508999),
    _r(56, 59),
    _p(63),
    _p(67),
    _p(6),
  ],
  SmartCardBrand.elo: [
    _p(401178),
    _p(401179),
    _p(438935),
    _p(457631),
    _p(457632),
    _p(431274),
    _p(451416),
    _p(457393),
    _p(504175),
    _r(506699, 506778),
    _r(509000, 509999),
    _p(627780),
    _p(636297),
    _p(636368),
    _r(650031, 650033),
    _r(650035, 650051),
    _r(650057, 650081),
    _r(650405, 650439),
    _r(650485, 650538),
    _r(650541, 650598),
    _r(650700, 650718),
    _r(650720, 650727),
    _r(650901, 650978),
    _r(651652, 651679),
    _r(651680, 651704),
    _r(655000, 655019),
    _r(655021, 655058),
  ],
  SmartCardBrand.mir: [_r(2200, 2204)],
  SmartCardBrand.hiper: [
    _p(637095),
    _p(63737423),
    _p(63743358),
    _p(637568),
    _p(637599),
    _p(637609),
    _p(637612),
  ],
  SmartCardBrand.hipercard: [_p(606282)],
  SmartCardBrand.naranja: [_p(589562), _p(402918), _p(527572)],
  SmartCardBrand.verve: [
    _r(506099, 506127),
    _p(506129),
    _r(506133, 506150),
    _r(506158, 506163),
    _p(506166),
    _p(506168),
    _p(506170),
    _p(506173),
    _r(506176, 506180),
    _p(506184),
    _r(506187, 506188),
    _p(506191),
    _p(506195),
    _p(506197),
    _p(507865),
    _p(507866),
    _r(507868, 507877),
    _r(507880, 507888),
    _p(507900),
    _p(507941),
  ],
};

const List<int> _powersOfTen = [
  1,
  10,
  100,
  1000,
  10000,
  100000,
  1000000,
  10000000,
  100000000,
];

final class SmartCardExpiry {
  const SmartCardExpiry(this.month, this.year);

  final int month;
  final int year;

  bool isExpired(DateTime now) {
    final lastDay = SmartDateUtils.daysInMonth(year, month);
    final end = DateTime(year, month, lastDay, 23, 59, 59, 999);
    return now.isAfter(end);
  }
}

abstract final class SmartCardUtils {
  static const int maxCardDigits = 19;

  static final RegExp _nonDigit = RegExp(r'\D');

  static String digitsOnly(String value) => value.replaceAll(_nonDigit, '');

  static SmartCardBrandMatch matchBrand(String value) {
    final digits = digitsOnly(value);
    if (digits.isEmpty) {
      return const SmartCardBrandMatch(
        brand: SmartCardBrand.unknown,
        likelyBrand: null,
        candidates: [],
      );
    }
    final strength = <SmartCardBrand, int>{};
    final partial = <SmartCardBrand>{};
    final typed = digits.length > 8 ? digits.substring(0, 8) : digits;
    for (final entry in _brandPatterns.entries) {
      for (final pattern in entry.value) {
        if (typed.length >= pattern.length) {
          final prefix = int.parse(typed.substring(0, pattern.length));
          if (prefix >= pattern.low && prefix <= pattern.high) {
            final score =
                pattern.length * 1000000000 - (pattern.high - pattern.low);
            final current = strength[entry.key] ?? 0;
            if (score > current) {
              strength[entry.key] = score;
            }
          }
        } else {
          final scale = _powersOfTen[pattern.length - typed.length];
          final low = int.parse(typed) * scale;
          final high = low + scale - 1;
          if (low <= pattern.high && high >= pattern.low) {
            partial.add(entry.key);
          }
        }
      }
    }
    final best = strength.values.isEmpty
        ? 0
        : strength.values.reduce((a, b) => a > b ? a : b);
    final strongest = [
      for (final entry in strength.entries)
        if (entry.value == best) entry.key,
    ];
    final likely = strongest.length == 1 ? strongest.single : null;
    final ordered = <SmartCardBrand>[
      ...(strength.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
          .map((entry) => entry.key),
      ...partial.where((brand) => !strength.containsKey(brand)),
    ];
    final others = partial.where((brand) => brand != likely);
    final certain = likely != null && others.isEmpty;
    return SmartCardBrandMatch(
      brand: certain ? likely : SmartCardBrand.unknown,
      likelyBrand: likely,
      candidates: ordered,
    );
  }

  static SmartCardBrand detectBrand(String value) => matchBrand(value).brand;

  static SmartCardNumberAssessment assessNumber(
    String value, {
    Set<SmartCardBrand>? acceptedBrands,
    bool validateLuhn = true,
    Set<SmartCardBrand> luhnExemptBrands = const {SmartCardBrand.unionPay},
  }) {
    final match = matchBrand(value);
    SmartCardNumberAssessment result(
      SmartCardNumberStatus status, {
      SmartCardNumberIssue issue = SmartCardNumberIssue.none,
      int? remaining,
      int digits = 0,
    }) {
      return SmartCardNumberAssessment(
        status: status,
        issue: issue,
        match: match,
        digitCount: digits,
        remainingDigits: remaining,
      );
    }

    if (value.isEmpty) {
      return result(SmartCardNumberStatus.empty);
    }
    final digits = digitsOnly(value);
    if (!RegExp(r'^[0-9 \-]+$').hasMatch(value) || digits.isEmpty) {
      return result(
        SmartCardNumberStatus.invalid,
        issue: SmartCardNumberIssue.invalidCharacters,
        digits: digits.length,
      );
    }
    final brand = match.brand;
    if (acceptedBrands != null &&
        match.isCertain &&
        !acceptedBrands.contains(brand)) {
      return result(
        SmartCardNumberStatus.invalid,
        issue: SmartCardNumberIssue.brandNotAccepted,
        digits: digits.length,
      );
    }
    final lengths = brand.lengths;
    final count = digits.length;
    if (count > brand.maxLength) {
      return result(
        SmartCardNumberStatus.invalid,
        issue: SmartCardNumberIssue.wrongLength,
        digits: count,
      );
    }
    if (!lengths.contains(count)) {
      final next = lengths.where((length) => length > count).toList()..sort();
      return result(
        SmartCardNumberStatus.incomplete,
        remaining: next.isEmpty ? null : next.first - count,
        digits: count,
      );
    }
    final checksum =
        !validateLuhn || luhnExemptBrands.contains(brand) || passesLuhn(digits);
    if (checksum) {
      if (acceptedBrands != null && !match.isCertain) {
        return result(
          SmartCardNumberStatus.invalid,
          issue: SmartCardNumberIssue.brandNotAccepted,
          digits: count,
        );
      }
      return result(SmartCardNumberStatus.valid, digits: count);
    }
    final eager = count == brand.primaryLength || count == brand.maxLength;
    if (eager) {
      return result(
        SmartCardNumberStatus.invalid,
        issue: SmartCardNumberIssue.failsChecksum,
        digits: count,
      );
    }
    final next = lengths.where((length) => length > count).toList()..sort();
    return result(
      SmartCardNumberStatus.incomplete,
      remaining: next.isEmpty ? null : next.first - count,
      digits: count,
    );
  }

  static bool passesLuhn(String value) {
    final digits = digitsOnly(value);
    if (digits.length < 2 ||
        digits.length != value.replaceAll(RegExp(r'[ \-]'), '').length) {
      return false;
    }
    var sum = 0;
    var doubleIt = false;
    for (var index = digits.length - 1; index >= 0; index--) {
      var digit = digits.codeUnitAt(index) - 0x30;
      if (doubleIt) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }
      sum += digit;
      doubleIt = !doubleIt;
    }
    return sum % 10 == 0;
  }

  static List<int> groupSizes(SmartCardBrand brand, int length) {
    final gaps = _effectiveGaps(brand, length);
    final sizes = <int>[];
    var previous = 0;
    for (final gap in gaps) {
      sizes.add(gap - previous);
      previous = gap;
    }
    sizes.add(length > previous ? length - previous : 0);
    return sizes;
  }

  static List<int> _effectiveGaps(SmartCardBrand brand, int length) {
    final gaps = [...brand.gaps];
    if (gaps.length == 3 && gaps.last == 12) {
      for (var gap = 16; gap < length; gap += 4) {
        gaps.add(gap);
      }
    }
    return gaps;
  }

  static String format(String value, {SmartCardBrand? brand}) {
    final digits = digitsOnly(value);
    final resolved = brand ?? detectBrand(digits);
    final gaps = _effectiveGaps(resolved, digits.length);
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && gaps.contains(index)) {
        buffer.write(' ');
      }
      buffer.write(digits[index]);
    }
    return buffer.toString();
  }

  static String maskedNumber(String value, {String maskCharacter = '\u2022'}) {
    final digits = digitsOnly(value);
    if (digits.length <= 4) {
      return digits;
    }
    final brand = detectBrand(digits);
    final gaps = _effectiveGaps(brand, digits.length);
    final visibleFrom = digits.length - 4;
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && gaps.contains(index)) {
        buffer.write(' ');
      }
      buffer.write(index >= visibleFrom ? digits[index] : maskCharacter);
    }
    return buffer.toString();
  }

  static SmartCardExpiry? tryParseExpiry(
    String text, {
    SmartExpiryFormat format = SmartExpiryFormat.mmYy,
  }) {
    final match = RegExp(
      format == SmartExpiryFormat.mmYy
          ? r'^(\d{2})/(\d{2})$'
          : r'^(\d{2})/(\d{4})$',
    ).firstMatch(text);
    if (match == null) {
      return null;
    }
    final month = int.parse(match.group(1)!);
    var year = int.parse(match.group(2)!);
    if (month < 1 || month > 12) {
      return null;
    }
    if (format == SmartExpiryFormat.mmYy) {
      year += 2000;
    }
    return SmartCardExpiry(month, year);
  }

  static bool isCvvLengthValid(
    String cvv,
    SmartCardBrand brand, {
    Set<int>? allowedLengths,
  }) {
    if (!RegExp(r'^[0-9]+$').hasMatch(cvv)) {
      return false;
    }
    if (allowedLengths != null) {
      return allowedLengths.contains(cvv.length);
    }
    if (brand == SmartCardBrand.unknown) {
      return cvv.length == 3 || cvv.length == 4;
    }
    return cvv.length == brand.cvvLength;
  }
}

final class SmartCardNumberFormatter extends TextInputFormatter {
  const SmartCardNumberFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (smartIsComposing(newValue)) {
      return newValue;
    }
    if (RegExp(r'[^0-9 \-]').hasMatch(newValue.text)) {
      return oldValue;
    }
    final digits = SmartCardUtils.digitsOnly(newValue.text);
    if (digits.length > SmartCardUtils.maxCardDigits) {
      return oldValue;
    }
    final brand = SmartCardUtils.detectBrand(digits);
    if (digits.length > brand.maxLength) {
      return oldValue;
    }
    int digitsBefore(int offset) {
      final clamped = offset.clamp(0, newValue.text.length);
      return SmartCardUtils.digitsOnly(
        newValue.text.substring(0, clamped),
      ).length;
    }

    final oldDigits = SmartCardUtils.digitsOnly(oldValue.text);
    var baseDigits = digitsBefore(newValue.selection.baseOffset);
    var extentDigits = digitsBefore(newValue.selection.extentOffset);
    var finalDigits = digits;
    final deletedSpace =
        newValue.text.length < oldValue.text.length &&
        digits == oldDigits &&
        newValue.selection.isCollapsed;
    final forward =
        oldValue.selection.isCollapsed &&
        oldValue.selection.baseOffset == newValue.selection.baseOffset;
    if (deletedSpace && forward && baseDigits < digits.length) {
      finalDigits =
          digits.substring(0, baseDigits) + digits.substring(baseDigits + 1);
      extentDigits = baseDigits;
    } else if (deletedSpace && baseDigits > 0) {
      finalDigits =
          digits.substring(0, baseDigits - 1) + digits.substring(baseDigits);
      baseDigits--;
      extentDigits = baseDigits;
    }
    final finalDisplay = SmartCardUtils.format(finalDigits);
    if (finalDisplay == newValue.text && !deletedSpace) {
      return newValue;
    }
    int finalOffset(int count) {
      if (count <= 0) {
        return 0;
      }
      var seen = 0;
      for (var index = 0; index < finalDisplay.length; index++) {
        if (finalDisplay[index] != ' ') {
          seen++;
          if (seen == count) {
            return index + 1;
          }
        }
      }
      return finalDisplay.length;
    }

    return TextEditingValue(
      text: finalDisplay,
      selection: TextSelection(
        baseOffset: finalOffset(baseDigits),
        extentOffset: finalOffset(extentDigits),
      ),
    );
  }
}
