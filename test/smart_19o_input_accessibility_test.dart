import 'package:flutter/cupertino.dart' show CupertinoPicker;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _page(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  double scale = 1,
  double width = 320,
  Brightness brightness = Brightness.light,
}) => MaterialApp(
  theme: ThemeData(brightness: brightness),
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: SingleChildScrollView(
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: SizedBox(width: width, child: child),
            ),
          ),
        ),
      ),
    ),
  ),
);

Widget _phone({
  String initialValue = '03001234567',
  bool? enabled,
  bool readOnly = false,
  AutovalidateMode? autovalidateMode,
  SmartPhonePolicy policy = SmartPhonePolicy.auto,
}) => SmartField.phone(
  label: 'Phone',
  showCountryPicker: true,
  initialCountryCode: 'PK',
  showClearButton: true,
  initialValue: initialValue,
  enabled: enabled,
  readOnly: readOnly,
  policy: policy,
  autovalidateMode: autovalidateMode,
);

Widget _dropdownDate({
  DateTime? initialDate,
  bool? enabled,
  bool readOnly = false,
  bool isRequired = false,
  AutovalidateMode? autovalidateMode,
  ValueChanged<DateTime?>? onDateChanged,
}) => SmartField.date(
  label: 'Birth date',
  mode: SmartDateMode.dropdowns,
  initialDate: initialDate,
  showClearButton: true,
  enabled: enabled,
  readOnly: readOnly,
  isRequired: isRequired,
  autovalidateMode: autovalidateMode,
  onDateChanged: onDateChanged,
);

DateTime _now() => DateTime(2024, 6, 15);

Future<void> _openWheel(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Choose date'));
  await tester.pumpAndSettle();
}

Future<void> _confirm(WidgetTester tester) async {
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

Finder _wheel(String label) => find
    .byType(CupertinoPicker)
    .at(const ['Day', 'Month', 'Year'].indexOf(label));

Future<void> _spin(WidgetTester tester, String label, int items) async {
  await tester.drag(_wheel(label), Offset(0, -36.0 * items));
  await tester.pumpAndSettle();
}

void main() {
  group('19O password strength semantics', () {
    Widget field({List<SmartPasswordCriterion>? criteria}) =>
        SmartField.password(
          label: 'Password',
          showStrengthIndicator: true,
          showStrengthChecklist: true,
          strengthCriteria: criteria,
        );

    final rules = [
      for (final rule in SmartPasswordStrength.defaultCriteria) rule.label,
    ];

    testWidgets('each rule is exposed once with its met state', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_page(field()));
      await tester.enterText(find.byType(TextFormField), 'abc');
      await tester.pump();
      final result = SmartPasswordStrength.evaluate('abc');
      expect(result.met, isNotEmpty);
      expect(result.unmet, isNotEmpty);
      for (final rule in result.met) {
        expect(find.bySemanticsLabel(rule.label), findsOneWidget);
        expect(
          tester.getSemantics(find.bySemanticsLabel(rule.label)),
          matchesSemantics(
            label: rule.label,
            hasCheckedState: true,
            isChecked: true,
          ),
        );
      }
      for (final rule in result.unmet) {
        expect(find.bySemanticsLabel(rule.label), findsOneWidget);
        expect(
          tester.getSemantics(find.bySemanticsLabel(rule.label)),
          matchesSemantics(label: rule.label, hasCheckedState: true),
        );
      }
      handle.dispose();
    });

    testWidgets('the level is one live region and updates while typing', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_page(field()));
      await tester.enterText(find.byType(TextFormField), 'abc');
      await tester.pump();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Password strength: Weak')),
        matchesSemantics(label: 'Password strength: Weak', isLiveRegion: true),
      );
      final digit = SmartPasswordCriterion.digit.label;
      expect(
        tester.getSemantics(find.bySemanticsLabel(digit)),
        matchesSemantics(label: digit, hasCheckedState: true),
      );
      await tester.enterText(find.byType(TextFormField), 'Abcdefg1!');
      await tester.pump();
      expect(find.bySemanticsLabel('Password strength: Weak'), findsNothing);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Password strength: Strong')),
        matchesSemantics(
          label: 'Password strength: Strong',
          isLiveRegion: true,
        ),
      );
      for (final rule in rules) {
        expect(
          tester.getSemantics(find.bySemanticsLabel(rule)),
          matchesSemantics(label: rule, hasCheckedState: true, isChecked: true),
        );
      }
      handle.dispose();
    });

    testWidgets('the password text is not in the semantics tree', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_page(field()));
      await tester.enterText(find.byType(TextFormField), 'Zq7!secretvalue');
      await tester.pump();
      final root = tester
          .binding
          .renderViews
          .first
          .owner!
          .semanticsOwner!
          .rootSemanticsNode!;
      final dump = root.toStringDeep();
      expect(dump, isNot(contains('Zq7!secretvalue')));
      expect(dump, contains('Password strength'));
      handle.dispose();
    });

    testWidgets('developer criteria are exposed with their own labels', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _page(
          field(
            criteria: [
              SmartPasswordCriterion('No spaces', (v) => !v.contains(' ')),
              SmartPasswordCriterion.minLength(12),
            ],
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'short');
      await tester.pump();
      expect(
        tester.getSemantics(find.bySemanticsLabel('No spaces')),
        matchesSemantics(
          label: 'No spaces',
          hasCheckedState: true,
          isChecked: true,
        ),
      );
      handle.dispose();
    });

    for (final direction in TextDirection.values) {
      for (final brightness in Brightness.values) {
        testWidgets(
          'guidelines pass at scale 3 in ${direction.name} ${brightness.name}',
          (tester) async {
            final handle = tester.ensureSemantics();
            await tester.pumpWidget(
              _page(
                field(),
                direction: direction,
                brightness: brightness,
                scale: 3,
                width: 260,
              ),
            );
            await tester.enterText(find.byType(TextFormField), 'abc');
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            for (final rule in rules) {
              expect(find.bySemanticsLabel(rule), findsOneWidget);
            }
            await expectLater(tester, meetsGuideline(textContrastGuideline));
            await expectLater(
              tester,
              meetsGuideline(labeledTapTargetGuideline),
            );
            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
            handle.dispose();
          },
        );
      }
    }
  });

  group('19O narrow and large-text layout', () {
    const scales = [1.0, 1.5, 2.0, 2.5, 3.0];
    const widths = [180.0, 260.0, 320.0, 480.0];

    final variants = <String, Widget Function()>{
      'phone': _phone,
      'phone with error': () => _phone(
        initialValue: '1',
        policy: SmartPhonePolicy.countryAware,
        autovalidateMode: AutovalidateMode.always,
      ),
      'phone disabled': () => _phone(enabled: false),
      'phone read-only': () => _phone(readOnly: true),
      'date': () => _dropdownDate(initialDate: DateTime(2020, 9, 24)),
      'date with error': () => _dropdownDate(
        isRequired: true,
        autovalidateMode: AutovalidateMode.always,
      ),
      'date disabled': () =>
          _dropdownDate(initialDate: DateTime(2020, 9, 24), enabled: false),
      'date read-only': () =>
          _dropdownDate(initialDate: DateTime(2020, 9, 24), readOnly: true),
    };

    for (final direction in TextDirection.values) {
      testWidgets('no overflow in ${direction.name} at any size', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1200, 6000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        for (final scale in scales) {
          for (final width in widths) {
            for (final variant in variants.entries) {
              await tester.pumpWidget(
                _page(
                  variant.value(),
                  direction: direction,
                  scale: scale,
                  width: width,
                ),
              );
              await tester.pumpAndSettle();
              expect(
                tester.takeException(),
                isNull,
                reason: '${variant.key} ${direction.name} x$scale w$width',
              );
              await tester.pumpWidget(const SizedBox());
            }
          }
        }
      });
    }

    testWidgets('audit case: phone at 260 px, scale 3, RTL', (tester) async {
      await tester.pumpWidget(
        _page(_phone(), direction: TextDirection.rtl, scale: 3, width: 260),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('+92'), findsOneWidget);
      expect(find.byTooltip('Clear phone number'), findsOneWidget);
      expect(tester.getSize(find.byType(EditableText)).width, greaterThan(0));
    });

    testWidgets('cramped phone keeps its text area, code and clear button', (
      tester,
    ) async {
      await tester.pumpWidget(_page(_phone(), scale: 3, width: 180));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('+92'), findsOneWidget);
      expect(tester.getSize(find.byType(EditableText)).width, greaterThan(0));
      final clear = tester.getSize(find.byTooltip('Clear phone number'));
      expect(clear.width, greaterThanOrEqualTo(48));
      expect(clear.height, greaterThanOrEqualTo(48));
      final picker = tester.getSize(
        find.ancestor(of: find.text('+92'), matching: find.byType(InkWell)),
      );
      expect(picker.height, greaterThanOrEqualTo(48));
      await tester.tap(find.text('+92'));
      await tester.pumpAndSettle();
      expect(find.text('Search country'), findsOneWidget);
    });

    testWidgets('the dial code is not scaled when there is room', (
      tester,
    ) async {
      await tester.pumpWidget(_page(_phone(), width: 320));
      await tester.pumpAndSettle();
      final normal = tester.getRect(find.text('+92'));
      await tester.pumpWidget(_page(_phone(), width: 600));
      await tester.pumpAndSettle();
      final wide = tester.getRect(find.text('+92'));
      expect(normal.size, wide.size);
      await tester.pumpWidget(_page(_phone(), scale: 3, width: 180));
      await tester.pumpAndSettle();
      final box = tester.renderObject<RenderBox>(find.text('+92'));
      final painted = MatrixUtils.transformRect(
        box.getTransformTo(null),
        Offset.zero & box.size,
      );
      expect(painted.width, lessThan(box.size.width));
    });

    testWidgets('date dropdowns keep full size when there is room', (
      tester,
    ) async {
      await tester.pumpWidget(
        _page(_dropdownDate(initialDate: DateTime(2020, 9, 24)), width: 320),
      );
      await tester.pumpAndSettle();
      for (final element in find.byType(DropdownButton<int>).evaluate()) {
        final box = element.renderObject! as RenderBox;
        final painted = MatrixUtils.transformRect(
          box.getTransformTo(null),
          Offset.zero & box.size,
        );
        expect(painted.width, moreOrLessEquals(box.size.width));
        expect(painted.height, moreOrLessEquals(box.size.height));
        expect(box.size.height, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('cramped date dropdowns show all parts and still work', (
      tester,
    ) async {
      final dates = <DateTime?>[];
      await tester.pumpWidget(
        _page(
          _dropdownDate(
            initialDate: DateTime(2020, 9, 24),
            onDateChanged: dates.add,
          ),
          width: 180,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(DropdownButton<int>), findsNWidgets(3));
      expect(find.text('24'), findsOneWidget);
      expect(find.text('2020'), findsOneWidget);
      expect(find.byTooltip('Clear'), findsOneWidget);
      await tester.tap(find.text('24'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('25').last);
      await tester.pumpAndSettle();
      expect(dates.last, DateTime(2020, 9, 25));
      await tester.tap(find.byTooltip('Clear'));
      await tester.pumpAndSettle();
      expect(dates.last, isNull);
    });
  });

  group('19O wheel date bounds', () {
    Widget wheel(
      TextEditingController controller, {
      DateTime? minDate,
      DateTime? maxDate,
      SmartDateRestriction restriction = SmartDateRestriction.none,
      int? firstYear,
      int? lastYear,
    }) => _page(
      Form(
        child: SmartField.date(
          controller: controller,
          mode: SmartDateMode.wheel,
          minDate: minDate,
          maxDate: maxDate,
          restriction: restriction,
          firstYear: firstYear,
          lastYear: lastYear,
          autovalidateMode: AutovalidateMode.always,
          now: _now,
        ),
      ),
      width: 400,
    );

    testWidgets('a day past maxDate returns to the bound', (tester) async {
      final controller = TextEditingController(text: '15/03/2024');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        wheel(
          controller,
          minDate: DateTime(2024, 3, 10),
          maxDate: DateTime(2024, 3, 20),
        ),
      );
      await _openWheel(tester);
      await _spin(tester, 'Day', 10);
      await _confirm(tester);
      expect(controller.text, '20/03/2024');
      expect(find.textContaining('or earlier'), findsNothing);
    });

    testWidgets('a day before minDate returns to the bound', (tester) async {
      final controller = TextEditingController(text: '15/03/2024');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        wheel(
          controller,
          minDate: DateTime(2024, 3, 10),
          maxDate: DateTime(2024, 3, 20),
        ),
      );
      await _openWheel(tester);
      await _spin(tester, 'Day', -12);
      await _confirm(tester);
      expect(controller.text, '10/03/2024');
      expect(find.textContaining('or later'), findsNothing);
    });

    testWidgets('a month outside the range returns to the bound', (
      tester,
    ) async {
      final controller = TextEditingController(text: '15/03/2024');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        wheel(
          controller,
          minDate: DateTime(2024, 3, 10),
          maxDate: DateTime(2024, 5, 20),
        ),
      );
      await _openWheel(tester);
      await _spin(tester, 'Month', -1);
      await _confirm(tester);
      expect(controller.text, '10/03/2024');
      await _openWheel(tester);
      await _spin(tester, 'Month', 6);
      await _confirm(tester);
      expect(controller.text, '20/05/2024');
    });

    testWidgets('a year outside the range returns to the bound', (
      tester,
    ) async {
      final controller = TextEditingController(text: '15/06/2023');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        wheel(
          controller,
          minDate: DateTime(2022, 8, 1),
          maxDate: DateTime(2024, 2, 10),
        ),
      );
      await _openWheel(tester);
      await _spin(tester, 'Year', 1);
      await _confirm(tester);
      expect(controller.text, '10/02/2024');
      await _openWheel(tester);
      await _spin(tester, 'Year', -2);
      await _confirm(tester);
      expect(controller.text, '01/08/2022');
    });

    testWidgets('leap day bounds are honoured', (tester) async {
      final controller = TextEditingController(text: '31/01/2024');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        wheel(
          controller,
          minDate: DateTime(2024, 1, 1),
          maxDate: DateTime(2024, 2, 29),
        ),
      );
      await _openWheel(tester);
      await _spin(tester, 'Month', 1);
      await _confirm(tester);
      expect(controller.text, '29/02/2024');
      await _openWheel(tester);
      await _spin(tester, 'Month', 1);
      await _confirm(tester);
      expect(controller.text, '29/02/2024');
    });

    testWidgets('OK is disabled while the selection is out of range', (
      tester,
    ) async {
      final controller = TextEditingController(text: '15/03/2024');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        wheel(
          controller,
          minDate: DateTime(2024, 3, 10),
          maxDate: DateTime(2024, 3, 20),
        ),
      );
      await _openWheel(tester);
      TextButton ok() => tester.widget(find.widgetWithText(TextButton, 'OK'));
      expect(ok().onPressed, isNotNull);
      await tester.drag(_wheel('Day'), const Offset(0, -360));
      await tester.pump();
      expect(ok().onPressed, isNull);
      await tester.pumpAndSettle();
      expect(ok().onPressed, isNotNull);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(controller.text, '15/03/2024');
    });

    testWidgets('futureOnly and pastOnly limit the wheel', (tester) async {
      final future = TextEditingController(text: '20/06/2024');
      final past = TextEditingController(text: '10/06/2024');
      addTearDown(future.dispose);
      addTearDown(past.dispose);
      await tester.pumpWidget(
        wheel(future, restriction: SmartDateRestriction.futureOnly),
      );
      await _openWheel(tester);
      await _spin(tester, 'Day', -10);
      await _confirm(tester);
      expect(future.text, '16/06/2024');
      await tester.pumpWidget(
        wheel(past, restriction: SmartDateRestriction.pastOnly),
      );
      await _openWheel(tester);
      await _spin(tester, 'Day', 10);
      await _confirm(tester);
      expect(past.text, '14/06/2024');
    });

    testWidgets('a field without bounds is not limited', (tester) async {
      final controller = TextEditingController(text: '15/03/2024');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        wheel(controller, firstYear: 1850, lastYear: 2150),
      );
      await _openWheel(tester);
      await _spin(tester, 'Year', -150);
      await _confirm(tester);
      expect(controller.text, '15/03/1874');
    });
  });

  group('19O digits outside ASCII keep the current contract', () {
    const samples = {
      'Arabic-Indic': '١٢٣',
      'Persian': '۱۲۳',
      'fullwidth': '１２３',
    };

    for (final sample in samples.entries) {
      testWidgets('${sample.key} digits are not entered in digit fields', (
        tester,
      ) async {
        final fields = <String, Widget>{
          'number': SmartField.number(),
          'amount': SmartField.amount(),
          'percentage': SmartField.percentage(),
          'otp': SmartField.otp(),
          'card': SmartField.creditCard(),
          'date': SmartField.date(),
          'time': SmartField.time(),
        };
        for (final field in fields.entries) {
          await tester.pumpWidget(_page(field.value, width: 480));
          final editable = find.byType(EditableText).first;
          await tester.enterText(editable, sample.value);
          await tester.pump();
          expect(
            tester.widget<EditableText>(editable).controller.text,
            isEmpty,
            reason: field.key,
          );
          await tester.pumpWidget(const SizedBox());
        }
      });

      testWidgets('${sample.key} digits stay in a phone field and fail', (
        tester,
      ) async {
        final formKey = GlobalKey<FormState>();
        await tester.pumpWidget(
          _page(Form(key: formKey, child: SmartField.phone())),
        );
        await tester.enterText(find.byType(EditableText), sample.value);
        await tester.pump();
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText))
              .controller
              .text,
          sample.value,
        );
        expect(formKey.currentState!.validate(), isFalse);
      });

      test('${sample.key} digits are rejected by the utilities', () {
        final digits = sample.value;
        expect(SmartAmountFormatter(decimalPlaces: 2).format(digits), isNull);
        expect(SmartAmountFormatter().normalize(digits), isNull);
        expect(SmartValidators.otp(length: 3)(digits), isNotNull);
        expect(SmartCardUtils.digitsOnly(digits), isEmpty);
        expect(
          const SmartNumberInputFormatter()
              .formatEditUpdate(
                TextEditingValue.empty,
                TextEditingValue(text: digits),
              )
              .text,
          isEmpty,
        );
      });
    }

    testWidgets('ASCII digits mixed with other digits are rejected whole', (
      tester,
    ) async {
      await tester.pumpWidget(_page(SmartField.number()));
      await tester.enterText(find.byType(EditableText), '12');
      await tester.enterText(find.byType(EditableText), '12٣');
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        '12',
      );
    });
  });

  group('19O comma decimal separator keeps the current contract', () {
    TextEditingValue type(SmartAmountFormatter formatter, String text) {
      return formatter.formatEditUpdate(
        const TextEditingValue(
          text: '12',
          selection: TextSelection.collapsed(offset: 2),
        ),
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        ),
      );
    }

    test('a comma is the decimal and the raw value uses a dot', () {
      final formatter = SmartAmountFormatter(
        decimalPlaces: 2,
        decimalSeparator: ',',
        groupingSeparator: ' ',
      );
      expect(type(formatter, '12,').text, '12,');
      expect(type(formatter, '12,5').text, '12,5');
      expect(formatter.normalize('12,5'), '12.5');
      expect(formatter.format('12,5'), '12,50');
    });

    test('a typed dot is not accepted as the decimal', () {
      final plain = SmartAmountFormatter(
        decimalPlaces: 2,
        decimalSeparator: ',',
        groupingSeparator: ' ',
      );
      expect(type(plain, '12.').text, '12');
      expect(type(plain, '12.5').text, '12');
      expect(plain.normalize('12.5'), isNull);
      final grouped = SmartAmountFormatter(
        decimalPlaces: 2,
        decimalSeparator: ',',
        groupingSeparator: '.',
        useGrouping: true,
      );
      expect(type(grouped, '12.').text, '12');
      expect(type(grouped, '12.5').text, '12');
    });

    testWidgets('the field requests a decimal keyboard', (tester) async {
      await tester.pumpWidget(
        _page(
          SmartField.amount(
            decimalPlaces: 2,
            decimalSeparator: ',',
            groupingSeparator: '.',
          ),
        ),
      );
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.keyboardType.decimal, isTrue);
    });
  });

  group('19O amount edge cases keep the current contract', () {
    final formatter = SmartAmountFormatter(
      decimalPlaces: 2,
      useGrouping: true,
      allowNegative: true,
      currencySymbol: r'$',
    );

    test('an incomplete decimal is not completed', () {
      expect(formatter.format('5.'), isNull);
      expect(formatter.normalize('5.'), isNull);
      expect(formatter.normalize('5.', allowPartial: true), isNotNull);
    });

    test('leading zeros are kept', () {
      expect(formatter.format('0005'), r'$0,005.00');
      expect(formatter.normalize('0005'), '0005');
      expect(formatter.format('00'), r'$00.00');
    });

    test('negative zero and sign placement are kept', () {
      expect(formatter.format('-0'), r'$-0.00');
      expect(formatter.normalize('-0'), '-0');
      expect(formatter.format('-.5'), r'$-0.50');
      expect(formatter.normalize('-.5'), '-0.5');
    });

    test('long values keep every digit', () {
      const value = '1234567890123456789012345.67';
      expect(formatter.normalize(value), value);
      expect(formatter.format(value), r'$1,234,567,890,123,456,789,012,345.67');
      expect(
        SmartDecimalUtils.round(
          '0.125',
          decimalPlaces: 2,
          mode: SmartRoundingMode.halfEven,
        ),
        '0.12',
      );
    });
  });

  group('19O remaining localisation and input checks', () {
    testWidgets('an OTP pasted in RTL keeps its digit order', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _page(
          SmartField.otp(controller: controller, length: 6),
          direction: TextDirection.rtl,
          width: 400,
        ),
      );
      await tester.enterText(find.byType(EditableText), '12 34-56');
      await tester.pump();
      expect(controller.text, '123456');
      final first = tester.getCenter(find.text('1'));
      final last = tester.getCenter(find.text('6'));
      expect(first.dx, lessThan(last.dx));
    });

    testWidgets('negative amounts and percentages read left to right in RTL', (
      tester,
    ) async {
      await tester.pumpWidget(
        _page(
          Column(
            children: [
              SmartField.amount(allowNegative: true, initialValue: '-1234.5'),
              SmartField.percentage(allowNegative: true, initialValue: '-12.5'),
            ],
          ),
          direction: TextDirection.rtl,
        ),
      );
      await tester.pump();
      for (final editable in tester.widgetList<EditableText>(
        find.byType(EditableText),
      )) {
        expect(editable.textDirection, TextDirection.ltr);
        expect(editable.controller.text, startsWith('-'));
      }
    });

    test('length rules count user-perceived characters', () {
      const family = '👨‍👩‍👧‍👦';
      expect(SmartValidators.maxLength(1)(family), isNull);
      expect(SmartValidators.minLength(2)(family), isNotNull);
      expect(SmartValidators.minLength(2)('éa'), isNull);
      expect(SmartTextUtils.countWords('مرحبا بالعالم'), 2);
    });

    test('12-hour time text uses fixed AM and PM markers', () {
      const format = SmartTimeFormat(use24Hour: false);
      expect(format.format(const TimeOfDay(hour: 15, minute: 5)), '03:05 PM');
      expect(format.format(const TimeOfDay(hour: 0, minute: 0)), '12:00 AM');
    });
  });
}
