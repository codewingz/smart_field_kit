import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          SmartField.name(label: 'Full name', isRequired: true),
          SmartField.email(label: 'Email', isRequired: true),
          SmartField.password(label: 'Password', isRequired: true),
          SmartField.amount(
            label: 'Budget',
            decimalLength: 2,
            useGrouping: true,
          ),
          FilledButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
              }
            },
            child: const Text('Create account'),
          ),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('README quick start compiles, validates, and saves', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: SignUpForm())),
      ),
    );
    await tester.tap(find.text('Create account'));
    await tester.pump();
    expect(find.text('This field is required.'), findsNWidgets(3));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full name'),
      'Ana',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'ana@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'secret123',
    );
    await tester.tap(find.text('Create account'));
    await tester.pump();
    expect(find.text('This field is required.'), findsNothing);
    const field = SmartField(label: 'Notes');
    expect(field.label, 'Notes');
  });
}
