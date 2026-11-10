import 'package:flutter/material.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

import '../demo_widgets.dart';

class TextPage extends StatefulWidget {
  const TextPage({super.key});

  @override
  State<TextPage> createState() => _TextPageState();
}

class _TextPageState extends State<TextPage> {
  final _formKey = GlobalKey<FormState>();
  SmartEmailPolicy _emailPolicy = SmartEmailPolicy.standard;
  bool _legacyUsername = false;
  SmartTextCase _textCase = SmartTextCase.none;
  bool _collapse = false;
  bool _bareDomain = false;
  String _rawMask = '';
  String _maskedText = '';
  String _plain = '';

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        DemoCard(
          title: 'Normal text',
          description:
              'SmartField() and SmartField.text() are normal text fields. '
              'Spaces, Unicode, and emoji are accepted; nothing is required '
              'or limited unless you opt in.',
          snippet:
              "SmartField(label: 'Notes')\nSmartField.text(label: 'Title')",
          child: Column(
            children: [
              SmartField(
                label: 'Anything (try ☕ or Ærøskøbing)',
                onChanged: (value) => setState(() => _plain = value),
              ),
              ValueRow('Value', _plain),
              const SizedBox(height: fieldGap),
              SmartField.text(label: 'Text, required', isRequired: true),
            ],
          ),
        ),
        DemoCard(
          title: 'Name and username',
          description:
              'Names accept Unicode, spaces, apostrophes, and hyphens. '
              'Usernames can be lowercased and limited to safe characters. '
              'The legacy preset reproduces the original ASCII rule.',
          snippet:
              "SmartField.name(capitalizeWords: true)\n"
              "SmartField.username(\n"
              "  usernameCase: SmartTextCase.lowercase,\n"
              "  allowedCharacters: SmartUsernameCharacters.usernameSafe,\n"
              ")",
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              children: [
                SmartField.name(label: 'Name', capitalizeWords: true),
                const SizedBox(height: fieldGap),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Original legacy username rule'),
                  subtitle: const Text('At least 5 ASCII letters or numbers.'),
                  value: _legacyUsername,
                  onChanged: (value) => setState(() => _legacyUsername = value),
                ),
                SmartField.username(
                  key: ValueKey(_legacyUsername),
                  label: 'Username',
                  usernameCase: SmartTextCase.lowercase,
                  allowedCharacters: SmartUsernameCharacters.usernameSafe,
                  validationPreset: _legacyUsername
                      ? SmartTextValidationPreset.loginUsername
                      : null,
                ),
              ],
            ),
          ),
        ),
        DemoCard(
          title: 'Email',
          description:
              'Standard validation checks practical syntax. The legacy policy '
              'applies the original expression. Existence of the mailbox '
              'is only known by your server.',
          snippet: "SmartField.email(policy: SmartEmailPolicy.legacy)",
          child: Column(
            children: [
              OptionChips<SmartEmailPolicy>(
                options: const {
                  SmartEmailPolicy.standard: 'Standard',
                  SmartEmailPolicy.legacy: 'Legacy',
                },
                selected: _emailPolicy,
                onChanged: (value) => setState(() => _emailPolicy = value),
              ),
              const SizedBox(height: fieldGap),
              SmartField.email(
                key: ValueKey(_emailPolicy),
                label: 'Email',
                policy: _emailPolicy,
                emailErrorText: 'Enter an email like name@example.com.',
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
            ],
          ),
        ),
        DemoCard(
          title: 'Description with word limits',
          description:
              'Multiline, grows with the text, and counts words. Word limits '
              'never block typing; they only affect validation.',
          snippet:
              "SmartField.description(\n  minWords: 3,\n  maxWords: 20,\n  showWordCount: true,\n)",
          child: SmartField.description(
            label: 'Description',
            minWords: 3,
            maxWords: 20,
            showWordCount: true,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ),
        DemoCard(
          title: 'Text formatters',
          description:
              'Optional case and whitespace formatters keep the caret and '
              'ignore active IME composition.',
          child: Column(
            children: [
              DropdownButtonFormField<SmartTextCase>(
                isExpanded: true,
                initialValue: _textCase,
                decoration: const InputDecoration(labelText: 'textCase'),
                items: [
                  for (final value in SmartTextCase.values)
                    DropdownMenuItem(value: value, child: Text(value.name)),
                ],
                onChanged: (value) =>
                    setState(() => _textCase = value ?? SmartTextCase.none),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('collapseWhitespace'),
                value: _collapse,
                onChanged: (value) => setState(() => _collapse = value!),
              ),
              SmartField.text(
                key: ValueKey('$_textCase$_collapse'),
                label: 'Type here',
                textCase: _textCase,
                collapseWhitespace: _collapse,
              ),
            ],
          ),
        ),
        DemoCard(
          title: 'Input mask: formatted text and raw value',
          description:
              'A format mask changes the formatted controller text '
              '(1234-5678). The raw value contains only the entered characters. '
              'This is not privacy masking.',
          snippet:
              "SmartField.text(\n  inputMask: '####-####',\n  onRawChanged: (raw) {},\n)",
          child: Column(
            children: [
              SmartField.text(
                label: 'Reference',
                inputMask: '####-####',
                onChanged: (value) => setState(() => _maskedText = value),
                onRawChanged: (raw) => setState(() => _rawMask = raw),
              ),
              ValueRow('Formatted', _maskedText),
              ValueRow('Raw', _rawMask),
            ],
          ),
        ),
        DemoCard(
          title: 'URL',
          description:
              'Checks URL syntax and allowed schemes. It does not tell you '
              'whether a site is safe or reachable.',
          snippet:
              "SmartField.url(\n  allowedSchemes: {'https'},\n  allowBareDomain: true,\n)",
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Allow bare domain (example.com)'),
                value: _bareDomain,
                onChanged: (value) => setState(() => _bareDomain = value),
              ),
              SmartField.url(
                key: ValueKey(_bareDomain),
                label: 'Website',
                allowedSchemes: const {'https'},
                allowBareDomain: _bareDomain,
                urlErrorText: 'Enter an https:// address.',
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
