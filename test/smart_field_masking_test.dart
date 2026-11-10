import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(
  Widget child, {
  ThemeData? theme,
  TextDirection direction = TextDirection.ltr,
  double textScaleFactor = 1,
  double width = 800,
}) {
  return MaterialApp(
    theme: theme,
    home: Directionality(
      textDirection: direction,
      child: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 800),
          textScaler: TextScaler.linear(textScaleFactor),
        ),
        child: Scaffold(
          body: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
}

TextField _textField(WidgetTester tester) {
  return tester.widget<TextField>(find.byType(TextField));
}

void main() {
  testWidgets('masking is disabled by default for supported fields', (
    tester,
  ) async {
    final phone = TextEditingController(text: '03001234567');
    final number = TextEditingController(text: '00012345');
    final amount = TextEditingController(text: '12345.67');
    addTearDown(phone.dispose);
    addTearDown(number.dispose);
    addTearDown(amount.dispose);

    await tester.pumpWidget(
      _app(
        Column(
          children: [
            SmartField.phone(controller: phone),
            SmartField.number(controller: number),
            SmartField.amount(controller: amount),
          ],
        ),
      ),
    );

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields[0].decoration?.prefixText, isNull);
    expect(fields[1].decoration?.prefixText, isNull);
    expect(fields[2].decoration?.prefixText, isNull);
    expect(phone.text, '03001234567');
    expect(number.text, '00012345');
    expect(amount.text, '12345.67');
  });

  testWidgets('masked number reveals for editing without changing raw data', (
    tester,
  ) async {
    final controller = TextEditingController.fromValue(
      const TextEditingValue(
        text: '0012345678',
        selection: TextSelection.collapsed(offset: 3),
      ),
    );
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      _app(
        SmartField.number(
          controller: controller,
          focusNode: focusNode,
          mask: true,
        ),
      ),
    );

    var field = _textField(tester);
    expect(field.decoration?.prefixText, '******5678');
    expect(field.style?.color, Colors.transparent);
    expect(field.enableInteractiveSelection, isFalse);
    expect(field.showCursor, isFalse);
    expect(controller.text, '0012345678');
    expect(controller.selection, const TextSelection.collapsed(offset: 3));

    await tester.tap(find.byType(TextFormField));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);
    field = _textField(tester);
    expect(field.decoration?.prefixText, isNull);
    expect(field.enableInteractiveSelection, isTrue);
    expect(controller.text, '0012345678');
    await tester.showKeyboard(find.byType(TextFormField));
    controller.selection = const TextSelection.collapsed(offset: 2);
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '00912345678',
        selection: TextSelection.collapsed(offset: 3),
      ),
    );
    await tester.pump();
    expect(controller.text, '00912345678');
    expect(controller.selection, const TextSelection.collapsed(offset: 3));

    focusNode.unfocus();
    await tester.pump();
    field = _textField(tester);
    expect(field.decoration?.prefixText, '*******5678');
    expect(controller.text, '00912345678');
    expect(controller.selection, const TextSelection.collapsed(offset: 3));
  });

  testWidgets('masked values keep callbacks validators and Form saves raw', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    final focusNode = FocusNode();
    final changes = <String>[];
    String? validated;
    String? saved;
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField.number(
            controller: controller,
            focusNode: focusNode,
            mask: true,
            onChanged: changes.add,
            onSaved: (value) => saved = value,
            validator: (value) {
              validated = value;
              return null;
            },
          ),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();
    await tester.enterText(find.byType(TextFormField), '00012345');
    focusNode.unfocus();
    await tester.pump();
    expect(formKey.currentState!.validate(), isTrue);
    formKey.currentState!.save();
    expect(changes, ['00012345']);
    expect(validated, '00012345');
    expect(saved, '00012345');
    expect(controller.text, '00012345');
    expect(_textField(tester).decoration?.prefixText, '****2345');
  });

  testWidgets('programmatic updates reset and rebuild without callbacks', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final first = TextEditingController(text: '1111122222');
    final second = TextEditingController(text: '3333344444');
    final changes = <String>[];
    var useSecond = false;
    var suffix = 4;
    late StateSetter update;
    addTearDown(first.dispose);
    addTearDown(second.dispose);

    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return Form(
              key: formKey,
              child: SmartField.number(
                controller: useSecond ? second : first,
                mask: true,
                maskVisibleSuffixDigits: suffix,
                onChanged: changes.add,
              ),
            );
          },
        ),
      ),
    );

    expect(_textField(tester).decoration?.prefixText, '******2222');
    first.text = '5555566666';
    await tester.pump();
    expect(_textField(tester).decoration?.prefixText, '******6666');
    expect(changes, isEmpty);

    first.clear();
    await tester.pump();
    expect(_textField(tester).decoration?.prefixText, isNull);
    expect(changes, isEmpty);
    first.text = '5555566666';
    await tester.pump();

    update(() {
      useSecond = true;
      suffix = 2;
    });
    await tester.pump();
    expect(_textField(tester).decoration?.prefixText, '********44');
    expect(first.text, '5555566666');
    expect(second.text, '3333344444');

    formKey.currentState!.reset();
    await tester.pump();
    expect(second.text, '3333344444');
    expect(_textField(tester).decoration?.prefixText, '********44');
    expect(changes, ['3333344444']);
  });

  testWidgets('read-only disabled and non-revealing fields remain masked', (
    tester,
  ) async {
    final readOnlyFocus = FocusNode();
    final hiddenFocus = FocusNode();
    addTearDown(readOnlyFocus.dispose);
    addTearDown(hiddenFocus.dispose);

    await tester.pumpWidget(
      _app(
        Column(
          children: [
            SmartField.number(
              controller: TextEditingController(text: '12345678'),
              focusNode: readOnlyFocus,
              mask: true,
              readOnly: true,
            ),
            SmartField.number(
              controller: TextEditingController(text: '87654321'),
              mask: true,
              enabled: false,
            ),
            SmartField.number(
              controller: TextEditingController(text: '11223344'),
              focusNode: hiddenFocus,
              mask: true,
              revealMaskOnFocus: false,
            ),
          ],
        ),
      ),
    );

    readOnlyFocus.requestFocus();
    await tester.pump();
    hiddenFocus.requestFocus();
    await tester.pump();
    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields[0].decoration?.prefixText, '****5678');
    expect(fields[1].decoration?.prefixText, '****4321');
    expect(fields[2].decoration?.prefixText, '****3344');
    expect(fields[2].readOnly, isTrue);
    expect(fields[2].enableInteractiveSelection, isFalse);
  });

  testWidgets('masked semantics expose only the masked presentation', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final controller = TextEditingController(text: '03001234567');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _app(
        SmartField.phone(
          label: 'Phone number',
          controller: controller,
          mask: true,
        ),
      ),
    );

    final node = tester.getSemantics(find.bySemanticsLabel('Phone number'));
    expect(node.value, '*******4567');
    expect(find.bySemanticsLabel(RegExp('03001234567')), findsNothing);
    expect(controller.text, '03001234567');
    semantics.dispose();
  });

  testWidgets('masked phone preserves country behavior and clear callback', (
    tester,
  ) async {
    final controller = TextEditingController(text: '03001234567');
    final changes = <String>[];
    SmartPhoneValue? phoneValue;
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _app(
        SmartField.phone(
          controller: controller,
          mask: true,
          showCountryPicker: true,
          initialCountryCode: 'PK',
          showClearButton: true,
          onChanged: changes.add,
          onPhoneChanged: (value) => phoneValue = value,
        ),
      ),
    );

    expect(find.text('+92'), findsOneWidget);
    expect(_textField(tester).decoration?.prefixText, '*******4567');
    expect(controller.text, '03001234567');

    await tester.tap(find.byTooltip('Clear phone number'));
    await tester.pump();
    expect(controller.text, isEmpty);
    expect(changes, ['']);
    expect(phoneValue?.text, '');
    expect(_textField(tester).decoration?.prefixText, isNull);
    expect(find.text('+92'), findsOneWidget);
  });

  testWidgets(
    'masked contact selection preserves international raw value',
    skip: kIsWeb,
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _app(
          SmartField.phone(
            controller: controller,
            mask: true,
            showCountryPicker: true,
            showContactPicker: true,
            contactPicker: () async => '+923001234567',
          ),
        ),
      );

      await tester.tap(find.byTooltip('Select phone number from contacts'));
      await tester.pumpAndSettle();
      expect(controller.text, '+923001234567');
      expect(_textField(tester).decoration?.prefixText, '+********4567');
      expect(find.text('+92'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets('masked amount preserves display raw callbacks and precision', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: '50000.00');
    final focusNode = FocusNode();
    String? saved;
    String? rawSaved;
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField.amount(
            controller: controller,
            focusNode: focusNode,
            decimalPlaces: 2,
            useGrouping: true,
            currencySymbol: r'$',
            mask: true,
            onSaved: (value) => saved = value,
            onRawSaved: (value) => rawSaved = value,
          ),
        ),
      ),
    );

    expect(controller.text, r'$50,000.00');
    expect(_textField(tester).decoration?.prefixText, r'$**,***.**');

    focusNode.requestFocus();
    await tester.pump();
    expect(controller.text, '50000.00');
    expect(_textField(tester).decoration?.prefixText, isNull);
    controller.selection = const TextSelection.collapsed(offset: 2);

    focusNode.unfocus();
    await tester.pump();
    expect(controller.text, r'$50,000.00');
    expect(controller.selection, const TextSelection.collapsed(offset: 3));
    expect(_textField(tester).decoration?.prefixText, r'$**,***.**');
    expect(formKey.currentState!.validate(), isTrue);
    formKey.currentState!.save();
    expect(saved, r'$50,000.00');
    expect(rawSaved, '50000.00');
  });

  testWidgets('invalid amount remains private and fails normal validation', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: '5,000.oo');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField.amount(
            controller: controller,
            decimalPlaces: 2,
            useGrouping: true,
            mask: true,
          ),
        ),
      ),
    );

    expect(controller.text, '5,000.oo');
    expect(_textField(tester).decoration?.prefixText, '*,***.**');
    expect(formKey.currentState!.validate(), isFalse);
    expect(controller.text, '5,000.oo');
  });

  testWidgets('masked fields support focus traversal and native editing', (
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
            SmartField.number(
              controller: TextEditingController(text: '1111122222'),
              focusNode: firstFocus,
              mask: true,
            ),
            SmartField.number(
              controller: TextEditingController(text: '3333344444'),
              focusNode: secondFocus,
              mask: true,
            ),
          ],
        ),
      ),
    );

    firstFocus.requestFocus();
    await tester.pump();
    expect(firstFocus.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(secondFocus.hasFocus, isTrue);
    expect(firstFocus.hasFocus, isFalse);
  });

  testWidgets('masked layout respects theme RTL scaling and narrow widths', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SmartField.phone(
          label: 'Phone',
          controller: TextEditingController(text: '03001234567'),
          mask: true,
          showCountryPicker: true,
          initialCountryCode: 'PK',
          showClearButton: true,
        ),
        theme: ThemeData.dark(useMaterial3: true),
        direction: TextDirection.rtl,
        textScaleFactor: 1.8,
        width: 240,
      ),
    );

    expect(
      _textField(tester).decoration?.prefixText,
      '\u2066*******4567\u2069',
    );
    expect(find.text('+92'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('constructors reject invalid mask options consistently', () {
    expect(
      () => SmartField.phone(maskVisibleSuffixDigits: -1),
      throwsArgumentError,
    );
    expect(() => SmartField.number(maskCharacter: ''), throwsArgumentError);
    expect(() => SmartField.amount(maskCharacter: '**'), throwsArgumentError);
  });
}
