import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );
}

void main() {
  group('19T async trigger change', () {
    testWidgets('a pending debounce does not start a check after the trigger '
        'becomes manual', (tester) async {
      var calls = 0;
      final controller = SmartFieldAsyncController();
      addTearDown(controller.dispose);
      late StateSetter rebuild;
      var trigger = SmartAsyncValidationTrigger.onChanged;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return SmartField(
                label: 'Name',
                asyncValidation: SmartAsyncValidation(
                  controller: controller,
                  trigger: trigger,
                  validator: (value) async {
                    calls++;
                    return null;
                  },
                ),
              );
            },
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), 'abc');
      await tester.pump();
      rebuild(() => trigger = SmartAsyncValidationTrigger.manual);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(calls, 0);
      final result = controller.validateAsync();
      await tester.pump();
      expect(await result, isTrue);
      expect(calls, 1);
    });

    testWidgets('the onChanged trigger still runs after its debounce', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(
        _app(
          SmartField(
            label: 'Name',
            asyncValidation: SmartAsyncValidation(
              validator: (value) async {
                calls++;
                return null;
              },
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), 'abc');
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(calls, 1);
    });
  });
}
