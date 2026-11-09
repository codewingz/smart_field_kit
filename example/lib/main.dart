import 'package:flutter/material.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _usernameAsync = SmartFieldAsyncController();
  final _passwordController = TextEditingController();
  final _serverError = SmartServerError();
  var _submitting = false;

  @override
  void dispose() {
    _searchController.dispose();
    _usernameAsync.dispose();
    _passwordController.dispose();
    _serverError.dispose();
    super.dispose();
  }

  Future<String?> _checkUsername(String value) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return value == 'taken' ? 'Username is already taken.' : null;
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _submitting = true);
    try {
      final isAvailable = await _usernameAsync.validateAsync();
      if (!isAvailable || !mounted || !_formKey.currentState!.validate()) {
        return;
      }
      _formKey.currentState!.save();
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SmartField.name(label: 'Full name'),
                  const SizedBox(height: 16),
                  SmartField.username(
                    label: 'Username',
                    isRequired: true,
                    asyncValidation: SmartAsyncValidation(
                      controller: _usernameAsync,
                      validator: _checkUsername,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: const Text('Submit'),
                  ),
                  const SizedBox(height: 16),
                  SmartField.search(
                    controller: _searchController,
                    label: 'Search',
                    hintText: 'Search products',
                    onSearch: (query) {},
                  ),
                  const SizedBox(height: 16),
                  SmartField.description(
                    label: 'Description',
                    hintText: 'Enter details',
                    minWords: 2,
                    maxWords: 200,
                    showWordCount: true,
                    textCase: SmartTextCase.capitalizeSentences,
                  ),
                  const SizedBox(height: 16),
                  SmartField.description(
                    label: 'Notes capped at eight lines',
                    maxLines: 8,
                  ),
                  const SizedBox(height: 16),
                  SmartField.text(
                    label: 'Legacy Form Field',
                    validationPreset: SmartTextValidationPreset.formfield,
                  ),
                  const SizedBox(height: 16),
                  SmartField.username(
                    label: 'Legacy Username',
                    validationPreset: SmartTextValidationPreset.loginUsername,
                  ),
                  const SizedBox(height: 16),
                  SmartField.email(
                    label: 'Email Address',
                    isRequired: true,
                    serverError: _serverError,
                    restorationId: 'email',
                  ),
                  TextButton(
                    onPressed: () =>
                        _serverError.set('Email already registered'),
                    child: const Text('Simulate server error'),
                  ),
                  const SizedBox(height: 16),
                  SmartField.email(
                    label: 'Legacy Email',
                    policy: SmartEmailPolicy.legacy,
                  ),
                  const SizedBox(height: 16),
                  SmartField.password(
                    label: 'Password',
                    isRequired: true,
                    controller: _passwordController,
                    validationMode: SmartValidationMode.selected,
                    builtInChecks: const {
                      SmartBuiltInCheck.passwordUppercase,
                      SmartBuiltInCheck.passwordDigit,
                    },
                  ),
                  const SizedBox(height: 16),
                  SmartField.password(
                    label: 'Confirm password',
                    isRequired: true,
                    matchController: _passwordController,
                  ),
                  const SizedBox(height: 16),
                  SmartField.password(
                    label: 'Strong Password',
                    policy: SmartPasswordPolicy.strong,
                  ),
                  const SizedBox(height: 16),
                  SmartField.number(label: 'Quantity'),
                  const SizedBox(height: 16),
                  SmartField.number(label: 'Masked Identifier', mask: true),
                  const SizedBox(height: 16),
                  SmartField.amount(
                    label: 'Amount',
                    decimalLength: 2,
                    useGrouping: true,
                    rounding: SmartRoundingMode.halfUp,
                  ),
                  const SizedBox(height: 16),
                  SmartField.amount(
                    label: 'Masked Amount',
                    decimalPlaces: 2,
                    useGrouping: true,
                    mask: true,
                  ),
                  const SizedBox(height: 16),
                  SmartField.url(
                    label: 'Website',
                    hintText: 'https://example.com',
                  ),
                  const SizedBox(height: 16),
                  SmartField.url(
                    label: 'Company website',
                    isRequired: true,
                    allowedSchemes: const {'https'},
                  ),
                  const SizedBox(height: 16),
                  SmartField.url(
                    label: 'Website or domain',
                    allowBareDomain: true,
                  ),
                  const SizedBox(height: 16),
                  SmartField.percentage(label: 'Growth rate'),
                  const SizedBox(height: 16),
                  SmartField.percentage(
                    label: 'Progress',
                    isRequired: true,
                    minValue: '0',
                    maxValue: '100',
                    decimalPlaces: 2,
                    allowNegative: false,
                  ),
                  const SizedBox(height: 16),
                  SmartField.otp(
                    label: 'Verification code',
                    onCompleted: (code) {},
                  ),
                  const SizedBox(height: 16),
                  SmartField.otp(
                    label: 'Legacy verification code',
                    policy: SmartOtpPolicy.legacy,
                  ),
                  const SizedBox(height: 16),
                  SmartField.phone(label: 'Phone Number'),
                  const SizedBox(height: 16),
                  SmartField.phone(label: 'Masked Phone Number', mask: true),
                  const SizedBox(height: 16),
                  SmartField.phone(
                    label: 'Phone With Country',
                    isRequired: true,
                    showCountryPicker: true,
                    initialCountryCode: 'PK',
                    allowedCountryCodes: const ['PK', 'US', 'GB'],
                    favoriteCountryCodes: const ['PK'],
                    showContactPicker: true,
                    showClearButton: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
