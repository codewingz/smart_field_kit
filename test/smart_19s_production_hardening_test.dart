import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

import 'support/web_skips.dart';

Widget _page(
  Widget child, {
  double width = 360,
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
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
            body: SingleChildScrollView(
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: SizedBox(width: width, child: child),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

List<SemanticsNode> _nodes(WidgetTester tester) {
  final nodes = <SemanticsNode>[];
  void visit(SemanticsNode node) {
    nodes.add(node);
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return nodes;
}

String _spoken(WidgetTester tester) {
  return _nodes(tester)
      .map((node) {
        final data = node.getSemanticsData();
        return '${data.label}|${data.value}|${data.hint}|${data.tooltip}';
      })
      .join('\n');
}

SemanticsData _fieldNode(WidgetTester tester) {
  return _nodes(tester)
      .map((node) => node.getSemanticsData())
      .firstWhere((data) => data.flagsCollection.isTextField);
}

void main() {
  group('19S masked fields never announce the raw value', () {
    final cases =
        <
          String,
          ({Widget Function(FocusNode focus) build, String raw, String masked})
        >{
          'number': (
            build: (focus) => SmartField.number(
              label: 'Account',
              focusNode: focus,
              mask: true,
              initialValue: '12345678',
            ),
            raw: '12345678',
            masked: '****5678',
          ),
          'phone': (
            build: (focus) => SmartField.phone(
              label: 'Phone',
              focusNode: focus,
              mask: true,
              initialValue: '+14155552671',
            ),
            raw: '+14155552671',
            masked: '2671',
          ),
          'phone with country picker': (
            build: (focus) => SmartField.phone(
              label: 'Phone',
              focusNode: focus,
              showCountryPicker: true,
              initialCountryCode: 'US',
              mask: true,
              initialValue: '4155552671',
            ),
            raw: '4155552671',
            masked: '******2671',
          ),
          'amount': (
            build: (focus) => SmartField.amount(
              label: 'Balance',
              focusNode: focus,
              mask: true,
              decimalPlaces: 2,
              useGrouping: true,
              currencySymbol: r'$',
              initialValue: '9876543.21',
            ),
            raw: '9,876,543.21',
            masked: r'$*,***,***.**',
          ),
        };

    for (final entry in cases.entries) {
      for (final direction in TextDirection.values) {
        for (final scale in [1.0, 3.0]) {
          testWidgets('${entry.key} ${direction.name} x$scale', (tester) async {
            final handle = tester.ensureSemantics();
            final focus = FocusNode();
            addTearDown(focus.dispose);
            await tester.pumpWidget(
              _page(
                entry.value.build(focus),
                direction: direction,
                scale: scale,
              ),
            );
            await tester.pumpAndSettle();
            final spoken = _spoken(tester);
            expect(spoken, isNot(contains(entry.value.raw)));
            expect(spoken, contains(entry.value.masked));
            final field = _fieldNode(tester);
            expect(field.flagsCollection.isObscured, isTrue);
            expect(
              field.label,
              contains(
                entry.key.startsWith('phone')
                    ? 'Phone'
                    : entry.key == 'amount'
                    ? 'Balance'
                    : 'Account',
              ),
            );
            expect(field.hasAction(SemanticsAction.tap), isTrue);
            expect(tester.takeException(), isNull);

            focus.requestFocus();
            await tester.pumpAndSettle();
            final revealed = _fieldNode(tester);
            expect(revealed.flagsCollection.isObscured, isFalse);
            expect(revealed.flagsCollection.isFocused, Tristate.isTrue);
            expect(
              tester
                  .widget<EditableText>(find.byType(EditableText))
                  .obscureText,
              isFalse,
            );
            handle.dispose();
          });
        }
      }
    }

    for (final state in ['disabled', 'read-only']) {
      testWidgets('a $state masked field stays masked', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          _page(
            SmartField.number(
              label: 'Account',
              mask: true,
              enabled: state != 'disabled',
              readOnly: state == 'read-only',
              initialValue: '12345678',
            ),
          ),
        );
        await tester.pumpAndSettle();
        final spoken = _spoken(tester);
        expect(spoken, isNot(contains('12345678')));
        expect(spoken, contains('****5678'));
        final field = _fieldNode(tester);
        expect(field.flagsCollection.isObscured, isTrue);
        if (state == 'disabled') {
          expect(field.flagsCollection.isEnabled, isNot(Tristate.isTrue));
        } else {
          expect(field.flagsCollection.isReadOnly, isTrue);
        }
        handle.dispose();
      });
    }

    testWidgets('picker, clear and prefix or suffix actions keep their nodes', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var tapped = 0;
      await tester.pumpWidget(
        _page(
          Column(
            children: [
              SmartField.phone(
                label: 'Phone',
                showCountryPicker: true,
                initialCountryCode: 'US',
                mask: true,
                initialValue: '4155552671',
              ),
              SmartField.number(
                label: 'Account',
                mask: true,
                initialValue: '12345678',
                decoration: InputDecoration(
                  prefixIcon: IconButton(
                    tooltip: 'Scan',
                    onPressed: () => tapped++,
                    icon: const Icon(Icons.qr_code),
                  ),
                  suffixIcon: IconButton(
                    tooltip: 'Help',
                    onPressed: () => tapped++,
                    icon: const Icon(Icons.help_outline),
                  ),
                ),
              ),
            ],
          ),
          width: 420,
        ),
      );
      await tester.pumpAndSettle();
      final spoken = _spoken(tester);
      expect(spoken, isNot(contains('4155552671')));
      expect(spoken, isNot(contains('12345678')));
      expect(spoken, contains('Scan'));
      expect(spoken, contains('Help'));
      await tester.tap(find.byTooltip('Scan'));
      await tester.tap(find.byTooltip('Help'));
      expect(tapped, 2);
      final buttons = _nodes(tester)
          .map((node) => node.getSemanticsData())
          .where(
            (data) =>
                data.flagsCollection.isButton &&
                data.hasAction(SemanticsAction.tap),
          );
      expect(buttons.length, greaterThanOrEqualTo(3));
      handle.dispose();
    });
  });

  testWidgets('19S a masked field still announces its error', (tester) async {
    final handle = tester.ensureSemantics();
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: '1234567890');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _page(
        Form(
          key: formKey,
          child: SmartField.number(
            label: 'Account',
            controller: controller,
            mask: true,
            maxLength: 4,
            maxLengthErrorText: 'Too long!',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pumpAndSettle();
    final field = _fieldNode(tester);
    expect(field.label, contains('Account'));
    expect(_spoken(tester), contains('Too long!'));
    expect(_spoken(tester), isNot(contains('1234567890')));
    expect(field.hint, contains('Too long!'));
    controller.text = '12';
    await tester.pumpAndSettle();
    expect(formKey.currentState!.validate(), isTrue);
    await tester.pumpAndSettle();
    expect(_spoken(tester), isNot(contains('Too long!')));
    handle.dispose();
  });

  group('19S removing asynchronous validation', () {
    Future<void> run(
      WidgetTester tester, {
      required Future<String?> Function(String value) validator,
      required Duration settle,
      required bool expectErrorBefore,
    }) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      Widget build(bool withAsync) => _page(
        Form(
          key: formKey,
          child: SmartField(
            controller: controller,
            asyncValidation: withAsync
                ? SmartAsyncValidation(
                    debounceDuration: Duration.zero,
                    timeout: const Duration(seconds: 2),
                    validator: validator,
                  )
                : null,
          ),
        ),
      );
      await tester.pumpWidget(build(true));
      await tester.enterText(find.byType(EditableText), 'taken');
      await tester.pump();
      await tester.pump(settle);
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).decoration?.errorText,
        expectErrorBefore ? isNotNull : isNull,
      );
      await tester.pumpWidget(build(false));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).decoration?.errorText,
        isNull,
      );
      expect(formKey.currentState!.validate(), isTrue);
      await tester.pump(const Duration(seconds: 5));
      expect(
        tester.widget<TextField>(find.byType(TextField)).decoration?.errorText,
        isNull,
      );
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    }

    testWidgets('while a check is pending', (tester) async {
      final pending = Completer<String?>();
      await run(
        tester,
        validator: (_) => pending.future,
        settle: const Duration(milliseconds: 10),
        expectErrorBefore: false,
      );
      pending.complete('Taken.');
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).decoration?.errorText,
        isNull,
      );
    });

    testWidgets('after a valid result', (tester) async {
      await run(
        tester,
        validator: (_) async => null,
        settle: const Duration(milliseconds: 10),
        expectErrorBefore: false,
      );
    });

    testWidgets('after an invalid result', (tester) async {
      await run(
        tester,
        validator: (_) async => 'Taken.',
        settle: const Duration(milliseconds: 10),
        expectErrorBefore: true,
      );
    });

    testWidgets('after an unavailable result', (tester) async {
      await run(
        tester,
        validator: (_) async => throw StateError('offline'),
        settle: const Duration(milliseconds: 10),
        expectErrorBefore: true,
      );
    });

    testWidgets('after a timeout', (tester) async {
      await run(
        tester,
        validator: (_) => Completer<String?>().future,
        settle: const Duration(seconds: 3),
        expectErrorBefore: true,
      );
    });

    testWidgets('attach and remove repeatedly', (tester) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController(text: 'taken');
      addTearDown(controller.dispose);
      var calls = 0;
      Widget build(bool withAsync) => _page(
        Form(
          key: formKey,
          child: SmartField(
            controller: controller,
            asyncValidation: withAsync
                ? SmartAsyncValidation(
                    debounceDuration: Duration.zero,
                    validator: (_) async {
                      calls++;
                      return 'Taken.';
                    },
                  )
                : null,
          ),
        ),
      );
      for (var cycle = 0; cycle < 4; cycle++) {
        await tester.pumpWidget(build(true));
        controller.text = 'taken$cycle';
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 10));
        await tester.pump();
        expect(find.text('Taken.'), findsOneWidget, reason: 'cycle $cycle');
        await tester.pumpWidget(build(false));
        await tester.pump();
        expect(find.text('Taken.'), findsNothing, reason: 'cycle $cycle');
        expect(formKey.currentState!.validate(), isTrue);
      }
      expect(calls, greaterThanOrEqualTo(4));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a completed check leaves no timeout timer behind', (
      tester,
    ) async {
      final async = SmartFieldAsyncController();
      addTearDown(async.dispose);
      await tester.pumpWidget(
        _page(
          SmartField(
            initialValue: 'free',
            asyncValidation: SmartAsyncValidation(
              controller: async,
              debounceDuration: Duration.zero,
              timeout: const Duration(minutes: 10),
              validator: (_) async => null,
            ),
          ),
        ),
      );
      late bool accepted;
      await tester.runAsync(() async {
        accepted = await async.validateAsync(force: true);
      });
      expect(accepted, isTrue);
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('19S masking privacy', () {
    test('a short amount is fully masked', () {
      expect(maskAmount('12', visibleSuffixDigits: 4), '**');
      expect(maskAmount('12.50', visibleSuffixDigits: 4), '**.**');
      expect(maskAmount('1234', visibleSuffixDigits: 4), '****');
      expect(maskAmount('12345', visibleSuffixDigits: 4), '*2345');
      expect(maskAmount('1,234.56', visibleSuffixDigits: 2), '*,***.56');
    });

    test('the currency symbol is kept on either side', () {
      expect(maskAmount('1,234.50', currencySymbol: r'$'), r'$*,***.**');
      expect(maskAmount(r'$1,234.50'), r'$*,***.**');
      expect(
        maskAmount(
          '1.234,50',
          currencySymbol: ' EUR',
          currencyPosition: SmartCurrencyPosition.suffix,
          groupingSeparator: '.',
          decimalSeparator: ',',
        ),
        '*.***,** EUR',
      );
      expect(maskAmount('12,34,567.89'), '**,**,***.**');
    });

    test('a sign before the currency symbol is masked, not rejected', () {
      final masked = maskAmount(r'-$1,234.50');
      expect(masked, isNot(matches(RegExp(r'\d'))));
      expect(masked, contains(r'$'));
      expect(masked, contains('*'));
    });

    test('non-ASCII digits never pass through a mask unmasked', () {
      for (final value in [
        '١٢٣٤٥٦',
        '१२३४५६',
        '１２３４５６',
        '12٣٤56',
        r'$٣٤12',
        '12 ٣٤',
      ]) {
        String? masked;
        try {
          masked = maskAmount(value);
        } on FormatException {
          masked = null;
        }
        if (masked != null) {
          expect(
            RegExp(r'\p{Nd}', unicode: true).hasMatch(masked),
            isFalse,
            reason: 'a digit of $value leaked into $masked',
          );
        }
      }
    });

    testWidgets('a masked amount field shows no digits for its currency', (
      tester,
    ) async {
      for (final position in SmartCurrencyPosition.values) {
        for (final style in SmartGroupingStyle.values) {
          await tester.pumpWidget(
            _page(
              SmartField.amount(
                mask: true,
                decimalPlaces: 2,
                useGrouping: true,
                groupingStyle: style,
                currencySymbol: position == SmartCurrencyPosition.prefix
                    ? 'Rs. '
                    : ' Rs',
                currencyPosition: position,
                initialValue: '1234567.89',
              ),
            ),
          );
          await tester.pumpAndSettle();
          final masked = find.textContaining('*');
          expect(masked, findsOneWidget, reason: '$position $style');
          final text = tester.widget<Text>(masked).data!;
          expect(text, isNot(matches(RegExp(r'\d'))), reason: text);
          expect(text, contains('Rs'), reason: text);
          await tester.pumpWidget(const SizedBox());
        }
      }
    });

    testWidgets('a short masked amount shows no digits', (tester) async {
      await tester.pumpWidget(
        _page(
          SmartField.amount(
            mask: true,
            maskVisibleSuffixDigits: 4,
            decimalPlaces: 2,
            initialValue: '12.50',
          ),
        ),
      );
      await tester.pumpAndSettle();
      final text = tester.widget<Text>(find.textContaining('*')).data!;
      expect(text, isNot(matches(RegExp(r'\d'))));
    });
  });

  group('19S exact value limits stay fast on long input', () {
    test('thousands of zeros are compared in bounded time', () {
      final minimum = SmartValidators.minValue('1');
      final maximum = SmartValidators.maxValue('5');
      final zeros = '0' * 20000;
      final watch = Stopwatch()..start();
      expect(minimum('${zeros}2'), isNull);
      expect(minimum('$zeros.${zeros}1'), isNotNull);
      expect(maximum('${zeros}9'), isNotNull);
      expect(maximum('4.$zeros'), isNull);
      expect(maximum('5.${zeros}1'), isNotNull);
      watch.stop();
      expect(watch.elapsedMilliseconds, lessThan(1000));
    });

    test('exact comparison results are unchanged', () {
      final minimum = SmartValidators.minValue('10.50');
      final maximum = SmartValidators.maxValue('0.30');
      expect(minimum('10.5'), isNull);
      expect(minimum('010.500'), isNull);
      expect(minimum('10.49999999999999999999'), isNotNull);
      expect(minimum('-0'), isNotNull);
      expect(maximum('0.3'), isNull);
      expect(maximum('.30'), isNull);
      expect(maximum('0.30000000000000000001'), isNotNull);
      expect(maximum('-0.0'), isNull);
    });
  });

  group('19S sensitive input does not train the keyboard', () {
    testWidgets('card and OTP fields disable personalized learning', (
      tester,
    ) async {
      await tester.pumpWidget(
        _page(
          Column(
            children: [
              SmartField.creditCard(),
              SmartField.otp(),
              SmartField.password(),
              SmartField(label: 'Notes'),
            ],
          ),
          width: 420,
        ),
      );
      await tester.pumpAndSettle();
      final editables = tester
          .widgetList<EditableText>(find.byType(EditableText))
          .toList();
      expect(editables.length, greaterThanOrEqualTo(6));
      expect(editables.last.enableIMEPersonalizedLearning, isTrue);
      for (final editable in editables.take(editables.length - 1)) {
        expect(editable.enableIMEPersonalizedLearning, isFalse);
      }
      for (final editable in editables.take(editables.length - 1)) {
        expect(editable.enableSuggestions, isFalse);
        expect(editable.autocorrect, isFalse);
      }
    });
  });

  group('19S narrow layouts do not overflow', () {
    for (final direction in TextDirection.values) {
      testWidgets('OTP boxes ${direction.name}', (tester) async {
        tester.view.physicalSize = const Size(1200, 3000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        for (final width in [120.0, 160.0, 200.0, 240.0, 320.0]) {
          for (final scale in [1.0, 2.0, 3.0]) {
            for (final length in [4, 6, 8]) {
              await tester.pumpWidget(
                _page(
                  SmartField.otp(length: length),
                  width: width,
                  scale: scale,
                  direction: direction,
                ),
              );
              await tester.pumpAndSettle();
              expect(
                tester.takeException(),
                isNull,
                reason: 'w$width x$scale length $length',
              );
              await tester.pumpWidget(const SizedBox());
            }
          }
        }
      });

      testWidgets('wheel date and time sheets ${direction.name}', (
        tester,
      ) async {
        addTearDown(tester.view.reset);
        for (final width in [200.0, 240.0, 280.0, 320.0]) {
          for (final scale in [1.0, 2.0, 3.0]) {
            for (final time in [false, true]) {
              tester.view.physicalSize = Size(width, 900);
              tester.view.devicePixelRatio = 1;
              await tester.pumpWidget(
                MaterialApp(
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: Directionality(
                      textDirection: direction,
                      child: child!,
                    ),
                  ),
                  home: Scaffold(
                    body: SingleChildScrollView(
                      child: time
                          ? SmartField.time(mode: SmartTimeMode.wheel)
                          : SmartField.date(
                              mode: SmartDateMode.wheel,
                              now: () => DateTime(2025, 6, 15),
                            ),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              await tester.tap(find.byType(TextField));
              await tester.pumpAndSettle();
              final reason = 'w$width x$scale time $time';
              expect(find.byType(TextButton), findsNWidgets(2), reason: reason);
              expect(tester.takeException(), isNull, reason: reason);
              await tester.pumpWidget(const SizedBox());
              await tester.pumpAndSettle();
            }
          }
        }
      });
    }

    testWidgets('OTP boxes shrinking from wide to narrow', (tester) async {
      for (final narrow in [90.0, 120.0, 200.0]) {
        await tester.pumpWidget(_page(SmartField.otp(), width: 400));
        await tester.pumpAndSettle();
        await tester.pumpWidget(_page(SmartField.otp(), width: narrow));
        for (var frame = 0; frame < 12; frame++) {
          await tester.pump(const Duration(milliseconds: 20));
          expect(
            tester.takeException(),
            isNull,
            reason: 'width $narrow frame $frame',
          );
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
    });
  });

  group('19S amount configuration changes', () {
    Future<void> change(
      WidgetTester tester, {
      required String start,
      required Widget Function(TextEditingController controller, bool changed)
      build,
      required String expected,
      required bool valid,
    }) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController(text: start);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _page(Form(key: formKey, child: build(controller, false))),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        _page(Form(key: formKey, child: build(controller, true))),
      );
      await tester.pumpAndSettle();
      expect(controller.text, expected);
      expect(formKey.currentState!.validate(), valid);
      String? saved;
      await tester.pumpWidget(
        _page(
          Form(
            key: formKey,
            child: KeyedSubtree(child: build(controller, true)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.text, expected);
      saved = controller.text;
      expect(saved, expected);
    }

    testWidgets('a new currency symbol', (tester) async {
      await change(
        tester,
        start: '1234.5',
        build: (controller, changed) => SmartField.amount(
          controller: controller,
          decimalPlaces: 2,
          useGrouping: true,
          currencySymbol: changed ? 'EUR ' : r'$',
        ),
        expected: 'EUR 1,234.50',
        valid: true,
      );
    });

    testWidgets('grouping switched off', (tester) async {
      await change(
        tester,
        start: '1234.5',
        build: (controller, changed) => SmartField.amount(
          controller: controller,
          decimalPlaces: 2,
          useGrouping: !changed,
        ),
        expected: '1234.50',
        valid: true,
      );
    });

    testWidgets('fewer decimal places drop only zeros', (tester) async {
      await change(
        tester,
        start: '12.5',
        build: (controller, changed) => SmartField.amount(
          controller: controller,
          decimalPlaces: changed ? 1 : 2,
        ),
        expected: '12.5',
        valid: true,
      );
      await change(
        tester,
        start: '12',
        build: (controller, changed) => SmartField.amount(
          controller: controller,
          decimalPlaces: changed ? 0 : 2,
        ),
        expected: '12',
        valid: true,
      );
    });

    testWidgets('fewer decimal places never discard entered digits', (
      tester,
    ) async {
      await change(
        tester,
        start: '12.55',
        build: (controller, changed) => SmartField.amount(
          controller: controller,
          decimalPlaces: changed ? 0 : 2,
        ),
        expected: '12.55',
        valid: false,
      );
    });

    testWidgets('new separators', (tester) async {
      await change(
        tester,
        start: '1234567.8',
        build: (controller, changed) => SmartField.amount(
          controller: controller,
          decimalPlaces: 2,
          useGrouping: true,
          groupingSeparator: changed ? '.' : ',',
          decimalSeparator: changed ? ',' : '.',
        ),
        expected: '1.234.567,80',
        valid: true,
      );
    });

    testWidgets('the form value and raw callback follow the new text', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController(text: '1234.5');
      addTearDown(controller.dispose);
      String? saved;
      String? raw;
      final changes = <String>[];
      Widget build(String symbol) => _page(
        Form(
          key: formKey,
          child: SmartField.amount(
            controller: controller,
            decimalPlaces: 2,
            useGrouping: true,
            currencySymbol: symbol,
            onChanged: changes.add,
            onSaved: (value) => saved = value,
            onRawSaved: (value) => raw = value,
          ),
        ),
      );
      await tester.pumpWidget(build(r'$'));
      await tester.pumpAndSettle();
      changes.clear();
      await tester.pumpWidget(build('PKR '));
      await tester.pumpAndSettle();
      expect(formKey.currentState!.validate(), isTrue);
      formKey.currentState!.save();
      expect(saved, 'PKR 1,234.50');
      expect(raw, '1234.50');
      expect(changes, isEmpty);
    });
  });

  group('19S typed dot with a dotted currency symbol', () {
    test('the symbol keeps its own dot', () {
      final formatter = SmartAmountFormatter(
        decimalSeparator: ',',
        groupingSeparator: ' ',
        currencySymbol: 'Rs.',
        acceptDotAsDecimal: true,
      );
      TextEditingValue paste(String text) => formatter.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        ),
      );
      expect(paste('Rs.50').text, '50');
      expect(paste('Rs.50.25').text, '50,25');
      expect(paste('50.25').text, '50,25');
      final suffix = SmartAmountFormatter(
        decimalSeparator: ',',
        groupingSeparator: ' ',
        currencySymbol: ' Rs.',
        currencyPosition: SmartCurrencyPosition.suffix,
        acceptDotAsDecimal: true,
      );
      expect(
        suffix
            .formatEditUpdate(
              TextEditingValue.empty,
              const TextEditingValue(
                text: '50.25 Rs.',
                selection: TextSelection.collapsed(offset: 9),
              ),
            )
            .text,
        '50,25',
      );
    });
  });

  group('19S verification codes', () {
    testWidgets('a pasted code with invisible characters fills every box', (
      tester,
    ) async {
      for (final pasted in [
        '12\u200b34\u200d56',
        '\u202a123456\u202c',
        '123\u2060456',
        '123\t456',
        '123\n456',
        '\u200e123-456\u200f',
      ]) {
        final controller = TextEditingController();
        final completed = <String>[];
        await tester.pumpWidget(
          _page(
            SmartField.otp(controller: controller, onCompleted: completed.add),
          ),
        );
        await tester.enterText(find.byType(EditableText).first, pasted);
        await tester.pumpAndSettle();
        expect(controller.text, '123456', reason: pasted.runes.toString());
        expect(completed, ['123456']);
        await tester.pumpWidget(const SizedBox());
        controller.dispose();
      }
    });

    testWidgets('a shorter length trims the code to what is shown', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController(text: '123456');
      addTearDown(controller.dispose);
      String? saved;
      Widget build(int length) => _page(
        Form(
          key: formKey,
          child: SmartField.otp(
            controller: controller,
            length: length,
            onSaved: (value) => saved = value,
          ),
        ),
      );
      await tester.pumpWidget(build(6));
      await tester.pumpAndSettle();
      await tester.pumpWidget(build(4));
      await tester.pumpAndSettle();
      expect(controller.text, '1234');
      expect(formKey.currentState!.validate(), isTrue);
      formKey.currentState!.save();
      expect(saved, '1234');
      await tester.pumpWidget(build(6));
      await tester.pumpAndSettle();
      expect(controller.text, '1234');
      expect(formKey.currentState!.validate(), isFalse);
    });
  });

  group('19S date and time bounds', () {
    testWidgets('pastOnly calendar ends on the day before today', (
      tester,
    ) async {
      for (final today in [
        DateTime(2025, 3, 10, 0, 30),
        DateTime(2025, 11, 3, 0, 30),
        DateTime(2025, 1, 1, 12),
        DateTime(2024, 3, 1, 23, 59),
      ]) {
        await tester.pumpWidget(
          _page(
            SmartField.date(
              mode: SmartDateMode.calendar,
              restriction: SmartDateRestriction.pastOnly,
              now: () => today,
            ),
          ),
        );
        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();
        final dialog = tester.widget<DatePickerDialog>(
          find.byType(DatePickerDialog),
        );
        final expected = DateTime(today.year, today.month, today.day - 1);
        expect(dialog.lastDate, expected, reason: '$today');
        expect(dialog.lastDate.hour, 0);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      }
    });

    testWidgets('a bound with seconds does not reject its own minute', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _page(
          Form(
            key: formKey,
            child: SmartField.dateTime(
              controller: controller,
              minDateTime: DateTime(2025, 6, 15, 10, 30, 45, 500),
              maxDateTime: DateTime(2025, 6, 15, 12, 0, 30),
            ),
          ),
          width: 420,
        ),
      );
      Future<bool> check(String text) async {
        controller.text = text;
        await tester.pump();
        return formKey.currentState!.validate();
      }

      expect(await check('15/06/2025 10:30'), isTrue);
      expect(await check('15/06/2025 10:29'), isFalse);
      expect(await check('15/06/2025 12:00'), isTrue);
      expect(await check('15/06/2025 12:01'), isFalse);
    });

    testWidgets('a reversed year range is refused while developing', (
      tester,
    ) async {
      expect(
        () => SmartField.date(
          mode: SmartDateMode.dropdowns,
          firstYear: 2030,
          lastYear: 2020,
        ),
        throwsAssertionError,
      );
      expect(
        () => SmartField.date(
          mode: SmartDateMode.dropdowns,
          firstYear: 2020,
          lastYear: 2020,
        ),
        returnsNormally,
      );
    });
  });

  group('19S URL and password character checks', () {
    test('a URL with an invisible or direction character is not valid', () {
      for (final value in [
        'https://exam\u200bple.com',
        'https://example.com/\u202egnp.exe',
        'https://example.com/\u2066a\u2069',
        'https://exa\u00admple.com',
        '\ufeffhttps://example.com',
        'https://example.com/a\u2060b',
        'https://example.com/\u200fa',
      ]) {
        expect(SmartUrlValidation.isValid(value), isFalse, reason: value);
        expect(SmartValidators.url()(value), isNotNull, reason: value);
      }
      for (final value in [
        'https://example.com',
        'https://example.com/path?q=1#top',
        'https://example.com/%E2%80%8B',
      ]) {
        expect(SmartUrlValidation.isValid(value), isTrue, reason: value);
      }
    });

    test('an invisible character is not a special character', () {
      final rule = SmartValidators.passwordRules({
        SmartBuiltInCheck.passwordSpecialCharacter,
      });
      for (final value in [
        'abc\u200bdef',
        'abc\u00a0def',
        'abc\u202edef',
        'abc\u0000def',
        'abc\u2028def',
        'abc\ufeffdef',
      ]) {
        expect(rule(value), isNotNull, reason: value.runes.toString());
      }
      for (final value in ['abc!def', 'abc_def', 'abc€def', 'abc😀def']) {
        expect(rule(value), isNull, reason: value);
      }
    });
  });

  group('19S decimal rounding errors carry no input text', () {
    test('the exception message does not repeat the value', () {
      const secret = '4111-1111-1111-1111';
      try {
        SmartDecimalUtils.round(
          secret,
          decimalPlaces: 2,
          mode: SmartRoundingMode.halfUp,
        );
        fail('expected a FormatException');
      } on FormatException catch (error) {
        expect(error.toString(), isNot(contains('4111')));
        expect(error.source, isNull);
      }
    });
  });

  group('19S contact selection with a shared dialing code', () {
    Future<SmartPhoneValue?> pick(
      WidgetTester tester, {
      required String contact,
      String? initialCountryCode,
      List<String>? allowed,
      List<SmartPhonePickerErrorCode>? errors,
    }) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      SmartPhoneValue? value;
      try {
        await tester.pumpWidget(
          _page(
            SmartField.phone(
              showCountryPicker: true,
              showContactPicker: true,
              initialCountryCode: initialCountryCode,
              allowedCountryCodes: allowed,
              contactPicker: () async => contact,
              onPhoneChanged: (next) => value = next,
              onContactPickerError: errors == null
                  ? null
                  : (error) => errors.add(error.code),
            ),
            width: 420,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.contact_phone));
        await tester.pumpAndSettle();
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
      return value;
    }

    testWidgets('a Canadian contact replaces a selected United States', (
      tester,
    ) async {
      final value = await pick(
        tester,
        contact: '+1 416 555 0123',
        initialCountryCode: 'US',
      );
      expect(value?.country?.isoCode, 'CA');
      expect(value?.e164, '+14165550123');
      expect(value?.isValid, isTrue);
    }, skip: skipContactPickerOnWeb);

    testWidgets('a United States contact keeps a selected United States', (
      tester,
    ) async {
      final value = await pick(
        tester,
        contact: '+1 415 555 2671',
        initialCountryCode: 'US',
      );
      expect(value?.country?.isoCode, 'US');
      expect(value?.e164, '+14155552671');
    }, skip: skipContactPickerOnWeb);

    testWidgets('a Kazakh contact replaces a selected Russia', (tester) async {
      final value = await pick(
        tester,
        contact: '+7 701 234 5678',
        initialCountryCode: 'RU',
      );
      expect(value?.country?.isoCode, 'KZ');
      expect(value?.e164, '+77012345678');
    }, skip: skipContactPickerOnWeb);

    testWidgets('a United Kingdom contact replaces a selected United States', (
      tester,
    ) async {
      final value = await pick(
        tester,
        contact: '+44 7400 123456',
        initialCountryCode: 'US',
      );
      expect(value?.country?.isoCode, 'GB');
      expect(value?.e164, '+447400123456');
      expect(value?.isValid, isTrue);
    }, skip: skipContactPickerOnWeb);

    testWidgets('without a selected country nothing is guessed', (
      tester,
    ) async {
      final value = await pick(tester, contact: '+1 416 555 0123');
      expect(value?.country?.isoCode, isNull);
      expect(value?.e164, '+14165550123');
    }, skip: skipContactPickerOnWeb);

    testWidgets('a restricted list still refuses a country outside it', (
      tester,
    ) async {
      final errors = <SmartPhonePickerErrorCode>[];
      final value = await pick(
        tester,
        contact: '+44 20 7946 0958',
        initialCountryCode: 'US',
        allowed: ['US', 'CA'],
        errors: errors,
      );
      expect(errors, [SmartPhonePickerErrorCode.disallowedCountry]);
      expect(value, isNull);
    }, skip: skipContactPickerOnWeb);
  });
}
