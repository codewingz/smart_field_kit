import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child, {TextDirection textDirection = TextDirection.ltr}) {
  return MaterialApp(
    home: Directionality(
      textDirection: textDirection,
      child: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}

void main() {
  testWidgets('uses native single-line search defaults and preserves text', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(SmartField.search(controller: controller)));

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.keyboardType, TextInputType.text);
    expect(field.textInputAction, TextInputAction.search);
    expect(field.maxLines, 1);
    expect(field.minLines, isNull);
    expect(find.byIcon(Icons.search), findsOneWidget);

    const value = "  اردو العربية café 🙂 <tag> SELECT *  ";
    await tester.enterText(find.byType(TextFormField), value);
    expect(controller.text, value);
  });

  testWidgets('keeps search optional and shared validation opt-in', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField.search(
            controller: controller,
            isRequired: true,
            requiredErrorText: 'Required',
            minLength: 3,
            minLengthErrorText: 'Too short',
            validator: (value) => value == 'valid' ? null : 'Custom',
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
    expect(find.text('Too short'), findsOneWidget);
    controller.text = 'valid';
    expect(formKey.currentState!.validate(), isTrue);
  });

  testWidgets('delivers immediate changes and debounced searches', (
    tester,
  ) async {
    final changes = <String>[];
    final searches = <String>[];
    await tester.pumpWidget(
      _app(SmartField.search(onChanged: changes.add, onSearch: searches.add)),
    );

    await tester.enterText(find.byType(TextFormField), 'one');
    expect(changes, ['one']);
    await tester.pump(const Duration(milliseconds: 299));
    expect(searches, isEmpty);
    await tester.enterText(find.byType(TextFormField), 'two');
    await tester.pump(const Duration(milliseconds: 300));
    expect(searches, ['two']);
  });

  testWidgets('supports immediate search and ignores blank search events', (
    tester,
  ) async {
    final searches = <String>[];
    await tester.pumpWidget(
      _app(
        SmartField.search(
          debounceDuration: Duration.zero,
          onSearch: searches.add,
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), '  ');
    expect(searches, isEmpty);
    await tester.enterText(find.byType(TextFormField), ' q ');
    expect(searches, [' q ']);
  });

  testWidgets('submit cancels debounce without triggering another search', (
    tester,
  ) async {
    final searches = <String>[];
    final submitted = <String>[];
    await tester.pumpWidget(
      _app(
        SmartField.search(onSearch: searches.add, onSubmitted: submitted.add),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'query');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(submitted, ['query']);
    expect(searches, isEmpty);
  });

  testWidgets(
    'clear sends one changed and cleared event and cancels debounce',
    (tester) async {
      final controller = TextEditingController();
      final changes = <String>[];
      final searches = <String>[];
      var clears = 0;
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.search(
            controller: controller,
            onChanged: changes.add,
            onSearch: searches.add,
            onCleared: () => clears++,
          ),
        ),
      );

      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'query');
      await tester.pump();
      expect(find.byTooltip('Clear search'), findsOneWidget);
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(controller.text, isEmpty);
      expect(changes, ['query', '']);
      expect(clears, 1);
      expect(searches, isEmpty);
    },
  );

  testWidgets('programmatic updates update UI without search callbacks', (
    tester,
  ) async {
    final controller = TextEditingController();
    final changes = <String>[];
    final searches = <String>[];
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        SmartField.search(
          controller: controller,
          onChanged: changes.add,
          onSearch: searches.add,
        ),
      ),
    );

    controller.text = 'external';
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('external'), findsOneWidget);
    expect(changes, isEmpty);
    expect(searches, isEmpty);
  });

  testWidgets('form reset and controller replacement cancel pending searches', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final firstController = TextEditingController();
    final secondController = TextEditingController();
    final searches = <String>[];
    var useSecond = false;
    late StateSetter rebuild;
    addTearDown(firstController.dispose);
    addTearDown(secondController.dispose);
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return Form(
              key: formKey,
              child: SmartField.search(
                controller: useSecond ? secondController : firstController,
                onSearch: searches.add,
              ),
            );
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'first');
    rebuild(() => useSecond = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(searches, isEmpty);

    await tester.enterText(find.byType(TextFormField), 'second');
    formKey.currentState!.reset();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(searches, isEmpty);
  });

  testWidgets('backspace to empty does not report a clear-button action', (
    tester,
  ) async {
    var clears = 0;
    final changes = <String>[];
    await tester.pumpWidget(
      _app(
        SmartField.search(onChanged: changes.add, onCleared: () => clears++),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'x');
    await tester.enterText(find.byType(TextFormField), '');
    expect(changes, ['x', '']);
    expect(clears, 0);
  });

  testWidgets('loading clear customization and interactive states are native', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'query');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        SmartField.search(
          controller: controller,
          isLoading: true,
          searchIcon: const Icon(Icons.travel_explore),
        ),
        textDirection: TextDirection.rtl,
      ),
    );

    expect(find.byIcon(Icons.travel_explore), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byTooltip('Clear search'), findsOneWidget);
    await tester.pumpWidget(
      _app(SmartField.search(controller: controller, readOnly: true)),
    );
    expect(find.byTooltip('Clear search'), findsNothing);
  });

  testWidgets(
    'external controller focus and selection remain owned by parent',
    (tester) async {
      final controller = TextEditingController(text: 'middle');
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        _app(SmartField.search(controller: controller, focusNode: focusNode)),
      );

      await tester.tap(find.byType(TextFormField));
      controller.selection = const TextSelection(
        baseOffset: 1,
        extentOffset: 4,
      );
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);
      expect(
        controller.selection,
        const TextSelection(baseOffset: 1, extentOffset: 4),
      );
    },
  );

  testWidgets('disposing cancels a pending search timer', (tester) async {
    final searches = <String>[];
    await tester.pumpWidget(_app(SmartField.search(onSearch: searches.add)));
    await tester.enterText(find.byType(TextFormField), 'query');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 400));
    expect(searches, isEmpty);
  });
}
