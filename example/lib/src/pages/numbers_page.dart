import 'package:flutter/material.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

import '../demo_widgets.dart';

class NumbersPage extends StatefulWidget {
  const NumbersPage({super.key});

  @override
  State<NumbersPage> createState() => _NumbersPageState();
}

class _NumbersPageState extends State<NumbersPage> {
  bool _negative = false;
  bool _limits = false;
  Object _decimalLength = 2;
  bool _grouping = true;
  bool _indian = false;
  bool _currency = false;
  SmartRoundingMode _rounding = SmartRoundingMode.none;
  bool _maskAmount = false;
  String _amountRaw = '';
  String _amountSavedRaw = '';
  String _percentDisplay = '';
  String _percentRaw = '';
  final _amountForm = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amountKey = ValueKey(
      '$_decimalLength$_grouping$_indian$_currency$_rounding$_maskAmount',
    );
    return PageBody(
      children: [
        DemoCard(
          title: 'Integer number',
          description:
              'Digits only by default. Negative numbers and value limits are '
              'opt-in; limits are compared exactly, without binary doubles.',
          snippet: "SmartField.number(\n  allowNegative: true,\n  minValue: '-10',\n  maxValue: '100',\n)",
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Allow negative'),
                value: _negative,
                onChanged: (value) => setState(() => _negative = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Limit to -10 … 100'),
                value: _limits,
                onChanged: (value) => setState(() => _limits = value),
              ),
              SmartField.number(
                key: ValueKey('$_negative$_limits'),
                label: 'Quantity',
                allowNegative: _negative,
                minValue: _limits ? '-10' : null,
                maxValue: _limits ? '100' : null,
                minValueErrorText: 'Must be at least -10.',
                maxValueErrorText: 'Must be at most 100.',
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
            ],
          ),
        ),
        DemoCard(
          title: 'Amount: displayed value versus raw value',
          description:
              'Type 50000.00 and leave the field: the display becomes '
              '50,000.00 while the developer receives the raw 50000.00. '
              'While focused, grouping and currency are hidden so editing is '
              'predictable.',
          snippet: "SmartField.amount(\n  decimalLength: 2,\n  useGrouping: true,\n  groupingStyle: SmartGroupingStyle.indian,\n  rounding: SmartRoundingMode.halfUp,\n  onRawChanged: (raw) {},\n  onRawSaved: (raw) {},\n)",
          child: Form(
            key: _amountForm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    for (final length in <Object>[false, 1, 2, 3])
                      ChoiceChip(
                        label: Text('decimalLength: $length'),
                        selected: _decimalLength == length,
                        onSelected: (_) =>
                            setState(() => _decimalLength = length),
                      ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Grouping'),
                  value: _grouping,
                  onChanged: (value) => setState(() => _grouping = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Indian grouping (1,23,45,678)'),
                  value: _indian,
                  onChanged: (value) => setState(() => _indian = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Currency symbol (PKR prefix)'),
                  value: _currency,
                  onChanged: (value) => setState(() => _currency = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Privacy mask when unfocused'),
                  value: _maskAmount,
                  onChanged: (value) => setState(() => _maskAmount = value),
                ),
                DropdownButtonFormField<SmartRoundingMode>(
                  isExpanded: true,
                  initialValue: _rounding,
                  decoration: const InputDecoration(labelText: 'rounding'),
                  items: [
                    for (final mode in SmartRoundingMode.values)
                      DropdownMenuItem(value: mode, child: Text(mode.name)),
                  ],
                  onChanged: (value) => setState(
                    () => _rounding = value ?? SmartRoundingMode.none,
                  ),
                ),
                const SizedBox(height: fieldGap),
                SmartField.amount(
                  key: amountKey,
                  label: 'Amount',
                  controller: _amountController,
                  decimalLength: _decimalLength,
                  useGrouping: _grouping,
                  groupingStyle: _indian
                      ? SmartGroupingStyle.indian
                      : SmartGroupingStyle.international,
                  currencySymbol: _currency ? 'PKR ' : null,
                  rounding: _rounding,
                  mask: _maskAmount,
                  onRawChanged: (raw) => setState(() => _amountRaw = raw),
                  onRawSaved: (raw) =>
                      setState(() => _amountSavedRaw = raw ?? '(incomplete)'),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _amountForm.currentState!.save(),
                  child: const Text('Save form (rounds and reports raw)'),
                ),
                ListenableBuilder(
                  listenable: _amountController,
                  builder: (context, _) =>
                      ValueRow('Displayed', _amountController.text),
                ),
                ValueRow('Raw (typing)', _amountRaw),
                ValueRow('Raw (saved)', _amountSavedRaw),
              ],
            ),
          ),
        ),
        DemoCard(
          title: 'Percentage',
          description:
              'The % is a visual suffix. The raw value is percentage points '
              '(12.5), never a fraction such as 0.125.',
          snippet: "SmartField.percentage(\n  decimalPlaces: 2,\n  minValue: '0',\n  maxValue: '100',\n)",
          child: Column(
            children: [
              SmartField.percentage(
                label: 'Discount',
                decimalPlaces: 2,
                allowNegative: false,
                minValue: '0',
                maxValue: '100',
                maxValueErrorText: 'Cannot exceed 100%.',
                onChanged: (text) => setState(() {
                  _percentDisplay = text;
                  _percentRaw = text;
                }),
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              ValueRow(
                'Displayed',
                _percentDisplay.isEmpty ? '' : '$_percentDisplay%',
              ),
              ValueRow('Raw', _percentRaw),
            ],
          ),
        ),
        DemoCard(
          title: 'Masked account number',
          description:
              'SmartField.number(mask: true) shows ******5678 while '
              'unfocused. The controller and callbacks keep the real digits.',
          child: SmartField.number(
            label: 'Account number',
            mask: true,
            maskVisibleSuffixDigits: 4,
            maskCharacter: '•',
          ),
        ),
      ],
    );
  }
}
