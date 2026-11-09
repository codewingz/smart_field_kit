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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Form(
              child: Column(
                children: [
                  SmartField.name(label: 'Full name'),
                  const SizedBox(height: 16),
                  SmartField.username(label: 'Username', isRequired: true),
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
                  SmartField.email(label: 'Email Address', isRequired: true),
                  const SizedBox(height: 16),
                  SmartField.email(
                    label: 'Legacy Email',
                    policy: SmartEmailPolicy.legacy,
                  ),
                  const SizedBox(height: 16),
                  SmartField.password(label: 'Password', isRequired: true),
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
                    decimalPlaces: 2,
                    useGrouping: true,
                  ),
                  const SizedBox(height: 16),
                  SmartField.amount(
                    label: 'Masked Amount',
                    decimalPlaces: 2,
                    useGrouping: true,
                    mask: true,
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
