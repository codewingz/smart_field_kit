import 'package:flutter/material.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

import '../demo_widgets.dart';

class SecurePage extends StatefulWidget {
  const SecurePage({super.key});

  @override
  State<SecurePage> createState() => _SecurePageState();
}

class _SecurePageState extends State<SecurePage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  SmartPasswordPolicy _policy = SmartPasswordPolicy.weak;
  String _status = 'Not submitted';

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        DemoCard(
          title: 'Password policy',
          description:
              'Visibility toggle and a documented policy. The weak policy only '
              'rejects empty values; the strong policy needs several character '
              'types. Passwords are never displayed or logged here.',
          snippet: "SmartField.password(policy: SmartPasswordPolicy.strong)",
          child: Column(
            children: [
              OptionChips<SmartPasswordPolicy>(
                options: const {
                  SmartPasswordPolicy.weak: 'weak',
                  SmartPasswordPolicy.strong: 'strong',
                },
                selected: _policy,
                onChanged: (value) => setState(() => _policy = value),
              ),
              const SizedBox(height: fieldGap),
              SmartField.password(
                key: ValueKey(_policy),
                label: 'Password',
                policy: _policy,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
            ],
          ),
        ),
        DemoCard(
          title: 'Strength indicator and checklist',
          description:
              'Informational feedback with developer-defined criteria. It is '
              'separate from validation.',
          snippet: "SmartField.password(\n  showStrengthIndicator: true,\n  showStrengthChecklist: true,\n  strengthCriteria: [\n    SmartPasswordCriterion.minLength(10),\n    SmartPasswordCriterion.digit,\n  ],\n)",
          child: SmartField.password(
            label: 'New password',
            showStrengthIndicator: true,
            showStrengthChecklist: true,
            strengthCriteria: [
              SmartPasswordCriterion.minLength(10),
              SmartPasswordCriterion.digit,
              SmartPasswordCriterion.specialCharacter,
              SmartPasswordCriterion(
                'No spaces',
                (value) => !value.contains(' '),
              ),
            ],
          ),
        ),
        DemoCard(
          title: 'Confirm password',
          description:
              'The second field compares against the first field\'s controller. '
              'Editing the first field revalidates a non-empty confirmation.',
          snippet: "SmartField.password(controller: password)\nSmartField.password(matchController: password)",
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              children: [
                SmartField.password(
                  label: 'Password',
                  controller: _password,
                  isRequired: true,
                ),
                const SizedBox(height: fieldGap),
                SmartField.password(
                  label: 'Confirm password',
                  matchController: _password,
                  mismatchErrorText: 'Passwords do not match.',
                  isRequired: true,
                ),
                const SizedBox(height: fieldGap),
                Row(
                  children: [
                    FilledButton(
                      onPressed: () => setState(
                        () => _status = _formKey.currentState!.validate()
                            ? 'Passwords match'
                            : 'Fix the errors above',
                      ),
                      child: const Text('Validate'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () {
                        _formKey.currentState!.reset();
                        setState(() => _status = 'Not submitted');
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                ValueRow('Status', _status),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
