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
| `minLines` | Sets the native minimum visible line count. It does not validate text length. |
| `maxLines` | Sets the native maximum visible line count. `null` allows growth up to parent constraints. |
| `expands` | Fills a bounded parent's height and requires both line settings to be `null`. |
| `inputFormatters` | Applies only developer-supplied native input formatters. |
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

`SmartField.text()` is the named equivalent for general text and adds optional `validationPreset` and `validationPresetErrorText` parameters. Plain `SmartField()` and `SmartField.text()` remain single-line by default. Either can use the native `minLines`, `maxLines`, and `expands` options when a different layout is required.

## Description SmartField

`SmartField.description()` is a free-form native multiline field for notes, explanations, support messages, product descriptions, comments, and similar text. It accepts empty input, Unicode scripts, spaces, punctuation, numbers, symbols, apostrophes, line breaks, and emoji by default. It does not trim, capitalize, filter, or impose a text-length rule.

```dart
SmartField.description(
  label: 'Description',
  hintText: 'Enter details',
)
```

The description starts at three visible lines with `minLines: 3`, uses `maxLines: null`, and grows and shrinks through Flutter's native `TextFormField` layout as newlines, wrapping, and pasted paragraphs change. Enter inserts a newline by default. Existing constructors remain one line unless configured otherwise.

Set a finite `maxLines` to stop outer growth and scroll internally without losing content:

```dart
SmartField.description(
  label: 'Notes',
  minLines: 3,
  maxLines: 8,
)
```

With `maxLines: null`, growth continues only while the parent layout permits it. A fixed-height or otherwise bounded parent can cap the field and cause internal scrolling. `expands: true` is different from automatic growth: it fills a bounded parent's available height and requires explicit `minLines: null` and `maxLines: null`.

```dart
SizedBox(
  height: 240,
  child: SmartField.description(
    minLines: null,
    maxLines: null,
    expands: true,
  ),
)
```

Requiredness, grapheme-aware validation lengths, custom validation, and formatters remain opt-in. Line-break characters count as user-visible characters for `minLength` and `maxLength`; these rules report errors and do not truncate input.

```dart
SmartField.description(
  label: 'Additional notes',
  isRequired: true,
  minLines: 3,
  maxLines: 6,
  minLength: 10,
  validator: (value) {
    if ((value ?? '').contains('FORBIDDEN_APP_SPECIFIC_VALUE')) {
      return 'Please revise this note';
    }
    return null;
  },
)
```

The original `description` and `formfield` rules are available only as legacy presets. They preserve their exact expression and metadata:

```dart
SmartField.description(
  label: 'Legacy description',
  validationPreset: SmartTextValidationPreset.description,
)

SmartField.text(
  label: 'Legacy form field',
  validationPreset: SmartTextValidationPreset.formfield,
)
```

```json
"description": {
  "expression": "^.{3,}$",
  "comment": "any chars, at least 3",
  "error_lbl": "msg_money_transfer_services"
},
"formfield": {
  "expression": "^.{3,}$",
  "comment": "any chars, at least 3",
  "error_lbl": "lbl_provide"
}
```

Under Dart's default regular-expression behavior, `.` does not match a newline. A multiline value can therefore fail either legacy preset even when it contains three or more visible characters. The expression is intentionally not rewritten with `dotAll`; use `minLength` or a custom validator for a multiline minimum. The legacy `errorLabel` values are identifiers rather than translated messages, and `validationPresetErrorText` supplies an application-owned visible message.

Description validation follows required → selected legacy preset → configured length rules → custom validator. Input validation is not SQL-injection or XSS protection. Applications remain responsible for parameterized database queries, contextual output encoding, safe rendering, authorization, and trusted server-side validation.

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

## Name and username SmartFields

`SmartField.name()` uses Flutter's name keyboard, word-capitalization suggestion, and name autofill hint. It does not change capitalization or rewrite stored text. International names, non-Latin scripts, combining marks, spaces, apostrophes, hyphens, punctuation, and emoji remain available by default with no minimum or maximum length.

```dart
SmartField.name(
  label: 'Full name',
)
```

`SmartField.username()` uses the normal text keyboard and username autofill hint with automatic capitalization, autocorrect, and suggestions disabled. It preserves exact case and characters. No default username length, allowed-character, lowercase, or uniqueness policy is imposed.

```dart
SmartField.username(
  label: 'Username',
  isRequired: true,
)
```

Applications can add their own `validator`, `minLength`, `maxLength`, error messages, autofill hints, and `inputFormatters`. Input formatters are opt-in because they can reject text while typing. Backend systems remain responsible for username uniqueness, authorization, SQL safety, output encoding, and impersonation controls.

The five original ASCII-only rules are available through the optional `validationPreset` parameter:

```dart
SmartField.username(
  label: 'Legacy username',
  validationPreset: SmartTextValidationPreset.loginUsername,
  validationPresetErrorText: 'Use at least five letters or numbers',
)
```

Validation runs in this order: required, selected preset, configured length rules, then the custom validator. Presets report errors without filtering or rewriting the field text. Their `errorLabel` values preserve legacy identifiers and are not translated user-facing messages.

```json
"login_username": {
  "expression": "^[a-zA-Z0-9]{5,}$",
  "comment": "at least 5 chars alphanumeric",
  "error_lbl": "lbl_username"
},
"beneficiary_nickname": {
  "expression": "^[a-zA-Z0-9]{3,}$",
  "comment": "At least 3 chars alphanumeric",
  "error_lbl": "beneficiary_nickname"
},
"min_text_field": {
  "expression": "^[a-zA-Z]{1,}$",
  "comment": "at least 1 chars",
  "error_lbl": "lbl_provide"
},
"street_name": {
  "expression": "^[a-zA-Z]{1,}$",
  "comment": "at least 1 chars",
  "error_lbl": "lbl_provide"
},
"alphanumeric_3": {
  "expression": "^[a-zA-Z0-9]{1,}$",
  "comment": "at least 1 chars alphanumeric",
  "error_lbl": "lbl_provide"
}
```

- `loginUsername` accepts only ASCII letters and digits with a minimum of five characters.
- `beneficiaryNickname` accepts only ASCII letters and digits with a minimum of three characters.
- `minTextField` and `streetName` accept one or more ASCII letters, rejecting spaces, digits, apostrophes, accents, and hyphens. They are too restrictive for many modern names and streets and are never defaults.
- `alphanumeric3` accepts one or more ASCII letters or digits. Despite its legacy key suggesting three, its exact expression has a minimum of one.

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

## OTP SmartField

`SmartField.otp()` is a native Flutter verification-code input backed by one `EditableText`, one controller, and one focus node. It displays separate boxes while preserving native selection, replacement, deletion, keyboard paste, controller updates, autofill, and `Form` behavior. It uses six visible ASCII digits by default, remains optional, and does not read SMS, email, or WhatsApp messages.

```dart
SmartField.otp(
  label: 'Verification code',
  onCompleted: (code) {
    verify(code);
  },
)
```

Set a positive custom length when needed. Invalid lengths throw `ArgumentError`.

```dart
SmartField.otp(
  length: 4,
  isRequired: true,
  obscureText: true,
)
```

OTP-specific options:

| Option | Behavior |
|---|---|
| `length` | Positive exact OTP length. Defaults to `6`. |
| `obscureText` | Replaces displayed digits with bullets without changing the controller value. |
| `policy` | Selects standard validation or the opt-in six-digit legacy rule. |
| `digitErrorText` | Customizes the non-ASCII-digit error. |
| `otpLengthErrorText` | Customizes the exact-length error. |
| `legacyErrorText` | Customizes the legacy-policy error. |
| `errorText` | Displays a parent-controlled server error until the parent clears it. |
| `onCompleted` | Receives locally valid values on incomplete-to-complete transitions. |
| `notifyOnProgrammaticChanges` | Allows controller-driven changes to call `onChanged` and `onCompleted`. Defaults to `false`. |
| `style` | Supplies optional box and state styling through `SmartOtpStyle`. |

The common `SmartField` options for label, hint, controller, focus node, autofocus, enabled/read-only state, keyboard action, `onChanged`, `onSaved`, required validation, additional length validation, custom validator, autovalidation, and decoration remain available. For OTP rendering, `decoration` supplies label, hint, error, and their text styles; `SmartOtpStyle` controls the boxes.

The default input formatter accepts only a complete ASCII-digit edit up to the configured length. A malformed or oversized paste is rejected as a whole instead of removing selected characters. Leading zeros are preserved. Programmatic controller updates refresh the boxes and validation but do not call `onChanged` or `onCompleted` by default, matching Flutter's user-change callback convention. Set `notifyOnProgrammaticChanges: true` when controller-driven changes should call both callbacks.

`onCompleted` runs only when the value transitions from incomplete or invalid to complete and locally valid. Rebuilds do not repeat it. Deleting a digit and completing the code again creates a new completion transition. The callback uses the unchanged controller text.

Validation order is required, ASCII digits, exact OTP length, optional legacy policy, developer length rules, then the custom validator. Parent-owned server errors stay visible until the parent clears them:

The reusable `SmartValidators.otp(length: 6)` validator provides the same optional-empty, ASCII-digit, exact-length, and selected-policy checks without the widget. Its `digitMessage`, `lengthMessage`, and `legacyMessage` parameters customize errors.

```dart
SmartField.otp(
  errorText: verificationError,
)
```

The supplied legacy rule is opt-in and requires `length: 6`. Selecting it with another length throws `ArgumentError`.

```dart
SmartField.otp(
  policy: SmartOtpPolicy.legacy,
)
```

```json
"opt_token": {
  "expression": "^[0-9]{6}$",
  "comment": "6 digits",
  "error_lbl": "lbl_token_needed"
}
```

Use `SmartOtpStyle` to configure box dimensions, spacing, borders, radius, fill colors, digit text, cursor color, and transition timing. Unset colors come from the active theme, and animations are disabled when the platform requests reduced motion.

`SmartOtpStyle` exposes `boxWidth`, `boxHeight`, `spacing`, `borderWidth`, `focusedBorderWidth`, `borderRadius`, `borderColor`, `focusedBorderColor`, `filledBorderColor`, `errorBorderColor`, `disabledBorderColor`, `fillColor`, `focusedFillColor`, `filledFillColor`, `errorFillColor`, `disabledFillColor`, `textStyle`, `cursorColor`, `animationDuration`, and `animationCurve`.

```dart
SmartField.otp(
  style: const SmartOtpStyle(
    boxWidth: 52,
    boxHeight: 60,
    spacing: 10,
    borderRadius: BorderRadius.all(Radius.circular(16)),
  ),
)
```

The control exposes one semantic text field, supports RTL and text scaling, and shrinks boxes and spacing to avoid horizontal overflow. WhatsApp codes can be pasted by the user or assigned through an app-owned controller; the package requests no message permissions and performs no message retrieval.

## Phone SmartField

`SmartField.phone()` uses the native phone keyboard and telephone autofill. The simple field has no country or contact picker, no global length limit, and no destructive formatter. It accepts editable international or local text while validation rejects malformed symbols, letters, emoji, and misplaced `+` characters.

```dart
SmartField.phone(
  label: 'Phone Number',
)
```

The optional country prefix opens a searchable, theme-aware country list. ISO codes configure countries; dialing codes do not.

```dart
SmartField.phone(
  label: 'Phone Number',
  isRequired: true,
  showCountryPicker: true,
  initialCountryCode: 'PK',
  allowedCountryCodes: const ['PK', 'US', 'GB'],
  favoriteCountryCodes: const ['PK'],
  showContactPicker: true,
  showClearButton: true,
  onCountryChanged: (country) {
    final isoCode = country?.isoCode;
    final dialCode = country?.dialCode;
  },
  onPhoneChanged: (phone) {
    final localText = phone.text;
    final e164 = phone.e164;
  },
)
```

The controller, `onChanged`, custom validator, and `onSaved` always use the exact text in the phone field. Selecting a country never inserts a prefix or rewrites that text. `SmartPhoneValue` separately exposes the selected country, parsed national number, and E.164 value. Its `e164` is `null` when input is invalid or cannot be parsed safely. Shared dialing codes do not cause an arbitrary country selection.

Phone policies are:

- `SmartPhonePolicy.auto`, the default, uses country metadata when a country is selected and syntax-only validation otherwise.
- `SmartPhonePolicy.syntaxOnly` validates conventional phone characters without a country length rule.
- `SmartPhonePolicy.countryAware` requires selected country context and validates against that country's metadata.
- `SmartPhonePolicy.legacy` applies the original ASCII-digit rule to the field text exactly.

Validation order is required, selected phone policy, configured length rules, then the custom validator. Empty values remain valid unless `isRequired` is enabled. Metadata validation checks plausible structure, not whether a number exists, is owned, or can receive calls or messages.

Original legacy preset:

```json
"phone_number": {
  "expression": "^[0-9]{7,15}$",
  "comment": "7 to 15 digits",
  "error_lbl": "lbl_phone_8"
}
```

The contact button is shown only on Android and iOS. It opens the operating system's native one-number picker and does not request broad contact-list access, enumerate the address book, upload data, or contact a server. Cancellation leaves the field unchanged. Other failures use `onContactPickerError` when supplied or accessible `SnackBar` feedback. Adding the option does not make the native dependency optional at install time. The package requires Flutter 3.44 or later because `flutter_native_contact_picker` 0.0.13 does, and that plugin requires iOS 13 or later; the example targets iOS 15.

Country names work in English without extra setup. Apps that need translated country names can add `CountryLocalizations.delegate` from `country_picker` to their `MaterialApp` localization delegates.

Phone support uses [`country_picker` 2.0.28](https://pub.dev/packages/country_picker), [`phone_numbers_parser` 9.0.29](https://pub.dev/packages/phone_numbers_parser), and [`flutter_native_contact_picker` 0.0.13](https://pub.dev/packages/flutter_native_contact_picker). The first two use the MIT license and the native picker uses BSD-3-Clause. Their notices are retained in `THIRD_PARTY_NOTICES.md`.
