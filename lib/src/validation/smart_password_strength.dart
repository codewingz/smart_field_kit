import 'package:characters/characters.dart';
import 'package:smart_field_kit/src/validation/smart_character_classes.dart';

/// Informational strength level derived from the share of criteria met.
enum SmartPasswordStrengthLevel { empty, weak, fair, good, strong }

/// One rule of the password-strength checklist: a label and a test.
final class SmartPasswordCriterion {
  /// Creates a criterion shown as [label] and met when [test] returns `true`.
  const SmartPasswordCriterion(this.label, this.test);

  factory SmartPasswordCriterion.minLength(int length, {String? label}) {
    return SmartPasswordCriterion(
      label ?? 'At least $length characters',
      (value) => value.characters.length >= length,
    );
  }

  static final SmartPasswordCriterion uppercase = SmartPasswordCriterion(
    'An uppercase letter',
    smartUppercaseExpression.hasMatch,
  );

  static final SmartPasswordCriterion lowercase = SmartPasswordCriterion(
    'A lowercase letter',
    smartLowercaseExpression.hasMatch,
  );

  static final SmartPasswordCriterion digit = SmartPasswordCriterion(
    'A number',
    smartDigitExpression.hasMatch,
  );

  static final SmartPasswordCriterion specialCharacter = SmartPasswordCriterion(
    'A special character',
    smartSpecialExpression.hasMatch,
  );

  final String label;
  final bool Function(String value) test;
}

/// The outcome of [SmartPasswordStrength.evaluate].
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

/// Computes password-strength feedback locally.
///
/// The result is guidance only and is separate from validation.
abstract final class SmartPasswordStrength {
  /// The criteria used when none are supplied.
  static final List<SmartPasswordCriterion> defaultCriteria = [
    SmartPasswordCriterion.minLength(8),
    SmartPasswordCriterion.uppercase,
    SmartPasswordCriterion.lowercase,
    SmartPasswordCriterion.digit,
    SmartPasswordCriterion.specialCharacter,
  ];

  /// The default English label of each level.
  static const Map<SmartPasswordStrengthLevel, String> defaultLabels = {
    SmartPasswordStrengthLevel.empty: 'Enter a password',
    SmartPasswordStrengthLevel.weak: 'Weak',
    SmartPasswordStrengthLevel.fair: 'Fair',
    SmartPasswordStrengthLevel.good: 'Good',
    SmartPasswordStrengthLevel.strong: 'Strong',
  };

  /// Evaluates [password] against the criteria. Nothing is stored or sent.
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
