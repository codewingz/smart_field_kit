import 'package:flutter/material.dart';
import 'package:smart_field_kit/src/smart_default_texts.dart';
import 'package:smart_field_kit/src/validation/smart_password_strength.dart';

class SmartPasswordStrengthIndicator extends StatelessWidget {
  const SmartPasswordStrengthIndicator({
    super.key,
    required this.password,
    this.criteria,
    this.labels,
    this.showChecklist = false,
    this.title = smartStrengthTitleText,
  });

  final String password;
  final List<SmartPasswordCriterion>? criteria;
  final Map<SmartPasswordStrengthLevel, String>? labels;
  final bool showChecklist;
  final String title;

  @override
  Widget build(BuildContext context) {
    final result = SmartPasswordStrength.evaluate(password, criteria: criteria);
    final names = {...SmartPasswordStrength.defaultLabels, ...?labels};
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = switch (result.level) {
      SmartPasswordStrengthLevel.empty => scheme.outline,
      SmartPasswordStrengthLevel.weak => scheme.error,
      SmartPasswordStrengthLevel.fair => scheme.tertiary,
      SmartPasswordStrengthLevel.good => scheme.secondary,
      SmartPasswordStrengthLevel.strong => scheme.primary,
    };
    final text = result.level == SmartPasswordStrengthLevel.empty
        ? names[result.level]!
        : '$title: ${names[result.level]}';
    return Semantics(
      label: text,
      liveRegion: true,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: result.score,
              minHeight: 4,
              color: color,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 4),
          Text(text, style: theme.textTheme.bodySmall?.copyWith(color: color)),
          if (showChecklist)
            for (final rule in [...result.met, ...result.unmet])
              Row(
                children: [
                  Icon(
                    result.met.contains(rule)
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 16,
                    color: result.met.contains(rule)
                        ? scheme.primary
                        : scheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(rule.label, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
        ],
      ),
    );
  }
}
