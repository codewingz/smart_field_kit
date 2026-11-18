import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme,
    home: Scaffold(body: child),
  );
}

void main() {
  group('SmartField.name', () {
    testWidgets(
      'uses name keyboard hints without changing international text',
      (tester) async {
        final controller = TextEditingController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          _app(SmartField.name(label: 'Full name', controller: controller)),
        );

        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.keyboardType, TextInputType.name);
        expect(field.textCapitalization, TextCapitalization.words);
        expect(field.autocorrect, isTrue);
        expect(field.enableSuggestions, isTrue);
        expect(field.autofillHints, contains(AutofillHints.name));

        for (final value in [
          'José Álvarez',
          'Zoë Smith',
          '李 小龍',
          'محمد علي',
          "O'Connor-Smith",
          'Zoe\u0308',
          'Alex 😀',
        ]) {
          await tester.enterText(find.byType(TextFormField), value);
          expect(controller.text, value);
        }
      },
    );

    testWidgets('has no default length restriction and counts graphemes', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController(text: 'o\u0308');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.name(
              controller: controller,
              minLength: 1,
              maxLength: 1,
            ),
          ),
        ),
      );

      expect(formKey.currentState!.validate(), isTrue);
      controller.text = List.filled(500, '名').join();
      await tester.pump();
      expect(controller.text.length, 500);
    });

    testWidgets('required whitespace fails without changing controller text', (
      tester,
    ) async {
      final optionalKey = GlobalKey<FormState>();
      final requiredKey = GlobalKey<FormState>();
      final optionalController = TextEditingController(text: '   ');
      final requiredController = TextEditingController(text: '   ');
      addTearDown(optionalController.dispose);
      addTearDown(requiredController.dispose);

      await tester.pumpWidget(
        _app(
          Column(
            children: [
              Form(
                key: optionalKey,
                child: SmartField.name(controller: optionalController),
              ),
              Form(
                key: requiredKey,
                child: SmartField.name(
                  controller: requiredController,
                  isRequired: true,
                ),
              ),
            ],
          ),
        ),
      );

      expect(optionalKey.currentState!.validate(), isTrue);
      expect(requiredKey.currentState!.validate(), isFalse);
      expect(optionalController.text, '   ');
      expect(requiredController.text, '   ');
    });

    testWidgets('legacy street preset is opt-in and does not filter text', (
      tester,
    ) async {
      final modernKey = GlobalKey<FormState>();
      final legacyKey = GlobalKey<FormState>();
      final modernController = TextEditingController(text: "José O'Neil-Smith");
      final legacyController = TextEditingController(text: 'John Doe');
      addTearDown(modernController.dispose);
      addTearDown(legacyController.dispose);

      await tester.pumpWidget(
        _app(
          Column(
            children: [
              Form(
                key: modernKey,
                child: SmartField.name(controller: modernController),
              ),
              Form(
                key: legacyKey,
                child: SmartField.name(
                  controller: legacyController,
                  validationPreset: SmartTextValidationPreset.streetName,
                ),
              ),
            ],
          ),
        ),
      );

      expect(modernKey.currentState!.validate(), isTrue);
      expect(legacyKey.currentState!.validate(), isFalse);
      expect(modernController.text, "José O'Neil-Smith");
      expect(legacyController.text, 'John Doe');
    });
  });

  group('SmartField.username', () {
    testWidgets('preserves case punctuation Unicode and short values', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.username(controller: controller),
          ),
        ),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.keyboardType, TextInputType.text);
      expect(field.textCapitalization, TextCapitalization.none);
      expect(field.autocorrect, isFalse);
      expect(field.enableSuggestions, isFalse);
      expect(field.autofillHints, contains(AutofillHints.username));

      for (final value in ['A', 'User_Name.42', '用户', 'User🙂']) {
        await tester.enterText(find.byType(TextFormField), value);
        expect(controller.text, value);
        expect(formKey.currentState!.validate(), isTrue);
      }
    });

    testWidgets('legacy preset validates without filtering partial typing', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.username(
              controller: controller,
              validationPreset: SmartTextValidationPreset.loginUsername,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'abcd');
      expect(controller.text, 'abcd');
      expect(formKey.currentState!.validate(), isFalse);
      await tester.enterText(find.byType(TextFormField), 'abcde');
      expect(controller.text, 'abcde');
      expect(formKey.currentState!.validate(), isTrue);
      await tester.enterText(find.byType(TextFormField), 'John Doe');
      expect(controller.text, 'John Doe');
      expect(formKey.currentState!.validate(), isFalse);
    });

    testWidgets('validation order is required preset length then custom', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      var customCalls = 0;

      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.username(
              controller: controller,
              isRequired: true,
              requiredErrorText: 'Required error',
              validationPreset: SmartTextValidationPreset.loginUsername,
              validationPresetErrorText: 'Preset error',
              minLength: 6,
              minLengthErrorText: 'Length error',
              validator: (value) {
                customCalls++;
                return value == 'abcdef' ? null : 'Custom error';
              },
            ),
          ),
        ),
      );

      expect(formKey.currentState!.validate(), isFalse);
      expect(customCalls, 0);

      controller.text = 'a b';
      expect(formKey.currentState!.validate(), isFalse);
      expect(customCalls, 0);

      controller.text = 'abcde';
      expect(formKey.currentState!.validate(), isFalse);
      expect(customCalls, 0);

      controller.text = 'abcdeg';
      expect(formKey.currentState!.validate(), isFalse);
      expect(customCalls, 1);

      controller.text = 'abcdef';
      expect(formKey.currentState!.validate(), isTrue);
      expect(customCalls, 2);
    });

    testWidgets('supports preset switching without changing text', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController(text: 'abc');
      addTearDown(controller.dispose);
      var preset = SmartTextValidationPreset.loginUsername;
      late StateSetter rebuild;

      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return Form(
                key: formKey,
                child: SmartField.username(
                  controller: controller,
                  validationPreset: preset,
                ),
              );
            },
          ),
        ),
      );

      expect(formKey.currentState!.validate(), isFalse);
      rebuild(() => preset = SmartTextValidationPreset.beneficiaryNickname);
      await tester.pump();
      expect(controller.text, 'abc');
      expect(formKey.currentState!.validate(), isTrue);
    });

    testWidgets('supports explicit developer input formatters', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _app(
          SmartField.username(
            controller: controller,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[a-z]')),
            ],
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'abc123XYZ');
      expect(controller.text, 'abc');
    });
  });

  testWidgets('preserves callbacks controller focus selection paste and save', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: 'AlphaBeta');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    String? changed;
    String? saved;

    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField.username(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            onChanged: (value) => changed = value,
            onSaved: (value) => saved = value,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    controller.value = const TextEditingValue(
      text: 'Alpha-Beta',
      selection: TextSelection.collapsed(offset: 6),
    );
    await tester.pump();
    expect(controller.selection.baseOffset, 6);

    await tester.enterText(find.byType(TextFormField), 'Pasted_User-42');
    formKey.currentState!.save();
    expect(controller.text, 'Pasted_User-42');
    expect(changed, 'Pasted_User-42');
    expect(saved, 'Pasted_User-42');
    formKey.currentState!.reset();
    await tester.pump();
    expect(controller.text, 'AlphaBeta');
  });

  testWidgets('inherits themes and exposes enabled read-only semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _app(
        Column(
          children: [
            SmartField.name(label: 'Full name', readOnly: true),
            SmartField.username(label: 'Username', enabled: false),
          ],
        ),
        theme: ThemeData.dark(useMaterial3: true),
      ),
    );

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields.first.readOnly, isTrue);
    expect(fields.last.enabled, isFalse);
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Full name')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Username')), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('mounts and disposes both constructors without controllers', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(Column(children: [SmartField.name(), SmartField.username()])),
    );
    await tester.enterText(find.byType(TextFormField).first, 'Renée');
    await tester.enterText(find.byType(TextFormField).last, 'User.Name');
    await tester.pumpWidget(_app(const SizedBox()));
    expect(tester.takeException(), isNull);
  });
}
