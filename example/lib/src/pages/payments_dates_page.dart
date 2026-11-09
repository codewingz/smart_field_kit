import 'package:flutter/material.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

import '../demo_widgets.dart';

String _synthetic(String prefix, int length) {
  final body = prefix.padRight(length - 1, '0');
  for (var digit = 0; digit < 10; digit++) {
    final candidate = '$body$digit';
    if (SmartCardUtils.passesLuhn(candidate)) {
      return candidate;
    }
  }
  return '${body}0';
}

final Map<String, String> _samples = {
  'Visa': '4111111111111111',
  'Mastercard': '5555555555554444',
  'Amex': _synthetic('37', 15),
  'Diners': _synthetic('36', 14),
  'Discover': '6011111111111117',
  'JCB': '3530111333300000',
  'UnionPay': _synthetic('62', 16),
  'Mir': _synthetic('2200', 16),
  'Troy': _synthetic('9792', 16),
  'Bad checksum': '4111111111111112',
};

class PaymentsDatesPage extends StatefulWidget {
  const PaymentsDatesPage({super.key});

  @override
  State<PaymentsDatesPage> createState() => _PaymentsDatesPageState();
}

class _PaymentsDatesPageState extends State<PaymentsDatesPage> {
  final _number = TextEditingController();
  SmartCardBrand _brand = SmartCardBrand.unknown;
  SmartCardNumberStatus _status = SmartCardNumberStatus.empty;
  bool _luhnUnionPay = false;
  String _dateRaw = '';
  String _timeRaw = '';
  String _dateTimeRaw = '';
  SmartDateMode _dateMode = SmartDateMode.calendar;

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supported = [
      for (final brand in SmartCardBrand.values)
        if (brand != SmartCardBrand.unknown) brand.displayName,
    ].join(', ');
    return PageBody(
      children: [
        DemoCard(
          title: 'Credit card (synthetic numbers only)',
          description:
              'Tap a sample to fill the number. Everything is checked locally '
              'and instantly: brand, grouping, length, Luhn, expiry, and '
              'brand-specific security-code length. A pass does not mean the '
              'card exists or will be approved. Number and security code are '
              'never displayed, stored, or logged by this app; do not enter '
              'real card data in a demo.',
          snippet: "SmartField.creditCard(\n  acceptedBrands: {SmartCardBrand.visa, SmartCardBrand.mastercard},\n  onChanged: (card) => card.brand,\n)",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final entry in _samples.entries)
                    ActionChip(
                      label: Text(entry.key),
                      onPressed: () => _number.text = entry.value,
                    ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enforce Luhn on UnionPay too'),
                subtitle: const Text(
                  'UnionPay is exempt from the checksum by default.',
                ),
                value: _luhnUnionPay,
                onChanged: (value) => setState(() => _luhnUnionPay = value),
              ),
              const SizedBox(height: 8),
              SmartField.creditCard(
                key: ValueKey(_luhnUnionPay),
                numberController: _number,
                luhnExemptBrands: _luhnUnionPay
                    ? const {}
                    : const {SmartCardBrand.unionPay},
                onChanged: (card) => setState(() {
                  _brand = card.brand;
                  _status = card.numberStatus;
                }),
              ),
              ValueRow('Brand', _brand.displayName),
              ValueRow('Number status', _status.name),
              const SizedBox(height: 8),
              Text(
                'Supported networks: $supported. RuPay is not supported; '
                'numbers from unsupported networks are treated as the matching '
                'supported brand or as unknown (12 to 19 digits).',
              ),
            ],
          ),
        ),
        DemoCard(
          title: 'Date',
          description:
              'Four modes: manual (masked typing), calendar, dropdowns, and '
              'wheel. Raw values are ISO text; the typed text stays in your '
              'chosen format.',
          snippet: "SmartField.date(\n  mode: SmartDateMode.calendar,\n  restriction: SmartDateRestriction.pastOnly,\n  onRawChanged: (iso) {},\n)",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OptionChips<SmartDateMode>(
                options: {
                  for (final mode in SmartDateMode.values) mode: mode.name,
                },
                selected: _dateMode,
                onChanged: (value) => setState(() {
                  _dateMode = value;
                  _dateRaw = '';
                }),
              ),
              const SizedBox(height: fieldGap),
              SmartField.date(
                key: ValueKey(_dateMode),
                label: 'Date',
                mode: _dateMode,
                showClearButton: true,
                onRawChanged: (raw) => setState(() => _dateRaw = raw),
              ),
              ValueRow('Raw (ISO)', _dateRaw),
            ],
          ),
        ),
        DemoCard(
          title: 'Time and date-time',
          description:
              'Time supports manual, picker, and wheel. Date-time supports '
              'manual and picker (date, then time); there is no date-time wheel.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SmartField.time(
                label: 'Time (picker)',
                mode: SmartTimeMode.picker,
                use24Hour: false,
                onRawChanged: (raw) => setState(() => _timeRaw = raw),
              ),
              ValueRow('Raw (ISO)', _timeRaw),
              const SizedBox(height: fieldGap),
              SmartField.time(label: 'Time (wheel)', mode: SmartTimeMode.wheel),
              const SizedBox(height: fieldGap),
              SmartField.dateTime(
                label: 'Date and time (picker)',
                mode: SmartTimeMode.picker,
                onRawChanged: (raw) => setState(() => _dateTimeRaw = raw),
              ),
              ValueRow('Raw (ISO)', _dateTimeRaw),
            ],
          ),
        ),
      ],
    );
  }
}
