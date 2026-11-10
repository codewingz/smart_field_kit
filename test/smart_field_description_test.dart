import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

void main() {
  testWidgets('uses native multiline defaults without restricting free text', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(SmartField.description(controller: controller)),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.minLines, 3);
    expect(field.maxLines, isNull);
    expect(field.expands, isFalse);
    expect(field.keyboardType, TextInputType.multiline);
    expect(field.textInputAction, TextInputAction.newline);
    expect(field.textCapitalization, TextCapitalization.none);
    expect(field.autofocus, isFalse);

    const value = "  مرحبا\n説明 🙂 ' <tag> SELECT *  ";
    await tester.enterText(find.byType(TextFormField), value);
    expect(controller.text, value);
  });

  testWidgets('keeps descriptions optional with no default length rule', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField.description(controller: controller),
        ),
      ),
    );

    for (final value in ['', 'a', 'ab', '🙂']) {
      controller.text = value;
      expect(formKey.currentState!.validate(), isTrue, reason: value);
    }
  });

  testWidgets('validates required preset length and custom rules in order', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField.description(
            controller: controller,
            isRequired: true,
            requiredErrorText: 'Required',
            validationPreset: SmartTextValidationPreset.description,
            validationPresetErrorText: 'Legacy',
            minLength: 4,
            minLengthErrorText: 'Length',
            validator: (_) => 'Custom',
          ),
        ),
      ),
    );

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Required'), findsOneWidget);

    controller.text = 'ab';
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Legacy'), findsOneWidget);

    controller.text = 'abc';
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Length'), findsOneWidget);

    controller.text = 'abcd';
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Custom'), findsOneWidget);
  });

  testWidgets('required validation rejects whitespace without rewriting it', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: ' \n  ');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField.description(
            controller: controller,
            isRequired: true,
          ),
        ),
      ),
    );

    expect(formKey.currentState!.validate(), isFalse);
    expect(controller.text, ' \n  ');
  });

  testWidgets('supports both legacy presets through the shared text API', (
    tester,
  ) async {
    final descriptionKey = GlobalKey<FormState>();
    final textKey = GlobalKey<FormState>();
    final descriptionController = TextEditingController(text: 'a\nbc');
    final textController = TextEditingController(text: 'ab');
    addTearDown(descriptionController.dispose);
    addTearDown(textController.dispose);
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            Form(
              key: descriptionKey,
              child: SmartField.description(
                controller: descriptionController,
                validationPreset: SmartTextValidationPreset.description,
              ),
            ),
            Form(
              key: textKey,
              child: SmartField.text(
                controller: textController,
                validationPreset: SmartTextValidationPreset.formfield,
              ),
            ),
          ],
        ),
      ),
    );

    expect(descriptionKey.currentState!.validate(), isFalse);
    expect(textKey.currentState!.validate(), isFalse);
    descriptionController.text = 'abc';
    textController.text = 'abc';
    expect(descriptionKey.currentState!.validate(), isTrue);
    expect(textKey.currentState!.validate(), isTrue);
  });

  testWidgets('enters edits replaces and deletes multiline text natively', (
    tester,
  ) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    final changes = <String>[];
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      _app(
        SmartField.description(
          controller: controller,
          focusNode: focusNode,
          onChanged: changes.add,
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField));
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'first\nsecond',
        selection: TextSelection.collapsed(offset: 12),
      ),
    );
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'first second',
        selection: TextSelection.collapsed(offset: 5),
      ),
    );
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'first new second',
        selection: TextSelection.collapsed(offset: 9),
      ),
    );
    await tester.pump();

    expect(focusNode.hasFocus, isTrue);
    expect(controller.text, 'first new second');
    expect(controller.selection, const TextSelection.collapsed(offset: 9));
    expect(changes, ['first\nsecond', 'first second', 'first new second']);
  });

  testWidgets('preserves composing text and supports optional formatters', (
    tester,
  ) async {
    final composingController = TextEditingController();
    final filteredController = TextEditingController();
    addTearDown(composingController.dispose);
    addTearDown(filteredController.dispose);
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            SmartField.description(controller: composingController),
            SmartField.description(
              controller: filteredController,
              inputFormatters: [FilteringTextInputFormatter.deny(RegExp('x'))],
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField).first);
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'に',
        selection: TextSelection.collapsed(offset: 1),
        composing: TextRange(start: 0, end: 1),
      ),
    );
    expect(
      composingController.value.composing,
      const TextRange(start: 0, end: 1),
    );

    await tester.enterText(find.byType(TextFormField).last, 'text\nnext');
    expect(filteredController.text, 'tet\nnet');
  });

  testWidgets('integrates callbacks autovalidation Form save and reset', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: 'initial\nvalue');
    String? saved;
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField.description(
            controller: controller,
            isRequired: true,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onSaved: (value) => saved = value,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'changed\nparagraph');
    formKey.currentState!.save();
    expect(saved, 'changed\nparagraph');
    formKey.currentState!.reset();
    await tester.pump();
    expect(controller.text, 'initial\nvalue');
  });

  testWidgets('starts at three lines and grows and shrinks with newlines', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SmartField.description(
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ),
    );
    final finder = find.byType(TextFormField);
    final initialHeight = tester.getSize(finder).height;

    await tester.enterText(finder, '1\n2\n3\n4');
    await tester.pump();
    final fourthLineHeight = tester.getSize(finder).height;
    expect(fourthLineHeight, greaterThan(initialHeight));

    await tester.enterText(finder, '1\n2\n3\n4\n5');
    await tester.pump();
    expect(tester.getSize(finder).height, greaterThan(fourthLineHeight));

    await tester.enterText(finder, 'short');
    await tester.pump();
    expect(tester.getSize(finder).height, initialHeight);
  });

  testWidgets('grows for soft wrapping paragraph paste and long words', (
    tester,
  ) async {
    await tester.pumpWidget(_app(SmartField.description(), width: 180));
    final finder = find.byType(TextFormField);
    final initialHeight = tester.getSize(finder).height;

    await tester.enterText(finder, List.filled(40, 'wrapped').join(' '));
    await tester.pump();
    final wrappedHeight = tester.getSize(finder).height;
    expect(wrappedHeight, greaterThan(initialHeight));

    await tester.enterText(
      finder,
      'first paragraph\n\nsecond paragraph\nthird',
    );
    await tester.pump();
    expect(tester.getSize(finder).height, greaterThan(initialHeight));

    await tester.enterText(
      finder,
      'https://${List.filled(30, 'segment').join()}',
    );
    await tester.pump();
    expect(tester.getSize(finder).height, greaterThan(initialHeight));
  });

  testWidgets('caps at maxLines and scrolls without losing content', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        SmartField.description(
          controller: controller,
          minLines: 3,
          maxLines: 8,
        ),
      ),
    );
    final finder = find.byType(TextFormField);
    await tester.enterText(finder, _lines(8));
    await tester.pump();
    final eightLineHeight = tester.getSize(finder).height;
    await tester.enterText(finder, _lines(12));
    await tester.pump();

    expect(tester.getSize(finder).height, eightLineHeight);
    expect(controller.text, _lines(12));
  });

  testWidgets('continues growing beyond eight lines when uncapped', (
    tester,
  ) async {
    await tester.pumpWidget(_app(SmartField.description()));
    final finder = find.byType(TextFormField);
    await tester.enterText(finder, _lines(8));
    await tester.pump();
    final eightLineHeight = tester.getSize(finder).height;
    await tester.enterText(finder, _lines(12));
    await tester.pump();

    expect(tester.getSize(finder).height, greaterThan(eightLineHeight));
  });

  testWidgets('respects bounded parents and explicit expands behavior', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SizedBox(
          height: 180,
          child: SmartField.description(
            minLines: null,
            maxLines: null,
            expands: true,
          ),
        ),
      ),
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.expands, isTrue);
    expect(tester.getSize(find.byType(TextFormField)).height, 180);
    expect(tester.takeException(), isNull);
  });

  testWidgets('respects an explicit fixed-height parent without losing text', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        SizedBox(
          height: 150,
          child: SmartField.description(controller: controller),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), _lines(12));
    await tester.pump();
    expect(tester.getSize(find.byType(TextFormField)).height, 150);
    expect(controller.text, _lines(12));
    expect(tester.takeException(), isNull);
  });

  testWidgets('rejects incompatible line configurations clearly', (
    tester,
  ) async {
    expect(() => SmartField.description(minLines: 0), throwsAssertionError);
    expect(
      () => SmartField.description(minLines: 4, maxLines: 3),
      throwsAssertionError,
    );
    expect(() => SmartField.description(expands: true), throwsAssertionError);
    expect(
      () =>
          SmartField.description(minLines: null, maxLines: null, expands: true),
      returnsNormally,
    );
  });

  testWidgets('keeps existing constructors single line by default', (
    tester,
  ) async {
    final fields = <Widget>[
      const SmartField(),
      SmartField.text(),
      SmartField.name(),
      SmartField.username(),
      SmartField.email(),
      SmartField.password(),
      SmartField.number(),
      SmartField.amount(),
      SmartField.phone(),
    ];
    await tester.pumpWidget(_app(ListView(children: fields)));

    for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
      expect(field.maxLines, 1);
      expect(field.expands, isFalse);
    }
  });

  testWidgets('supports themes RTL text scaling errors and constrained width', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 180,
                  child: Form(
                    key: formKey,
                    child: SmartField.description(
                      label: 'تفاصيل',
                      isRequired: true,
                      decoration: const InputDecoration(
                        helperText: 'مساعدة طويلة تبقى مرئية',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('مساعدة طويلة تبقى مرئية'), findsOneWidget);
    expect(find.text('This field is required.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('responds to width and dynamic font changes', (tester) async {
    final controller = TextEditingController(
      text: List.filled(8, 'responsive content').join(' '),
    );
    var width = 320.0;
    var fontSize = 14.0;
    late StateSetter setState;
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setter) {
            setState = setter;
            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: width,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    textTheme: Theme.of(
                      context,
                    ).textTheme.apply(fontSizeFactor: fontSize / 14),
                  ),
                  child: SmartField.description(controller: controller),
                ),
              ),
            );
          },
        ),
        width: 400,
      ),
    );
    final finder = find.byType(TextFormField);
    final wideHeight = tester.getSize(finder).height;

    setState(() => width = 160);
    await tester.pump();
    final narrowHeight = tester.getSize(finder).height;
    expect(narrowHeight, greaterThan(wideHeight));

    setState(() => fontSize = 24);
    await tester.pump();
    expect(tester.getSize(finder).height, greaterThanOrEqualTo(narrowHeight));
    expect(controller.text, isNotEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('participates in native keyboard focus traversal', (
    tester,
  ) async {
    final firstFocus = FocusNode();
    final secondFocus = FocusNode();
    addTearDown(firstFocus.dispose);
    addTearDown(secondFocus.dispose);
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            SmartField.description(
              focusNode: firstFocus,
              autofocus: true,
              maxLines: 3,
            ),
            SmartField.description(focusNode: secondFocus, maxLines: 3),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(firstFocus.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(secondFocus.hasFocus, isTrue);
  });

  testWidgets(
    'preserves external ownership read-only disabled and long paste',
    (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              SmartField.description(
                controller: controller,
                focusNode: focusNode,
                readOnly: true,
                maxLines: 5,
              ),
              SmartField.description(enabled: false),
            ],
          ),
        ),
      );

      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(fields.first.readOnly, isTrue);
      expect(fields.last.enabled, isFalse);
      controller.text = List.filled(500, 'paragraph content').join('\n');
      await tester.pump();
      await tester.pumpWidget(_app(const SizedBox()));
      expect(controller.text, isNotEmpty);
      expect(focusNode.requestFocus, returnsNormally);
    },
  );
}

Widget _app(Widget child, {double width = 360}) {
  return MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(width: width, child: child),
      ),
    ),
  );
}

String _lines(int count) {
  return List.generate(count, (index) => 'line ${index + 1}').join('\n');
}
