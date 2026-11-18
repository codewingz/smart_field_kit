import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child, {TextDirection direction = TextDirection.ltr}) {
  return MaterialApp(
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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('amount formats on blur and keeps the raw value', (tester) async {
    final controller = TextEditingController();
    String? raw;
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            SmartField.amount(
              controller: controller,
              useGrouping: true,
              decimalPlaces: 2,
              onRawChanged: (value) => raw = value,
            ),
            const TextField(key: Key('other')),
          ],
        ),
      ),
    );
    await tester.tap(find.byType(TextFormField).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '50000');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('other')));
    await tester.pumpAndSettle();
    expect(controller.text, '50,000.00');
    expect(raw, '50000');
  });

  testWidgets('right-to-left layout keeps digit order', (tester) async {
    final otp = TextEditingController(text: '123456');
    final card = TextEditingController(text: '4111 1111 1111 1111');
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            SmartField.otp(controller: otp),
            SmartField.creditCard(numberController: card),
          ],
        ),
        direction: TextDirection.rtl,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getCenter(find.text('1')).dx,
      lessThan(tester.getCenter(find.text('6')).dx),
    );
    final editable = tester.allRenderObjects
        .whereType<RenderEditable>()
        .firstWhere(
          (render) => render.text?.toPlainText() == '4111 1111 1111 1111',
        );
    expect(
      editable.getLocalRectForCaret(const TextPosition(offset: 1)).left,
      lessThan(
        editable.getLocalRectForCaret(const TextPosition(offset: 16)).left,
      ),
    );
  });

  testWidgets('calendar picker writes the chosen date and validates it', (
    tester,
  ) async {
    final controller = TextEditingController();
    final calls = <String>[];
    await tester.pumpWidget(
      _app(
        SmartField.date(
          mode: SmartDateMode.calendar,
          now: () => DateTime(2026, 6, 15),
          controller: controller,
          asyncValidation: SmartAsyncValidation(
            debounceDuration: Duration.zero,
            validator: (value) async {
              calls.add(value);
              return null;
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(controller.text, '15/06/2026');
    expect(calls, ['2026-06-15']);
  });

  testWidgets('dropdown date shows an out-of-range value and clears', (
    tester,
  ) async {
    final controller = TextEditingController(text: '01/01/1850');
    await tester.pumpWidget(
      _app(
        SmartField.date(
          mode: SmartDateMode.dropdowns,
          controller: controller,
          showClearButton: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('1850').hitTestable(), findsOneWidget);
    await tester.tap(find.byTooltip('Clear'));
    await tester.pumpAndSettle();
    expect(controller.text, isEmpty);
  });

  testWidgets('country picker selects a country', (tester) async {
    final countries = <String>[];
    await tester.pumpWidget(
      _app(
        SmartField.phone(
          showCountryPicker: true,
          initialCountryCode: 'GB',
          allowedCountryCodes: const ['US', 'GB'],
          onCountryChanged: (country) => countries.add(country!.isoCode),
        ),
      ),
    );
    await tester.tap(find.text('+44'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('United States').last);
    await tester.pumpAndSettle();
    expect(countries, ['US']);
    expect(find.text('+1'), findsOneWidget);
  });

  testWidgets('password toggle and masked field work on a real engine', (
    tester,
  ) async {
    final account = TextEditingController(text: '1234567890');
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            SmartField.password(
              controller: TextEditingController(text: 'Secret12'),
            ),
            SmartField.number(controller: account, mask: true),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Show password'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Hide password'), findsOneWidget);
    expect(find.textContaining('******7890'), findsOneWidget);
    expect(account.text, '1234567890');
  });
}
