# smart_field_kit

`smart_field_kit` provides reusable Flutter form fields built on Flutter's native Material text-field behavior.

## Normal SmartField

`SmartField` is a normal text field by default. It allows empty input and unrestricted normal text, including letters, numbers, spaces, punctuation, Unicode, and emoji. It adds no automatic validators, character filters, or length limits.

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
| `enabled` | Uses Flutter's normal enabled state. `null` keeps the native default. |
| `readOnly` | Uses Flutter's read-only behavior. Defaults to `false`. |
| `keyboardType` | Forwards the requested `TextInputType`. |
| `textInputAction` | Forwards the requested keyboard action. |
| `onChanged` | Receives native user-initiated text changes. |
| `onSaved` | Runs when the surrounding `Form` is saved. |
| `validator` | Runs through native `Form` validation when supplied. |
| `decoration` | Customizes the native `InputDecoration`. Defaults to an empty decoration. |

`label` and `hintText` fill missing values in `decoration`. Values already supplied by `decoration` take precedence.

Controllers and focus nodes supplied by the developer remain developer-owned and must be disposed by their owner. When they are omitted, Flutter's native `TextFormField` lifecycle applies.

## Form validation

`SmartField` has no built-in validation. Supply a validator when the application needs one.

```dart
final formKey = GlobalKey<FormState>();

Form(
  key: formKey,
  child: SmartField(
    label: 'Display name',
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'Enter a display name';
      }
      return null;
    },
  ),
)
```

The field uses the inherited `ThemeData`, `InputDecorationTheme`, Material version, keyboard behavior, and `Form` lifecycle.
