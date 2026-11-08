import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

void main() {
  testWidgets('uses one native input with OTP defaults', (tester) async {
    await tester.pumpWidget(_app(SmartField.otp(label: 'Code')));

    expect(find.byType(EditableText), findsOneWidget);
    final input = tester.widget<EditableText>(find.byType(EditableText));
    expect(input.keyboardType, TextInputType.number);
    expect(input.autofillHints, const [AutofillHints.oneTimeCode]);
    expect(input.autofocus, isFalse);
    expect(input.obscureText, isFalse);
    expect(find.byType(AnimatedContainer), findsNWidgets(6));
  });

  testWidgets(
    'accepts leading zeros and fires completion once per transition',
    (tester) async {
      final changes = <String>[];
      final completions = <String>[];
      await tester.pumpWidget(
        _app(
          SmartField.otp(
            length: 4,
            onChanged: changes.add,
            onCompleted: completions.add,
          ),
        ),
      );

      await tester.enterText(find.byType(EditableText), '0123');
      await tester.pump();
      expect(changes, ['0123']);
      expect(completions, ['0123']);

      await tester.pumpWidget(
        _app(
          SmartField.otp(
            length: 4,
            onChanged: changes.add,
            onCompleted: completions.add,
          ),
        ),
      );
      await tester.pump();
      expect(completions, ['0123']);

      await tester.enterText(find.byType(EditableText), '012');
      await tester.enterText(find.byType(EditableText), '0123');
      expect(completions, ['0123', '0123']);
    },
  );

  testWidgets('rejects malformed and oversized user edits atomically', (
    tester,
  ) async {
    final controller = TextEditingController(text: '12');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(SmartField.otp(length: 4, controller: controller)),
    );

    await tester.enterText(find.byType(EditableText), '12a3');
    expect(controller.text, '12');
    await tester.enterText(find.byType(EditableText), '12345');
    expect(controller.text, '12');
    await tester.enterText(find.byType(EditableText), '0012');
    expect(controller.text, '0012');
  });

  testWidgets(
    'supports digit typing and backspace without duplicate callbacks',
    (tester) async {
      final changes = <String>[];
      final completed = <String>[];
      await tester.pumpWidget(
        _app(
          SmartField.otp(
            length: 4,
            onChanged: changes.add,
            onCompleted: completed.add,
          ),
        ),
      );
      await tester.tap(find.byType(AnimatedContainer).first);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '1',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '12',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '123',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '1234',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '123',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      await tester.pump();

      expect(changes, ['1', '12', '123', '1234', '123']);
      expect(completed, ['1234']);
    },
  );

  testWidgets('supports selection and middle replacement without forcing end', (
    tester,
  ) async {
    final controller = TextEditingController(text: '1234');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      _app(
        SmartField.otp(length: 4, controller: controller, focusNode: focusNode),
      ),
    );

    await tester.tap(find.byType(AnimatedContainer).at(1));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);
    expect(controller.selection, const TextSelection.collapsed(offset: 1));

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '1934',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    await tester.pump();
    expect(controller.text, '1934');
    expect(controller.selection, const TextSelection.collapsed(offset: 2));
  });

  testWidgets('keeps programmatic callbacks silent by default and can notify', (
    tester,
  ) async {
    final controller = TextEditingController();
    final changes = <String>[];
    final completions = <String>[];
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        SmartField.otp(
          controller: controller,
          onChanged: changes.add,
          onCompleted: completions.add,
        ),
      ),
    );

    controller.text = '123456';
    await tester.pump();
    expect(changes, isEmpty);
    expect(completions, isEmpty);

    await tester.pumpWidget(
      _app(
        SmartField.otp(
          controller: controller,
          notifyOnProgrammaticChanges: true,
          onChanged: changes.add,
          onCompleted: completions.add,
        ),
      ),
    );
    controller.text = '12345';
    controller.text = '123456';
    await tester.pump();
    expect(changes, ['12345', '123456']);
    expect(completions, ['123456']);
  });

  testWidgets('validates required format length additional and custom order', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField.otp(
            controller: controller,
            length: 4,
            isRequired: true,
            requiredErrorText: 'Required',
            minLength: 5,
            minLengthErrorText: 'Additional length',
            digitErrorText: 'Digits',
            otpLengthErrorText: 'Exact length',
            validator: (_) => 'Custom',
          ),
        ),
      ),
    );

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Required'), findsOneWidget);

    controller.text = 'ab';
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Digits'), findsOneWidget);

    controller.text = '12';
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Exact length'), findsOneWidget);

    controller.text = '1234';
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Additional length'), findsOneWidget);
  });

  testWidgets('integrates with Form save and reset', (tester) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: '123456');
    String? saved;
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField.otp(
            controller: controller,
            onSaved: (value) => saved = value,
          ),
        ),
      ),
    );

    controller.text = '654321';
    formKey.currentState!.save();
    expect(saved, '654321');
    formKey.currentState!.reset();
    await tester.pump();
    expect(controller.text, '123456');
  });

  testWidgets('preserves parent-controlled error until the parent clears it', (
    tester,
  ) async {
    String? error = 'Incorrect verification code';
    late StateSetter setState;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setter) {
            setState = setter;
            return SmartField.otp(errorText: error);
          },
        ),
      ),
    );

    expect(find.text(error), findsOneWidget);
    await tester.enterText(find.byType(EditableText), '123456');
    expect(find.text(error), findsOneWidget);
    setState(() => error = null);
    await tester.pump();
    expect(find.text('Incorrect verification code'), findsNothing);
  });

  testWidgets('obscures only the visual value and preserves state', (
    tester,
  ) async {
    final controller = TextEditingController(text: '123456')
      ..selection = const TextSelection.collapsed(offset: 3);
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      _app(
        SmartField.otp(
          controller: controller,
          focusNode: focusNode,
          obscureText: true,
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();
    expect(find.text('•'), findsNWidgets(6));
    expect(find.text('1'), findsNothing);
    expect(controller.text, '123456');
    expect(controller.selection, const TextSelection.collapsed(offset: 3));
    expect(focusNode.hasFocus, isTrue);
  });

  testWidgets('supports enabled and read-only states', (tester) async {
    await tester.pumpWidget(_app(SmartField.otp(enabled: false)));
    var input = tester.widget<EditableText>(find.byType(EditableText));
    expect(input.readOnly, isTrue);

    await tester.pumpWidget(_app(SmartField.otp(readOnly: true)));
    input = tester.widget<EditableText>(find.byType(EditableText));
    expect(input.readOnly, isTrue);
  });

  testWidgets('supports runtime length updates and rejects invalid config', (
    tester,
  ) async {
    var length = 4;
    late StateSetter setState;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setter) {
            setState = setter;
            return SmartField.otp(length: length);
          },
        ),
      ),
    );
    expect(find.byType(AnimatedContainer), findsNWidgets(4));
    setState(() => length = 6);
    await tester.pump();
    expect(find.byType(AnimatedContainer), findsNWidgets(6));

    expect(() => SmartField.otp(length: 0), throwsArgumentError);
    expect(
      () => SmartField.otp(length: 4, policy: SmartOtpPolicy.legacy),
      throwsArgumentError,
    );
  });

  testWidgets(
    'supports eight digits controller clearing and custom completion',
    (tester) async {
      final controller = TextEditingController();
      final completed = <String>[];
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.otp(
            length: 8,
            controller: controller,
            validator: (value) => value == '00000001' ? null : 'Rejected',
            onCompleted: completed.add,
          ),
        ),
      );

      expect(find.byType(AnimatedContainer), findsNWidgets(8));
      await tester.enterText(find.byType(EditableText), '00000000');
      expect(completed, isEmpty);
      await tester.enterText(find.byType(EditableText), '00000001');
      expect(completed, ['00000001']);
      controller.clear();
      await tester.pump();
      expect(find.text('0'), findsNothing);
    },
  );

  testWidgets(
    'changes visibility at runtime without changing completion state',
    (tester) async {
      final controller = TextEditingController(text: '123456')
        ..selection = const TextSelection.collapsed(offset: 2);
      final focusNode = FocusNode();
      final completed = <String>[];
      var obscure = false;
      late StateSetter setState;
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setter) {
              setState = setter;
              return SmartField.otp(
                controller: controller,
                focusNode: focusNode,
                obscureText: obscure,
                onCompleted: completed.add,
              );
            },
          ),
        ),
      );
      focusNode.requestFocus();
      await tester.pump();

      setState(() => obscure = true);
      await tester.pump();
      expect(find.text('•'), findsNWidgets(6));
      expect(controller.text, '123456');
      expect(controller.selection, const TextSelection.collapsed(offset: 2));
      expect(focusNode.hasFocus, isTrue);
      expect(completed, isEmpty);
    },
  );

  testWidgets('keeps developer-owned controller and focus node undisposed', (
    tester,
  ) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      _app(SmartField.otp(controller: controller, focusNode: focusNode)),
    );
    await tester.pumpWidget(_app(const SizedBox()));

    controller.text = '123456';
    expect(controller.text, '123456');
    expect(focusNode.requestFocus, returnsNormally);
  });

  testWidgets(
    'uses custom state colors and disables animation when requested',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: SmartField.otp(
              style: const SmartOtpStyle(
                boxWidth: 40,
                boxHeight: 50,
                borderColor: Colors.orange,
                fillColor: Colors.black,
              ),
            ),
          ),
        ),
      );

      final box = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );
      final decoration = box.decoration! as BoxDecoration;
      expect(box.duration, Duration.zero);
      expect(box.constraints!.maxWidth, 40);
      expect(box.constraints!.maxHeight, 50);
      expect(decoration.color, Colors.black);
      expect(decoration.border!.top.color, Colors.orange);
    },
  );

  testWidgets('stays responsive in narrow RTL layouts with large text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Center(
              child: SizedBox(
                width: 140,
                child: SmartField.otp(
                  style: const SmartOtpStyle(boxWidth: 60, spacing: 12),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(AnimatedContainer), findsNWidgets(6));
  });

  testWidgets('exposes one semantic text field with its label', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app(SmartField.otp(label: 'Verification code')));

    expect(find.bySemanticsLabel(RegExp('Verification code')), findsOneWidget);
    semantics.dispose();
  });
}

Widget _app(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}
