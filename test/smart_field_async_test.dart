import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child, {TextDirection direction = TextDirection.ltr}) {
  return MaterialApp(
    home: Directionality(
      textDirection: direction,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    ),
  );
}

const _debounce = Duration(milliseconds: 400);

void main() {
  _compositionTests();
  testWidgets('does nothing without an async validator', (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(_app(SmartField.username()));
    await tester.enterText(find.byType(TextFormField), 'abc');
    await tester.pump(_debounce);
    expect(calls, isEmpty);
  });

  testWidgets('debounces edits and passes the raw value', (tester) async {
    final calls = <String>[];
    final controller = SmartFieldAsyncController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        SmartField(
          asyncValidation: SmartAsyncValidation(
            controller: controller,
            validator: (value) async {
              calls.add(value);
              return null;
            },
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'a');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextFormField), 'ab');
    await tester.pump(const Duration(milliseconds: 300));
    expect(calls, isEmpty);
    await tester.pump(const Duration(milliseconds: 150));
    expect(calls, ['ab']);
    expect(controller.status, SmartAsyncValidationStatus.valid);
    await tester.pump(const Duration(seconds: 2));
    expect(calls, ['ab']);
  });

  testWidgets('zero debounce runs immediately and rebuilds do not recheck', (
    tester,
  ) async {
    final calls = <String>[];
    Widget build() => _app(
      SmartField(
        asyncValidation: SmartAsyncValidation(
          debounceDuration: Duration.zero,
          validator: (value) async {
            calls.add(value);
            return null;
          },
        ),
      ),
    );
    await tester.pumpWidget(build());
    await tester.enterText(find.byType(TextFormField), 'x');
    await tester.pump();
    expect(calls, ['x']);
    await tester.pumpWidget(build());
    await tester.pumpWidget(build());
    await tester.pump(const Duration(seconds: 2));
    expect(calls, ['x']);
  });

  testWidgets('optional empty and invalid syntax never call the checker', (
    tester,
  ) async {
    final calls = <String>[];
    await tester.pumpWidget(
      _app(
        SmartField.email(
          asyncValidation: SmartAsyncValidation(
            debounceDuration: Duration.zero,
            validator: (value) async {
              calls.add(value);
              return null;
            },
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), '');
    await tester.enterText(find.byType(TextFormField), 'not-an-email');
    await tester.pump(_debounce);
    expect(calls, isEmpty);
    await tester.enterText(find.byType(TextFormField), 'a@example.com');
    await tester.pump();
    expect(calls, ['a@example.com']);
  });

  testWidgets('required empty shows the required error and skips the checker', (
    tester,
  ) async {
    final calls = <String>[];
    final formKey = GlobalKey<FormState>();
    final controller = SmartFieldAsyncController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField.username(
            isRequired: true,
            requiredErrorText: 'Required',
            asyncValidation: SmartAsyncValidation(
              controller: controller,
              validator: (value) async {
                calls.add(value);
                return null;
              },
            ),
          ),
        ),
      ),
    );
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Required'), findsOneWidget);
    expect(await controller.validateAsync(), isFalse);
    expect(calls, isEmpty);
  });

  testWidgets('rejection shows the returned message and blocks validate', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField.username(
            asyncValidation: SmartAsyncValidation(
              debounceDuration: Duration.zero,
              validator: (value) async => 'Taken',
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'alice');
    await tester.pump();
    await tester.pump();
    expect(find.text('Taken'), findsOneWidget);
    expect(formKey.currentState!.validate(), isFalse);
    await tester.enterText(find.byType(TextFormField), 'bob');
    await tester.pump();
    expect(formKey.currentState!.validate(), isFalse);
  });

  testWidgets('failures and timeouts become unavailable and never pass', (
    tester,
  ) async {
    final controller = SmartFieldAsyncController();
    final formKey = GlobalKey<FormState>();
    addTearDown(controller.dispose);
    var mode = 0;
    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField(
            asyncValidation: SmartAsyncValidation(
              controller: controller,
              debounceDuration: Duration.zero,
              timeout: const Duration(seconds: 1),
              unavailableErrorText: 'Offline',
              validator: (value) {
                if (mode == 0) {
                  throw const FormatException('network');
                }
                return Completer<String?>().future;
              },
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'abc');
    await tester.pump();
    await tester.pump();
    expect(controller.status, SmartAsyncValidationStatus.unavailable);
    expect(find.text('Offline'), findsOneWidget);
    expect(formKey.currentState!.validate(), isFalse);
    expect(await controller.validateAsync(), isFalse);

    mode = 1;
    final future = controller.validateAsync();
    await tester.pump();
    expect(controller.status, SmartAsyncValidationStatus.pending);
    await tester.pump(const Duration(seconds: 2));
    expect(await future, isFalse);
    expect(controller.status, SmartAsyncValidationStatus.unavailable);
  });

  testWidgets('ignores out-of-order results', (tester) async {
    final controller = SmartFieldAsyncController();
    addTearDown(controller.dispose);
    final completers = <String, Completer<String?>>{};
    await tester.pumpWidget(
      _app(
        SmartField(
          asyncValidation: SmartAsyncValidation(
            controller: controller,
            debounceDuration: Duration.zero,
            validator: (value) {
              final completer = Completer<String?>();
              completers[value] = completer;
              return completer.future;
            },
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'old');
    await tester.pump();
    await tester.enterText(find.byType(TextFormField), 'new');
    await tester.pump();
    completers['new']!.complete(null);
    await tester.pump();
    expect(controller.status, SmartAsyncValidationStatus.valid);
    completers['old']!.complete('Old error');
    await tester.pump();
    expect(controller.status, SmartAsyncValidationStatus.valid);
    expect(find.text('Old error'), findsNothing);
  });

  testWidgets('clearing during a check discards its result', (tester) async {
    final controller = SmartFieldAsyncController();
    final text = TextEditingController();
    final completer = Completer<String?>();
    addTearDown(controller.dispose);
    addTearDown(text.dispose);
    await tester.pumpWidget(
      _app(
        SmartField(
          controller: text,
          asyncValidation: SmartAsyncValidation(
            controller: controller,
            debounceDuration: Duration.zero,
            validator: (value) => completer.future,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'abc');
    await tester.pump();
    expect(controller.status, SmartAsyncValidationStatus.pending);
    text.clear();
    await tester.pump();
    expect(controller.status, SmartAsyncValidationStatus.idle);
    completer.complete('Late');
    await tester.pump();
    expect(controller.status, SmartAsyncValidationStatus.idle);
    expect(find.text('Late'), findsNothing);
  });

  testWidgets('manual trigger runs only on validateAsync, immediately', (
    tester,
  ) async {
    final calls = <String>[];
    final controller = SmartFieldAsyncController();
    final formKey = GlobalKey<FormState>();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField.username(
            asyncValidation: SmartAsyncValidation(
              controller: controller,
              trigger: SmartAsyncValidationTrigger.manual,
              validator: (value) async {
                calls.add(value);
                return null;
              },
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'alice');
    await tester.pump(const Duration(seconds: 2));
    expect(calls, isEmpty);
    expect(await controller.validateAsync(), isTrue);
    expect(calls, ['alice']);
    expect(await controller.validateAsync(), isTrue);
    expect(calls, ['alice']);
    expect(await controller.validateAsync(force: true), isTrue);
    expect(calls, ['alice', 'alice']);
    await tester.enterText(find.byType(TextFormField), 'alice2');
    expect(controller.status, SmartAsyncValidationStatus.idle);
  });

  testWidgets('unfocus trigger validates when focus leaves', (tester) async {
    final calls = <String>[];
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      _app(
        SmartField(
          focusNode: focusNode,
          asyncValidation: SmartAsyncValidation(
            trigger: SmartAsyncValidationTrigger.onUnfocus,
            validator: (value) async {
              calls.add(value);
              return null;
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TextFormField));
    await tester.enterText(find.byType(TextFormField), 'abc');
    await tester.pump(const Duration(seconds: 2));
    expect(calls, isEmpty);
    focusNode.unfocus();
    await tester.pump();
    expect(calls, ['abc']);
  });

  testWidgets('validateAsync keeps validate synchronous and gates submit', (
    tester,
  ) async {
    final controller = SmartFieldAsyncController();
    final formKey = GlobalKey<FormState>();
    final text = TextEditingController();
    final completer = Completer<String?>();
    addTearDown(controller.dispose);
    addTearDown(text.dispose);
    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField.username(
            controller: text,
            asyncValidation: SmartAsyncValidation(
              controller: controller,
              trigger: SmartAsyncValidationTrigger.manual,
              validator: (value) => completer.future,
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'alice');
    expect(formKey.currentState!.validate(), isTrue);
    final result = controller.validateAsync();
    await tester.pump();
    expect(formKey.currentState!.validate(), isTrue);
    text.text = 'alice2';
    completer.complete(null);
    expect(await result, isFalse);
    expect(controller.status, SmartAsyncValidationStatus.idle);
  });

  testWidgets('does not pass password or percent display text', (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            SmartField.percentage(
              asyncValidation: SmartAsyncValidation(
                debounceDuration: Duration.zero,
                validator: (value) async {
                  calls.add(value);
                  return null;
                },
              ),
            ),
            SmartField.amount(
              decimalPlaces: 2,
              useGrouping: true,
              currencySymbol: '\$',
              asyncValidation: SmartAsyncValidation(
                debounceDuration: Duration.zero,
                validator: (value) async {
                  calls.add(value);
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField).first, '12.5');
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).last, '1200.50');
    await tester.pump();
    expect(calls.first, '12.5');
    expect(calls.last, isNot(contains('\$')));
    expect(calls.last, isNot(contains(',')));
  });

  testWidgets('shows a loading indicator while pending', (tester) async {
    final completer = Completer<String?>();
    await tester.pumpWidget(
      _app(
        SmartField(
          asyncValidation: SmartAsyncValidation(
            debounceDuration: Duration.zero,
            loadingSemanticsLabel: 'Checking',
            validator: (value) => completer.future,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'abc');
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    completer.complete(null);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('custom loading indicator, dark theme, RTL, scale, no edits', (
    tester,
  ) async {
    final completer = Completer<String?>();
    final text = TextEditingController();
    addTearDown(text.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(2),
            size: Size(200, 600),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: SmartField.url(
                controller: text,
                label: 'Website',
                asyncValidation: SmartAsyncValidation(
                  debounceDuration: Duration.zero,
                  loadingIndicator: const Icon(Icons.hourglass_empty),
                  validator: (value) => completer.future,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'https://a.com/x');
    await tester.pump();
    expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
    expect(text.text, 'https://a.com/x');
    expect(tester.takeException(), isNull);
    completer.complete('No');
    await tester.pump();
    expect(text.text, 'https://a.com/x');
  });

  testWidgets('disposal and disabling ignore late results', (tester) async {
    final completer = Completer<String?>();
    final controller = SmartFieldAsyncController();
    addTearDown(controller.dispose);
    Widget build({bool enabled = true, bool present = true}) => _app(
      present
          ? SmartField(
              enabled: enabled,
              asyncValidation: SmartAsyncValidation(
                controller: controller,
                debounceDuration: Duration.zero,
                validator: (value) => completer.future,
              ),
            )
          : const SizedBox(),
    );
    await tester.pumpWidget(build());
    await tester.enterText(find.byType(TextFormField), 'abc');
    await tester.pump();
    expect(controller.status, SmartAsyncValidationStatus.pending);
    await tester.pumpWidget(build(enabled: false));
    expect(controller.status, SmartAsyncValidationStatus.idle);
    await tester.pumpWidget(build(present: false));
    completer.complete('Late');
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(await controller.validateAsync(), isFalse);
  });

  testWidgets('form reset clears async state', (tester) async {
    final formKey = GlobalKey<FormState>();
    final controller = SmartFieldAsyncController();
    final text = TextEditingController();
    addTearDown(controller.dispose);
    addTearDown(text.dispose);
    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: SmartField(
            controller: text,
            asyncValidation: SmartAsyncValidation(
              controller: controller,
              debounceDuration: Duration.zero,
              validator: (value) async => 'Taken',
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'abc');
    await tester.pump();
    await tester.pump();
    expect(controller.status, SmartAsyncValidationStatus.invalid);
    formKey.currentState!.reset();
    await tester.pump();
    expect(controller.status, SmartAsyncValidationStatus.idle);
    expect(find.text('Taken'), findsNothing);
  });

  testWidgets('swapping the text controller resets the async state', (
    tester,
  ) async {
    final async = SmartFieldAsyncController();
    final first = TextEditingController();
    final second = TextEditingController(text: 'other');
    addTearDown(async.dispose);
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    Widget build(TextEditingController text) => _app(
      SmartField(
        controller: text,
        asyncValidation: SmartAsyncValidation(
          controller: async,
          debounceDuration: Duration.zero,
          validator: (value) async => null,
        ),
      ),
    );
    await tester.pumpWidget(build(first));
    await tester.enterText(find.byType(TextFormField), 'abc');
    await tester.pump();
    expect(async.status, SmartAsyncValidationStatus.valid);
    await tester.pumpWidget(build(second));
    expect(async.status, SmartAsyncValidationStatus.idle);
  });

  testWidgets('otp completion is not repeated by async state changes', (
    tester,
  ) async {
    var completed = 0;
    final controller = SmartFieldAsyncController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        SmartField.otp(
          onCompleted: (_) => completed++,
          asyncValidation: SmartAsyncValidation(
            controller: controller,
            debounceDuration: Duration.zero,
            validator: (value) async => 'Wrong code',
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(EditableText), '123456');
    await tester.pump();
    await tester.pump();
    expect(completed, 1);
    expect(controller.status, SmartAsyncValidationStatus.invalid);
    expect(find.text('Wrong code'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(completed, 1);
  });

  testWidgets('search callback stays separate from async validation', (
    tester,
  ) async {
    final searches = <String>[];
    final checks = <String>[];
    await tester.pumpWidget(
      _app(
        SmartField.search(
          onSearch: searches.add,
          debounceDuration: Duration.zero,
          asyncValidation: SmartAsyncValidation(
            debounceDuration: Duration.zero,
            validator: (value) async {
              checks.add(value);
              return null;
            },
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'shoes');
    await tester.pump();
    expect(searches, ['shoes']);
    expect(checks, ['shoes']);
  });

  testWidgets('description keeps growing with async enabled', (tester) async {
    await tester.pumpWidget(
      _app(
        SmartField.description(
          asyncValidation: SmartAsyncValidation(
            debounceDuration: Duration.zero,
            validator: (value) async => null,
          ),
        ),
      ),
    );
    final before = tester.getSize(find.byType(TextFormField)).height;
    await tester.enterText(find.byType(TextFormField), 'a\nb\nc\nd\ne\nf');
    await tester.pump();
    expect(
      tester.getSize(find.byType(TextFormField)).height,
      greaterThan(before),
    );
  });

  group('configuration transitions', () {
    testWidgets(
      'a forced check replaces an accepted result with the new rule',
      (tester) async {
        final text = TextEditingController();
        final async = SmartFieldAsyncController();
        var firstCalls = 0;
        var secondCalls = 0;
        Future<String?> first(String value) async {
          firstCalls++;
          return null;
        }

        Future<String?> second(String value) async {
          secondCalls++;
          return 'Rejected by B';
        }

        addTearDown(text.dispose);
        addTearDown(async.dispose);
        Widget build(SmartAsyncValidator validator) => _app(
          SmartField(
            controller: text,
            asyncValidation: SmartAsyncValidation(
              controller: async,
              trigger: SmartAsyncValidationTrigger.manual,
              validator: validator,
            ),
          ),
        );

        await tester.pumpWidget(build(first));
        await tester.enterText(find.byType(TextFormField), 'candidate');
        expect(await async.validateAsync(), isTrue);
        await tester.pumpWidget(build(second));
        expect(await async.validateAsync(), isTrue);
        expect(secondCalls, 0);
        expect(await async.validateAsync(force: true), isFalse);
        await tester.pump();
        expect(firstCalls, 1);
        expect(secondCalls, 1);
        expect(find.text('Rejected by B'), findsOneWidget);
      },
    );

    testWidgets('a forced check replaces a rejected result with the new rule', (
      tester,
    ) async {
      final text = TextEditingController(text: 'candidate');
      final async = SmartFieldAsyncController();
      var secondCalls = 0;
      Future<String?> first(String value) async => 'Rejected by A';
      Future<String?> second(String value) async {
        secondCalls++;
        return null;
      }

      addTearDown(text.dispose);
      addTearDown(async.dispose);
      Widget build(SmartAsyncValidator validator) => _app(
        SmartField(
          controller: text,
          asyncValidation: SmartAsyncValidation(
            controller: async,
            trigger: SmartAsyncValidationTrigger.manual,
            validator: validator,
          ),
        ),
      );

      await tester.pumpWidget(build(first));
      expect(await async.validateAsync(), isFalse);
      await tester.pumpWidget(build(second));
      expect(await async.validateAsync(), isFalse);
      expect(secondCalls, 0);
      expect(await async.validateAsync(force: true), isTrue);
      expect(secondCalls, 1);
      expect(async.status, SmartAsyncValidationStatus.valid);
    });

    testWidgets(
      'a forced check replaces a pending one and ignores its result',
      (tester) async {
        final text = TextEditingController(text: 'candidate');
        final async = SmartFieldAsyncController();
        final first = Completer<String?>();
        final second = Completer<String?>();
        var secondCalls = 0;
        addTearDown(text.dispose);
        addTearDown(async.dispose);
        Widget build(SmartAsyncValidator validator) => _app(
          SmartField(
            controller: text,
            asyncValidation: SmartAsyncValidation(
              controller: async,
              trigger: SmartAsyncValidationTrigger.manual,
              validator: validator,
            ),
          ),
        );

        await tester.pumpWidget(build((value) => first.future));
        final obsolete = async.validateAsync();
        await tester.pump();
        await tester.pumpWidget(
          build((value) {
            secondCalls++;
            return second.future;
          }),
        );
        final joined = async.validateAsync();
        await tester.pump();
        expect(secondCalls, 0);
        final latest = async.validateAsync(force: true);
        await tester.pump();
        expect(secondCalls, 1);
        second.complete('Rejected by B');
        await tester.pump();
        expect(await latest, isFalse);
        expect(async.status, SmartAsyncValidationStatus.invalid);
        first.complete(null);
        await tester.pump();
        expect(await obsolete, isFalse);
        expect(await joined, isFalse);
        expect(async.status, SmartAsyncValidationStatus.invalid);
        expect(async.errorText, 'Rejected by B');
      },
    );

    testWidgets('removing async validation detaches pending work', (
      tester,
    ) async {
      final text = TextEditingController(text: 'candidate');
      final async = SmartFieldAsyncController();
      final pending = Completer<String?>();
      addTearDown(text.dispose);
      addTearDown(async.dispose);
      await tester.pumpWidget(
        _app(
          SmartField(
            controller: text,
            asyncValidation: SmartAsyncValidation(
              controller: async,
              trigger: SmartAsyncValidationTrigger.manual,
              validator: (value) => pending.future,
            ),
          ),
        ),
      );
      final obsolete = async.validateAsync();
      await tester.pump();
      await tester.pumpWidget(_app(SmartField(controller: text)));
      pending.complete('Late');
      await tester.pump();
      expect(await obsolete, isFalse);
      expect(async.status, SmartAsyncValidationStatus.idle);
      expect(await async.validateAsync(), isFalse);
      expect(find.text('Late'), findsNothing);
    });

    testWidgets('adding async validation observes existing populated text', (
      tester,
    ) async {
      final text = TextEditingController(text: 'candidate');
      final calls = <String>[];
      addTearDown(text.dispose);
      await tester.pumpWidget(_app(SmartField(controller: text)));
      await tester.pumpWidget(
        _app(
          SmartField(
            controller: text,
            asyncValidation: SmartAsyncValidation(
              debounceDuration: Duration.zero,
              validator: (value) async {
                calls.add(value);
                return null;
              },
            ),
          ),
        ),
      );
      await tester.pump();
      expect(calls, ['candidate']);
    });

    testWidgets('disabling invalidates pending validation', (tester) async {
      final text = TextEditingController(text: 'candidate');
      final async = SmartFieldAsyncController();
      final pending = Completer<String?>();
      addTearDown(text.dispose);
      addTearDown(async.dispose);
      Widget build(bool enabled) => _app(
        SmartField(
          controller: text,
          enabled: enabled,
          asyncValidation: SmartAsyncValidation(
            controller: async,
            trigger: SmartAsyncValidationTrigger.manual,
            validator: (value) => pending.future,
          ),
        ),
      );

      await tester.pumpWidget(build(true));
      final obsolete = async.validateAsync();
      await tester.pump();
      await tester.pumpWidget(build(false));
      expect(async.status, SmartAsyncValidationStatus.idle);
      pending.complete('Late');
      await tester.pump();
      expect(await obsolete, isFalse);
      expect(async.status, SmartAsyncValidationStatus.idle);
    });

    testWidgets('equivalent configuration keeps a valid cached result', (
      tester,
    ) async {
      final text = TextEditingController(text: 'candidate');
      final async = SmartFieldAsyncController();
      var calls = 0;
      Future<String?> validator(String value) async {
        calls++;
        return null;
      }

      final config = SmartAsyncValidation(
        controller: async,
        trigger: SmartAsyncValidationTrigger.manual,
        validator: validator,
      );
      addTearDown(text.dispose);
      addTearDown(async.dispose);
      Widget build() =>
          _app(SmartField(controller: text, asyncValidation: config));

      await tester.pumpWidget(build());
      expect(await async.validateAsync(), isTrue);
      await tester.pumpWidget(build());
      expect(await async.validateAsync(), isTrue);
      expect(calls, 1);
      expect(async.status, SmartAsyncValidationStatus.valid);
    });

    testWidgets(
      'a pending onChanged check continues after the validator changes',
      (tester) async {
        final text = TextEditingController();
        final async = SmartFieldAsyncController();
        final first = Completer<String?>();
        final calls = <String>[];
        addTearDown(text.dispose);
        addTearDown(async.dispose);
        Widget build(SmartAsyncValidator validator) => _app(
          SmartField(
            controller: text,
            asyncValidation: SmartAsyncValidation(
              controller: async,
              debounceDuration: Duration.zero,
              validator: validator,
            ),
          ),
        );

        await tester.pumpWidget(build((value) => first.future));
        await tester.enterText(find.byType(TextFormField), 'candidate');
        await tester.pump();
        expect(async.status, SmartAsyncValidationStatus.pending);
        await tester.pumpWidget(
          build((value) async {
            calls.add(value);
            return 'Rejected by B';
          }),
        );
        await tester.pump();
        await tester.pump();
        expect(calls, isEmpty);
        expect(async.status, SmartAsyncValidationStatus.pending);
        first.complete(null);
        await tester.pump();
        expect(async.status, SmartAsyncValidationStatus.valid);
        expect(await async.validateAsync(force: true), isFalse);
        expect(calls, ['candidate']);
        expect(async.status, SmartAsyncValidationStatus.invalid);
        expect(async.errorText, 'Rejected by B');
      },
    );
  });
}

void _compositionTests() {
  group('IME composition', () {
    Widget build(
      List<String> calls, {
      Completer<String?>? gate,
      bool enabled = true,
    }) => _app(
      SmartField(
        enabled: enabled,
        asyncValidation: SmartAsyncValidation(
          debounceDuration: Duration.zero,
          validator: (value) {
            calls.add(value);
            return gate?.future ?? Future<String?>.value();
          },
        ),
      ),
    );

    testWidgets('uncommitted composing text is not validated', (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(build(calls));
      await tester.showKeyboard(find.byType(EditableText));
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'ka',
          selection: TextSelection.collapsed(offset: 2),
          composing: TextRange(start: 0, end: 2),
        ),
      );
      await tester.pump();
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'kan',
          selection: TextSelection.collapsed(offset: 3),
          composing: TextRange(start: 0, end: 3),
        ),
      );
      await tester.pump();
      expect(calls, isEmpty);
    });

    testWidgets('the committed value is validated once', (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(build(calls));
      await tester.showKeyboard(find.byType(EditableText));
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'ka',
          selection: TextSelection.collapsed(offset: 2),
          composing: TextRange(start: 0, end: 2),
        ),
      );
      await tester.pump();
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'か',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      await tester.pump();
      expect(calls, ['か']);
    });

    testWidgets('unchanged text at commit is still validated once', (
      tester,
    ) async {
      final calls = <String>[];
      await tester.pumpWidget(build(calls));
      await tester.showKeyboard(find.byType(EditableText));
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'abc',
          selection: TextSelection.collapsed(offset: 3),
          composing: TextRange(start: 0, end: 3),
        ),
      );
      await tester.pump();
      expect(calls, isEmpty);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'abc',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      await tester.pump();
      expect(calls, ['abc']);
    });

    testWidgets('a pending result is dropped when composition resumes', (
      tester,
    ) async {
      final calls = <String>[];
      final gate = Completer<String?>();
      await tester.pumpWidget(build(calls, gate: gate));
      await tester.enterText(find.byType(EditableText), 'abc');
      await tester.pump();
      expect(calls, ['abc']);
      await tester.showKeyboard(find.byType(EditableText));
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'abcd',
          selection: TextSelection.collapsed(offset: 4),
          composing: TextRange(start: 3, end: 4),
        ),
      );
      await tester.pump();
      gate.complete('Rejected');
      await tester.pump();
      expect(find.text('Rejected'), findsNothing);
      expect(calls, ['abc']);
    });
  });
}
