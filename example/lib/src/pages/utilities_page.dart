import 'package:flutter/material.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

import '../demo_widgets.dart';

class UtilitiesPage extends StatefulWidget {
  const UtilitiesPage({super.key});

  @override
  State<UtilitiesPage> createState() => _UtilitiesPageState();
}

class _UtilitiesPageState extends State<UtilitiesPage> {
  final _input = TextEditingController(text: '03001234567');

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  String _safe(String Function() run) {
    try {
      return run();
    } on FormatException catch (error) {
      return 'FormatException: ${error.message}';
    } on ArgumentError catch (error) {
      return 'ArgumentError: ${error.message}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        DemoCard(
          title: 'Masking utilities',
          description:
              'Independent of the widget. They return masked copies and never '
              'change their input. Masking is a visual privacy aid, not '
              'encryption. Use only sample values here.',
          snippet: "maskMobile('03001234567')\nmaskAccountNumber('000012345678')\nmaskAmount('12,345.67 PKR')",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _input,
                decoration: const InputDecoration(
                  labelText: 'Sample value (not sensitive)',
                ),
                onChanged: (_) => setState(() {}),
              ),
              ValueRow('maskMobile', _safe(() => maskMobile(_input.text))),
              ValueRow(
                'maskAccount',
                _safe(() => maskAccountNumber(_input.text)),
              ),
              ValueRow('maskAmount', _safe(() => maskAmount(_input.text))),
              ValueRow(
                'formatNumber',
                _safe(
                  () =>
                      formatNumber(
                        _input.text,
                        decimalPlaces: 2,
                        useGrouping: true,
                      ) ??
                      '(not a valid number)',
                ),
              ),
            ],
          ),
        ),
        DemoCard(
          title: 'Validators, text, and decimal helpers',
          description:
              'The same code the widgets use, callable without a widget.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ValueRow(
                'email',
                SmartValidators.email()('not-an-email') ?? 'valid',
              ),
              ValueRow(
                'url',
                SmartValidators.url()('https://example.com') ?? 'valid',
              ),
              ValueRow(
                'words',
                '${SmartTextUtils.countWords('three small words')}',
              ),
              ValueRow(
                'round',
                SmartDecimalUtils.round(
                  '12.345',
                  decimalPlaces: 2,
                  mode: SmartRoundingMode.halfUp,
                ),
              ),
              ValueRow(
                'password',
                SmartPasswordStrength.evaluate('Tr0ub4dor&3').level.name,
              ),
              ValueRow(
                'Luhn',
                '${SmartCardUtils.passesLuhn('4111111111111111')}',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
