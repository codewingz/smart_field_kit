import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('accepts unrestricted normal text and empty input', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(SmartField(controller: controller)));

    const value = 'Ayesha Khan 123 !@# اردو 中文 😀';
    await tester.enterText(find.byType(TextFormField), value);
    expect(controller.text, value);

    await tester.enterText(find.byType(TextFormField), '');
    expect(controller.text, isEmpty);
  });

  testWidgets('exposes labels hints decoration and keyboard options', (
    tester,
  ) async {
    const decoration = InputDecoration(prefixText: 'Prefix ');

    await tester.pumpWidget(
      _app(
        const SmartField(
          label: 'Full Name',
          hintText: 'Enter your name',
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          decoration: decoration,
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration!.labelText, 'Full Name');
    expect(field.decoration!.hintText, 'Enter your name');
    expect(field.decoration!.prefixText, 'Prefix ');
    expect(field.keyboardType, TextInputType.name);
    expect(field.textInputAction, TextInputAction.next);
  });

  testWidgets('preserves decoration label and hint values', (tester) async {
    await tester.pumpWidget(
      _app(
        const SmartField(
          label: 'Shortcut label',
          hintText: 'Shortcut hint',
          decoration: InputDecoration(
            labelText: 'Decoration label',
            hintText: 'Decoration hint',
          ),
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration!.labelText, 'Decoration label');
    expect(field.decoration!.hintText, 'Decoration hint');
  });

  testWidgets('uses the ambient input decoration theme', (tester) async {
    const fillColor = Color(0xFF123456);
    final theme = ThemeData(
      useMaterial3: true,
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: fillColor,
      ),
    );

    await tester.pumpWidget(_app(const SmartField(), theme: theme));

    final decorator = tester.widget<InputDecorator>(
      find.byType(InputDecorator),
    );
    expect(decorator.decoration.filled, isTrue);
    expect(decorator.decoration.fillColor, fillColor);
  });

  testWidgets('forwards change and save callbacks', (tester) async {
    final formKey = GlobalKey<FormState>();
    String? changedValue;
    String? savedValue;

    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField(
            onChanged: (value) => changedValue = value,
            onSaved: (value) => savedValue = value,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'Saved value');
    formKey.currentState!.save();

    expect(changedValue, 'Saved value');
    expect(savedValue, 'Saved value');
  });

  testWidgets('uses a custom validator with Form validation', (tester) async {
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField(
            validator: (value) => value == 'valid' ? null : 'Invalid value',
          ),
        ),
      ),
    );

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Invalid value'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'valid');
    expect(formKey.currentState!.validate(), isTrue);
    await tester.pump();
    expect(find.text('Invalid value'), findsNothing);
  });

  testWidgets('allows empty input without a validator', (tester) async {
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      _app(Form(key: formKey, child: const SmartField())),
    );

    expect(formKey.currentState!.validate(), isTrue);
  });

  testWidgets('uses externally owned controller and focus node', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Initial value');
    final focusNode = FocusNode();

    await tester.pumpWidget(
      _app(SmartField(controller: controller, focusNode: focusNode)),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller, same(controller));
    expect(field.focusNode, same(focusNode));
    expect(find.text('Initial value'), findsOneWidget);

    focusNode.requestFocus();
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.pumpWidget(_app(const SizedBox.shrink()));
    controller.text = 'Still usable';
    focusNode.requestFocus();
    expect(controller.text, 'Still usable');

    controller.dispose();
    focusNode.dispose();
  });

  testWidgets('forwards enabled and readOnly states', (tester) async {
    await tester.pumpWidget(
      _app(
        const Column(
          children: [SmartField(enabled: false), SmartField(readOnly: true)],
        ),
      ),
    );

    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields.first.enabled, isFalse);
    expect(fields.last.readOnly, isTrue);
  });

  testWidgets('mounts and disposes without an external controller', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const SmartField()));
    expect(find.byType(TextFormField), findsOneWidget);

    await tester.pumpWidget(_app(const SizedBox.shrink()));
    expect(tester.takeException(), isNull);
  });
}
