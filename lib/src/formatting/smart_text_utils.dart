enum SmartTextCase {
  none,
  capitalizeFirstLetter,
  capitalizeWords,
  capitalizeSentences,
  lowercase,
  uppercase,
}

abstract final class SmartTextUtils {
  static final RegExp _whitespace = RegExp(r'\s');
  static final RegExp _wordExpression = RegExp(r'\S+');
  static final RegExp _lineBreakExpression = RegExp(r'\r\n?');
  static final RegExp _inlineSpaceRun = RegExp(r'[^\S\n]{2,}');

  static int countWords(String text) {
    return _wordExpression.allMatches(text).length;
  }

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
