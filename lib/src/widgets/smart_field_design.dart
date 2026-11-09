import 'package:flutter/material.dart';

abstract final class SmartFieldDesign {
  static const double borderRadius = 12;
  static const double borderWidth = 1;
  static const double activeBorderWidth = 2;
  static const EdgeInsets contentPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );

  static InputDecoration resolve(BuildContext context, InputDecoration source) {
    final theme = Theme.of(context);
    final inputTheme = theme.inputDecorationTheme;
    final scheme = theme.colorScheme;

    final hasBorder =
        source.border != null ||
        source.enabledBorder != null ||
        source.focusedBorder != null ||
        source.errorBorder != null ||
        source.focusedErrorBorder != null ||
        source.disabledBorder != null ||
        inputTheme.border != null ||
        inputTheme.enabledBorder != null ||
        inputTheme.focusedBorder != null ||
        inputTheme.errorBorder != null ||
        inputTheme.focusedErrorBorder != null ||
        inputTheme.disabledBorder != null;
    final hasPadding =
        source.contentPadding != null ||
        inputTheme.contentPadding != null ||
        (source.isCollapsed ?? false);

    if (hasBorder && hasPadding) {
      return source;
    }

    OutlineInputBorder outline(Color color, double width) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return source.copyWith(
      border: hasBorder ? null : outline(scheme.outline, borderWidth),
      enabledBorder: hasBorder ? null : outline(scheme.outline, borderWidth),
      focusedBorder: hasBorder
          ? null
          : outline(scheme.primary, activeBorderWidth),
      errorBorder: hasBorder ? null : outline(scheme.error, activeBorderWidth),
      focusedErrorBorder: hasBorder
          ? null
          : outline(scheme.error, activeBorderWidth),
      disabledBorder: hasBorder
          ? null
          : outline(scheme.onSurface.withValues(alpha: 0.12), borderWidth),
      contentPadding: hasPadding ? null : contentPadding,
    );
  }
}
