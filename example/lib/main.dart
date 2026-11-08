import 'package:flutter/material.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            child: Column(
              children: [
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
                SmartField.amount(
                  label: 'Amount',
                  decimalPlaces: 2,
                  useGrouping: true,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
