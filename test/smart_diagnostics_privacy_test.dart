import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  const secret = '+923001234567';

  testWidgets('a picker failure shows only its generic message', skip: kIsWeb, (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await tester.pumpWidget(
        _app(
          SmartField.phone(
            showContactPicker: true,
            contactPicker: () async => throw StateError('failed for $secret'),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Select phone number from contacts'));
      await tester.pumpAndSettle();
      expect(find.text('Unable to open the contact picker.'), findsOneWidget);
      expect(find.textContaining(secret), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets(
    'the error callback keeps the original cause object',
    skip: kIsWeb,
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final errors = <SmartPhonePickerError>[];
        final cause = StateError('failed for $secret');
        await tester.pumpWidget(
          _app(
            SmartField.phone(
              showContactPicker: true,
              contactPicker: () async => throw cause,
              onContactPickerError: errors.add,
            ),
          ),
        );
        await tester.tap(find.byTooltip('Select phone number from contacts'));
        await tester.pumpAndSettle();
        expect(errors.single.cause, same(cause));
        expect(errors.single.code, SmartPhonePickerErrorCode.platformFailure);
        expect(errors.single.message, 'Unable to open the contact picker.');
        expect(errors.single.toString(), isNot(contains(secret)));
        expect(find.byType(SnackBar), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets('widget diagnostics never include field text', (tester) async {
    final controller = TextEditingController(text: secret);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(SmartField.phone(controller: controller, mask: true)),
    );
    final widget = tester.widget(find.byType(SmartField));
    expect(widget.toStringDeep(), isNot(contains(secret)));
    expect(widget.toString(), isNot(contains(secret)));
    expect(
      SmartPhoneValue(
        text: 'x',
        country: null,
        nationalNumber: null,
        e164: null,
        isValid: false,
      ).toString(),
      isNot(contains(secret)),
    );
  });

  testWidgets('phone, amount and OTP text is not restored after a restart', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        restorationScopeId: 'app',
        home: Scaffold(
          body: Column(
            children: [
              SmartField.phone(restorationId: 'phone'),
              SmartField.amount(restorationId: 'amount'),
              SmartField.otp(restorationId: 'otp'),
            ],
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(EditableText).at(0), '03001234567');
    await tester.enterText(find.byType(EditableText).at(1), '12345.67');
    await tester.enterText(find.byType(EditableText).at(2), '123456');
    await tester.pump();
    await tester.restartAndRestore();
    for (var i = 0; i < 3; i++) {
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).at(i))
            .controller
            .text,
        isEmpty,
      );
    }
  });
}
