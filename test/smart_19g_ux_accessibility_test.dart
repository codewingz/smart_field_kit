import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  ThemeData? theme,
}) {
  return MaterialApp(
    theme: theme,
    home: Directionality(
      textDirection: direction,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    ),
  );
}

TextEditingValue _edit(
  TextInputFormatter formatter,
  String oldText,
  int oldCaret,
  String newText,
  int newCaret,
) {
  return formatter.formatEditUpdate(
    TextEditingValue(
      text: oldText,
      selection: TextSelection.collapsed(offset: oldCaret),
    ),
    TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCaret),
    ),
  );
}

double _caretX(WidgetTester tester, int offset) {
  final render = tester.allRenderObjects.whereType<RenderEditable>().first;
  return render.getLocalRectForCaret(TextPosition(offset: offset)).left;
}

void main() {
  group('19G right-to-left digit order', () {
    testWidgets('OTP boxes keep typed order', (tester) async {
      final controller = TextEditingController(text: '123456');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.otp(controller: controller),
          direction: TextDirection.rtl,
        ),
      );
      final positions = [
        for (final digit in ['1', '2', '3', '4', '5', '6'])
          tester.getCenter(find.text(digit)).dx,
      ];
      for (var index = 1; index < positions.length; index++) {
        expect(positions[index], greaterThan(positions[index - 1]));
      }
      expect(controller.text, '123456');
    });

    Future<void> expectLogicalOrder(
      WidgetTester tester,
      Widget field,
      int early,
      int late,
    ) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_app(field, direction: TextDirection.rtl));
      await tester.pump();
      expect(_caretX(tester, early), lessThan(_caretX(tester, late)));
      final editable = tester.widget<EditableText>(
        find.byType(EditableText).first,
      );
      expect(editable.textDirection, TextDirection.ltr);
      expect(editable.textAlign, TextAlign.right);
    }

    testWidgets('card, phone, amount, percentage and time keep typed order', (
      tester,
    ) async {
      final controllers = [
        TextEditingController(text: '4111 1111 1111 1111'),
        TextEditingController(text: '+92 300 1234567'),
        TextEditingController(text: '1234567'),
        TextEditingController(text: '-500'),
        TextEditingController(text: '-12.5'),
        TextEditingController(text: '09:30 PM'),
        TextEditingController(text: '12 345'),
      ];
      for (final controller in controllers) {
        addTearDown(controller.dispose);
      }
      await expectLogicalOrder(
        tester,
        SmartField.creditCard(numberController: controllers[0]),
        1,
        16,
      );
      await expectLogicalOrder(
        tester,
        SmartField.phone(controller: controllers[1]),
        1,
        12,
      );
      await expectLogicalOrder(
        tester,
        SmartField.amount(
          controller: controllers[2],
          useGrouping: true,
          groupingSeparator: ' ',
        ),
        1,
        8,
      );
      expect(controllers[2].text, '1 234 567');
      await expectLogicalOrder(
        tester,
        SmartField.amount(controller: controllers[3], allowNegative: true),
        0,
        3,
      );
      await expectLogicalOrder(
        tester,
        SmartField.percentage(controller: controllers[4]),
        0,
        4,
      );
      await expectLogicalOrder(
        tester,
        SmartField.time(use24Hour: false, controller: controllers[5]),
        1,
        7,
      );
      await expectLogicalOrder(
        tester,
        SmartField.number(controller: controllers[6]),
        1,
        5,
      );
    });

    testWidgets('dial code reads left to right and text fields stay ambient', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              SmartField.phone(
                showCountryPicker: true,
                initialCountryCode: 'PK',
              ),
              const SmartField(label: 'Name'),
            ],
          ),
          direction: TextDirection.rtl,
        ),
      );
      expect(
        tester.widget<Text>(find.text('+92')).textDirection,
        TextDirection.ltr,
      );
      final plain = tester.widget<EditableText>(find.byType(EditableText).last);
      expect(plain.textDirection, isNull);
      expect(plain.textAlign, TextAlign.start);
    });

    testWidgets('left-to-right layouts are unchanged', (tester) async {
      await tester.pumpWidget(_app(SmartField.amount()));
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.textAlign, TextAlign.start);
    });
  });

  group('19G accessible actions', () {
    testWidgets('password toggle is activated through semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(SmartField.password(label: 'Password')));
      final node = tester.getSemantics(find.bySemanticsLabel('Show password'));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      tester.semantics.tap(find.semantics.byLabel('Show password'));
      await tester.pump();
      expect(find.bySemanticsLabel('Hide password'), findsOneWidget);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).obscureText,
        isFalse,
      );
      handle.dispose();
    });

    testWidgets('a disabled password toggle exposes no action', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(SmartField.password(label: 'Password', enabled: false)),
      );
      final node = tester.getSemantics(find.bySemanticsLabel('Show password'));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      handle.dispose();
    });

    testWidgets('search clear is activated through semantics', (tester) async {
      final handle = tester.ensureSemantics();
      final controller = TextEditingController(text: 'query');
      addTearDown(controller.dispose);
      var cleared = 0;
      await tester.pumpWidget(
        _app(
          SmartField.search(controller: controller, onCleared: () => cleared++),
        ),
      );
      tester.semantics.tap(find.semantics.byLabel('Clear search'));
      await tester.pump();
      expect(controller.text, isEmpty);
      expect(cleared, 1);
      handle.dispose();
    });

    testWidgets('labels are announced once', (tester) async {
      final handle = tester.ensureSemantics();
      final otp = TextEditingController(text: '12');
      addTearDown(otp.dispose);
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              SmartField.otp(label: 'Code', controller: otp),
              SmartField.phone(
                showCountryPicker: true,
                initialCountryCode: 'US',
              ),
              SmartField.date(
                label: 'Birth',
                mode: SmartDateMode.dropdowns,
                initialDate: DateTime(2020, 3, 4),
              ),
            ],
          ),
        ),
      );
      final code = tester
          .getSemantics(find.byType(EditableText).first)
          .getSemanticsData();
      expect(code.label, 'Code');
      expect(
        find.bySemanticsLabel('Change country, United States, +1'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp(r'Day\nDay')), findsNothing);
      expect(find.bySemanticsLabel(RegExp(r'^Day\n4$')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('fields meet tap-target and contrast guidelines', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      for (final brightness in Brightness.values) {
        final formKey = GlobalKey<FormState>();
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          _app(
            Form(
              key: formKey,
              child: Column(
                children: [
                  SmartField.email(label: 'Email', isRequired: true),
                  SmartField.password(label: 'Password'),
                  SmartField.search(
                    label: 'Search',
                    controller: TextEditingController(text: 'abc'),
                  ),
                  SmartField.percentage(label: 'Rate', isRequired: true),
                  SmartField.otp(label: 'Code', isRequired: true),
                  SmartField.date(
                    label: 'Birth',
                    mode: SmartDateMode.dropdowns,
                    isRequired: true,
                    showClearButton: true,
                    initialDate: DateTime(2020, 3, 4),
                  ),
                  SmartField.date(label: 'Start', mode: SmartDateMode.calendar),
                ],
              ),
            ),
            theme: ThemeData(useMaterial3: true, brightness: brightness),
          ),
        );
        formKey.currentState!.validate();
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      }
      handle.dispose();
    });
  });

  group('19G OTP paste menu', () {
    testWidgets('long press offers Paste and applies clipboard digits', (
      tester,
    ) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.getData') {
            return <String, dynamic>{'text': '654321'};
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final controller = TextEditingController(text: '12');
      addTearDown(controller.dispose);
      final completed = <String>[];
      await tester.pumpWidget(
        _app(
          SmartField.otp(controller: controller, onCompleted: completed.add),
        ),
      );
      await tester.longPress(find.byType(AnimatedContainer).first);
      await tester.pumpAndSettle();
      expect(find.text('Paste'), findsOneWidget);
      await tester.tap(find.text('Paste'));
      await tester.pumpAndSettle();
      expect(controller.text, '654321');
      expect(completed, ['654321']);
    });

    testWidgets('a read-only field shows no Paste menu', (tester) async {
      await tester.pumpWidget(_app(SmartField.otp(readOnly: true)));
      await tester.longPress(find.byType(AnimatedContainer).first);
      await tester.pumpAndSettle();
      expect(find.text('Paste'), findsNothing);
    });
  });

  group('19G search debounce and phone server errors', () {
    testWidgets('moving the caret keeps the pending search', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final searches = <String>[];
      await tester.pumpWidget(
        _app(SmartField.search(controller: controller, onSearch: searches.add)),
      );
      await tester.enterText(find.byType(EditableText), 'query');
      await tester.pump(const Duration(milliseconds: 100));
      controller.selection = const TextSelection.collapsed(offset: 2);
      await tester.pump(const Duration(milliseconds: 400));
      expect(searches, ['query']);
    });

    testWidgets('a programmatic text change still cancels the search', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final searches = <String>[];
      await tester.pumpWidget(
        _app(SmartField.search(controller: controller, onSearch: searches.add)),
      );
      await tester.enterText(find.byType(EditableText), 'query');
      await tester.pump(const Duration(milliseconds: 100));
      controller.text = 'other';
      await tester.pump(const Duration(milliseconds: 400));
      expect(searches, isEmpty);
    });

    testWidgets('phone clear removes a server error and notifies once', (
      tester,
    ) async {
      final server = SmartServerError();
      final controller = TextEditingController(text: '4155552671');
      addTearDown(server.dispose);
      addTearDown(controller.dispose);
      final changes = <String>[];
      await tester.pumpWidget(
        _app(
          SmartField.phone(
            controller: controller,
            showClearButton: true,
            serverError: server,
            onChanged: changes.add,
          ),
        ),
      );
      server.set('Rejected');
      await tester.pump();
      await tester.tap(find.byTooltip('Clear phone number'));
      await tester.pump();
      expect(controller.text, isEmpty);
      expect(server.errorText, isNull);
      expect(changes, ['']);
    });
  });

  group('19G delete keys and caret mapping', () {
    test('forward delete on a mask literal removes the next character', () {
      final mask = SmartMaskFormatter(SmartInputMask('##/##'));
      final forward = _edit(mask, '12/34', 2, '1234', 2);
      expect(forward.text, '12/4');
      expect(forward.selection.baseOffset, 2);
      final back = _edit(mask, '12/34', 3, '1234', 2);
      expect(back.text, '13/4');
      expect(back.selection.baseOffset, 1);
    });

    test('forward delete on a card space removes the next digit', () {
      const card = SmartCardNumberFormatter();
      final forward = _edit(card, '4111 2345', 4, '41112345', 4);
      expect(forward.text, '4111 345');
      expect(forward.selection.baseOffset, 4);
      final back = _edit(card, '4111 2345', 5, '41112345', 4);
      expect(back.text, '4112 345');
      expect(back.selection.baseOffset, 3);
    });

    test('a currency symbol with a dot or digit keeps the caret', () {
      final rupee = SmartAmountFormatter(
        decimalPlaces: 2,
        useGrouping: true,
        currencySymbol: 'Rs.',
      );
      final shown = rupee.toDisplayValue(
        const TextEditingValue(
          text: '1234.5',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      expect(shown.text, 'Rs.1,234.50');
      expect(shown.selection.baseOffset, 6);
      final editable = rupee.toEditableValue(
        const TextEditingValue(
          text: 'Rs.1,234.50',
          selection: TextSelection.collapsed(offset: 6),
        ),
      );
      expect(editable.text, '1234.50');
      expect(editable.selection.baseOffset, 2);
      final digitSymbol = SmartAmountFormatter(currencySymbol: 'A1');
      final value = digitSymbol.toDisplayValue(
        const TextEditingValue(
          text: '5',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      expect(value.text, 'A15');
      expect(value.selection.baseOffset, 3);
    });
  });

  group('19G date dropdown', () {
    testWidgets('the clear button empties the date and reports it', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final dates = <DateTime?>[];
      final changes = <String>[];
      await tester.pumpWidget(
        _app(
          SmartField.date(
            mode: SmartDateMode.dropdowns,
            controller: controller,
            initialDate: DateTime(2020, 3, 4),
            showClearButton: true,
            onDateChanged: dates.add,
            onChanged: changes.add,
          ),
        ),
      );
      await tester.pump();
      expect(controller.text, '04/03/2020');
      await tester.tap(find.byTooltip('Clear'));
      await tester.pump();
      expect(controller.text, isEmpty);
      expect(dates, [null]);
      expect(changes, ['']);
      expect(find.byTooltip('Clear'), findsNothing);
    });

    testWidgets('no clear button without the option or when read-only', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              SmartField.date(
                mode: SmartDateMode.dropdowns,
                initialDate: DateTime(2020, 3, 4),
              ),
              SmartField.date(
                mode: SmartDateMode.dropdowns,
                initialDate: DateTime(2020, 3, 4),
                showClearButton: true,
                readOnly: true,
              ),
            ],
          ),
        ),
      );
      expect(find.byTooltip('Clear'), findsNothing);
    });

    testWidgets('a narrow field still shows day and year', (tester) async {
      await tester.pumpWidget(
        _app(
          Center(
            child: SizedBox(
              width: 260,
              child: SmartField.date(
                mode: SmartDateMode.dropdowns,
                initialDate: DateTime(1990, 9, 21),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.text('1990').hitTestable()).width,
        greaterThan(20),
      );
      expect(
        tester.getSize(find.text('21').hitTestable()).width,
        greaterThan(10),
      );
    });
  });

  group('19G card autofill', () {
    testWidgets('the three card fields share one autofill group', (
      tester,
    ) async {
      await tester.pumpWidget(_app(SmartField.creditCard()));
      expect(find.byType(AutofillGroup), findsOneWidget);
    });
  });
}
