import 'package:flutter/material.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

import '../demo_widgets.dart';

const _policyNotes = <SmartPhonePolicy, String>{
  SmartPhonePolicy.auto:
      'Recommended. Uses the selected country\'s numbering rules; without a '
      'country it validates +international numbers; otherwise syntax only.',
  SmartPhonePolicy.countryAware:
      'Requires a selected country and validates against its metadata.',
  SmartPhonePolicy.syntaxOnly:
      'Checks conventional phone characters only. No length rule.',
  SmartPhonePolicy.legacy: 'The original rule: 7 to 15 ASCII digits.',
};

class PhonePage extends StatefulWidget {
  const PhonePage({super.key});

  @override
  State<PhonePage> createState() => _PhonePageState();
}

class _PhonePageState extends State<PhonePage> {
  SmartPhonePolicy _policy = SmartPhonePolicy.auto;
  bool _picker = true;
  SmartPhoneValue? _value;
  SmartPhoneCountry? _country;

  @override
  Widget build(BuildContext context) {
    final value = _value;
    return PageBody(
      children: [
        DemoCard(
          title: 'Phone policies',
          description:
              'Pick a policy and try these numbers: +923001234567 (valid '
              'international), 03001234567 with Pakistan selected, '
              '12345 (syntax passes, country rules reject it).',
          snippet: "SmartField.phone(\n  policy: SmartPhonePolicy.auto,\n  showCountryPicker: true,\n  initialCountryCode: 'PK',\n  onPhoneChanged: (phone) {},\n)",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  for (final policy in SmartPhonePolicy.values)
                    ChoiceChip(
                      label: Text(policy.name),
                      selected: _policy == policy,
                      onSelected: (_) => setState(() {
                        _policy = policy;
                        _value = null;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(_policyNotes[_policy]!),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show country picker'),
                value: _picker,
                onChanged: (value) => setState(() {
                  _picker = value;
                  _value = null;
                }),
              ),
              SmartField.phone(
                key: ValueKey('$_policy$_picker'),
                label: 'Phone number',
                policy: _policy,
                showCountryPicker: _picker,
                initialCountryCode: _picker ? 'PK' : null,
                allowedCountryCodes: _picker
                    ? const ['PK', 'US', 'GB', 'AE', 'IN']
                    : null,
                favoriteCountryCodes: _picker ? const ['PK'] : null,
                showContactPicker: true,
                showClearButton: true,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onCountryChanged: (country) =>
                    setState(() => _country = country),
                onPhoneChanged: (phone) => setState(() => _value = phone),
              ),
              ValueRow(
                'Country',
                _country?.isoCode ?? (_picker ? 'PK (initial)' : '(none)'),
              ),
              ValueRow('Text', value?.text ?? ''),
              ValueRow('National', value?.nationalNumber ?? '(not parsed)'),
              ValueRow('E.164', value?.e164 ?? '(null: invalid or unparsed)'),
              ValueRow('Country valid', '${value?.isValid ?? false}'),
            ],
          ),
        ),
        const DemoCard(
          title: 'Syntax versus country validity',
          description:
              'Syntax-only accepts any sensible mix of digits, spaces, '
              'hyphens, parentheses, and a leading +. Country-aware validation '
              'also checks the number against that country\'s numbering rules, '
              'so a number can pass syntax and still be rejected. There is no '
              'universal length. Metadata checks plausibility, not that a '
              'number exists or can receive calls.',
          child: SizedBox.shrink(),
        ),
        DemoCard(
          title: 'Privacy-masked phone',
          description:
              'Masking is visual only. The unfocused field shows ******4567 '
              'while the controller keeps the real digits; focusing reveals '
              'them for editing.',
          snippet: "SmartField.phone(mask: true)",
          child: SmartField.phone(
            label: 'Phone (masked when unfocused)',
            mask: true,
          ),
        ),
      ],
    );
  }
}
