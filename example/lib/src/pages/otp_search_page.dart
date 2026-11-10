import 'package:flutter/material.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

import '../demo_widgets.dart';

const _catalog = <String>[
  'Apple',
  'Apricot',
  'Banana',
  'Blueberry',
  'Cherry',
  'Grape',
  'Lemon',
  'Mango',
  'Orange',
  'Peach',
  'Pear',
  'Plum',
];

class OtpSearchPage extends StatefulWidget {
  const OtpSearchPage({super.key});

  @override
  State<OtpSearchPage> createState() => _OtpSearchPageState();
}

class _OtpSearchPageState extends State<OtpSearchPage> {
  final _serverError = SmartServerError();
  final _searchController = TextEditingController();
  bool _obscure = false;
  int _otpLength = 6;
  String _otpStatus = 'Waiting for a code';
  List<String> _results = _catalog;
  bool _searching = false;
  int _searchCalls = 0;

  @override
  void dispose() {
    _serverError.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    setState(() {
      _searching = true;
      _searchCalls++;
    });
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted || _searchController.text != query) {
      return;
    }
    final lower = query.trim().toLowerCase();
    setState(() {
      _results = [
        for (final item in _catalog)
          if (item.toLowerCase().contains(lower)) item,
      ];
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        DemoCard(
          title: 'One-time code',
          description:
              'A single native input drawn as boxes: autofill, paste, and '
              'completion. Code values are never shown or logged by this app. '
              'Enter any code; 000000 simulates a server rejection.',
          snippet:
              "SmartField.otp(\n  length: 6,\n  obscureText: false,\n  onCompleted: (code) {},\n  serverError: serverError,\n)",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OptionChips<int>(
                options: const {4: '4 digits', 6: '6 digits', 8: '8 digits'},
                selected: _otpLength,
                onChanged: (value) => setState(() => _otpLength = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Hide digits'),
                value: _obscure,
                onChanged: (value) => setState(() => _obscure = value),
              ),
              Center(
                child: SmartField.otp(
                  key: ValueKey('$_otpLength$_obscure'),
                  length: _otpLength,
                  obscureText: _obscure,
                  serverError: _serverError,
                  onChanged: (code) => setState(
                    () => _otpStatus = code.isEmpty
                        ? 'Waiting for a code'
                        : '${code.length} of $_otpLength digits entered',
                  ),
                  onCompleted: (code) {
                    setState(
                      () => _otpStatus = 'Completed ($_otpLength digits)',
                    );
                    if (code == '0' * _otpLength) {
                      _serverError.set('That code was rejected.');
                    }
                  },
                ),
              ),
              ValueRow('Status', _otpStatus),
              const SizedBox(height: 8),
              const Text(
                'The package does not read SMS or WhatsApp. Autofill depends '
                'on the platform keyboard and may not work on every device.',
              ),
            ],
          ),
        ),
        DemoCard(
          title: 'Search with debounce',
          description:
              'onSearch runs after typing pauses. Clear cancels pending work. '
              'This demo filters a local list with a simulated 350 ms delay; '
              'there is no network.',
          snippet:
              "SmartField.search(\n  debounceDuration: const Duration(milliseconds: 400),\n  onSearch: (query) {},\n  isLoading: loading,\n)",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SmartField.search(
                label: 'Search fruit',
                controller: _searchController,
                isLoading: _searching,
                onSearch: _search,
                onCleared: () => setState(() {
                  _results = _catalog;
                  _searching = false;
                }),
              ),
              ValueRow('Searches', '$_searchCalls debounced call(s)'),
              const SizedBox(height: 8),
              if (_results.isEmpty)
                const Text('No matches')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final item in _results) Chip(label: Text(item)),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
