# smart_field_kit

`smart_field_kit` provides reusable Flutter form fields built on Flutter's native Material text-field behavior.

## Normal SmartField

`SmartField` is a normal text field by default. It allows empty input and unrestricted normal text, including letters, numbers, spaces, punctuation, Unicode, and emoji. Required and length validation are opt-in. It adds no character filters or default length limits.

```dart
import 'package:flutter/material.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

SmartField(
  label: 'Full Name',
  hintText: 'Enter your name',
)
```

## Options

| Option | Behavior |
|---|---|
| `label` | Fills the decoration label when the supplied decoration has no label. |
| `hintText` | Fills the decoration hint when the supplied decoration has no hint. |
| `controller` | Uses a developer-owned `TextEditingController`. Flutter creates internal control when omitted. |
| `focusNode` | Uses a developer-owned `FocusNode`. Flutter manages focus internally when omitted. |
| `autofocus` | Uses Flutter's native autofocus behavior. Defaults to `false`. |
| `enabled` | Uses Flutter's normal enabled state. `null` keeps the native default. |
| `readOnly` | Uses Flutter's read-only behavior. Defaults to `false`. |
| `keyboardType` | Forwards the requested `TextInputType`. |
| `textCapitalization` | Forwards native text capitalization behavior. |
| `autocorrect` | Enables native autocorrection for normal fields by default. |
| `autofillHints` | Forwards native platform autofill hints. |
| `textInputAction` | Forwards the requested keyboard action. |
| `onChanged` | Receives native user-initiated text changes. |
| `onSaved` | Runs when the surrounding `Form` is saved. |
| `isRequired` | Rejects null, empty, and whitespace-only values when `true`. Defaults to `false`. |
| `requiredErrorText` | Sets the required-field error message. |
| `minLength` | Sets an optional minimum user-visible character count. |
| `minLengthErrorText` | Sets the minimum-length error message. |
| `maxLength` | Sets an optional maximum user-visible character count without filtering input. |
| `maxLengthErrorText` | Sets the maximum-length error message. |
| `validator` | Runs after required and length validation when supplied. |
| `autovalidateMode` | Uses Flutter's native automatic validation behavior. |
| `decoration` | Customizes the native `InputDecoration`. Defaults to an empty decoration. |

`label` and `hintText` fill missing values in `decoration`. Values already supplied by `decoration` take precedence.

Controllers and focus nodes supplied by the developer remain developer-owned and must be disposed by their owner. When they are omitted, Flutter's native `TextFormField` lifecycle applies.

## Form validation

Validation runs in this order: required, minimum length, maximum length, then the custom validator. The first error is displayed. Optional blank values skip length validation. Length validation uses Unicode grapheme clusters, so a visible emoji is counted as one character.

```dart
final formKey = GlobalKey<FormState>();

Form(
  key: formKey,
  child: SmartField(
    label: 'Display name',
    isRequired: true,
    requiredErrorText: 'Enter a display name',
    minLength: 2,
    maxLength: 50,
    validator: (value) {
      if (value == 'Unknown') {
        return 'Please enter a valid name';
      }
      return null;
    },
  ),
)
```

The field uses the inherited `ThemeData`, `InputDecorationTheme`, Material version, keyboard behavior, and `Form` lifecycle.

## Standalone validators

`SmartValidators` can be used independently of `SmartField`.

```dart
final validator = SmartValidators.compose([
  SmartValidators.requiredField(message: 'Value required'),
  SmartValidators.minLength(2),
  SmartValidators.maxLength(50),
]);

final error = validator('value');
```

Validation does not remove or rewrite input. Client-side validation is not SQL-injection protection; backend systems must use parameterized queries and trusted server-side validation.

## Email SmartField

`SmartField.email()` uses Flutter's email keyboard and autofill hint, disables autocorrect, and applies no capitalization. Empty input remains optional unless `isRequired` is enabled. The default policy accepts practical formats including plus-addressing and subdomains without changing the stored value.

```dart
SmartField.email(
  label: 'Email Address',
  isRequired: true,
)
```

The optional legacy policy preserves the supplied `email_address` rule exactly. It is intentionally narrower than the default policy and rejects addresses containing subdomains.

```dart
SmartField.email(
  label: 'Legacy Email',
  policy: SmartEmailPolicy.legacy,
)
```

Original legacy preset:

```json
"email_address": {
  "expression": "^[A-Za-z0-9][A-Za-z0-9.!#$%&'*+\\-/=?^_`{|}~]*@[A-Za-z0-9-]+\\.[A-Za-z]+$",
  "comment": "valid email address",
  "error_lbl": "lbl_provide"
}
```

The default email validator is intentionally practical rather than a complete implementation of every valid internationalized or quoted email-address form. No global email length limit is imposed. Configure `minLength` or `maxLength` only when the application requires them.
