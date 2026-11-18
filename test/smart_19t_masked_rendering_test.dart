import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _page(Widget child, TextDirection direction) {
  return MaterialApp(
    home: Directionality(
      textDirection: direction,
      child: Scaffold(
        body: Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(
            width: 400,
            child: Padding(padding: const EdgeInsets.all(16), child: child),
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

void _expectVisibleBetweenIcons(WidgetTester tester, String reason) {
  expect(tester.takeException(), isNull, reason: reason);
  final masked = find.textContaining('*');
  expect(masked, findsOneWidget, reason: reason);
  final painted = _painted(tester, masked);
  final field = tester.getRect(find.byType(TextFormField));
  final room = tester.getRect(find.byType(EditableText));
  expect(painted.width, greaterThan(0), reason: reason);
  expect(painted.left, greaterThanOrEqualTo(room.left - 0.5), reason: reason);
  expect(painted.right, lessThanOrEqualTo(room.right + 0.5), reason: reason);
  expect(painted.top, greaterThanOrEqualTo(field.top - 0.5), reason: reason);
  expect(painted.bottom, lessThanOrEqualTo(field.bottom + 0.5), reason: reason);
  for (final icon in find.byType(Icon).evaluate()) {
    final rect = tester.getRect(find.byWidget(icon.widget));
    expect(
      painted.overlaps(rect),
      isFalse,
      reason: '$reason: masked text $painted overlaps icon $rect',
    );
  }
}

Widget _number({bool suffix = true, bool prefix = true}) {
  return SmartField.number(
    mask: true,
    initialValue: '1234567890123456',
    decoration: InputDecoration(
      prefixIcon: prefix ? const Icon(Icons.tag) : null,
      suffixIcon: suffix ? const Icon(Icons.info_outline) : null,
    ),
  );
}

void main() {
  group('19T masked text is visible and unclipped', () {
    for (final direction in TextDirection.values) {
      testWidgets('between prefix and suffix icons in ${direction.name}', (
        tester,
      ) async {
        await tester.pumpWidget(_page(_number(), direction));
        await tester.pumpAndSettle();
        _expectVisibleBetweenIcons(tester, direction.name);
      });

      testWidgets('phone with country picker in ${direction.name}', (
        tester,
      ) async {
        await tester.pumpWidget(
          _page(
            SmartField.phone(
              mask: true,
              showCountryPicker: true,
              initialCountryCode: 'US',
              showClearButton: true,
              initialValue: '4155552671',
            ),
            direction,
          ),
        );
        await tester.pumpAndSettle();
        _expectVisibleBetweenIcons(tester, direction.name);
      });
    }

    testWidgets('after the direction changes at run time', (tester) async {
      await tester.pumpWidget(_page(_number(), TextDirection.ltr));
      await tester.pumpAndSettle();
      _expectVisibleBetweenIcons(tester, 'ltr');
      await tester.pumpWidget(_page(_number(), TextDirection.rtl));
      await tester.pumpAndSettle();
      _expectVisibleBetweenIcons(tester, 'rtl');
      await tester.pumpWidget(_page(_number(), TextDirection.ltr));
      await tester.pumpAndSettle();
      _expectVisibleBetweenIcons(tester, 'ltr again');
    });

    testWidgets('after a suffix icon is added and removed', (tester) async {
      await tester.pumpWidget(_page(_number(suffix: false), TextDirection.ltr));
      await tester.pumpAndSettle();
      _expectVisibleBetweenIcons(tester, 'no suffix');
      final wide = _painted(tester, find.textContaining('*'));
      await tester.pumpWidget(_page(_number(), TextDirection.ltr));
      await tester.pumpAndSettle();
      _expectVisibleBetweenIcons(tester, 'suffix added');
      await tester.pumpWidget(_page(_number(suffix: false), TextDirection.ltr));
      await tester.pumpAndSettle();
      _expectVisibleBetweenIcons(tester, 'suffix removed');
      expect(_painted(tester, find.textContaining('*')), wide);
    });

    testWidgets('after a validation error appears', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        _page(
          Form(
            key: formKey,
            child: SmartField.number(
              mask: true,
              initialValue: '1234567890123456',
              validator: (_) => 'Not accepted',
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.tag),
                suffixIcon: Icon(Icons.info_outline),
              ),
            ),
          ),
          TextDirection.ltr,
        ),
      );
      await tester.pumpAndSettle();
      formKey.currentState!.validate();
      await tester.pumpAndSettle();
      expect(find.text('Not accepted'), findsOneWidget);
      _expectVisibleBetweenIcons(tester, 'error');
    });
  });
}
