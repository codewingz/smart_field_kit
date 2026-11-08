import 'package:flutter/material.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

void main() {
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: EdgeInsets.all(24),
          child: SmartField(label: 'Full Name', hintText: 'Enter your name'),
        ),
      ),
    ),
  );
}
