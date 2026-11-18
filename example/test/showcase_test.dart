import 'package:example/main.dart';
import 'package:example/src/app_shell.dart';
import 'package:example/src/settings.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _openPage(WidgetTester tester, String label) async {
  final scaffold = tester.firstState<ScaffoldState>(find.byType(Scaffold));
  if (scaffold.hasDrawer) {
    scaffold.openDrawer();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, label));
  } else {
    await tester.tap(find.text(label).first);
  }
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

const _pages = [
  'Text',
  'Passwords',
  'Phone',
  'Numbers',
  'OTP & search',
  'Validation',
  'Cards & dates',
  'Design',
  'Utilities',
];

void main() {
  for (final size in const [Size(390, 844), Size(1200, 900)]) {
    testWidgets('every page renders at ${size.width.toInt()} wide', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const ExampleApp());
      for (final page in _pages) {
        await _openPage(tester, page);
        expect(find.byType(TextField), findsWidgets, reason: page);
        expect(tester.takeException(), isNull, reason: page);
      }
    });
  }

  testWidgets('every page renders on a small right-to-left large-text phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final settings = ShowcaseSettings();
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
        ),
        home: AppShell(settings: settings),
      ),
    );
    await tester.pumpAndSettle();
    for (final page in _pages) {
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      final entry = find.widgetWithText(ListTile, page);
      await tester.scrollUntilVisible(
        entry,
        80,
        scrollable: find.descendant(
          of: find.byType(Drawer),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(entry);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: page);
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        for (var step = 0; step < 12; step++) {
          await tester.drag(
            scrollable.first,
            const Offset(0, -400),
            warnIfMissed: false,
          );
          await tester.pump();
          expect(tester.takeException(), isNull, reason: '$page scroll $step');
        }
      }
    }
  });

  testWidgets('amount shows grouped display and raw value', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ExampleApp());
    await _openPage(tester, 'Numbers');
    await tester.enterText(_field('Amount'), '50000.00');
    await tester.pump();
    expect(find.text('50000.00'), findsWidgets);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final field = tester.widget<EditableText>(
      find
          .descendant(of: _field('Amount'), matching: find.byType(EditableText))
          .first,
    );
    expect(field.controller.text, '50,000.00');
  });

  testWidgets('percentage keeps percentage points', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ExampleApp());
    await _openPage(tester, 'Numbers');
    await tester.enterText(_field('Discount'), '12.5');
    await tester.pump();
    expect(find.text('12.5%'), findsOneWidget);
    expect(find.text('12.5'), findsWidgets);
  });

  testWidgets('confirm password mismatch is reported', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ExampleApp());
    await _openPage(tester, 'Passwords');
    await tester.enterText(_field('Password').last, 'abc12345');
    await tester.enterText(_field('Confirm password'), 'different');
    await tester.pump();
    await tester.tap(find.text('Validate'));
    await tester.pump();
    expect(find.text('Passwords do not match.'), findsOneWidget);
  });

  testWidgets('async username: taken, then available, then submit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ExampleApp());
    await _openPage(tester, 'Validation');
    await tester.enterText(_field('Username'), 'taken');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Username is already taken.'), findsWidgets);
    await tester.enterText(_field('Username'), 'freshname');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Username is already taken.'), findsNothing);
    final submit = find.widgetWithText(FilledButton, 'Submit');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    expect(find.text('Submitted'), findsWidgets);
  });

  testWidgets('phone policy shows parsed E.164 for a +92 number', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ExampleApp());
    await _openPage(tester, 'Phone');
    await tester.enterText(_field('Phone number'), '+923001234567');
    await tester.pump();
    expect(find.text('+923001234567'), findsWidgets);
    expect(find.text('true'), findsOneWidget);
  });

  testWidgets('card page never shows entered card digits', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ExampleApp());
    await _openPage(tester, 'Cards & dates');
    await tester.tap(find.widgetWithText(ActionChip, 'Visa'));
    await tester.pump();
    expect(find.text('Visa'), findsWidgets);
    expect(find.text('valid'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text && (widget.data ?? '').contains('4111111111111111'),
      ),
      findsNothing,
    );
  });
}
