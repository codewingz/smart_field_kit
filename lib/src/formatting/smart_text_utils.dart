/// A text-case transformation.
enum SmartTextCase {
  none,
  capitalizeFirstLetter,
  capitalizeWords,
  capitalizeSentences,
  lowercase,
  uppercase,
}

/// Text helpers used by the fields and available on their own.
abstract final class SmartTextUtils {
  static final RegExp _whitespace = RegExp(r'\s');
  static final RegExp _wordExpression = RegExp(r'\S+');
  static final RegExp _lineBreakExpression = RegExp(r'\r\n?');
  static final RegExp _inlineSpaceRun = RegExp(r'[^\S\n]{2,}');

  /// Replaces Arabic-Indic (U+0660 to U+0669), Persian (U+06F0 to U+06F9)
  /// and fullwidth (U+FF10 to U+FF19) digits with ASCII digits. Every other
  /// character, including other numerals and separators, is unchanged.
  static String normalizeDigits(String text) {
    StringBuffer? buffer;
    for (var index = 0; index < text.length; index++) {
      final unit = text.codeUnitAt(index);
      final digit = unit >= 0x0660 && unit <= 0x0669
          ? unit - 0x0660
          : unit >= 0x06F0 && unit <= 0x06F9
          ? unit - 0x06F0
          : unit >= 0xFF10 && unit <= 0xFF19
          ? unit - 0xFF10
          : -1;
      if (digit < 0) {
        buffer?.writeCharCode(unit);
        continue;
      }
      buffer ??= StringBuffer(text.substring(0, index));
      buffer.writeCharCode(0x30 + digit);
    }
    return buffer?.toString() ?? text;
  }

  /// The number of whitespace-separated words.
  static int countWords(String text) {
    return _wordExpression.allMatches(text).length;
  }

  /// Applies [mode] to [text].
  static String applyCase(String text, SmartTextCase mode) {
    switch (mode) {
      case SmartTextCase.none:
        return text;
      case SmartTextCase.capitalizeFirstLetter:
        return capitalizeFirstLetter(text);
      case SmartTextCase.capitalizeWords:
        return capitalizeWords(text);
      case SmartTextCase.capitalizeSentences:
        return capitalizeSentences(text);
      case SmartTextCase.lowercase:
        return text.toLowerCase();
      case SmartTextCase.uppercase:
        return text.toUpperCase();
    }
  }

  static String capitalizeFirstLetter(String text) {
    final buffer = StringBuffer();
    var done = false;
    for (final rune in text.runes) {
      final character = String.fromCharCode(rune);
      if (!done && !_whitespace.hasMatch(character)) {
        buffer.write(character.toUpperCase());
        done = true;
      } else {
        buffer.write(character);
      }
    }
    return buffer.toString();
  }

  static String capitalizeWords(String text) {
    final buffer = StringBuffer();
    var atWordStart = true;
    for (final rune in text.runes) {
      final character = String.fromCharCode(rune);
      if (_whitespace.hasMatch(character)) {
        atWordStart = true;
        buffer.write(character);
      } else if (atWordStart) {
        buffer.write(character.toUpperCase());
        atWordStart = false;
      } else {
        buffer.write(character);
      }
    }
    return buffer.toString();
  }

  static String capitalizeSentences(String text) {
    final buffer = StringBuffer();
    var atSentenceStart = true;
    var afterTerminator = false;
    for (final rune in text.runes) {
      final character = String.fromCharCode(rune);
      if (_whitespace.hasMatch(character)) {
        if (afterTerminator || character == '\n') {
          atSentenceStart = true;
        }
        buffer.write(character);
        continue;
      }
      if (atSentenceStart) {
        buffer.write(character.toUpperCase());
        atSentenceStart = false;
      } else {
        buffer.write(character);
      }
      afterTerminator =
          character == '.' || character == '!' || character == '?';
    }
    return buffer.toString();
  }

  /// Replaces runs of spaces with a single space.
  static String collapseWhitespace(String text, {bool trimLeading = false}) {
    var result = text
        .replaceAll(_lineBreakExpression, '\n')
        .replaceAllMapped(_inlineSpaceRun, (_) => ' ');
    if (trimLeading) {
      result = result.replaceFirst(RegExp(r'^\s+'), '');
    }
    return result;
  }
}
