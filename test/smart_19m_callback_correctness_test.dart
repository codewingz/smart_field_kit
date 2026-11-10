import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  ),
);

class _StatusHost extends StatefulWidget {
  const _StatusHost({required this.controller, required this.validator});

  final SmartFieldAsyncController controller;
  final Future<String?> Function(String value) validator;

  @override
  State<_StatusHost> createState() => _StatusHostState();
}

class _StatusHostState extends State<_StatusHost> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('status ${widget.controller.status.name}'),
        SmartField.username(
          asyncValidation: SmartAsyncValidation(
            controller: widget.controller,
            debounceDuration: Duration.zero,
            validator: (value) => widget.validator(value),
          ),
        ),
      ],
    );
  }
}

const _quiet = Duration(milliseconds: 300);

void main() {
  group('19M async validation with inline validators', () {
    testWidgets('a rejection survives a parent rebuild without a request', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final calls = <String>[];
      late StateSetter rebuild;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return Form(
                key: formKey,
                child: SmartField.username(
                  asyncValidation: SmartAsyncValidation(
                    debounceDuration: const Duration(milliseconds: 100),
                    validator: (value) async {
                      calls.add(value);
                      return value == 'alice' ? 'Taken' : null;
                    },
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'alice');
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();
      expect(find.text('Taken'), findsOneWidget);
      expect(formKey.currentState!.validate(), isFalse);
      expect(calls, ['alice']);

      for (var i = 0; i < 5; i++) {
        rebuild(() {});
        await tester.pump();
        await tester.pump();
      }
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Taken'), findsOneWidget);
      expect(formKey.currentState!.validate(), isFalse);
      expect(calls, ['alice']);
    });

    testWidgets('an accepted result survives rebuilds and is reused', (
      tester,
    ) async {
      final controller = SmartFieldAsyncController();
      addTearDown(controller.dispose);
      var calls = 0;
      late StateSetter rebuild;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return SmartField.username(
                asyncValidation: SmartAsyncValidation(
                  controller: controller,
                  debounceDuration: Duration.zero,
                  validator: (value) async {
                    calls++;
                    return null;
                  },
                ),
              );
            },
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'bob');
      await tester.pump();
      expect(controller.status, SmartAsyncValidationStatus.valid);
      rebuild(() {});
      await tester.pump();
      await tester.pump();
      expect(controller.status, SmartAsyncValidationStatus.valid);
      expect(await controller.validateAsync(), isTrue);
      expect(calls, 1);
    });

    testWidgets('a status listener that rebuilds does not restart the check', (
      tester,
    ) async {
      final controller = SmartFieldAsyncController();
      addTearDown(controller.dispose);
      final never = Completer<String?>();
      final statuses = <SmartAsyncValidationStatus>[];
      controller.addListener(() => statuses.add(controller.status));
      var calls = 0;
      await tester.pumpWidget(
        _app(
          _StatusHost(
            controller: controller,
            validator: (value) {
              calls++;
              return never.future;
            },
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'alice');
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(calls, 1);
      expect(statuses, [SmartAsyncValidationStatus.pending]);
      expect(find.text('status pending'), findsOneWidget);
    });

    testWidgets('a slow check completes once after status-driven rebuilds', (
      tester,
    ) async {
      final controller = SmartFieldAsyncController();
      addTearDown(controller.dispose);
      final slow = Completer<String?>();
      final statuses = <SmartAsyncValidationStatus>[];
      controller.addListener(() => statuses.add(controller.status));
      var calls = 0;
      await tester.pumpWidget(
        _app(
          _StatusHost(
            controller: controller,
            validator: (value) {
              calls++;
              return slow.future;
            },
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'alice');
      await tester.pump(const Duration(seconds: 3));
      slow.complete('Taken');
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(calls, 1);
      expect(statuses, [
        SmartAsyncValidationStatus.pending,
        SmartAsyncValidationStatus.invalid,
      ]);
      expect(find.text('Taken'), findsOneWidget);
      expect(find.text('status invalid'), findsOneWidget);
    });

    testWidgets('ValueListenableBuilder rebuilds keep a debounced check', (
      tester,
    ) async {
      final ticks = ValueNotifier<int>(0);
      addTearDown(ticks.dispose);
      final calls = <String>[];
      await tester.pumpWidget(
        _app(
          ValueListenableBuilder<int>(
            valueListenable: ticks,
            builder: (context, tick, _) => SmartField.username(
              label: 'User $tick',
              asyncValidation: SmartAsyncValidation(
                validator: (value) async {
                  calls.add(value);
                  return 'Taken';
                },
              ),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'alice');
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        ticks.value++;
        await tester.pump();
      }
      expect(calls, isEmpty);
      await tester.pump(const Duration(milliseconds: 99));
      expect(calls, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(calls, ['alice']);
      for (var i = 0; i < 3; i++) {
        ticks.value++;
        await tester.pump();
        await tester.pump();
      }
      expect(calls, ['alice']);
      expect(find.text('Taken'), findsOneWidget);
    });

    testWidgets('a timeout still ends a check that never completes', (
      tester,
    ) async {
      final controller = SmartFieldAsyncController();
      addTearDown(controller.dispose);
      final never = Completer<String?>();
      var calls = 0;
      late StateSetter rebuild;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return SmartField.username(
                asyncValidation: SmartAsyncValidation(
                  controller: controller,
                  debounceDuration: Duration.zero,
                  timeout: const Duration(seconds: 1),
                  validator: (value) {
                    calls++;
                    return never.future;
                  },
                ),
              );
            },
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'alice');
      await tester.pump(const Duration(milliseconds: 500));
      rebuild(() {});
      await tester.pump(const Duration(milliseconds: 499));
      expect(controller.status, SmartAsyncValidationStatus.pending);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(controller.status, SmartAsyncValidationStatus.unavailable);
      expect(calls, 1);
      rebuild(() {});
      await tester.pump();
      await tester.pump();
      expect(controller.status, SmartAsyncValidationStatus.unavailable);
      expect(calls, 1);
    });

    testWidgets('a text change starts one new check and drops the old one', (
      tester,
    ) async {
      final controller = SmartFieldAsyncController();
      addTearDown(controller.dispose);
      final gates = <String, Completer<String?>>{};
      final calls = <String>[];
      await tester.pumpWidget(
        _app(
          _StatusHost(
            controller: controller,
            validator: (value) {
              calls.add(value);
              return (gates[value] = Completer<String?>()).future;
            },
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'alice');
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), 'alicia');
      await tester.pump();
      await tester.pump();
      expect(calls, ['alice', 'alicia']);
      gates['alicia']!.complete(null);
      await tester.pump();
      gates['alice']!.complete('Taken');
      await tester.pump();
      await tester.pump();
      expect(controller.status, SmartAsyncValidationStatus.valid);
      expect(find.text('Taken'), findsNothing);
      expect(calls, ['alice', 'alicia']);
    });

    testWidgets('a rule change is applied by validateAsync(force: true)', (
      tester,
    ) async {
      final controller = SmartFieldAsyncController();
      addTearDown(controller.dispose);
      final calls = <String>[];
      var blocked = 'alice';
      late StateSetter rebuild;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return SmartField.username(
                asyncValidation: SmartAsyncValidation(
                  controller: controller,
                  debounceDuration: Duration.zero,
                  validator: (value) async {
                    calls.add('$blocked:$value');
                    return value == blocked ? 'Taken' : null;
                  },
                ),
              );
            },
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'alice');
      await tester.pump();
      await tester.pump();
      expect(find.text('Taken'), findsOneWidget);

      rebuild(() => blocked = 'bob');
      await tester.pump();
      await tester.pump();
      expect(find.text('Taken'), findsOneWidget);
      expect(await controller.validateAsync(), isFalse);
      expect(calls, ['alice:alice']);

      expect(await controller.validateAsync(force: true), isTrue);
      await tester.pump();
      await tester.pump();
      expect(calls, ['alice:alice', 'bob:alice']);
      expect(controller.status, SmartAsyncValidationStatus.valid);
      expect(find.text('Taken'), findsNothing);
    });

    testWidgets('a replaced validator function is used by a forced check', (
      tester,
    ) async {
      final controller = SmartFieldAsyncController();
      final text = TextEditingController(text: 'alice');
      addTearDown(controller.dispose);
      addTearDown(text.dispose);
      var oldCalls = 0;
      var newCalls = 0;
      Future<String?> oldRule(String value) async {
        oldCalls++;
        return 'Old rule';
      }

      Future<String?> newRule(String value) async {
        newCalls++;
        return null;
      }

      Widget build(SmartAsyncValidator validator) => _app(
        SmartField(
          controller: text,
          asyncValidation: SmartAsyncValidation(
            controller: controller,
            trigger: SmartAsyncValidationTrigger.manual,
            validator: validator,
          ),
        ),
      );
      await tester.pumpWidget(build(oldRule));
      expect(await controller.validateAsync(), isFalse);
      await tester.pumpWidget(build(newRule));
      await tester.pump();
      expect(controller.errorText, 'Old rule');
      expect(newCalls, 0);
      expect(await controller.validateAsync(force: true), isTrue);
      expect(oldCalls, 1);
      expect(newCalls, 1);
      expect(controller.errorText, isNull);
    });

    testWidgets('a forced check replaces a pending one and ignores its reply', (
      tester,
    ) async {
      final controller = SmartFieldAsyncController();
      final text = TextEditingController(text: 'alice');
      addTearDown(controller.dispose);
      addTearDown(text.dispose);
      final first = Completer<String?>();
      final second = Completer<String?>();
      var calls = 0;
      await tester.pumpWidget(
        _app(
          SmartField(
            controller: text,
            asyncValidation: SmartAsyncValidation(
              controller: controller,
              trigger: SmartAsyncValidationTrigger.manual,
              validator: (value) => ++calls == 1 ? first.future : second.future,
            ),
          ),
        ),
      );
      final obsolete = controller.validateAsync();
      final joined = controller.validateAsync();
      await tester.pump();
      expect(calls, 1);
      final latest = controller.validateAsync(force: true);
      await tester.pump();
      expect(calls, 2);
      second.complete('Rejected');
      expect(await latest, isFalse);
      first.complete(null);
      expect(await obsolete, isFalse);
      expect(await joined, isFalse);
      await tester.pump();
      expect(controller.status, SmartAsyncValidationStatus.invalid);
      expect(controller.errorText, 'Rejected');
    });

    testWidgets('replacing the async controller keeps the result', (
      tester,
    ) async {
      final first = SmartFieldAsyncController();
      final second = SmartFieldAsyncController();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      var calls = 0;
      Widget build(SmartFieldAsyncController controller) => _app(
        SmartField.username(
          asyncValidation: SmartAsyncValidation(
            controller: controller,
            debounceDuration: Duration.zero,
            validator: (value) async {
              calls++;
              return 'Taken';
            },
          ),
        ),
      );
      await tester.pumpWidget(build(first));
      await tester.enterText(find.byType(TextFormField), 'alice');
      await tester.pump();
      await tester.pump();
      await tester.pumpWidget(build(second));
      await tester.pump();
      expect(first.status, SmartAsyncValidationStatus.idle);
      expect(second.status, SmartAsyncValidationStatus.invalid);
      expect(second.errorText, 'Taken');
      expect(find.text('Taken'), findsOneWidget);
      expect(calls, 1);
    });

    testWidgets('replacing the text controller drops the result', (
      tester,
    ) async {
      final first = TextEditingController();
      final second = TextEditingController(text: 'alice');
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      final controller = SmartFieldAsyncController();
      addTearDown(controller.dispose);
      var calls = 0;
      Widget build(TextEditingController text) => _app(
        SmartField.username(
          controller: text,
          asyncValidation: SmartAsyncValidation(
            controller: controller,
            debounceDuration: Duration.zero,
            validator: (value) async {
              calls++;
              return 'Taken';
            },
          ),
        ),
      );
      await tester.pumpWidget(build(first));
      await tester.enterText(find.byType(TextFormField), 'alice');
      await tester.pump();
      await tester.pump();
      expect(controller.status, SmartAsyncValidationStatus.invalid);
      await tester.pumpWidget(build(second));
      await tester.pump();
      expect(controller.status, SmartAsyncValidationStatus.idle);
      expect(controller.errorText, isNull);
      expect(calls, 1);
    });

    testWidgets('removing the field ignores a late reply', (tester) async {
      final controller = SmartFieldAsyncController();
      addTearDown(controller.dispose);
      final late = Completer<String?>();
      final statuses = <SmartAsyncValidationStatus>[];
      controller.addListener(() => statuses.add(controller.status));
      await tester.pumpWidget(
        _app(
          _StatusHost(controller: controller, validator: (_) => late.future),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'alice');
      await tester.pump();
      await tester.pumpWidget(_app(const SizedBox()));
      late.complete('Taken');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(statuses, [SmartAsyncValidationStatus.pending]);
      expect(controller.status, SmartAsyncValidationStatus.idle);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a dropdown date keeps its result across rebuilds', (
      tester,
    ) async {
      final controller = SmartFieldAsyncController();
      addTearDown(controller.dispose);
      var calls = 0;
      late StateSetter rebuild;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return SmartField.date(
                mode: SmartDateMode.dropdowns,
                initialDate: DateTime(2020, 3, 4),
                asyncValidation: SmartAsyncValidation(
                  controller: controller,
                  trigger: SmartAsyncValidationTrigger.manual,
                  validator: (value) async {
                    calls++;
                    return 'Booked';
                  },
                ),
              );
            },
          ),
        ),
      );
      expect(await controller.validateAsync(), isFalse);
      await tester.pump();
      rebuild(() {});
      await tester.pump();
      await tester.pump();
      expect(controller.errorText, 'Booked');
      expect(find.text('Booked'), findsOneWidget);
      expect(calls, 1);
    });
  });

  group('19M search debounce with inline callbacks', () {
    testWidgets('onChanged rebuilding the parent still delivers the search', (
      tester,
    ) async {
      final searches = <String>[];
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => SmartField.search(
              onChanged: (_) => setState(() {}),
              onSearch: (query) => searches.add(query),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'flutter');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 299));
      expect(searches, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      expect(searches, ['flutter']);
      await tester.pump(const Duration(seconds: 2));
      expect(searches, ['flutter']);
    });

    testWidgets('rapid keystrokes produce one search for the last text', (
      tester,
    ) async {
      final searches = <String>[];
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => SmartField.search(
              onChanged: (_) => setState(() {}),
              onSearch: (query) => searches.add(query),
            ),
          ),
        ),
      );
      for (final text in ['f', 'fl', 'flu', 'flut']) {
        await tester.enterText(find.byType(TextFormField), text);
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(searches, isEmpty);
      await tester.pump(const Duration(milliseconds: 199));
      expect(searches, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      expect(searches, ['flut']);
    });

    testWidgets('isLoading changes do not cancel or repeat the search', (
      tester,
    ) async {
      final searches = <String>[];
      var loading = false;
      late StateSetter rebuild;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return SmartField.search(
                isLoading: loading,
                onChanged: (_) => setState(() => loading = !loading),
                onSearch: (query) {
                  searches.add(query);
                  setState(() => loading = true);
                },
              );
            },
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'query');
      await tester.pump(const Duration(milliseconds: 150));
      rebuild(() => loading = false);
      await tester.pump(const Duration(milliseconds: 150));
      expect(searches, ['query']);
      await tester.pump();
      rebuild(() => loading = false);
      await tester.pump(const Duration(seconds: 2));
      expect(searches, ['query']);
    });

    testWidgets('unrelated rebuilds keep the original firing time', (
      tester,
    ) async {
      final searches = <String>[];
      var tick = 0;
      late StateSetter rebuild;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return Column(
                children: [
                  Text('tick $tick'),
                  SmartField.search(onSearch: (query) => searches.add(query)),
                ],
              );
            },
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'query');
      for (var i = 0; i < 2; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        rebuild(() => tick++);
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 99));
      expect(searches, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      expect(searches, ['query']);
    });

    testWidgets('the latest callback receives the search', (tester) async {
      final first = <String>[];
      final second = <String>[];
      Widget build(ValueChanged<String>? onSearch) =>
          _app(SmartField.search(onSearch: onSearch));
      await tester.pumpWidget(build(first.add));
      await tester.enterText(find.byType(TextFormField), 'query');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(build(second.add));
      await tester.pump(_quiet);
      expect(first, isEmpty);
      expect(second, ['query']);
    });

    testWidgets('removing the callback before the timer sends nothing', (
      tester,
    ) async {
      final searches = <String>[];
      Widget build(ValueChanged<String>? onSearch) =>
          _app(SmartField.search(onSearch: onSearch));
      await tester.pumpWidget(build(searches.add));
      await tester.enterText(find.byType(TextFormField), 'query');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(build(null));
      await tester.pump(_quiet);
      expect(searches, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a debounce duration change cancels the pending search', (
      tester,
    ) async {
      final searches = <String>[];
      Widget build(Duration debounce) => _app(
        SmartField.search(
          debounceDuration: debounce,
          onSearch: (query) => searches.add(query),
        ),
      );
      await tester.pumpWidget(build(_quiet));
      await tester.enterText(find.byType(TextFormField), 'query');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(build(const Duration(milliseconds: 500)));
      await tester.pump(const Duration(seconds: 2));
      expect(searches, isEmpty);
      await tester.enterText(find.byType(TextFormField), 'next');
      await tester.pump(const Duration(milliseconds: 499));
      expect(searches, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      expect(searches, ['next']);
    });

    testWidgets('caret movement keeps the search while the parent rebuilds', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final searches = <String>[];
      late StateSetter rebuild;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return SmartField.search(
                controller: controller,
                onSearch: (query) => searches.add(query),
              );
            },
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'query');
      await tester.pump(const Duration(milliseconds: 100));
      controller.selection = const TextSelection.collapsed(offset: 2);
      rebuild(() {});
      await tester.pump(const Duration(milliseconds: 200));
      expect(searches, ['query']);
    });

    testWidgets('clear cancels the search while the parent rebuilds', (
      tester,
    ) async {
      final searches = <String>[];
      final changes = <String>[];
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => SmartField.search(
              onChanged: (value) => setState(() => changes.add(value)),
              onSearch: (query) => searches.add(query),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'query');
      await tester.pump();
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(changes, ['query', '']);
      expect(searches, isEmpty);
    });

    for (final state in ['readOnly', 'disabled']) {
      testWidgets('becoming $state cancels the pending search', (tester) async {
        final searches = <String>[];
        Widget build(bool interactive) => _app(
          SmartField.search(
            readOnly: state == 'readOnly' && !interactive,
            enabled: state == 'readOnly' || interactive,
            onSearch: (query) => searches.add(query),
          ),
        );
        await tester.pumpWidget(build(true));
        await tester.enterText(find.byType(TextFormField), 'query');
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpWidget(build(false));
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpWidget(build(true));
        await tester.pump(const Duration(seconds: 1));
        expect(searches, isEmpty);
      });
    }

    testWidgets('controller replacement cancels with inline callbacks', (
      tester,
    ) async {
      final first = TextEditingController();
      final second = TextEditingController();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      final searches = <String>[];
      Widget build(TextEditingController controller) => _app(
        SmartField.search(
          controller: controller,
          onSearch: (query) => searches.add(query),
        ),
      );
      await tester.pumpWidget(build(first));
      await tester.enterText(find.byType(TextFormField), 'query');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(build(second));
      await tester.pump(const Duration(seconds: 1));
      expect(searches, isEmpty);
    });

    testWidgets('unmounting sends nothing', (tester) async {
      final searches = <String>[];
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => SmartField.search(
              onChanged: (_) => setState(() {}),
              onSearch: (query) => searches.add(query),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'query');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(_app(const SizedBox()));
      await tester.pump(const Duration(seconds: 1));
      expect(searches, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('zero debounce sends each edit once while rebuilding', (
      tester,
    ) async {
      final searches = <String>[];
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => SmartField.search(
              debounceDuration: Duration.zero,
              onChanged: (_) => setState(() {}),
              onSearch: (query) => searches.add(query),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'a');
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), 'ab');
      await tester.pump(const Duration(seconds: 1));
      expect(searches, ['a', 'ab']);
    });
  });
}
