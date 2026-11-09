enum SmartPasswordStrengthLevel { empty, weak, fair, good, strong }

final class SmartPasswordCriterion {
  const SmartPasswordCriterion(this.label, this.test);

  factory SmartPasswordCriterion.minLength(int length, {String? label}) {
    return SmartPasswordCriterion(
      label ?? 'At least $length characters',
      (value) => value.runes.length >= length,
    );
  }

  static final SmartPasswordCriterion uppercase = SmartPasswordCriterion(
    'An uppercase letter',
    (value) => RegExp(r'\p{Lu}', unicode: true).hasMatch(value),
  );

  static final SmartPasswordCriterion lowercase = SmartPasswordCriterion(
    'A lowercase letter',
    (value) => RegExp(r'\p{Ll}', unicode: true).hasMatch(value),
  );

  static final SmartPasswordCriterion digit = SmartPasswordCriterion(
    'A number',
    (value) => RegExp(r'\p{Nd}', unicode: true).hasMatch(value),
  );

  static final SmartPasswordCriterion specialCharacter = SmartPasswordCriterion(
    'A special character',
    (value) => RegExp(r'[^\p{L}\p{N}\p{M}\s]', unicode: true).hasMatch(value),
  );

  final String label;
  final bool Function(String value) test;
}

final class SmartPasswordStrengthResult {
  const SmartPasswordStrengthResult({
    required this.level,
    required this.score,
    required this.met,
    required this.unmet,
  });

  final SmartPasswordStrengthLevel level;
  final double score;
  final List<SmartPasswordCriterion> met;
  final List<SmartPasswordCriterion> unmet;

  @override
  String toString() {
    return 'SmartPasswordStrengthResult(level: ${level.name}, '
        'met: ${met.length}, unmet: ${unmet.length})';
  }
}

abstract final class SmartPasswordStrength {
  static final List<SmartPasswordCriterion> defaultCriteria = [
    SmartPasswordCriterion.minLength(8),
    SmartPasswordCriterion.uppercase,
    SmartPasswordCriterion.lowercase,
    SmartPasswordCriterion.digit,
    SmartPasswordCriterion.specialCharacter,
  ];

  static const Map<SmartPasswordStrengthLevel, String> defaultLabels = {
    SmartPasswordStrengthLevel.empty: 'Enter a password',
    SmartPasswordStrengthLevel.weak: 'Weak',
    SmartPasswordStrengthLevel.fair: 'Fair',
    SmartPasswordStrengthLevel.good: 'Good',
    SmartPasswordStrengthLevel.strong: 'Strong',
  };

  static SmartPasswordStrengthResult evaluate(
    String password, {
    List<SmartPasswordCriterion>? criteria,
  }) {
    final rules = criteria ?? defaultCriteria;
    final met = <SmartPasswordCriterion>[];
    final unmet = <SmartPasswordCriterion>[];
    for (final rule in rules) {
      (rule.test(password) ? met : unmet).add(rule);
    }
    if (password.isEmpty || rules.isEmpty) {
      return SmartPasswordStrengthResult(
        level: SmartPasswordStrengthLevel.empty,
        score: 0,
        met: met,
        unmet: unmet,
      );
    }
    final score = met.length / rules.length;
    final level = score >= 1
        ? SmartPasswordStrengthLevel.strong
        : score > 0.6
        ? SmartPasswordStrengthLevel.good
        : score > 0.4
        ? SmartPasswordStrengthLevel.fair
        : SmartPasswordStrengthLevel.weak;
    return SmartPasswordStrengthResult(
      level: level,
      score: score,
      met: met,
      unmet: unmet,
    );
  }
}
