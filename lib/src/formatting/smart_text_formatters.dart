import 'package:flutter/services.dart';
import 'package:smart_field_kit/src/formatting/smart_composing.dart';
import 'package:smart_field_kit/src/formatting/smart_text_utils.dart';

/// The characters a username field accepts while typing.
enum SmartUsernameCharacters { any, letters, lettersAndDigits, usernameSafe }

TextEditingValue _transform(
  TextEditingValue value,
  String Function(String text) convert,
) {
  if (smartIsComposing(value)) {
    return value;
  }
  final text = convert(value.text);
  if (text == value.text) {
    return value;
  }
  int map(int offset) {
    if (offset < 0) {
      return offset;
    }
    final clamped = offset > value.text.length ? value.text.length : offset;
    return convert(value.text.substring(0, clamped)).length;
  }

  return TextEditingValue(
    text: text,
    selection: TextSelection(
      baseOffset: map(value.selection.baseOffset),
      extentOffset: map(value.selection.extentOffset),
      affinity: value.selection.affinity,
      isDirectional: value.selection.isDirectional,
    ),
    composing: TextRange.empty,
  );
}

/// Applies a [SmartTextCase] to committed text and keeps the caret.
final class SmartTextCaseFormatter extends TextInputFormatter {
  const SmartTextCaseFormatter(this.mode);

  final SmartTextCase mode;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (mode == SmartTextCase.none) {
      return newValue;
    }
    return _transform(newValue, (text) => SmartTextUtils.applyCase(text, mode));
  }
}

/// Collapses repeated spaces in committed text.
final class SmartWhitespaceFormatter extends TextInputFormatter {
  const SmartWhitespaceFormatter({this.trimLeading = false});

  final bool trimLeading;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return _transform(
      newValue,
      (text) =>
          SmartTextUtils.collapseWhitespace(text, trimLeading: trimLeading),
    );
  }
}

/// Rejects edits containing characters outside the allowed set and can
/// force lower or upper case.
final class SmartUsernameFormatter extends TextInputFormatter {
  const SmartUsernameFormatter({
    this.allowedCharacters = SmartUsernameCharacters.any,
    this.textCase = SmartTextCase.none,
  }) : assert(
         textCase == SmartTextCase.none ||
             textCase == SmartTextCase.lowercase ||
             textCase == SmartTextCase.uppercase,
       );

  final SmartUsernameCharacters allowedCharacters;
  final SmartTextCase textCase;

  static final RegExp _letters = RegExp(r'^[\p{L}\p{M}]*$', unicode: true);
  static final RegExp _lettersAndDigits = RegExp(
    r'^[\p{L}\p{M}\p{N}]*$',
    unicode: true,
  );
  static final RegExp _usernameSafe = RegExp(
    r'^[\p{L}\p{M}\p{N}._\-]*$',
    unicode: true,
  );

  bool allows(String text) {
    switch (allowedCharacters) {
      case SmartUsernameCharacters.any:
        return true;
      case SmartUsernameCharacters.letters:
        return _letters.hasMatch(text);
      case SmartUsernameCharacters.lettersAndDigits:
        return _lettersAndDigits.hasMatch(text);
      case SmartUsernameCharacters.usernameSafe:
        return _usernameSafe.hasMatch(text);
    }
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!smartIsComposing(newValue) && !allows(newValue.text)) {
      return smartBeforeComposition(oldValue);
    }
    return _transform(
      newValue,
      (text) => SmartTextUtils.applyCase(text, textCase),
    );
  }
}

/// Replaces Arabic-Indic, Persian and fullwidth digits with ASCII digits.
///
/// Text length, caret and selection are unchanged. Text that the
/// keyboard is still composing is left alone until it is committed.
final class SmartDigitNormalizationFormatter extends TextInputFormatter {
  /// Creates a digit-normalizing formatter.
  const SmartDigitNormalizationFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (smartIsComposing(newValue)) {
      return newValue;
    }
    final text = SmartTextUtils.normalizeDigits(newValue.text);
    return text == newValue.text ? newValue : newValue.copyWith(text: text);
  }
}
