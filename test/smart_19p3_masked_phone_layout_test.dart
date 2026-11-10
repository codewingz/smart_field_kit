import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _page(
  Widget child, {
  required double width,
  required double scale,
  required TextDirection direction,
}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: Directionality(
          textDirection: direction,
          child: Scaffold(
            body: Align(
              alignment: AlignmentDirectional.topStart,
              child: SizedBox(
                width: width,
                child: Padding(padding: const EdgeInsets.all(16), child: child),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Rect _painted(WidgetTester tester, Finder finder) {
  final box = tester.renderObject<RenderBox>(finder);
  return MatrixUtils.transformRect(
    box.getTransformTo(null),
    Offset.zero & box.size,
  );
}

void main() {
  group('19P.3 masked text stays inside its field', () {
    final fields = <String, Widget Function()>{
      'phone with country picker': () => SmartField.phone(
        label: 'Phone',
        showCountryPicker: true,
        initialCountryCode: 'US',
        mask: true,
        initialValue: '4155552671',
      ),
      'phone': () => SmartField.phone(mask: true, initialValue: '+14155552671'),
      'amount': () => SmartField.amount(
        mask: true,
        decimalPlaces: 2,
        useGrouping: true,
        currencySymbol: r'$',
        initialValue: '12345678901234.56',
      ),
      'number': () =>
          SmartField.number(mask: true, initialValue: '1234567890123456789012'),
    };

    for (final direction in TextDirection.values) {
      testWidgets('at every size in ${direction.name}', (tester) async {
        tester.view.physicalSize = const Size(1400, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        for (final width in [240.0, 320.0, 360.0, 600.0, 1280.0]) {
          for (final scale in [1.0, 1.3, 2.0, 3.0]) {
            for (final field in fields.entries) {
              await tester.pumpWidget(
                _page(
                  field.value(),
                  width: width,
                  scale: scale,
                  direction: direction,
                ),
              );
              await tester.pumpAndSettle();
              final reason = '${field.key} w$width x$scale ${direction.name}';
              expect(tester.takeException(), isNull, reason: reason);
              final masked = find.textContaining('*');
              expect(masked, findsOneWidget, reason: reason);
              final bounds = tester.getRect(find.byType(TextFormField));
              final painted = _painted(tester, masked);
              expect(
                painted.left,
                greaterThanOrEqualTo(bounds.left - 0.5),
                reason: reason,
              );
              expect(
                painted.right,
                lessThanOrEqualTo(bounds.right + 0.5),
                reason: reason,
              );
              expect(painted.width, greaterThan(0), reason: reason);
              await tester.pumpWidget(const SizedBox());
            }
          }
        }
      });
    }

    testWidgets('the masked text is not scaled when there is room', (
      tester,
    ) async {
      await tester.pumpWidget(
        _page(
          fields['phone with country picker']!(),
          width: 400,
          scale: 1,
          direction: TextDirection.ltr,
        ),
      );
      await tester.pumpAndSettle();
      final masked = find.text('******2671');
      expect(masked, findsOneWidget);
      final natural = tester.getSize(masked);
      final painted = _painted(tester, masked);
      expect(painted.width, moreOrLessEquals(natural.width));
      expect(painted.height, moreOrLessEquals(natural.height));
    });

    testWidgets('a cramped masked phone reveals and edits on focus', (
      tester,
    ) async {
      final controller = TextEditingController(text: '4155552671');
      final focus = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        _page(
          SmartField.phone(
            controller: controller,
            focusNode: focus,
            showCountryPicker: true,
            initialCountryCode: 'US',
            mask: true,
          ),
          width: 320,
          scale: 2,
          direction: TextDirection.ltr,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('*'), findsOneWidget);
      focus.requestFocus();
      await tester.pumpAndSettle();
      expect(find.textContaining('*'), findsNothing);
      expect(tester.getSize(find.byType(EditableText)).width, greaterThan(48));
      await tester.enterText(find.byType(EditableText), '4155552672');
      focus.unfocus();
      await tester.pumpAndSettle();
      expect(controller.text, '4155552672');
      expect(find.text('******2672'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a developer prefixText is still combined with the mask', (
      tester,
    ) async {
      await tester.pumpWidget(
        _page(
          SmartField.number(
            mask: true,
            initialValue: '12345678',
            decoration: const InputDecoration(prefixText: 'ID '),
          ),
          width: 400,
          scale: 1,
          direction: TextDirection.ltr,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ID ****5678'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
