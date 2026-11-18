import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _page(
  Widget child, {
  double width = 320,
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

typedef _Build =
    Widget Function({
      TextEditingController? controller,
      required bool seeded,
      required FormFieldSetter<String> onSaved,
      required FormFieldSetter<String> onRawSaved,
    });

class _Mask {
  _Mask(this.painted, this.room, this.natural);

  final Rect painted;
  final Rect room;
  final Size natural;

  double get scale => painted.height / natural.height;

  Rect get visible => painted.intersect(room);
}

_Mask _mask(WidgetTester tester) {
  final finder = find.textContaining('*');
  expect(finder, findsOneWidget);
  final box = tester.renderObject<RenderBox>(finder);
  return _Mask(
    MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size),
    tester.getRect(find.byType(EditableText)),
    box.size,
  );
}

void _expectMaskInside(WidgetTester tester, String reason) {
  expect(tester.takeException(), isNull, reason: reason);
  final mask = _mask(tester);
  final field = tester.getRect(find.byType(TextFormField));
  expect(
    mask.room.left,
    greaterThanOrEqualTo(field.left - 0.5),
    reason: reason,
  );
  expect(mask.room.right, lessThanOrEqualTo(field.right + 0.5), reason: reason);
  expect(mask.scale, greaterThanOrEqualTo(0.6 - 0.001), reason: reason);
  expect(mask.scale, lessThanOrEqualTo(1.001), reason: reason);
  if (mask.room.width < 1) {
    return;
  }
  expect(mask.visible.width, greaterThan(0), reason: reason);
  expect(
    mask.painted.right,
    lessThanOrEqualTo(mask.room.right + 0.5),
    reason: reason,
  );
  if (mask.painted.left < mask.room.left - 0.5) {
    expect(mask.scale, moreOrLessEquals(0.6, epsilon: 0.001), reason: reason);
    expect(
      mask.painted.right,
      moreOrLessEquals(mask.room.right, epsilon: 0.5),
      reason: reason,
    );
  }
  for (final icon in [Icons.tag, Icons.info]) {
    final found = find.byIcon(icon);
    if (found.evaluate().isEmpty) {
      continue;
    }
    expect(
      mask.visible.overlaps(tester.getRect(found)),
      isFalse,
      reason: '$reason overlaps $icon',
    );
  }
  final clear = find.byTooltip('Clear phone number');
  if (clear.evaluate().isNotEmpty) {
    expect(
      mask.visible.overlaps(tester.getRect(clear)),
      isFalse,
      reason: '$reason overlaps clear',
    );
  }
}

const _icons = InputDecoration(
  prefixIcon: Icon(Icons.tag),
  suffixIcon: Icon(Icons.info),
);

String _editable(WidgetTester tester, [int index = 0]) {
  return tester
      .widget<EditableText>(find.byType(EditableText).at(index))
      .controller
      .text;
}

void main() {
  group('19R masked text stays in its room after every rebuild', () {
    const widths = [120.0, 160.0, 200.0, 240.0, 320.0];

    final fields =
        <String, Widget Function(TextEditingController, InputDecoration)>{
          'number': (controller, decoration) => SmartField.number(
            controller: controller,
            mask: true,
            decoration: decoration,
          ),
          'amount': (controller, decoration) => SmartField.amount(
            controller: controller,
            mask: true,
            decimalPlaces: 2,
            useGrouping: true,
            decoration: decoration,
          ),
          'phone': (controller, decoration) => SmartField.phone(
            controller: controller,
            mask: true,
            showCountryPicker: true,
            initialCountryCode: 'US',
            showClearButton: true,
          ),
        };

    for (final entry in fields.entries) {
      testWidgets('${entry.key}: initial layout and parent rebuilds', (
        tester,
      ) async {
        for (final width in widths) {
          final controller = TextEditingController(text: '1234567890123456');
          late StateSetter rebuild;
          await tester.pumpWidget(
            _page(
              StatefulBuilder(
                builder: (context, setState) {
                  rebuild = setState;
                  return entry.value(controller, _icons);
                },
              ),
              width: width,
            ),
          );
          await tester.pumpAndSettle();
          _expectMaskInside(tester, '${entry.key} w$width initial');
          final before = _mask(tester).painted;
          for (var i = 0; i < 3; i++) {
            rebuild(() {});
            await tester.pump();
            _expectMaskInside(tester, '${entry.key} w$width rebuild $i');
          }
          expect(_mask(tester).painted, before);
          await tester.pumpWidget(const SizedBox());
          controller.dispose();
        }
      });

      testWidgets('${entry.key}: controller text changes while unfocused', (
        tester,
      ) async {
        for (final width in widths) {
          final controller = TextEditingController(text: '12345678');
          await tester.pumpWidget(
            _page(entry.value(controller, _icons), width: width),
          );
          await tester.pumpAndSettle();
          controller.text = '123456789012345678901234';
          await tester.pumpAndSettle();
          _expectMaskInside(tester, '${entry.key} w$width long');
          controller.text = '1234';
          await tester.pumpAndSettle();
          _expectMaskInside(tester, '${entry.key} w$width short');
          await tester.pumpWidget(const SizedBox());
          controller.dispose();
        }
      });

      testWidgets('${entry.key}: text scale and direction change at run time', (
        tester,
      ) async {
        for (final width in widths) {
          final controller = TextEditingController(text: '1234567890123456');
          Widget build(double scale, TextDirection direction) => _page(
            entry.value(controller, _icons),
            width: width,
            scale: scale,
            direction: direction,
          );
          await tester.pumpWidget(build(1, TextDirection.ltr));
          await tester.pumpAndSettle();
          for (final step in [
            (3.0, TextDirection.ltr),
            (3.0, TextDirection.rtl),
            (1.0, TextDirection.rtl),
            (2.0, TextDirection.ltr),
          ]) {
            await tester.pumpWidget(build(step.$1, step.$2));
            await tester.pump();
            _expectMaskInside(
              tester,
              '${entry.key} w$width x${step.$1} ${step.$2.name}',
            );
          }
          await tester.pumpWidget(const SizedBox());
          controller.dispose();
        }
      });
    }

    testWidgets('icons added and removed after the first layout', (
      tester,
    ) async {
      for (final width in widths) {
        final controller = TextEditingController(text: '1234567890123456');
        Widget build(InputDecoration decoration) => _page(
          SmartField.number(
            controller: controller,
            mask: true,
            decoration: decoration,
          ),
          width: width,
        );
        await tester.pumpWidget(build(const InputDecoration()));
        await tester.pumpAndSettle();
        _expectMaskInside(tester, 'w$width none');
        for (final decoration in const [
          InputDecoration(suffixIcon: Icon(Icons.info)),
          _icons,
          InputDecoration(prefixIcon: Icon(Icons.tag)),
          InputDecoration(),
          _icons,
        ]) {
          await tester.pumpWidget(build(decoration));
          await tester.pump();
          _expectMaskInside(tester, 'w$width $decoration');
        }
        await tester.pumpWidget(const SizedBox());
        controller.dispose();
      }
    });

    testWidgets('a validation error and a focus cycle keep the text in place', (
      tester,
    ) async {
      for (final width in widths) {
        final controller = TextEditingController(text: '1234567890123456');
        final formKey = GlobalKey<FormState>();
        final focus = FocusNode();
        await tester.pumpWidget(
          _page(
            Form(
              key: formKey,
              child: SmartField.number(
                controller: controller,
                focusNode: focus,
                mask: true,
                maxLength: 4,
                decoration: _icons,
              ),
            ),
            width: width,
          ),
        );
        await tester.pumpAndSettle();
        expect(formKey.currentState!.validate(), isFalse);
        await tester.pumpAndSettle();
        expect(find.textContaining('no more than'), findsOneWidget);
        _expectMaskInside(tester, 'w$width error');
        focus.requestFocus();
        await tester.pumpAndSettle();
        expect(find.textContaining('*'), findsNothing);
        expect(_editable(tester), '1234567890123456');
        focus.unfocus();
        await tester.pumpAndSettle();
        _expectMaskInside(tester, 'w$width after focus cycle');
        await tester.pumpWidget(const SizedBox());
        controller.dispose();
        focus.dispose();
      }
    });

    testWidgets('text that fits is drawn at full size from the start edge', (
      tester,
    ) async {
      final controller = TextEditingController(text: '12345678');
      addTearDown(controller.dispose);
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          _page(
            SmartField.number(
              controller: controller,
              mask: true,
              decoration: _icons,
            ),
            width: 400,
            direction: direction,
          ),
        );
        await tester.pumpAndSettle();
        final mask = _mask(tester);
        expect(mask.scale, moreOrLessEquals(1, epsilon: 0.001));
        if (direction == TextDirection.ltr) {
          expect(mask.painted.left, moreOrLessEquals(mask.room.left));
        } else {
          expect(mask.painted.right, moreOrLessEquals(mask.room.right));
        }
      }
    });

    testWidgets('nothing is painted over the icons or outside the room', (
      tester,
    ) async {
      final key = GlobalKey();
      final controller = TextEditingController(text: '12');
      addTearDown(controller.dispose);
      late StateSetter rebuild;
      await tester.pumpWidget(
        _page(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return RepaintBoundary(
                key: key,
                child: SmartField.number(
                  controller: controller,
                  mask: true,
                  decoration: _icons,
                ),
              );
            },
          ),
          width: 200,
        ),
      );
      await tester.pumpAndSettle();
      Future<ByteData> capture() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(key),
        );
        final data = await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          image.dispose();
          return bytes!;
        });
        return data!;
      }

      final origin = tester.getTopLeft(find.byKey(key));
      final size = tester.getSize(find.byKey(key));
      final short = await capture();
      controller.text = '123456789012345678901234567890';
      await tester.pumpAndSettle();
      rebuild(() {});
      await tester.pump();
      final long = await capture();
      final room = tester.getRect(find.byType(EditableText)).shift(-origin);
      final width = size.width.round();
      var differing = 0;
      var differingOutsideRoom = 0;
      for (var y = 0; y < size.height.round(); y++) {
        for (var x = 0; x < width; x++) {
          final index = (y * width + x) * 4;
          if (short.getUint32(index) == long.getUint32(index)) {
            continue;
          }
          differing++;
          if (x < room.left.floor() || x >= room.right.ceil()) {
            differingOutsideRoom++;
          }
        }
      }
      expect(differing, greaterThan(0));
      expect(differingOutsideRoom, 0);
    });
  });

  group('19R masked text with developer decoration and styling', () {
    testWidgets('a developer prefix widget is kept beside the masked text', (
      tester,
    ) async {
      await tester.pumpWidget(
        _page(
          SmartField.number(
            initialValue: '12345678',
            mask: true,
            decoration: const InputDecoration(prefix: Text('ID ')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('ID '), findsOneWidget);
      expect(find.text('****5678'), findsOneWidget);
      expect(
        tester.getRect(find.text('ID ')).right,
        lessThanOrEqualTo(_mask(tester).painted.left + 0.5),
      );
    });

    testWidgets('a developer prefixText is kept and the mask still scales', (
      tester,
    ) async {
      await tester.pumpWidget(
        _page(
          SmartField.number(
            initialValue: '1234567890123456',
            mask: true,
            decoration: const InputDecoration(
              prefixText: 'ID ',
              suffixIcon: Icon(Icons.info),
            ),
          ),
          width: 200,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ID '), findsOneWidget);
      _expectMaskInside(tester, 'prefixText');
    });

    testWidgets(
      'prefixText with a suffix widget or suffixText does not throw',
      (tester) async {
        for (final decoration in const [
          InputDecoration(prefixText: 'ID ', suffix: Text('kg')),
          InputDecoration(prefixText: 'ID ', suffixText: 'kg'),
          InputDecoration(prefix: Text('ID '), suffix: Text('kg')),
        ]) {
          await tester.pumpWidget(
            _page(
              SmartField.number(
                initialValue: '12345678',
                mask: true,
                decoration: decoration,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.textContaining('5678'), findsWidgets);
          await tester.pumpWidget(const SizedBox());
        }
      },
    );

    testWidgets('the field style and the disabled colour are applied', (
      tester,
    ) async {
      Widget build({bool? enabled}) => _page(
        SmartField.number(
          initialValue: '12345678',
          mask: true,
          enabled: enabled,
          style: const TextStyle(fontSize: 22, letterSpacing: 2),
        ),
      );
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();
      var style = tester.widget<Text>(find.text('****5678')).style!;
      expect(style.fontSize, 22);
      expect(style.letterSpacing, 2);
      final context = tester.element(find.byType(TextFormField));
      final onSurface = Theme.of(context).colorScheme.onSurface;
      await tester.pumpWidget(build(enabled: false));
      await tester.pumpAndSettle();
      style = tester.widget<Text>(find.text('****5678')).style!;
      expect(style.color, onSurface.withValues(alpha: 0.38));
    });

    testWidgets('the real value is never in a Text or in semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _page(
          SmartField.phone(
            label: 'Phone',
            initialValue: '4155552671',
            mask: true,
            showCountryPicker: true,
            initialCountryCode: 'US',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Text && (widget.data ?? '').contains('5555'),
        ),
        findsNothing,
      );
      final root = tester
          .binding
          .renderViews
          .first
          .owner!
          .semanticsOwner!
          .rootSemanticsNode!;
      expect(root.toStringDeep(), isNot(contains('4155552671')));
      expect(root.toStringDeep(), contains('******2671'));
      handle.dispose();
    });
  });

  group('19R date and time reset then save', () {
    final kinds =
        <
          String,
          ({
            _Build build,
            String typed,
            String typedText,
            String initialText,
            String initialRaw,
          })
        >{
          'date': (
            build:
                ({
                  controller,
                  required seeded,
                  required onSaved,
                  required onRawSaved,
                }) => SmartField.date(
                  controller: controller,
                  initialDate: seeded ? DateTime(2024, 2, 29) : null,
                  onSaved: onSaved,
                  onRawSaved: onRawSaved,
                ),
            typed: '01012000',
            typedText: '01/01/2000',
            initialText: '29/02/2024',
            initialRaw: '2024-02-29',
          ),
          'time': (
            build:
                ({
                  controller,
                  required seeded,
                  required onSaved,
                  required onRawSaved,
                }) => SmartField.time(
                  controller: controller,
                  initialTime: seeded
                      ? const TimeOfDay(hour: 8, minute: 5)
                      : null,
                  onSaved: onSaved,
                  onRawSaved: onRawSaved,
                ),
            typed: '2359',
            typedText: '23:59',
            initialText: '08:05',
            initialRaw: '08:05',
          ),
          'dateTime': (
            build:
                ({
                  controller,
                  required seeded,
                  required onSaved,
                  required onRawSaved,
                }) => SmartField.dateTime(
                  controller: controller,
                  initialDateTime: seeded ? DateTime(2024, 2, 29, 8, 5) : null,
                  onSaved: onSaved,
                  onRawSaved: onRawSaved,
                ),
            typed: '010120002359',
            typedText: '01/01/2000 23:59',
            initialText: '29/02/2024 08:05',
            initialRaw: '2024-02-29T08:05',
          ),
        };

    for (final entry in kinds.entries) {
      final kind = entry.value;
      for (final external in [false, true]) {
        final owner = external ? 'external' : 'owned';
        testWidgets('${entry.key}, $owner controller, with an initial value', (
          tester,
        ) async {
          final formKey = GlobalKey<FormState>();
          final saved = <String?>[];
          final raw = <String?>[];
          final controller = external ? TextEditingController() : null;
          addTearDown(() => controller?.dispose());
          await tester.pumpWidget(
            _page(
              Form(
                key: formKey,
                child: kind.build(
                  controller: controller,
                  seeded: true,
                  onSaved: saved.add,
                  onRawSaved: raw.add,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(_editable(tester), kind.initialText);
          for (var round = 0; round < 3; round++) {
            await tester.enterText(find.byType(EditableText), kind.typed);
            await tester.pump();
            expect(_editable(tester), kind.typedText);
            formKey.currentState!.save();
            expect(saved.last, kind.typedText);
            formKey.currentState!.reset();
            formKey.currentState!.save();
            expect(saved.last, kind.initialText, reason: 'round $round');
            expect(raw.last, kind.initialRaw, reason: 'round $round');
            await tester.pump();
            await tester.pump();
            expect(_editable(tester), kind.initialText);
            formKey.currentState!.save();
            expect(saved.last, kind.initialText, reason: 'round $round');
            expect(raw.last, kind.initialRaw, reason: 'round $round');
            expect(formKey.currentState!.validate(), isTrue);
          }
        });

        testWidgets('${entry.key}, $owner controller, empty at the start', (
          tester,
        ) async {
          final formKey = GlobalKey<FormState>();
          final saved = <String?>[];
          final raw = <String?>[];
          final controller = external ? TextEditingController() : null;
          addTearDown(() => controller?.dispose());
          await tester.pumpWidget(
            _page(
              Form(
                key: formKey,
                child: kind.build(
                  controller: controller,
                  seeded: false,
                  onSaved: saved.add,
                  onRawSaved: raw.add,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(EditableText), kind.typed);
          await tester.pump();
          formKey.currentState!.reset();
          formKey.currentState!.save();
          expect(saved.last, '');
          await tester.pump();
          await tester.pump();
          expect(_editable(tester), '');
          formKey.currentState!.save();
          expect(saved.last, '');
          expect(raw.last ?? '', '');
        });
      }
    }

    testWidgets('picker-mode fields reset to the value they show', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final date = TextEditingController();
      final time = TextEditingController();
      addTearDown(date.dispose);
      addTearDown(time.dispose);
      final saved = <String, String?>{};
      await tester.pumpWidget(
        _page(
          Form(
            key: formKey,
            child: Column(
              children: [
                SmartField.date(
                  controller: date,
                  mode: SmartDateMode.calendar,
                  initialDate: DateTime(2024, 2, 29),
                  onRawSaved: (value) => saved['calendar'] = value,
                ),
                SmartField.time(
                  controller: time,
                  mode: SmartTimeMode.wheel,
                  initialTime: const TimeOfDay(hour: 8, minute: 5),
                  onRawSaved: (value) => saved['wheel'] = value,
                ),
                SmartField.date(
                  mode: SmartDateMode.dropdowns,
                  initialDate: DateTime(2024, 2, 29),
                  onRawSaved: (value) => saved['dropdowns'] = value,
                ),
              ],
            ),
          ),
          width: 500,
        ),
      );
      await tester.pumpAndSettle();
      date.text = '01/01/2000';
      time.text = '23:59';
      await tester.tap(find.text('29').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('28').last);
      await tester.pumpAndSettle();
      formKey.currentState!.save();
      expect(saved, {
        'calendar': '2000-01-01',
        'wheel': '23:59',
        'dropdowns': '2024-02-28',
      });
      formKey.currentState!.reset();
      formKey.currentState!.save();
      await tester.pumpAndSettle();
      formKey.currentState!.save();
      expect(saved, {
        'calendar': '2024-02-29',
        'wheel': '08:05',
        'dropdowns': '2024-02-29',
      });
      expect(date.text, '29/02/2024');
      expect(time.text, '08:05');
    });
  });

  group('19R reset and controller swaps keep the saved value current', () {
    testWidgets('masked phone and number: reset then save', (tester) async {
      final formKey = GlobalKey<FormState>();
      final saved = <String, String?>{};
      await tester.pumpWidget(
        _page(
          Form(
            key: formKey,
            child: Column(
              children: [
                SmartField.phone(
                  initialValue: '+44 7400 123456',
                  mask: true,
                  onSaved: (value) => saved['phone'] = value,
                ),
                SmartField.number(
                  initialValue: '1234',
                  mask: true,
                  onSaved: (value) => saved['number'] = value,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(EditableText).first,
        '+44 7400 999999',
      );
      await tester.enterText(find.byType(EditableText).last, '99999');
      await tester.pumpAndSettle();
      formKey.currentState!.save();
      expect(saved, {'phone': '+44 7400 999999', 'number': '99999'});
      formKey.currentState!.reset();
      formKey.currentState!.save();
      expect(saved, {'phone': '+44 7400 123456', 'number': '1234'});
      await tester.pumpAndSettle();
      formKey.currentState!.save();
      expect(saved, {'phone': '+44 7400 123456', 'number': '1234'});
      expect(_editable(tester, 0), '+44 7400 123456');
      expect(_editable(tester, 1), '1234');
    });

    testWidgets('owned-controller fields after a parent rebuild', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final saved = <String, String?>{};
      late StateSetter rebuild;
      await tester.pumpWidget(
        _page(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return Form(
                key: formKey,
                child: Column(
                  children: [
                    SmartField.amount(
                      initialValue: '10',
                      decimalPlaces: 2,
                      onRawSaved: (value) => saved['amount'] = value,
                    ),
                    SmartField.search(
                      initialValue: 'first',
                      onSaved: (value) => saved['search'] = value,
                    ),
                    SmartField.password(
                      initialValue: 'Secret1!',
                      showStrengthIndicator: true,
                      onSaved: (value) => saved['password'] = value,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).at(0), '77');
      await tester.enterText(find.byType(EditableText).at(1), 'second');
      await tester.enterText(find.byType(EditableText).at(2), 'Other2@');
      rebuild(() {});
      await tester.pump(const Duration(seconds: 1));
      formKey.currentState!.reset();
      formKey.currentState!.save();
      await tester.pump(const Duration(seconds: 1));
      formKey.currentState!.save();
      expect(saved, {
        'amount': '10.00',
        'search': 'first',
        'password': 'Secret1!',
      });
    });

    testWidgets('OTP follows a replaced controller', (tester) async {
      final formKey = GlobalKey<FormState>();
      final first = TextEditingController(text: '123');
      final second = TextEditingController(text: '987654');
      final empty = TextEditingController();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      addTearDown(empty.dispose);
      final saved = <String?>[];
      Widget build(TextEditingController? controller) => _page(
        Form(
          key: formKey,
          child: SmartField.otp(
            controller: controller,
            isRequired: true,
            onSaved: saved.add,
          ),
        ),
        width: 420,
      );
      await tester.pumpWidget(build(first));
      formKey.currentState!.save();
      expect(saved.last, '123');
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pumpWidget(build(second));
      await tester.pump();
      formKey.currentState!.save();
      expect(saved.last, '987654');
      expect(formKey.currentState!.validate(), isTrue);
      await tester.pumpWidget(build(empty));
      await tester.pump();
      formKey.currentState!.save();
      expect(saved.last, '');
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pumpWidget(build(second));
      await tester.pump();
      await tester.pumpWidget(build(null));
      await tester.pump();
      formKey.currentState!.save();
      expect(saved.last, '987654');
      expect(tester.takeException(), isNull);
    });

    testWidgets('dropdown date follows a cleared external controller', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final raw = <String?>[];
      final dates = <DateTime?>[];
      await tester.pumpWidget(
        _page(
          Form(
            key: formKey,
            child: SmartField.date(
              controller: controller,
              mode: SmartDateMode.dropdowns,
              initialDate: DateTime(2024, 5, 17),
              onRawSaved: raw.add,
              onDateChanged: dates.add,
            ),
          ),
          width: 420,
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.text, '17/05/2024');
      expect(find.text('17'), findsOneWidget);
      controller.clear();
      await tester.pumpAndSettle();
      expect(controller.text, '');
      expect(find.text('17'), findsNothing);
      expect(find.text('2024'), findsNothing);
      expect(find.text('Day'), findsOneWidget);
      formKey.currentState!.save();
      expect(raw.last ?? '', '');
      controller.text = '03/04/2023';
      await tester.pumpAndSettle();
      expect(find.text('2023'), findsOneWidget);
      formKey.currentState!.save();
      expect(raw.last, '2023-04-03');
    });

    testWidgets('dropdown date async check uses the current date format', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final seen = <String>[];
      Widget build(String format) => _page(
        SmartField.date(
          controller: controller,
          mode: SmartDateMode.dropdowns,
          dateFormat: format,
          firstYear: 2024,
          lastYear: 2024,
          asyncValidation: SmartAsyncValidation(
            debounceDuration: Duration.zero,
            validator: (value) async {
              seen.add(value);
              return null;
            },
          ),
        ),
        width: 420,
      );
      await tester.pumpWidget(build('dd/MM/yyyy'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(build('MM/dd/yyyy'));
      await tester.pumpAndSettle();
      controller.text = '04/03/2024';
      await tester.pumpAndSettle();
      expect(seen, ['2024-04-03']);
    });

    testWidgets('amount onSaved is the shown text; the raw value is stable', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final focus = FocusNode();
      addTearDown(focus.dispose);
      final saved = <String?>[];
      final raw = <String?>[];
      await tester.pumpWidget(
        _page(
          Form(
            key: formKey,
            child: SmartField.amount(
              focusNode: focus,
              decimalPlaces: 2,
              useGrouping: true,
              currencySymbol: r'$',
              onSaved: saved.add,
              onRawSaved: raw.add,
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), '1234.5');
      await tester.pump();
      formKey.currentState!.save();
      expect(saved.last, _editable(tester));
      expect(saved.last, '1234.5');
      expect(raw.last, '1234.50');
      focus.unfocus();
      await tester.pump();
      formKey.currentState!.save();
      expect(saved.last, _editable(tester));
      expect(saved.last, r'$1,234.50');
      expect(raw.last, '1234.50');
    });
  });

  group('19R async status listeners during a rebuild', () {
    for (final change in ['disable', 'swap controller', 'both']) {
      for (final state in ['pending', 'valid', 'invalid']) {
        testWidgets('$change while $state does not throw', (tester) async {
          final controller = SmartFieldAsyncController();
          final first = TextEditingController();
          final second = TextEditingController(text: 'other');
          addTearDown(controller.dispose);
          addTearDown(first.dispose);
          addTearDown(second.dispose);
          final gate = Completer<String?>();
          var enabled = true;
          var text = first;
          var builds = 0;
          final statuses = <SmartAsyncValidationStatus>[];
          late StateSetter rebuild;
          await tester.pumpWidget(
            _page(
              StatefulBuilder(
                builder: (context, setState) {
                  rebuild = setState;
                  builds++;
                  return Form(
                    child: SmartField.username(
                      controller: text,
                      enabled: enabled,
                      asyncValidation: SmartAsyncValidation(
                        controller: controller,
                        debounceDuration: Duration.zero,
                        validator: (value) => state == 'pending'
                            ? gate.future
                            : Future.value(state == 'invalid' ? 'Taken' : null),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
          controller.addListener(() {
            statuses.add(controller.status);
            rebuild(() {});
          });
          await tester.enterText(find.byType(TextFormField), 'alice');
          await tester.pump();
          await tester.pump();
          expect(controller.status.name, state);
          rebuild(() {
            if (change != 'swap controller') {
              enabled = false;
            }
            if (change != 'disable') {
              text = second;
            }
          });
          await tester.pump();
          expect(tester.takeException(), isNull);
          await tester.pump();
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(controller.status, SmartAsyncValidationStatus.idle);
          expect(statuses.last, SmartAsyncValidationStatus.idle);
          expect(find.text('Taken'), findsNothing);
          expect(builds, lessThan(12));
        });
      }
    }
  });

  group('19R card auto-advance and autofill', () {
    Future<void> typeDigits(WidgetTester tester, String digits) async {
      for (var i = 1; i <= digits.length; i++) {
        final field = find.byType(EditableText).first;
        if (!tester.widget<EditableText>(field).focusNode.hasFocus) {
          return;
        }
        await tester.enterText(field, digits.substring(0, i));
        await tester.pump();
      }
    }

    bool focused(WidgetTester tester, int index) => tester
        .widget<EditableText>(find.byType(EditableText).at(index))
        .focusNode
        .hasFocus;

    testWidgets('a 19-digit UnionPay number can be typed in full', (
      tester,
    ) async {
      await tester.pumpWidget(_page(SmartField.creditCard(), width: 420));
      await tester.showKeyboard(find.byType(EditableText).first);
      await typeDigits(tester, '621234567890123456');
      expect(focused(tester, 0), isTrue);
      expect(_editable(tester).replaceAll(' ', ''), '621234567890123456');
      await typeDigits(tester, '6212345678901234567');
      expect(_editable(tester).replaceAll(' ', ''), '6212345678901234567');
      expect(focused(tester, 1), isTrue);
    });

    testWidgets('single-length brands advance at their length', (tester) async {
      for (final number in ['5555555555554444', '378282246310005']) {
        await tester.pumpWidget(_page(SmartField.creditCard(), width: 420));
        await tester.showKeyboard(find.byType(EditableText).first);
        await typeDigits(tester, number);
        expect(_editable(tester).replaceAll(' ', ''), number);
        expect(focused(tester, 1), isTrue, reason: number);
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('a 16-digit Visa with a wrong checksum keeps the focus', (
      tester,
    ) async {
      await tester.pumpWidget(_page(SmartField.creditCard(), width: 420));
      await tester.showKeyboard(find.byType(EditableText).first);
      await typeDigits(tester, '4111111111111112');
      expect(focused(tester, 0), isTrue);
    });

    testWidgets('disposing the card field does not ask the platform to save', (
      tester,
    ) async {
      await tester.pumpWidget(_page(SmartField.creditCard(), width: 420));
      await tester.showKeyboard(find.byType(EditableText).first);
      await tester.enterText(
        find.byType(EditableText).first,
        '4111111111111111',
      );
      await tester.pump();
      tester.testTextInput.log.clear();
      await tester.pumpWidget(_page(const SizedBox()));
      await tester.pump();
      final finishes = tester.testTextInput.log
          .where((call) => call.method == 'TextInput.finishAutofillContext')
          .toList();
      expect(finishes, hasLength(1));
      expect(finishes.single.arguments, isFalse);
    });

    testWidgets('the three inputs still declare card autofill hints', (
      tester,
    ) async {
      await tester.pumpWidget(_page(SmartField.creditCard(), width: 420));
      final hints = [
        for (final field in tester.widgetList<EditableText>(
          find.byType(EditableText),
        ))
          field.autofillHints?.toList(),
      ];
      expect(hints[0], contains(AutofillHints.creditCardNumber));
      expect(hints[1], isNotEmpty);
      expect(hints[2], contains(AutofillHints.creditCardSecurityCode));
      expect(find.byType(AutofillGroup), findsOneWidget);
    });
  });

  group('19R OTP paste of a full code', () {
    TextEditingValue value(String text, [int? offset]) => TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset ?? text.length),
    );

    testWidgets('a full code pasted after typed digits replaces them', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final completed = <String>[];
      await tester.pumpWidget(
        _page(
          SmartField.otp(controller: controller, onCompleted: completed.add),
          width: 420,
        ),
      );
      await tester.showKeyboard(find.byType(EditableText));
      tester.testTextInput.updateEditingValue(value('1'));
      await tester.pump();
      tester.testTextInput.updateEditingValue(value('1123456'));
      await tester.pump();
      expect(controller.text, '123456');
      expect(completed, ['123456']);
      tester.testTextInput.updateEditingValue(value('123456654321'));
      await tester.pump();
      expect(controller.text, '654321');
      expect(completed, ['123456', '654321']);
      tester.testTextInput.updateEditingValue(value('987 654654321', 7));
      await tester.pump();
      expect(controller.text, '987654');
    });

    testWidgets('typing and other oversize input behave as before', (
      tester,
    ) async {
      final controller = TextEditingController(text: '123456')
        ..selection = const TextSelection.collapsed(offset: 2);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _page(SmartField.otp(controller: controller), width: 420),
      );
      await tester.showKeyboard(find.byType(EditableText));
      tester.testTextInput.updateEditingValue(value('1293456', 3));
      await tester.pump();
      expect(controller.text, '129456');
      controller.clear();
      tester.testTextInput.updateEditingValue(value('12345678'));
      await tester.pump();
      expect(controller.text, '123456');
      tester.testTextInput.updateEditingValue(value('12345699'));
      await tester.pump();
      expect(controller.text, '123456');
    });
  });
}
