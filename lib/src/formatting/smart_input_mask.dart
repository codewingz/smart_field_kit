import 'package:flutter/services.dart';
import 'package:smart_field_kit/src/formatting/smart_composing.dart';

final class _MaskToken {
  const _MaskToken.literal(this.character) : slot = null;

  const _MaskToken.slot(this.slot) : character = null;

  final String? character;
  final String? slot;

  bool get isSlot => slot != null;
}

final class SmartInputMask {
  SmartInputMask(this.pattern) : _tokens = _parse(pattern) {
    if (!_tokens.any((token) => token.isSlot)) {
      throw ArgumentError.value(
        pattern,
        'pattern',
        'A mask needs at least one input slot (#, A, or *).',
      );
    }
  }

  final String pattern;
  final List<_MaskToken> _tokens;

  late final Set<String> _literalCharacters = {
    for (final token in _tokens)
      if (!token.isSlot) token.character!,
  };

  static final RegExp _digit = RegExp(r'^[0-9]$');
  static final RegExp _letter = RegExp(r'^[\p{L}\p{M}]$', unicode: true);
  static final RegExp _alphanumeric = RegExp(
    r'^[\p{L}\p{M}0-9]$',
    unicode: true,
  );

  static List<_MaskToken> _parse(String pattern) {
    final tokens = <_MaskToken>[];
    final characters = pattern.runes.map(String.fromCharCode).toList();
    for (var index = 0; index < characters.length; index++) {
      final character = characters[index];
      if (character == r'\' && index + 1 < characters.length) {
        tokens.add(_MaskToken.literal(characters[++index]));
      } else if (character == '#' || character == 'A' || character == '*') {
        tokens.add(_MaskToken.slot(character));
      } else {
        tokens.add(_MaskToken.literal(character));
      }
    }
    return tokens;
  }

  int get capacity => _tokens.where((token) => token.isSlot).length;

  bool accepts(String slot, String character) {
    switch (slot) {
      case '#':
        return _digit.hasMatch(character);
      case 'A':
        return _letter.hasMatch(character);
      default:
        return _alphanumeric.hasMatch(character);
    }
  }

  bool isComplete(String raw) {
    return raw.runes.length == capacity && acceptsRaw(raw);
  }

  bool acceptsRaw(String raw) {
    final characters = raw.runes.map(String.fromCharCode).toList();
    if (characters.length > capacity) {
      return false;
    }
    var index = 0;
    for (final token in _tokens) {
      if (!token.isSlot) {
        continue;
      }
      if (index >= characters.length) {
        break;
      }
      if (!accepts(token.slot!, characters[index++])) {
        return false;
      }
    }
    return true;
  }

  ({String display, List<int> offsets}) apply(String raw) {
    final characters = raw.runes.map(String.fromCharCode).toList();
    final buffer = StringBuffer();
    final offsets = <int>[0];
    var placed = 0;
    var pendingLiterals = StringBuffer();
    for (final token in _tokens) {
      if (placed >= characters.length) {
        break;
      }
      if (!token.isSlot) {
        pendingLiterals.write(token.character);
        continue;
      }
      buffer.write(pendingLiterals);
      pendingLiterals = StringBuffer();
      buffer.write(characters[placed]);
      placed++;
      offsets.add(buffer.length);
    }
    return (display: buffer.toString(), offsets: offsets);
  }

  String display(String raw) => apply(raw).display;

  ({String raw, List<int> rawBefore})? scan(String text) {
    final characters = text.runes.map(String.fromCharCode).toList();
    final raw = StringBuffer();
    final rawBefore = <int>[];
    var tokenIndex = 0;
    var rawCount = 0;
    var unitOffset = 0;
    for (final character in characters) {
      for (var unit = 0; unit < character.length; unit++) {
        rawBefore.add(rawCount);
      }
      unitOffset += character.length;
      var consumed = false;
      while (!consumed) {
        if (tokenIndex >= _tokens.length) {
          return null;
        }
        final token = _tokens[tokenIndex];
        if (!token.isSlot) {
          tokenIndex++;
          if (token.character == character) {
            consumed = true;
          }
          continue;
        }
        if (!accepts(token.slot!, character)) {
          if (_literalCharacters.contains(character)) {
            consumed = true;
            continue;
          }
          return null;
        }
        raw.write(character);
        rawCount++;
        tokenIndex++;
        consumed = true;
      }
    }
    rawBefore.add(rawCount);
    assert(rawBefore.length == unitOffset + 1);
    return (raw: raw.toString(), rawBefore: rawBefore);
  }

  String? extractRaw(String text) => scan(text)?.raw;
}

final class SmartMaskFormatter extends TextInputFormatter {
  SmartMaskFormatter(this.mask);

  final SmartInputMask mask;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (smartIsComposing(newValue)) {
      return newValue;
    }
    final scanned = mask.scan(newValue.text);
    if (scanned == null) {
      return oldValue;
    }
    var raw = scanned.raw;
    int rawAt(int offset) {
      if (offset < 0) {
        return -1;
      }
      return scanned.rawBefore[offset.clamp(0, scanned.rawBefore.length - 1)];
    }

    var baseRaw = rawAt(newValue.selection.baseOffset);
    var extentRaw = rawAt(newValue.selection.extentOffset);
    final oldRaw = mask.extractRaw(oldValue.text);
    final deletedOnlyLiteral =
        oldRaw != null &&
        newValue.text.length < oldValue.text.length &&
        raw == oldRaw &&
        newValue.selection.isCollapsed &&
        baseRaw > 0;
    if (deletedOnlyLiteral) {
      final characters = raw.runes.map(String.fromCharCode).toList();
      characters.removeAt(baseRaw - 1);
      raw = characters.join();
      baseRaw--;
      extentRaw = baseRaw;
    }
    final applied = mask.apply(raw);
    if (applied.display == newValue.text && !deletedOnlyLiteral) {
      return newValue;
    }
    int offset(int rawCount) {
      if (rawCount < 0) {
        return rawCount;
      }
      return applied.offsets[rawCount.clamp(0, applied.offsets.length - 1)];
    }

    return TextEditingValue(
      text: applied.display,
      selection: TextSelection(
        baseOffset: offset(baseRaw),
        extentOffset: offset(extentRaw),
        affinity: newValue.selection.affinity,
        isDirectional: newValue.selection.isDirectional,
      ),
    );
  }
}
