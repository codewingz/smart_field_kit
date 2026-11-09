import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

const _viaDecoration = InputDecoration(enabled: false);

void main() {
  group('effective interactivity is the same for enabled and decoration', () {
    for (final variant in ['enabled: false', 'decoration.enabled: false']) {
      final disabled = variant == 'enabled: false';
      testWidgets('search clear button is absent ($variant)', (tester) async {
        final controller = TextEditingController(text: 'query');
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          _app(
            SmartField.search(
              controller: controller,
              enabled: disabled ? false : null,
              decoration: disabled ? const InputDecoration() : _viaDecoration,
            ),
          ),
        );
        expect(find.byTooltip('Clear search'), findsNothing);
        expect(
          tester.widget<EditableText>(find.byType(EditableText)).readOnly,
          isTrue,
        );
      });

      testWidgets('phone actions are disabled ($variant)', skip: kIsWeb, (
        tester,
      ) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          var picks = 0;
          final controller = TextEditingController(text: '+923001234567');
          addTearDown(controller.dispose);
          await tester.pumpWidget(
            _app(
              SmartField.phone(
                controller: controller,
                showContactPicker: true,
                showClearButton: true,
                contactPicker: () async {
                  picks++;
                  return '+16502530000';
                },
                enabled: disabled ? false : null,
                decoration: disabled ? const InputDecoration() : _viaDecoration,
              ),
            ),
          );
          await tester.tap(
            find.byTooltip('Select phone number from contacts'),
            warnIfMissed: false,
          );
          await tester.tap(
            find.byTooltip('Clear phone number'),
            warnIfMissed: false,
          );
          await tester.pump();
          expect(picks, 0);
          expect(controller.text, '+923001234567');
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('async validation does not start ($variant)', (tester) async {
        var calls = 0;
        final controller = TextEditingController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          _app(
            SmartField(
              controller: controller,
              enabled: disabled ? false : null,
              decoration: disabled ? const InputDecoration() : _viaDecoration,
              asyncValidation: SmartAsyncValidation(
                debounceDuration: Duration.zero,
                validator: (value) async {
                  calls++;
                  return null;
                },
              ),
            ),
          ),
        );
        controller.text = 'programmatic';
        await tester.pump();
        expect(calls, 0);
        expect(controller.text, 'programmatic');
      });
    }

    testWidgets('programmatic changes still reach an enabled search field', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(SmartField.search(controller: controller)));
      controller.text = 'set by code';
      await tester.pump();
      expect(find.byTooltip('Clear search'), findsOneWidget);
    });
  });
}
