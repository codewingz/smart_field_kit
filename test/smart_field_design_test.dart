import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(
  Widget child, {
  ThemeData? theme,
  TextDirection direction = TextDirection.ltr,
  double scale = 1,
  Size? size,
}) {
  return MaterialApp(
    theme: theme,
    home: MediaQuery(
      data: MediaQueryData(
        textScaler: TextScaler.linear(scale),
        size: size ?? const Size(800, 600),
      ),
      child: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: SingleChildScrollView(
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      ),
    ),
  );
}

InputDecoration _decorationOf(WidgetTester tester, [int index = 0]) {
  return tester
      .widgetList<InputDecorator>(find.byType(InputDecorator))
      .elementAt(index)
      .decoration;
}

OutlineInputBorder _outline(InputBorder? border) =>
    border! as OutlineInputBorder;

void main() {
  testWidgets('package fallback: 12px outline, 1px/2px widths, 16/12 padding', (
    tester,
  ) async {
    await tester.pumpWidget(_app(SmartField(label: 'Name')));
    final decoration = _decorationOf(tester);
    final enabled = _outline(decoration.enabledBorder);
    final focused = _outline(decoration.focusedBorder);
    final error = _outline(decoration.errorBorder);
    final focusedError = _outline(decoration.focusedErrorBorder);
    final disabled = _outline(decoration.disabledBorder);
    expect(enabled.borderRadius, BorderRadius.circular(12));
    expect(enabled.borderSide.width, 1);
    expect(focused.borderSide.width, 2);
    expect(error.borderSide.width, 2);
    expect(focusedError.borderSide.width, 2);
    expect(disabled.borderSide.width, 1);
    expect(
      decoration.contentPadding,
      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  });

  testWidgets('fallback colors come from the theme in light and dark', (
    tester,
  ) async {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      final theme = ThemeData(brightness: brightness);
      await tester.pumpWidget(_app(SmartField(label: 'Name'), theme: theme));
      await tester.pumpAndSettle();
      final decoration = _decorationOf(tester);
      expect(
        _outline(decoration.enabledBorder).borderSide.color,
        theme.colorScheme.outline,
      );
      expect(
        _outline(decoration.focusedBorder).borderSide.color,
        theme.colorScheme.primary,
      );
      expect(
        _outline(decoration.errorBorder).borderSide.color,
        theme.colorScheme.error,
      );
    }
  });

  testWidgets('application theme overrides the package fallback', (
    tester,
  ) async {
    final theme = ThemeData(
      inputDecorationTheme: const InputDecorationTheme(
        border: UnderlineInputBorder(),
        contentPadding: EdgeInsets.all(3),
      ),
    );
    await tester.pumpWidget(_app(SmartField(label: 'Name'), theme: theme));
    final decoration = _decorationOf(tester);
    expect(decoration.enabledBorder, isNull);
    expect(decoration.focusedBorder, isNull);
    expect(decoration.contentPadding, const EdgeInsets.all(3));
  });

  testWidgets('developer decoration overrides theme and fallback', (
    tester,
  ) async {
    final theme = ThemeData(
      inputDecorationTheme: const InputDecorationTheme(
        border: UnderlineInputBorder(),
      ),
    );
    const custom = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(2)),
    );
    await tester.pumpWidget(
      _app(
        SmartField(
          label: 'Name',
          decoration: const InputDecoration(
            border: custom,
            contentPadding: EdgeInsets.all(5),
          ),
        ),
        theme: theme,
      ),
    );
    final decoration = _decorationOf(tester);
    expect(decoration.border, custom);
    expect(decoration.enabledBorder, isNull);
    expect(decoration.contentPadding, const EdgeInsets.all(5));
  });

  testWidgets('every non-OTP constructor receives the shared design', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            SmartField.text(),
            SmartField.name(),
            SmartField.username(),
            SmartField.email(),
            SmartField.password(),
            SmartField.phone(),
            SmartField.number(),
            SmartField.amount(),
            SmartField.percentage(),
            SmartField.url(),
            SmartField.search(),
            SmartField.description(),
          ],
        ),
      ),
    );
    final decorators = tester
        .widgetList<InputDecorator>(find.byType(InputDecorator))
        .toList();
    expect(decorators.length, greaterThanOrEqualTo(12));
    for (final decorator in decorators) {
      expect(decorator.decoration.enabledBorder, isA<OutlineInputBorder>());
    }
  });

  testWidgets('focus styling follows actual focus', (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            SmartField(focusNode: focusNode, label: 'A'),
            SmartField(label: 'B'),
          ],
        ),
      ),
    );
    expect(
      tester
          .widget<InputDecorator>(find.byType(InputDecorator).first)
          .isFocused,
      isFalse,
    );
    focusNode.requestFocus();
    await tester.pump();
    expect(
      tester
          .widget<InputDecorator>(find.byType(InputDecorator).first)
          .isFocused,
      isTrue,
    );
    expect(
      tester.widget<InputDecorator>(find.byType(InputDecorator).last).isFocused,
      isFalse,
    );
  });

  testWidgets('error, disabled, and read-only states render', (tester) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: Column(
            children: [
              SmartField(isRequired: true, requiredErrorText: 'Needed'),
              SmartField(enabled: false, label: 'Off'),
              SmartField(readOnly: true, label: 'Read'),
            ],
          ),
        ),
      ),
    );
    formKey.currentState!.validate();
    await tester.pump();
    expect(find.text('Needed'), findsOneWidget);
    expect(_decorationOf(tester, 0).errorText, 'Needed');
    expect(
      tester.widgetList<TextField>(find.byType(TextField)).elementAt(1).enabled,
      isFalse,
    );
    expect(
      tester
          .widgetList<TextField>(find.byType(TextField))
          .elementAt(2)
          .readOnly,
      isTrue,
    );
  });

  testWidgets(
    'large text, RTL, narrow, and multiline layouts do not overflow',
    (tester) async {
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              SmartField.email(label: 'A long label for the email address'),
              SmartField.description(label: 'Description'),
              SmartField.percentage(label: 'Rate'),
            ],
          ),
          theme: ThemeData(brightness: Brightness.dark),
          direction: TextDirection.rtl,
          scale: 2,
          size: const Size(220, 700),
        ),
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'one\ntwo\nthree\nfour\nfive\nsix',
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('semantics keep the label with the shared design', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_app(SmartField.email(label: 'Email')));
    expect(find.bySemanticsLabel(RegExp('Email')), findsWidgets);
    handle.dispose();
  });
}
