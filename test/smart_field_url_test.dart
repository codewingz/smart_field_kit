import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child, {TextDirection direction = TextDirection.ltr}) {
  return MaterialApp(
    home: Directionality(
      textDirection: direction,
      child: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}

void main() {
  group('SmartUrlValidation', () {
    const valid = [
      'https://example.com',
      'HTTPS://EXAMPLE.com',
      'http://example.com/path/to/page',
      'https://www.example.com/search?q=hello%20world&sort=asc#results',
      'https://example.com:8443/path',
      'http://localhost:3000',
      'http://intranet',
      'http://192.168.1.10:8080',
      'http://[::1]:8080/',
      'http://[2001:db8::1]/',
      'https://example.com/path/%E2%9C%93?x=1&y=2#frag',
      'https://example.com/café/中文',
      'https://münchen.example/',
      'https://user:pass@example.com/',
      'https://example.com.',
      'https://sub-domain.example.co.uk',
    ];
    const invalid = [
      'example.com',
      'https://',
      'http://',
      'http:///example.com',
      'http://exa mple.com',
      ' https://example.com',
      'https://example.com ',
      'https://example.com/a b',
      'https://example.com/\n',
      'https://example.com/%ZZ',
      'https://example.com/%2',
      'javascript:alert(1)',
      'data:text/html,hi',
      'file:///tmp/example.txt',
      'ftp://example.com',
      'custom://example.com',
      'mailto:a@example.com',
      'https://example.com:abc',
      'https://example.com:',
      'https://example.com:99999',
      'https://999.1.1.1',
      'http://[::1',
      'http://[zzz]/',
      'https://exa..mple.com',
      'https://-bad.example.com',
      'https://exa<mple.com',
      'https://example.com/<script>',
      'https://@example.com',
      'https:/example.com',
      'https//example.com',
      '  ',
    ];

    test('accepts complete http and https URLs by default', () {
      for (final value in valid) {
        expect(SmartUrlValidation.isValid(value), isTrue, reason: value);
      }
    });

    test('rejects malformed or unsupported values by default', () {
      for (final value in invalid) {
        expect(SmartUrlValidation.isValid(value), isFalse, reason: value);
      }
    });

    test('https only policy', () {
      const schemes = {'https'};
      expect(
        SmartUrlValidation.isValid('https://a.com', allowedSchemes: schemes),
        isTrue,
      );
      expect(
        SmartUrlValidation.isValid('http://a.com', allowedSchemes: schemes),
        isFalse,
      );
    });

    test('extra schemes are opt-in and still need an authority', () {
      const schemes = {'http', 'https', 'ftp'};
      expect(
        SmartUrlValidation.isValid('ftp://a.com', allowedSchemes: schemes),
        isTrue,
      );
      expect(
        SmartUrlValidation.isValid('ftp://', allowedSchemes: schemes),
        isFalse,
      );
      expect(
        SmartUrlValidation.isValid(
          'javascript:alert(1)',
          allowedSchemes: schemes,
        ),
        isFalse,
      );
    });

    test('bare domains are opt-in', () {
      for (final value in [
        'example.com',
        'www.example.com/path?q=1#x',
        'example.com:8080',
        '192.168.0.1',
        '[::1]:80',
      ]) {
        expect(SmartUrlValidation.isValid(value), isFalse, reason: value);
        expect(
          SmartUrlValidation.isValid(value, allowBareDomain: true),
          isTrue,
          reason: value,
        );
      }
      for (final value in [
        'localhost',
        'javascript:alert(1)',
        'mailto:a@example.com',
        'user@example.com',
        '/path',
        'exa mple.com',
        'file:///tmp/a',
        'ftp://example.com',
      ]) {
        expect(
          SmartUrlValidation.isValid(value, allowBareDomain: true),
          isFalse,
          reason: value,
        );
      }
    });

    test('validator treats empty as valid and whitespace as invalid', () {
      final validator = SmartValidators.url(message: 'bad');
      expect(validator(null), isNull);
      expect(validator(''), isNull);
      expect(validator('  '), 'bad');
      expect(validator('nope'), 'bad');
      expect(validator('https://a.com'), isNull);
    });
  });

  group('SmartField.url', () {
    testWidgets('uses URL keyboard, done action, and no text transformation', (
      tester,
    ) async {
      await tester.pumpWidget(_app(SmartField.url()));
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.keyboardType, TextInputType.url);
      expect(field.textInputAction, TextInputAction.done);
      expect(field.textCapitalization, TextCapitalization.none);
      expect(field.autocorrect, isFalse);
      expect(field.enableSuggestions, isFalse);
      expect(field.maxLines, 1);
    });

    testWidgets('keeps raw text exact and never rewrites it', (tester) async {
      final controller = TextEditingController();
      final formKey = GlobalKey<FormState>();
      String? changed;
      String? saved;
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.url(
              controller: controller,
              allowBareDomain: true,
              onChanged: (value) => changed = value,
              onSaved: (value) => saved = value,
            ),
          ),
        ),
      );

      const raw = 'HTTPS://Example.COM/A%20b?Q=1&r=%7e#Frag';
      await tester.enterText(find.byType(TextFormField), raw);
      expect(controller.text, raw);
      expect(changed, raw);
      expect(formKey.currentState!.validate(), isTrue);
      formKey.currentState!.save();
      expect(saved, raw);

      await tester.enterText(find.byType(TextFormField), 'Example.com');
      expect(controller.text, 'Example.com');
      expect(formKey.currentState!.validate(), isTrue);
      formKey.currentState!.reset();
      await tester.pump();
      expect(controller.text, isEmpty);
    });

    testWidgets('partial typing stays editable and malformed paste is kept', (
      tester,
    ) async {
      final controller = TextEditingController();
      final formKey = GlobalKey<FormState>();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.url(controller: controller),
          ),
        ),
      );

      for (final value in [
        'h',
        'https:',
        'https://',
        'https://exa',
        'http://exa mple.com/%ZZ',
      ]) {
        await tester.enterText(find.byType(TextFormField), value);
        expect(controller.text, value);
      }
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Enter a valid URL.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '');
      expect(formKey.currentState!.validate(), isTrue);
    });

    testWidgets('required, whitespace, custom message, and validation order', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.url(
              controller: controller,
              isRequired: true,
              requiredErrorText: 'Required',
              urlErrorText: 'Bad URL',
              allowedSchemes: const {'https'},
              maxLength: 40,
              maxLengthErrorText: 'Too long',
              validator: (value) =>
                  value!.contains('blocked.example') ? 'Blocked' : null,
            ),
          ),
        ),
      );

      String? error() {
        formKey.currentState!.validate();
        final state = tester.state<FormFieldState<String>>(
          find.byType(TextFormField),
        );
        return state.errorText;
      }

      expect(error(), 'Required');
      controller.text = '   ';
      expect(error(), 'Required');
      controller.text = 'http://a.com';
      expect(error(), 'Bad URL');
      controller.text = 'https://${'a' * 50}.com';
      expect(error(), 'Too long');
      controller.text = 'https://blocked.example';
      expect(error(), 'Blocked');
      controller.text = 'https://a.com';
      expect(error(), isNull);
    });

    testWidgets('pastes and edits in the middle preserving the caret', (
      tester,
    ) async {
      final controller = TextEditingController(
        text: 'https://example.com/path',
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(SmartField.url(controller: controller)));
      await tester.showKeyboard(find.byType(TextFormField));

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'https://example.com/long/path',
          selection: TextSelection.collapsed(offset: 24),
        ),
      );
      await tester.pump();
      expect(controller.text, 'https://example.com/long/path');
      expect(controller.selection, const TextSelection.collapsed(offset: 24));

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'https://exa mple.com/long/path',
          selection: TextSelection.collapsed(offset: 12),
        ),
      );
      await tester.pump();
      expect(controller.text, 'https://exa mple.com/long/path');
    });

    testWidgets('does not touch IME composition', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(SmartField.url(controller: controller)));
      await tester.showKeyboard(find.byType(TextFormField));
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'https://中',
          selection: TextSelection.collapsed(offset: 9),
          composing: TextRange(start: 8, end: 9),
        ),
      );
      await tester.pump();
      expect(controller.text, 'https://中');
      expect(controller.value.composing, const TextRange(start: 8, end: 9));
    });

    testWidgets('undo and redo restore raw text', skip: kIsWeb, (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(SmartField.url(controller: controller)));
      await tester.showKeyboard(find.byType(TextFormField));
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'https://a.com',
          selection: TextSelection.collapsed(offset: 13),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'https://a.com/x',
          selection: TextSelection.collapsed(offset: 15),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();
      expect(controller.text, 'https://a.com');
    });

    testWidgets('developer input formatters are applied', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.url(
            controller: controller,
            inputFormatters: [FilteringTextInputFormatter.deny(' ')],
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'https://a b.com');
      expect(controller.text, 'https://ab.com');
    });

    testWidgets('autovalidate on user interaction and read-only/disabled', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              SmartField.url(
                controller: controller,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              SmartField.url(enabled: false),
              SmartField.url(readOnly: true),
            ],
          ),
        ),
      );
      expect(find.text('Enter a valid URL.'), findsNothing);
      await tester.enterText(find.byType(TextFormField).first, 'nope');
      await tester.pump();
      expect(find.text('Enter a valid URL.'), findsOneWidget);
      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(fields[1].enabled, isFalse);
      expect(fields[2].readOnly, isTrue);
    });

    testWidgets('keeps developer controller and focus node owned by parent', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'https://a.com');
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        _app(SmartField.url(controller: controller, focusNode: focusNode)),
      );
      await tester.pumpWidget(_app(const SizedBox()));
      controller.text = 'https://b.com';
      focusNode.requestFocus();
      expect(controller.text, 'https://b.com');
    });

    testWidgets(
      'layout survives dark theme, RTL, narrow width, long text, and scale',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: Brightness.dark),
            home: MediaQuery(
              data: const MediaQueryData(
                textScaler: TextScaler.linear(2),
                size: Size(180, 600),
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  body: SmartField.url(
                    label:
                        'A very long website label that should wrap or ellipsize',
                    decoration: const InputDecoration(
                      suffixIcon: Icon(Icons.link),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.enterText(
          find.byType(TextFormField),
          'https://example.com/${'long/' * 60}',
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.byIcon(Icons.link), findsOneWidget);
      },
    );

    testWidgets('exposes label to semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(SmartField.url(label: 'Website')));
      expect(find.bySemanticsLabel(RegExp('Website')), findsWidgets);
      handle.dispose();
    });
  });
}
