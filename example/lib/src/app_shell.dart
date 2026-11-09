import 'package:flutter/material.dart';

import 'pages/design_page.dart';
import 'pages/numbers_page.dart';
import 'pages/otp_search_page.dart';
import 'pages/payments_dates_page.dart';
import 'pages/phone_page.dart';
import 'pages/secure_page.dart';
import 'pages/text_page.dart';
import 'pages/utilities_page.dart';
import 'pages/validation_page.dart';
import 'settings.dart';

class _Destination {
  const _Destination(this.label, this.icon, this.builder);

  final String label;
  final IconData icon;
  final Widget Function(ShowcaseSettings settings) builder;
}

final List<_Destination> _destinations = [
  _Destination('Text', Icons.text_fields, (_) => const TextPage()),
  _Destination('Passwords', Icons.lock_outline, (_) => const SecurePage()),
  _Destination('Phone', Icons.phone_outlined, (_) => const PhonePage()),
  _Destination('Numbers', Icons.pin_outlined, (_) => const NumbersPage()),
  _Destination('OTP & search', Icons.search, (_) => const OtpSearchPage()),
  _Destination('Validation', Icons.rule, (_) => const ValidationPage()),
  _Destination(
    'Cards & dates',
    Icons.credit_card,
    (_) => const PaymentsDatesPage(),
  ),
  _Destination(
    'Design',
    Icons.palette_outlined,
    (s) => DesignPage(settings: s),
  ),
  _Destination('Utilities', Icons.build_outlined, (_) => const UtilitiesPage()),
];

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.settings});

  final ShowcaseSettings settings;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final destination = _destinations[_index];
    final body = KeyedSubtree(
      key: ValueKey(_index),
      child: destination.builder(widget.settings),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text('smart_field_kit · ${destination.label}'),
        actions: [
          IconButton(
            tooltip: 'Toggle light and dark theme',
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              final dark = Theme.of(context).brightness == Brightness.dark;
              widget.settings.themeMode = dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
            },
          ),
        ],
      ),
      drawer: wide
          ? null
          : Drawer(
              child: SafeArea(
                child: ListView(
                  children: [
                    for (var i = 0; i < _destinations.length; i++)
                      ListTile(
                        leading: Icon(_destinations[i].icon),
                        title: Text(_destinations[i].label),
                        selected: i == _index,
                        onTap: () {
                          Navigator.of(context).pop();
                          setState(() => _index = i);
                        },
                      ),
                  ],
                ),
              ),
            ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  labelType: NavigationRailLabelType.all,
                  onDestinationSelected: (value) =>
                      setState(() => _index = value),
                  destinations: [
                    for (final item in _destinations)
                      NavigationRailDestination(
                        icon: Icon(item.icon),
                        label: Text(item.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
    );
  }
}
