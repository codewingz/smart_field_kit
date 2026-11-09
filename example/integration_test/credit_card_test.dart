import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('credit card input on a real engine', (tester) async {
    SmartCreditCardValue? latest;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SmartField.creditCard(
                now: () => DateTime(2024, 6, 15),
                onChanged: (value) => latest = value,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final number = find.byType(TextFormField).at(0);
    await tester.enterText(number, '4111 1111');
    await tester.pumpAndSettle();
    expect(find.text('Visa · 8 more digits'), findsOneWidget);

    await tester.enterText(number, '4111111111111112');
    await tester.pumpAndSettle();
    expect(find.text('Check the card number.'), findsOneWidget);

    await tester.enterText(number, '378282246310005');
    await tester.pumpAndSettle();
    expect(find.text('American Express'), findsWidgets);
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).at(0))
          .controller
          .text,
      '3782 822463 10005',
    );

    await tester.enterText(find.byType(TextFormField).at(1), '1229');
    await tester.enterText(find.byType(TextFormField).at(2), '1234');
    await tester.pumpAndSettle();
    expect(latest!.brand, SmartCardBrand.amex);
    expect(latest!.numberStatus, SmartCardNumberStatus.valid);
    expect(latest!.expiryYear, 2029);
    expect(
      tester.widget<TextField>(find.byType(TextField).at(2)).obscureText,
      isTrue,
    );
    expect(latest.toString(), isNot(contains('3782')));
  });
}
