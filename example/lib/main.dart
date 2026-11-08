import 'package:flutter/material.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            child: SmartField(
              label: 'Full Name',
              hintText: 'Enter your name',
              isRequired: true,
              minLength: 2,
              validator: (value) {
                if (value == 'Unknown') {
                  return 'Please enter a valid name';
                }
                return null;
              },
            ),
          ),
        ),
      ),
    ),
  );
}
