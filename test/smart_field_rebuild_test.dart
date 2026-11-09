import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Future<int> _rebuilds(WidgetTester tester, Widget field) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: field)));
  var count = 0;
  debugOnRebuildDirtyWidget = (element, builtOnce) {
    if (element.widget is SmartField) {
      count++;
    }
  };
  var text = '';
  for (var i = 0; i < 20; i++) {
    text += 'a';
    await tester.enterText(find.byType(TextFormField), text);
    await tester.pump();
  }
  debugOnRebuildDirtyWidget = null;
  return count;
}

typedef _Build = SmartField Function(TextEditingController, FocusNode);

class _Run {
  _Run(this.values, this.typingRebuilds, this.blurRebuilds, this.blurText);

  final List<String> values;
  final int typingRebuilds;
  final int blurRebuilds;
  final String blurText;
}

Future<_Run> _typeAccepted(
  WidgetTester tester,
  _Build build,
  List<String> steps,
) async {
  final controller = TextEditingController();
  final focus = FocusNode();
  addTearDown(controller.dispose);
  addTearDown(focus.dispose);
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: build(controller, focus))),
  );
  focus.requestFocus();
  await tester.pump();
  var count = 0;
  debugOnRebuildDirtyWidget = (element, builtOnce) {
    if (element.widget is SmartField) {
      count++;
    }
  };
  final values = <String>[];
  for (final step in steps) {
    await tester.enterText(find.byType(TextFormField), step);
    await tester.pump();
    values.add(controller.text);
  }
  final typing = count;
  focus.unfocus();
  await tester.pump();
  debugOnRebuildDirtyWidget = null;
  return _Run(values, typing, count - typing, controller.text);
}

void main() {
  tearDown(() => debugOnRebuildDirtyWidget = null);

  group('accepted numeric typing', () {
    testWidgets('number keeps every digit and rebuilds nothing', (
      tester,
    ) async {
      final raws = <String>[];
      final run = await _typeAccepted(
        tester,
        (c, f) =>
            SmartField.number(controller: c, focusNode: f, onChanged: raws.add),
        ['1', '12', '123'],
      );
      expect(run.values, ['1', '12', '123']);
      expect(raws, ['1', '12', '123']);
      expect(run.typingRebuilds, 0);
      expect(run.blurText, '123');
    });

    testWidgets('amount shows exact partial values and groups on blur', (
      tester,
    ) async {
      final raws = <String>[];
      final run = await _typeAccepted(
        tester,
        (c, f) => SmartField.amount(
          controller: c,
          focusNode: f,
          decimalLength: 2,
          useGrouping: true,
          onRawChanged: raws.add,
        ),
        ['1', '12.', '12.3', '1234.56'],
      );
      expect(run.values, ['1', '12.', '12.3', '1234.56']);
      expect(raws, ['1', '12.', '12.3', '1234.56']);
      expect(run.typingRebuilds, 0);
      expect(run.blurText, '1,234.56');
    });

    testWidgets('negative amounts keep their partial states', (tester) async {
      final run = await _typeAccepted(
        tester,
        (c, f) => SmartField.amount(
          controller: c,
          focusNode: f,
          decimalLength: 2,
          useGrouping: true,
          allowNegative: true,
        ),
        ['-', '-1', '-12.5'],
      );
      expect(run.values, ['-', '-1', '-12.5']);
      expect(run.typingRebuilds, 0);
      expect(run.blurText, '-12.50');
    });

    testWidgets('pasting a long amount is one edit and formats on blur', (
      tester,
    ) async {
      final run = await _typeAccepted(
        tester,
        (c, f) => SmartField.amount(
          controller: c,
          focusNode: f,
          decimalLength: 2,
          useGrouping: true,
          groupingStyle: SmartGroupingStyle.indian,
        ),
        ['1234567890.5'],
      );
      expect(run.values, ['1234567890.5']);
      expect(run.typingRebuilds, 0);
      expect(run.blurText, '1,23,45,67,890.50');
    });

    testWidgets('percentage keeps typed text and rebuilds nothing', (
      tester,
    ) async {
      final run = await _typeAccepted(
        tester,
        (c, f) => SmartField.percentage(controller: c, focusNode: f),
        ['1', '12', '12.5'],
      );
      expect(run.values, ['1', '12', '12.5']);
      expect(run.typingRebuilds, 0);
      expect(run.blurText, '12.5');
    });

    testWidgets('a masked number rebuilds only when its presentation changes', (
      tester,
    ) async {
      final run = await _typeAccepted(
        tester,
        (c, f) => SmartField.number(controller: c, focusNode: f, mask: true),
        ['1', '12', '123'],
      );
      expect(run.values, ['1', '12', '123']);
      expect(run.typingRebuilds, 0);
      expect(run.blurRebuilds, greaterThanOrEqualTo(1));
    });
  });

  group('rejected characters', () {
    testWidgets('are separate from accepted typing and change nothing', (
      tester,
    ) async {
      final run = await _typeAccepted(
        tester,
        (c, f) => SmartField.amount(controller: c, focusNode: f),
        ['a', 'ab'],
      );
      expect(run.values, ['', '']);
      expect(run.typingRebuilds, 0);
    });
  });

  testWidgets('typing does not rebuild the host unnecessarily', (tester) async {
    expect(await _rebuilds(tester, const SmartField()), 0);
    expect(
      await _rebuilds(tester, SmartField.password(showStrengthIndicator: true)),
      0,
    );
    expect(await _rebuilds(tester, SmartField.number(mask: true)), 0);
    expect(
      await _rebuilds(tester, SmartField.search(onSearch: (_) {})),
      lessThanOrEqualTo(2),
    );
    expect(await _rebuilds(tester, SmartField.phone()), lessThanOrEqualTo(2));
    expect(await _rebuilds(tester, SmartField.amount(decimalPlaces: 2)), 0);
  });
}
