import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Set<String>> _constructors() {
  final source = File('lib/src/widgets/smart_field.dart').readAsStringSync();
  final result = <String, Set<String>>{};
  final start = RegExp(r'\n  (?:const )?(SmartField(?:\.\w+)?)\(\{');
  for (final match in start.allMatches(source)) {
    var depth = 1;
    var index = match.end;
    while (depth > 0) {
      final char = source[index];
      if (char == '{') {
        depth++;
      } else if (char == '}') {
        depth--;
      }
      index++;
    }
    final body = source.substring(match.end, index - 1);
    final names = <String>{};
    final current = StringBuffer();
    var nesting = 0;
    void flush() {
      final declaration = current.toString().split('=').first.trim();
      current.clear();
      if (declaration.isEmpty) {
        return;
      }
      names.add(
        declaration
            .split(RegExp(r'\s+'))
            .last
            .replaceFirst('super.', '')
            .replaceFirst('this.', ''),
      );
    }

    for (final char in body.split('')) {
      if ('([{<'.contains(char)) {
        nesting++;
      } else if (')]}>'.contains(char)) {
        nesting--;
      }
      if (char == ',' && nesting == 0) {
        flush();
      } else {
        current.write(char);
      }
    }
    flush();
    result[match.group(1)!] = names;
  }
  return result;
}

const _everyField = {
  'enabled',
  'readOnly',
  'onChanged',
  'isRequired',
  'requiredErrorText',
  'autovalidateMode',
  'decoration',
};

const _singleField = {
  'label',
  'hintText',
  'controller',
  'focusNode',
  'onSaved',
  'validator',
  'asyncValidation',
  'serverError',
  'textInputAction',
  'autofocus',
  'validationMode',
  'builtInChecks',
};

const _textEditing = {
  'initialValue',
  'onEditingComplete',
  'onTap',
  'onTapOutside',
  'style',
  'textAlign',
  'textDirection',
  'restorationId',
  'minLength',
  'maxLength',
};

const _textBased = [
  'SmartField',
  'SmartField.description',
  'SmartField.text',
  'SmartField.email',
  'SmartField.url',
  'SmartField.name',
  'SmartField.username',
  'SmartField.search',
  'SmartField.phone',
  'SmartField.password',
  'SmartField.number',
  'SmartField.percentage',
  'SmartField.amount',
];

const _knownGaps = {
  'SmartField.search': {'textInputAction'},
  'SmartField.otp': {
    'initialValue',
    'onEditingComplete',
    'onTap',
    'onTapOutside',
    'textAlign',
    'textDirection',
  },
  'SmartField.date': {
    'initialValue',
    'onEditingComplete',
    'onTap',
    'onTapOutside',
    'style',
    'textAlign',
    'textDirection',
    'restorationId',
    'minLength',
    'maxLength',
  },
  'SmartField.time': {
    'initialValue',
    'onEditingComplete',
    'onTap',
    'onTapOutside',
    'style',
    'textAlign',
    'textDirection',
    'restorationId',
    'minLength',
    'maxLength',
  },
  'SmartField.dateTime': {
    'initialValue',
    'onEditingComplete',
    'onTap',
    'onTapOutside',
    'style',
    'textAlign',
    'textDirection',
    'restorationId',
    'minLength',
    'maxLength',
  },
};

void main() {
  const skip = kIsWeb
      ? 'Reads project files through dart:io, which is unavailable in a browser.'
      : null;

  group('19P shared constructor options', skip: skip, () {
    late Map<String, Set<String>> all;
    late Map<String, Set<String>> public;

    setUp(() {
      all = _constructors();
      public = {
        for (final entry in all.entries)
          if (!entry.key.contains('._')) entry.key: entry.value,
      };
    });

    test('the public constructor list is unchanged', () {
      expect(public.keys.toList(), [
        ..._textBased.sublist(0, 10),
        'SmartField.number',
        'SmartField.percentage',
        'SmartField.amount',
        'SmartField.otp',
        'SmartField.date',
        'SmartField.time',
        'SmartField.dateTime',
        'SmartField.creditCard',
      ]);
    });

    test('every constructor has the options common to all fields', () {
      for (final entry in public.entries) {
        expect(
          entry.value,
          containsAll(_everyField),
          reason: '${entry.key} lacks ${_everyField.difference(entry.value)}',
        );
      }
    });

    test('every single-input constructor has the shared field options', () {
      for (final entry in public.entries) {
        if (entry.key == 'SmartField.creditCard') {
          continue;
        }
        final expected = _singleField.difference(
          _knownGaps[entry.key] ?? const {},
        );
        expect(
          entry.value,
          containsAll(expected),
          reason: '${entry.key} lacks ${expected.difference(entry.value)}',
        );
      }
    });

    test('every text-based constructor has the text-editing options', () {
      for (final name in _textBased) {
        final parameters = public[name]!;
        expect(
          parameters,
          containsAll(_textEditing),
          reason: '$name lacks ${_textEditing.difference(parameters)}',
        );
        if (name != 'SmartField.search') {
          expect(parameters, contains('onFieldSubmitted'), reason: name);
        }
      }
    });

    test('the recorded gaps are exactly the current gaps', () {
      for (final name in [
        'SmartField.otp',
        'SmartField.date',
        'SmartField.time',
        'SmartField.dateTime',
      ]) {
        final missing = {
          ..._singleField,
          ..._textEditing,
        }.difference(public[name]!);
        expect(missing, _knownGaps[name], reason: name);
      }
      expect(
        _singleField.difference(public['SmartField.search']!),
        _knownGaps['SmartField.search'],
      );
    });

    test('raw-value callbacks exist where a raw value exists', () {
      for (final name in [
        'SmartField.text',
        'SmartField.amount',
        'SmartField.date',
        'SmartField.time',
        'SmartField.dateTime',
      ]) {
        expect(
          public[name],
          containsAll({'onRawChanged', 'onRawSaved'}),
          reason: name,
        );
      }
    });
  });
}
