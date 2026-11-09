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

void main() {
  tearDown(() => debugOnRebuildDirtyWidget = null);

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
