import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

Widget _app(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  double scale = 1,
}) {
  return MaterialApp(
    home: Directionality(
      textDirection: direction,
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
}

List<String> _semanticTexts(WidgetTester tester) {
  final texts = <String>[];
  void visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    texts
      ..add(data.label)
      ..add(data.value)
      ..add(data.hint)
      ..add(data.tooltip);
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
  group('password visibility labels', () {
    testWidgets('keep the English defaults', (tester) async {
      await tester.pumpWidget(_app(SmartField.password()));
      expect(find.byTooltip('Show password'), findsOneWidget);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(find.byTooltip('Hide password'), findsOneWidget);
    });

    testWidgets('use developer strings for tooltip and semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          SmartField.password(
            showPasswordLabel: 'Mostrar contraseña',
            hidePasswordLabel: 'Ocultar contraseña',
          ),
        ),
      );
      expect(find.byTooltip('Mostrar contraseña'), findsOneWidget);
      expect(_semanticTexts(tester), contains('Mostrar contraseña'));
      await tester.tap(find.byTooltip('Mostrar contraseña'));
      await tester.pump();
      expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
      expect(_semanticTexts(tester), contains('Ocultar contraseña'));
      handle.dispose();
    });

    testWidgets('follow a locale change during a rebuild', (tester) async {
      Widget build(String show) =>
          _app(SmartField.password(showPasswordLabel: show));
      await tester.pumpWidget(build('Show'));
      expect(find.byTooltip('Show'), findsOneWidget);
      await tester.pumpWidget(build('Afficher'));
      expect(find.byTooltip('Afficher'), findsOneWidget);
      expect(find.byTooltip('Show'), findsNothing);
    });

    testWidgets('can be activated from the keyboard and stay RTL safe', (
      tester,
    ) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.password(
            focusNode: focus,
            showPasswordLabel: 'إظهار',
            hidePasswordLabel: 'إخفاء',
          ),
          direction: TextDirection.rtl,
          scale: 2,
        ),
      );
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.byTooltip('إخفاء'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a disabled field disables the toggle', (tester) async {
      await tester.pumpWidget(
        _app(SmartField.password(enabled: false, showPasswordLabel: 'Mostrar')),
      );
      await tester.tap(find.byTooltip('Mostrar'), warnIfMissed: false);
      await tester.pump();
      expect(find.byTooltip('Mostrar'), findsOneWidget);
    });
  });

  group('search labels', () {
    testWidgets('English defaults', (tester) async {
      await tester.pumpWidget(
        _app(
          SmartField.search(
            isLoading: true,
            controller: TextEditingController(text: 'q'),
          ),
        ),
      );
      final handle = tester.ensureSemantics();
      await tester.pump();
      expect(find.byTooltip('Clear search'), findsOneWidget);
      expect(_semanticTexts(tester).join('|'), contains('Loading search'));
      handle.dispose();
    });

    testWidgets('developer strings replace both labels', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          SmartField.search(
            isLoading: true,
            controller: TextEditingController(text: 'q'),
            clearLabel: 'Effacer la recherche',
            loadingLabel: 'Recherche en cours',
          ),
        ),
      );
      expect(find.byTooltip('Effacer la recherche'), findsOneWidget);
      final texts = _semanticTexts(tester).join('|');
      expect(texts, contains('Effacer la recherche'));
      expect(texts, contains('Recherche en cours'));
      expect(find.byTooltip('Clear search'), findsNothing);
      handle.dispose();
    });
  });

  group('phone labels', () {
    testWidgets('English defaults', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          _app(
            SmartField.phone(
              showCountryPicker: true,
              showContactPicker: true,
              showClearButton: true,
              controller: TextEditingController(text: '03001234567'),
            ),
          ),
        );
        expect(
          find.byTooltip('Select phone number from contacts'),
          findsOneWidget,
        );
        expect(find.byTooltip('Clear phone number'), findsOneWidget);
        expect(_semanticTexts(tester), contains('Select country'));
        handle.dispose();
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('developer strings replace every first-party label', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          _app(
            SmartField.phone(
              showCountryPicker: true,
              initialCountryCode: 'PK',
              showContactPicker: true,
              showClearButton: true,
              controller: TextEditingController(text: '03001234567'),
              selectCountryLabel: 'Elegir país',
              changeCountryLabelBuilder: (country) =>
                  'Cambiar país, ${country.name}, ${country.dialCode}',
              contactPickerLabel: 'Elegir de contactos',
              clearLabel: 'Borrar teléfono',
              countrySearchHint: 'Buscar país',
            ),
          ),
        );
        expect(find.byTooltip('Elegir de contactos'), findsOneWidget);
        expect(find.byTooltip('Borrar teléfono'), findsOneWidget);
        expect(
          _semanticTexts(tester).any((t) => t.startsWith('Cambiar país, ')),
          isTrue,
        );
        await tester.tap(find.text('+92'));
        await tester.pumpAndSettle();
        expect(find.text('Buscar país'), findsOneWidget);
        expect(find.text('Search country'), findsNothing);
        handle.dispose();
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('masked phone labels never expose the digits', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          SmartField.phone(
            label: 'Teléfono',
            mask: true,
            showClearButton: true,
            clearLabel: 'Borrar teléfono',
            controller: TextEditingController(text: '03001234567'),
          ),
        ),
      );
      final text = _semanticTexts(tester).join('|');
      expect(text, contains('Teléfono'));
      expect(text, isNot(contains('03001234567')));
      handle.dispose();
    });
  });

  group('date and time labels', () {
    testWidgets('clear and picker tooltips: defaults and overrides', (
      tester,
    ) async {
      final controller = TextEditingController(text: '15/03/2024');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SmartField.date(
            controller: controller,
            mode: SmartDateMode.calendar,
            showClearButton: true,
          ),
        ),
      );
      expect(find.byTooltip('Clear'), findsOneWidget);
      expect(find.byTooltip('Choose date'), findsOneWidget);
      await tester.pumpWidget(
        _app(
          SmartField.date(
            controller: controller,
            mode: SmartDateMode.calendar,
            showClearButton: true,
            clearLabel: 'Borrar',
            pickerLabel: 'Elegir fecha',
          ),
        ),
      );
      expect(find.byTooltip('Borrar'), findsOneWidget);
      expect(find.byTooltip('Elegir fecha'), findsOneWidget);
      await tester.tap(find.byTooltip('Borrar'));
      await tester.pump();
      expect(controller.text, isEmpty);
    });

    testWidgets('time and dateTime accept the same overrides', (tester) async {
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              SmartField.time(
                mode: SmartTimeMode.picker,
                pickerLabel: 'Elegir hora',
              ),
              SmartField.dateTime(
                mode: SmartTimeMode.picker,
                pickerLabel: 'Elegir fecha y hora',
              ),
            ],
          ),
        ),
      );
      expect(find.byTooltip('Elegir hora'), findsOneWidget);
      expect(find.byTooltip('Elegir fecha y hora'), findsOneWidget);
    });

    testWidgets('dropdown parts use the developer strings', (tester) async {
      await tester.pumpWidget(
        _app(
          SmartField.date(
            mode: SmartDateMode.dropdowns,
            dayLabel: 'Día',
            monthLabel: 'Mes',
            yearLabel: 'Año',
          ),
        ),
      );
      expect(find.text('Día'), findsOneWidget);
      expect(find.text('Mes'), findsOneWidget);
      expect(find.text('Año'), findsOneWidget);
      expect(find.text('Day'), findsNothing);
    });

    testWidgets('wheel sheets use the developer strings', (tester) async {
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              SmartField.date(
                mode: SmartDateMode.wheel,
                dayLabel: 'Día',
                monthLabel: 'Mes',
                yearLabel: 'Año',
              ),
            ],
          ),
        ),
      );
      final handle = tester.ensureSemantics();
      await tester.tap(find.byTooltip('Choose date'));
      await tester.pumpAndSettle();
      final texts = _semanticTexts(tester);
      expect(texts, containsAll(['Día', 'Mes', 'Año']));
      handle.dispose();
    });

    testWidgets('time wheel uses developer hour, minute and period labels', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          SmartField.time(
            mode: SmartTimeMode.wheel,
            use24Hour: false,
            hourLabel: 'Hora',
            minuteLabel: 'Minuto',
            periodLabel: 'a. m. o p. m.',
          ),
        ),
      );
      await tester.tap(find.byTooltip('Choose time'));
      await tester.pumpAndSettle();
      expect(
        _semanticTexts(tester),
        containsAll(['Hora', 'Minuto', 'a. m. o p. m.']),
      );
      handle.dispose();
    });
  });

  test('constructors stay const-compatible', () {
    const field = SmartField(label: 'Notes');
    expect(field.label, 'Notes');
  });
}
