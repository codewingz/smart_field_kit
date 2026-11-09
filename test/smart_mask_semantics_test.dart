import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

List<String> _allText(WidgetTester tester) {
  final texts = <String>[];
  void visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    texts
      ..add(data.label)
      ..add(data.value)
      ..add(data.hint);
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return texts;
}

void main() {
  group('privacy masking keeps accessible names and errors', () {
    testWidgets('decoration label, hint and server error survive masking', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final server = SmartServerError();
      final controller = TextEditingController(text: '12345.67');
      addTearDown(server.dispose);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.amount(
            controller: controller,
            decimalPlaces: 2,
            mask: true,
            serverError: server,
            decoration: const InputDecoration(
              labelText: 'Invoice total',
              hintText: 'Amount hint',
            ),
          ),
        ),
      );
      server.set('Amount rejected');
      await tester.pump();
      final text = _allText(tester).join('|');
      expect(text, contains('Invoice total'));
      expect(text, contains('Amount rejected'));
      expect(text, isNot(contains('12345')));
      expect(text, isNot(contains('67')));
      handle.dispose();
    });

    testWidgets('the label parameter and validation errors are announced', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController(text: '0012345678');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: SmartField.number(
              controller: controller,
              label: 'Account number',
              mask: true,
              validator: (value) => 'Account looks wrong',
            ),
          ),
        ),
      );
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      final text = _allText(tester).join('|');
      expect(text, contains('Account number'));
      expect(text, contains('Account looks wrong'));
      expect(text, isNot(contains('0012345678')));
      expect(text, contains('******5678'));
      handle.dispose();
    });

    testWidgets('the unmasked value is revealed only while editing', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final focus = FocusNode();
      final controller = TextEditingController(text: '0012345678');
      addTearDown(focus.dispose);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.number(
            controller: controller,
            focusNode: focus,
            label: 'Account number',
            mask: true,
          ),
        ),
      );
      expect(_allText(tester).join('|'), isNot(contains('0012345678')));
      focus.requestFocus();
      await tester.pump();
      expect(controller.text, '0012345678');
      focus.unfocus();
      await tester.pump();
      expect(_allText(tester).join('|'), isNot(contains('0012345678')));
      handle.dispose();
    });

    testWidgets('a masked field still exposes a tap action and masked value', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final controller = TextEditingController(text: '0012345678');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.number(
            controller: controller,
            label: 'Account number',
            mask: true,
          ),
        ),
      );
      final node = tester.getSemantics(
        find.bySemanticsLabel(RegExp('Account number')).first,
      );
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      expect(_allText(tester).join('|'), contains('******5678'));
      handle.dispose();
    });
  });
}
