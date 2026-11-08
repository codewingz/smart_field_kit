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
| `enableSuggestions` | Enables native keyboard suggestions for normal fields by default. |
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

## Password SmartField

`SmartField.password()` obscures text by default, uses Flutter's password keyboard and autofill hint, and disables capitalization, autocorrect, and keyboard suggestions. Its accessible show/hide control can be removed with `showVisibilityToggle: false`. Toggling visibility does not change the password, selection, controller, or focus.

No complexity or length rule is enabled by default. Empty input remains optional unless `isRequired` is enabled.

```dart
SmartField.password(
  label: 'Password',
  isRequired: true,
)
```

The supplied legacy policies are explicitly opt-in:

```dart
SmartField.password(
  label: 'Password',
  isRequired: true,
  policy: SmartPasswordPolicy.strong,
)
```

Validation runs in this order: required, selected password policy, configured length limits, then the custom validator. The first error is displayed. Password text is never trimmed, replaced, or filtered.

Original legacy presets:

```json
"login_password_weak": {
  "expression": "^.{5,}$",
  "comment": "any chars, at least 6",
  "error_lbl": "msg_confirm_password"
},
"login_password": {
  "expression": "^(?=.*?[A-Z])(?=(.*[a-z]){1,})(?=(.*[\\d]){1,})(?=(.*[\\W]){1,})(?!.*\\s).{8,}$",
  "comment": "Password should have,at least a upper case letter, a lower case letter, a digit, a special character [@#$%^&+=] length of at least 4no white space allowed",
  "error_lbl": "msg_confirm_password"
}
```

The weak expression accepts five or more characters even though its comment says six. The strong expression requires at least eight characters even though its comment says four. The expressions and metadata are preserved without correcting those mismatches.

## Number SmartField

`SmartField.number()` accepts normal multi-digit integers, `0`, leading zeros, deletion, selection, and paste. It does not convert the text to an integer, so identifier-like values such as `000123` remain unchanged. Negative values, length limits, numeric value limits, and required validation are opt-in.

```dart
SmartField.number(
  label: 'Quantity',
)
```

Numeric bounds use exact decimal strings and do not use `double` arithmetic:

```dart
SmartField.number(
  label: 'Quantity',
  allowNegative: true,
  minValue: '-100',
  maxValue: '1000000000000000000000000000000',
)
```

The optional legacy policy preserves the supplied rule exactly:

```dart
SmartField.number(
  policy: SmartNumberPolicy.legacy,
)
```

```json
"number": {
  "expression": "^[0-9]$",
  "comment": "8 digits",
  "error_lbl": "lbl_phone_8"
}
```

The expression accepts exactly one digit although its comment says eight. Normal number fields use the multi-digit standard policy.

## Amount SmartField

`SmartField.amount()` accepts exact decimal text without converting through `double`. No currency, grouping, decimal limit, fixed fractional suffix, value bound, or digit limit is applied unless configured.

```dart
SmartField.amount(
  label: 'Amount',
  decimalPlaces: 2,
  useGrouping: true,
)
```

With that configuration, `50000.00` is editable while focused and displays as `50,000.00` after focus leaves the field. Partial values remain editable without repeated grouping. Invalid text such as `5,000.oo` is rejected rather than cleaned into a valid amount.

Currency text, separators, position, negative values, and exact value bounds are optional:

```dart
SmartField.amount(
  label: 'Balance',
  decimalPlaces: 2,
  useGrouping: true,
  currencySymbol: ' USD',
  currencyPosition: SmartCurrencyPosition.suffix,
  allowNegative: true,
  minValue: '-1000000.00',
  maxValue: '1000000.00',
)
```

`currencySymbol` accepts a symbol or code exactly as supplied. Include a space in that string when separation is wanted.

### Display and raw amount values

- The controller, `onChanged`, custom `validator`, and `onSaved` preserve Flutter's display-text behavior.
- While focused, the display text is ungrouped and has no configured currency text.
- When focus leaves, configured grouping, decimal padding, and currency text are displayed.
- `onRawChanged` receives normalized ungrouped numeric text during user edits.
- `onRawSaved` receives normalized ungrouped numeric text when the `Form` is saved, or `null` when the display is not a complete valid amount.
- `SmartAmountFormatter` provides the same exact normalization and formatting independently of the widget.

The optional legacy amount policy is evaluated against normalized, ungrouped text:

```dart
SmartField.amount(
  decimalPlaces: 2,
  policy: SmartAmountPolicy.legacy,
)
```

```json
"amount_of_money": {
  "expression": "^\\d+(\\.\\d{1,2})?$",
  "comment": "Please enter a valid amount (e.g., 123.45)",
  "error_lbl": ""
}
```

The legacy policy remains opt-in. The standard policy follows the configured precision instead of forcing one or two decimal places.

For number and amount fields, validation runs in this order: required, field syntax or selected legacy policy, configured length rules, minimum value, maximum value, then the custom validator. The first error is displayed.
