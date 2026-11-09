import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('switching field kinds keeps the developer controller alive', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'abc');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    final kinds = <SmartField>[
      SmartField.phone(controller: controller, focusNode: focusNode),
      SmartField.search(controller: controller, focusNode: focusNode),
      SmartField.amount(controller: controller, focusNode: focusNode),
      SmartField.password(controller: controller, focusNode: focusNode),
      SmartField.text(controller: controller, focusNode: focusNode),
    ];
    for (final kind in kinds) {
      await tester.pumpWidget(_app(kind));
      await tester.pump();
    }
    await tester.pumpWidget(const SizedBox());
    controller.text = 'still usable';
    focusNode.requestFocus();
    expect(controller.text, 'still usable');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'password visibility survives rebuilds and resets on kind change',
    (tester) async {
      await tester.pumpWidget(_app(SmartField.password()));
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      await tester.pumpWidget(_app(SmartField.password(label: 'Changed')));
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      await tester.pumpWidget(_app(SmartField.text()));
      expect(find.byIcon(Icons.visibility_off), findsNothing);
      expect(find.byIcon(Icons.visibility), findsNothing);
    },
  );

  testWidgets('async validation can be attached and removed at runtime', (
    tester,
  ) async {
    final async = SmartFieldAsyncController();
    addTearDown(async.dispose);
    final completer = Completer<String?>();
    await tester.pumpWidget(_app(SmartField.text()));
    await tester.pumpWidget(
      _app(
        SmartField.text(
          asyncValidation: SmartAsyncValidation(
            controller: async,
            debounceDuration: Duration.zero,
            validator: (_) => completer.future,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'x');
    await tester.pump();
    await tester.pumpWidget(_app(SmartField.text()));
    completer.complete(null);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('search clear button empties the field and notifies once', (
    tester,
  ) async {
    final changes = <String>[];
    var cleared = 0;
    await tester.pumpWidget(
      _app(
        SmartField.search(onChanged: changes.add, onCleared: () => cleared++),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'milk');
    await tester.pump();
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();
    expect(changes.last, '');
    expect(cleared, 1);
    expect(find.byTooltip('Clear search'), findsNothing);
  });
}
