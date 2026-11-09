import 'package:flutter/material.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

import '../demo_widgets.dart';

class ValidationPage extends StatefulWidget {
  const ValidationPage({super.key});

  @override
  State<ValidationPage> createState() => _ValidationPageState();
}

class _ValidationPageState extends State<ValidationPage> {
  final _modeForm = GlobalKey<FormState>();
  SmartValidationMode _mode = SmartValidationMode.both;
  final Set<SmartBuiltInCheck> _checks = {SmartBuiltInCheck.passwordDigit};

  final _asyncForm = GlobalKey<FormState>();
  final _asyncController = SmartFieldAsyncController();
  SmartAsyncValidationTrigger _trigger = SmartAsyncValidationTrigger.onChanged;
  final List<String> _log = [];
  String _submitResult = 'Not submitted';
  bool _submitting = false;

  final _serverError = SmartServerError();
  final _serverForm = GlobalKey<FormState>();
  String _serverResult = '';

  @override
  void initState() {
    super.initState();
    _asyncController.addListener(_onAsync);
  }

  @override
  void dispose() {
    _asyncController
      ..removeListener(_onAsync)
      ..dispose();
    _serverError.dispose();
    super.dispose();
  }

  void _onAsync() {
    if (mounted) {
      setState(() {});
    }
  }

  void _record(String line) {
    if (!mounted) {
      return;
    }
    setState(() {
      _log.insert(0, line);
      if (_log.length > 6) {
        _log.removeLast();
      }
    });
  }

  Future<String?> _checkUsername(String value) async {
    final slow = value.startsWith('slow');
    _record('check "$value" started${slow ? ' (slow: 1.5 s)' : ''}');
    await Future<void>.delayed(
      slow
          ? const Duration(milliseconds: 1500)
          : const Duration(milliseconds: 500),
    );
    _record('check "$value" returned');
    if (value == 'offline') {
      throw StateError('simulated network failure');
    }
    return value == 'taken' ? 'Username is already taken.' : null;
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    if (!_asyncForm.currentState!.validate()) {
      setState(() => _submitResult = 'Synchronous rules failed');
      return;
    }
    setState(() {
      _submitting = true;
      _submitResult = 'Checking…';
    });
    final available = await _asyncController.validateAsync();
    if (!mounted) {
      return;
    }
    final stillValid = available && _asyncForm.currentState!.validate();
    setState(() {
      _submitting = false;
      _submitResult = stillValid
          ? 'Submitted'
          : 'Blocked: ${_asyncController.errorText ?? 'invalid'}';
    });
  }

  Future<void> _simulateServer() async {
    final applied = await _serverError.track(
      Future<String?>.delayed(
        const Duration(milliseconds: 400),
        () => 'This email is already registered.',
      ),
    );
    if (mounted) {
      setState(
        () => _serverResult = applied ? 'Server error shown' : 'Ignored',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        DemoCard(
          title: 'Validation modes and selectable checks',
          description:
              'both: built-in rule then your validator. builtIn: built-in only. '
              'custom: only your validator. selected: only the listed '
              'checks plus your validator. This password field also has a '
              'custom rule that rejects the word "password".',
          snippet: "SmartField.password(\n  validationMode: SmartValidationMode.selected,\n  builtInChecks: {SmartBuiltInCheck.passwordDigit},\n  validator: (value) => ...,\n)",
          child: Form(
            key: _modeForm,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    for (final mode in SmartValidationMode.values)
                      ChoiceChip(
                        label: Text(mode.name),
                        selected: _mode == mode,
                        onSelected: (_) => setState(() => _mode = mode),
                      ),
                  ],
                ),
                if (_mode == SmartValidationMode.selected)
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final check in SmartBuiltInCheck.values)
                        FilterChip(
                          label: Text(check.name),
                          selected: _checks.contains(check),
                          onSelected: (on) => setState(
                            () =>
                                on ? _checks.add(check) : _checks.remove(check),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: fieldGap),
                SmartField.password(
                  key: ValueKey('$_mode${_checks.length}${_checks.join()}'),
                  label: 'Password',
                  policy: SmartPasswordPolicy.strong,
                  validationMode: _mode,
                  builtInChecks: Set.of(_checks),
                  validator: (value) =>
                      (value ?? '').toLowerCase().contains('password')
                      ? 'Choose something less obvious.'
                      : null,
                ),
              ],
            ),
          ),
        ),
        DemoCard(
          title: 'Async validation (simulated, no network)',
          description:
              'Try "taken" (invalid), "offline" (unavailable), "ok" (valid), '
              'and "slow-1" then quickly "slow-2": the older response is '
              'ignored. Flutter\'s FormState.validate() is synchronous, so submit '
              'awaits validateAsync() as well.',
          snippet: "SmartAsyncValidation(\n  controller: controller,\n  debounceDuration: const Duration(milliseconds: 400),\n  validator: (value) async {\n    await Future.delayed(const Duration(milliseconds: 500));\n    return value == 'taken' ? 'Username is already taken.' : null;\n  },\n)\n\nif (await controller.validateAsync()) formKey.currentState!.save();",
          child: Form(
            key: _asyncForm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OptionChips<SmartAsyncValidationTrigger>(
                  options: {
                    for (final trigger in SmartAsyncValidationTrigger.values)
                      trigger: trigger.name,
                  },
                  selected: _trigger,
                  onChanged: (value) => setState(() => _trigger = value),
                ),
                const SizedBox(height: fieldGap),
                SmartField.username(
                  key: ValueKey(_trigger),
                  label: 'Username',
                  isRequired: true,
                  asyncValidation: SmartAsyncValidation(
                    controller: _asyncController,
                    trigger: _trigger,
                    debounceDuration: const Duration(milliseconds: 400),
                    validator: _checkUsername,
                    timeout: const Duration(seconds: 3),
                    unavailableErrorText: 'Network unavailable. Try again.',
                  ),
                ),
                ValueRow('Status', _asyncController.status.name),
                ValueRow('Error', _asyncController.errorText ?? ''),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: Text(_submitting ? 'Checking…' : 'Submit'),
                ),
                ValueRow('Submit', _submitResult),
                ValueRow('Log', _log.isEmpty ? '' : _log.join('\n')),
              ],
            ),
          ),
        ),
        DemoCard(
          title: 'Server errors',
          description:
              'A message from your backend shown through the normal error UI. '
              'It clears on the next edit, and a stale response never overwrites '
              'a newer one.',
          snippet: "final serverError = SmartServerError();\nserverError.set('Email already registered');\nawait serverError.track(api.check(email));",
          child: Form(
            key: _serverForm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SmartField.email(label: 'Email', serverError: _serverError),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilledButton(
                      onPressed: _simulateServer,
                      child: const Text('Simulate server rejection'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        _serverError.clear();
                        setState(() => _serverResult = 'Cleared');
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
                ValueRow('Result', _serverResult),
              ],
            ),
          ),
        ),
        DemoCard(
          title: 'State restoration',
          description:
              'Eligible nonsensitive fields restore their text when given a '
              'restorationId inside a RestorationScope. Amount, phone, search, '
              'masked, password, OTP, and card fields are never restored.',
          snippet: "SmartField.text(restorationId: 'notes')",
          child: SmartField.text(
            label: 'Restorable text',
            restorationId: 'showcase_restorable_text',
          ),
        ),
      ],
    );
  }
}
