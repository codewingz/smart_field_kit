import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}

TextEditingValue _edit(
  TextInputFormatter formatter,
  String oldText,
  String newText, {
  int? caret,
  TextRange composing = TextRange.empty,
}) {
  return formatter.formatEditUpdate(
    TextEditingValue(
      text: oldText,
      selection: TextSelection.collapsed(offset: oldText.length),
    ),
    TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: caret ?? newText.length),
      composing: composing,
    ),
  );
}

void main() {
  group('SmartTextUtils', () {
    test('countWords handles spaces, newlines, unicode, and emoji', () {
      expect(SmartTextUtils.countWords(''), 0);
      expect(SmartTextUtils.countWords('   \n\t '), 0);
      expect(SmartTextUtils.countWords('one'), 1);
      expect(SmartTextUtils.countWords('  one   two\nthree\r\nfour\tfive '), 5);
      expect(SmartTextUtils.countWords('café 你好 مرحبا'), 3);
      expect(SmartTextUtils.countWords('hi 😀 👍🏽 there'), 4);
      expect(SmartTextUtils.countWords('non breaking　space'), 3);
    });

    test('capitalization helpers', () {
      expect(
        SmartTextUtils.capitalizeFirstLetter('  hello world'),
        '  Hello world',
      );
      expect(
        SmartTextUtils.capitalizeWords('anne marie o\'neil'),
        'Anne Marie O\'neil',
      );
      expect(
        SmartTextUtils.capitalizeWords('mcDonald  smith'),
        'McDonald  Smith',
      );
      expect(
        SmartTextUtils.capitalizeSentences('hello. how are you? fine!\nok'),
        'Hello. How are you? Fine!\nOk',
      );
      expect(
        SmartTextUtils.capitalizeSentences('3.5 apples. yes'),
        '3.5 apples. Yes',
      );
      expect(SmartTextUtils.applyCase('AbC', SmartTextCase.lowercase), 'abc');
      expect(SmartTextUtils.applyCase('AbC', SmartTextCase.uppercase), 'ABC');
      expect(SmartTextUtils.applyCase('AbC', SmartTextCase.none), 'AbC');
    });

    test('collapseWhitespace is safe', () {
      expect(SmartTextUtils.collapseWhitespace('a   b\t\tc'), 'a b c');
      expect(SmartTextUtils.collapseWhitespace('a\r\nb\rc'), 'a\nb\nc');
      expect(SmartTextUtils.collapseWhitespace('a \n b'), 'a \n b');
      expect(SmartTextUtils.collapseWhitespace('  a', trimLeading: true), 'a');
    });

    test('word validators', () {
      final min = SmartValidators.minWords(3, message: 'min');
      final max = SmartValidators.maxWords(3, message: 'max');
      expect(min(''), isNull);
      expect(min('one two'), 'min');
      expect(min('one two three'), isNull);
      expect(max('one two three'), isNull);
      expect(max('one two three four'), 'max');
      expect(() => SmartValidators.minWords(-1), throwsArgumentError);
    });
  });

  group('formatters', () {
    test('case formatter keeps caret and handles middle edits', () {
      const formatter = SmartTextCaseFormatter(SmartTextCase.capitalizeWords);
      final result = _edit(formatter, 'ab cd', 'ab xcd', caret: 4);
      expect(result.text, 'Ab Xcd');
      expect(result.selection, const TextSelection.collapsed(offset: 4));
      final pasted = _edit(formatter, '', 'jane doe');
      expect(pasted.text, 'Jane Doe');
      expect(pasted.selection.baseOffset, 8);
    });

    test('case formatter leaves composing text and none mode alone', () {
      const formatter = SmartTextCaseFormatter(SmartTextCase.uppercase);
      final composing = _edit(
        formatter,
        '',
        'abc',
        composing: const TextRange(start: 0, end: 3),
      );
      expect(composing.text, 'abc');
      expect(
        _edit(const SmartTextCaseFormatter(SmartTextCase.none), '', 'abc').text,
        'abc',
      );
    });

    test('username formatter rejects disallowed edits and applies case', () {
      const formatter = SmartUsernameFormatter(
        allowedCharacters: SmartUsernameCharacters.usernameSafe,
        textCase: SmartTextCase.lowercase,
      );
      expect(_edit(formatter, 'ab', 'Ab_c.d-e1').text, 'ab_c.d-e1');
      expect(_edit(formatter, 'ab', 'ab c').text, 'ab');
      expect(_edit(formatter, 'ab', 'ab!').text, 'ab');
      expect(_edit(formatter, '', 'Jürgen').text, 'jürgen');
      const letters = SmartUsernameFormatter(
        allowedCharacters: SmartUsernameCharacters.letters,
      );
      expect(_edit(letters, 'ab', 'ab1').text, 'ab');
      const alnum = SmartUsernameFormatter(
        allowedCharacters: SmartUsernameCharacters.lettersAndDigits,
      );
      expect(_edit(alnum, 'ab', 'ab1').text, 'ab1');
      expect(_edit(alnum, 'ab', 'ab_').text, 'ab');
    });

    test('whitespace formatter collapses runs and keeps newlines', () {
      const formatter = SmartWhitespaceFormatter();
      expect(_edit(formatter, 'a ', 'a  ').text, 'a ');
      expect(_edit(formatter, 'a', 'a\r\nb').text, 'a\nb');
      final result = _edit(formatter, 'a b', 'a   b', caret: 3);
      expect(result.text, 'a b');
      expect(result.selection.baseOffset, 2);
    });
  });

  group('SmartField integration', () {
    testWidgets('name capitalizeWords is optional and keeps caret', (
      tester,
    ) async {
      final plain = TextEditingController();
      final capital = TextEditingController();
      addTearDown(plain.dispose);
      addTearDown(capital.dispose);
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              SmartField.name(controller: plain),
              SmartField.name(controller: capital, capitalizeWords: true),
            ],
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField).at(0), 'jane doe');
      await tester.enterText(find.byType(TextFormField).at(1), 'jane doe');
      expect(plain.text, 'jane doe');
      expect(capital.text, 'Jane Doe');
    });

    testWidgets('username policies and developer formatters combine', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.username(
            controller: controller,
            usernameCase: SmartTextCase.lowercase,
            allowedCharacters: SmartUsernameCharacters.usernameSafe,
            inputFormatters: [LengthLimitingTextInputFormatter(6)],
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'Ab_Cd');
      expect(controller.text, 'ab_cd');
      await tester.enterText(find.byType(TextFormField), 'ab cd');
      expect(controller.text, 'ab_cd');
      await tester.enterText(find.byType(TextFormField), 'ABCDEFGH');
      expect(controller.text, 'abcdef');
    });

    testWidgets('email, password, otp, phone, url, amount keep raw text', (
      tester,
    ) async {
      final controllers = List.generate(6, (_) => TextEditingController());
      for (final c in controllers) {
        addTearDown(c.dispose);
      }
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              SmartField.email(controller: controllers[0]),
              SmartField.password(controller: controllers[1]),
              SmartField.phone(controller: controllers[2]),
              SmartField.url(controller: controllers[3]),
              SmartField.amount(controller: controllers[4]),
              SmartField.number(controller: controllers[5]),
            ],
          ),
        ),
      );
      final inputs = {
        0: 'John.Doe@Example.COM',
        1: 'sEcReT pass ',
        2: '+92 300 1234567',
        3: 'https://Example.com/CaSe/Path',
        4: '12.5',
        5: '123',
      };
      for (final entry in inputs.entries) {
        await tester.enterText(
          find.byType(TextFormField).at(entry.key),
          entry.value,
        );
        expect(controllers[entry.key].text, entry.value);
      }
      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      for (final index in [0, 1, 3]) {
        expect(fields[index].textCapitalization, TextCapitalization.none);
      }
    });

    testWidgets('text and description case and whitespace options', (
      tester,
    ) async {
      final text = TextEditingController();
      final description = TextEditingController();
      addTearDown(text.dispose);
      addTearDown(description.dispose);
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              SmartField.text(
                controller: text,
                textCase: SmartTextCase.capitalizeFirstLetter,
              ),
              SmartField.description(
                controller: description,
                textCase: SmartTextCase.capitalizeSentences,
                collapseWhitespace: true,
              ),
            ],
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField).at(0), 'hello world');
      expect(text.text, 'Hello world');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'first   one. second\r\nthird',
      );
      expect(description.text, 'First one. Second\nThird');
    });
  });

  group('word limits and count', () {
    testWidgets('shows readable count and validates limits', (tester) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.description(
              controller: controller,
              minWords: 2,
              maxWords: 4,
              showWordCount: true,
              minWordsErrorText: 'Too short',
              maxWordsErrorText: 'Too long',
              maxLength: 1000,
            ),
          ),
        ),
      );
      expect(find.text('0 / 4 words'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'one');
      await tester.pump();
      expect(find.text('1 / 4 words'), findsOneWidget);
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Too short'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'one two\nthree');
      await tester.pump();
      expect(find.text('3 / 4 words'), findsOneWidget);
      expect(formKey.currentState!.validate(), isTrue);
      controller.text = 'a b c d e 😀';
      await tester.pump();
      expect(find.text('6 / 4 words'), findsOneWidget);
      expect(formKey.currentState!.validate(), isFalse);
    });

    testWidgets('count without a maximum, no controller, and growth', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(SmartField.description(showWordCount: true)),
      );
      expect(find.text('0 words'), findsOneWidget);
      final before = tester.getSize(find.byType(TextFormField)).height;
      await tester.enterText(
        find.byType(TextFormField),
        List.generate(12, (i) => 'word$i').join('\n'),
      );
      await tester.pump();
      expect(find.text('12 words'), findsOneWidget);
      expect(
        tester.getSize(find.byType(TextFormField)).height,
        greaterThan(before),
      );
      await tester.enterText(find.byType(TextFormField), 'solo');
      await tester.pump();
      expect(find.text('1 word'), findsOneWidget);
    });

    testWidgets('character and word limits stay independent', (tester) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController(text: 'aaaaaaaaaa bbbbbbbbbb');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.description(
              controller: controller,
              maxLength: 11,
              maxLengthErrorText: 'chars',
              maxWords: 5,
              maxWordsErrorText: 'words',
            ),
          ),
        ),
      );
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('chars'), findsOneWidget);
      controller.text = 'a b c d e f';
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('words'), findsOneWidget);
    });
  });
}
