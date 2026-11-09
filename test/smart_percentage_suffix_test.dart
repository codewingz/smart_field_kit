import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(
  Widget child, {
  ThemeData? theme,
  TextDirection direction = TextDirection.ltr,
  double scale = 1,
}) {
  return MaterialApp(
    theme: theme,
    home: Directionality(
      textDirection: direction,
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
}

void main() {
  group('percentage suffix', () {
    testWidgets('the default field shows exactly one percent sign', (
      tester,
    ) async {
      await tester.pumpWidget(_app(SmartField.percentage(label: 'Rate')));
      expect(find.text('%'), findsOneWidget);
    });

    testWidgets('a developer suffixIcon keeps the icon and shows one percent', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SmartField.percentage(
            decoration: const InputDecoration(suffixIcon: Icon(Icons.info)),
          ),
        ),
      );
      expect(find.byIcon(Icons.info), findsOneWidget);
      expect(find.text('%'), findsOneWidget);
    });

    testWidgets('a developer suffixText replaces the percent sign', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SmartField.percentage(
            decoration: const InputDecoration(suffixText: 'pct'),
          ),
        ),
      );
      expect(find.text('pct'), findsOneWidget);
      expect(find.text('%'), findsNothing);
    });

    testWidgets('a developer suffix widget replaces the percent sign', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SmartField.percentage(
            decoration: const InputDecoration(suffix: Text('per cent')),
          ),
        ),
      );
      expect(find.text('per cent'), findsOneWidget);
      expect(find.text('%'), findsNothing);
    });

    testWidgets('a custom percentSymbol is shown once', (tester) async {
      await tester.pumpWidget(
        _app(SmartField.percentage(percentSymbol: 'pts')),
      );
      expect(find.text('pts'), findsOneWidget);
      expect(find.text('%'), findsNothing);
    });

    testWidgets('disabled and read-only fields still show the symbol', (
      tester,
    ) async {
      await tester.pumpWidget(_app(SmartField.percentage(enabled: false)));
      expect(find.text('%'), findsOneWidget);
      await tester.pumpWidget(_app(SmartField.percentage(readOnly: true)));
      expect(find.text('%'), findsOneWidget);
    });

    testWidgets('themes, RTL and text scale keep one visible symbol', (
      tester,
    ) async {
      for (final theme in [ThemeData.light(), ThemeData.dark()]) {
        for (final direction in TextDirection.values) {
          await tester.pumpWidget(
            _app(
              SmartField.percentage(),
              theme: theme,
              direction: direction,
              scale: 2,
            ),
          );
          expect(find.text('%'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      }
    });

    testWidgets('the symbol never enters raw values, callbacks or saves', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final changed = <String>[];
      String? saved;
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.percentage(
              onChanged: changed.add,
              onSaved: (v) => saved = v,
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), '12.5');
      await tester.pump();
      formKey.currentState!.save();
      expect(changed.last, '12.5');
      expect(saved, '12.5');
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        '12.5',
      );
    });

    testWidgets('the semantics tree contains the value without the symbol', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(SmartField.percentage(label: 'Growth')));
      await tester.enterText(find.byType(EditableText), '12.5');
      await tester.pump();
      expect(find.bySemanticsLabel(RegExp('Growth')), findsWidgets);
      handle.dispose();
    });
  });
}
