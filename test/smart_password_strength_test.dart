import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

void main() {
  group('SmartPasswordStrength', () {
    test('default criteria grade passwords', () {
      SmartPasswordStrengthLevel level(String value) =>
          SmartPasswordStrength.evaluate(value).level;
      expect(level(''), SmartPasswordStrengthLevel.empty);
      expect(level('a'), SmartPasswordStrengthLevel.weak);
      expect(level('abc'), SmartPasswordStrengthLevel.weak);
      expect(level('abcdefgh'), SmartPasswordStrengthLevel.weak);
      expect(level('abcdefgH'), SmartPasswordStrengthLevel.fair);
      expect(level('abcdefH1'), SmartPasswordStrengthLevel.good);
      expect(level('abcdefH1!'), SmartPasswordStrengthLevel.strong);
      expect(level('Äbcdef1!'), SmartPasswordStrengthLevel.strong);
    });

    test('score and met lists', () {
      final result = SmartPasswordStrength.evaluate('abcdefH1');
      expect(result.score, closeTo(0.8, 1e-9));
      expect(result.met.length, 4);
      expect(result.unmet.single.label, 'A special character');
      expect(result.toString(), isNot(contains('abcdefH1')));
    });

    test('developer criteria replace the defaults', () {
      final criteria = [
        SmartPasswordCriterion.minLength(4, label: 'Four characters'),
        SmartPasswordCriterion('Contains x', (value) => value.contains('x')),
      ];
      expect(
        SmartPasswordStrength.evaluate('abcd', criteria: criteria).level,
        SmartPasswordStrengthLevel.fair,
      );
      expect(
        SmartPasswordStrength.evaluate('abcx', criteria: criteria).level,
        SmartPasswordStrengthLevel.strong,
      );
      expect(
        SmartPasswordStrength.evaluate('abc', criteria: const []).level,
        SmartPasswordStrengthLevel.empty,
      );
    });
  });

  group('SmartField.password strength indicator', () {
    testWidgets('is off by default and adds no widgets', (tester) async {
      await tester.pumpWidget(_app(SmartField.password()));
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('updates while typing and on programmatic changes', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.password(
            controller: controller,
            showStrengthIndicator: true,
          ),
        ),
      );
      expect(find.text('Enter a password'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'abc');
      await tester.pump();
      expect(find.text('Password strength: Weak'), findsOneWidget);
      controller.text = 'abcdefH1!';
      await tester.pump();
      expect(find.text('Password strength: Strong'), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, 1);
    });

    testWidgets('works without a developer controller', (tester) async {
      await tester.pumpWidget(
        _app(SmartField.password(showStrengthIndicator: true)),
      );
      await tester.enterText(find.byType(TextFormField), 'abcdefH1');
      await tester.pump();
      expect(find.text('Password strength: Good'), findsOneWidget);
    });

    testWidgets('custom criteria, labels, and checklist', (tester) async {
      await tester.pumpWidget(
        _app(
          SmartField.password(
            showStrengthIndicator: true,
            showStrengthChecklist: true,
            strengthCriteria: [
              SmartPasswordCriterion.minLength(6, label: 'Six characters'),
              SmartPasswordCriterion.digit,
            ],
            strengthLabels: const {
              SmartPasswordStrengthLevel.strong: 'Excellent',
            },
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'abcdef');
      await tester.pump();
      expect(find.text('Six characters'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'abcdef1');
      await tester.pump();
      expect(find.text('Password strength: Excellent'), findsOneWidget);
    });

    testWidgets('does not change validation, value, or visibility toggle', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.password(
              controller: controller,
              showStrengthIndicator: true,
              policy: SmartPasswordPolicy.strong,
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'abcdefgh');
      await tester.pump();
      expect(controller.text, 'abcdefgh');
      expect(formKey.currentState!.validate(), isFalse);
      await tester.enterText(find.byType(TextFormField), 'Abcdefg1!');
      expect(formKey.currentState!.validate(), isTrue);
      expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText,
        isTrue,
      );
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText,
        isFalse,
      );
      expect(controller.text, 'Abcdefg1!');
    });

    testWidgets('never prints the password and exposes only a status label', (
      tester,
    ) async {
      final printed = <String>[];
      final original = debugPrint;
      debugPrint = (message, {wrapWidth}) => printed.add(message ?? '');
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(SmartField.password(showStrengthIndicator: true)),
      );
      await tester.enterText(find.byType(TextFormField), 'Sup3r-secret!');
      await tester.pump();
      expect(printed.where((line) => line.contains('Sup3r')), isEmpty);
      expect(
        find.bySemanticsLabel('Password strength: Strong'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp('Sup3r')), findsNothing);
      debugPrint = original;
      handle.dispose();
    });

    testWidgets('lays out in dark, RTL, large text, and narrow widths', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2),
              size: Size(200, 600),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: SmartField.password(
                  showStrengthIndicator: true,
                  showStrengthChecklist: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'abc');
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
