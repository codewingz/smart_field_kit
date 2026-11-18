# smart_field_kit

**One flexible Flutter form-field toolkit. Familiar Flutter APIs, purpose-built input types, and reusable validation—without rebuilding the same form logic in every app.**

[![Flutter package](https://img.shields.io/badge/Flutter-package-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-null--safe-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![pub package](https://img.shields.io/pub/v/smart_field_kit.svg)](https://pub.dev/packages/smart_field_kit)

Build anything from a plain text field to a country-aware phone input, exact-decimal amount, OTP entry, credit-card form, or date picker using the same `SmartField` family.

```dart
SmartField.email(label: 'Email', isRequired: true);
SmartField.phone(label: 'Phone', showCountryPicker: true);
SmartField.amount(label: 'Amount', decimalLength: 2, useGrouping: true);
SmartField.otp(length: 6, onCompleted: (value) {});
```

> **Requirements:** Flutter 3.47.0 or later and Dart 3.13.0 or later. Version 0.1.0 builds on [`material_ui`](https://pub.dev/packages/material_ui), Flutter's standalone Material package; see [Moving from 0.0.1](#moving-from-001). Tested platforms and known limits are listed in [Platform notes](#platform-notes).

**Why this package?** Use a single, familiar set of input widgets while keeping Flutter's `Form`, `TextEditingController`, `FocusNode`, `InputDecoration`, keyboard, theme, and validation conventions. Ordinary text stays unrestricted by default; special rules are opt-in or specific to a selected field type.

## Contents

- [Why SmartField Kit](#why-smartfield-kit)
- [Feature overview](#feature-overview)
- [Installation](#installation)
- [Quick start: working Form](#quick-start-working-form)
- [Choose a field](#choose-a-field)
- [Documentation](#documentation)
  - [Fields](#fields)
  - [Validation](#validation)
  - [Formatting and masks](#formatting-and-masks)
  - [Phone numbers](#phone-numbers)
  - [Cards and dates](#cards-and-dates)
  - [Customization and localization](#customization-and-localization)
  - [Security and privacy](#security-and-privacy)
  - [Platform notes](#platform-notes)
- [Example application and development](#example-application-and-development)
- [Frequently asked questions](#frequently-asked-questions)
- [Contributing](#contributing)
- [Third-party acknowledgments](#third-party-acknowledgments)
- [License](#license)

## Why SmartField Kit

Flutter already has excellent native text fields. `smart_field_kit` builds on them rather than replacing Flutter's form system. It brings commonly repeated work into reusable, opt-in field behavior:

- **One API family:** easy-to-read constructors such as `SmartField.email()` and `.amount()`.
- **Familiar integration:** native `Form` validation, `onSaved`, input decorations, controllers, focus, and theme behavior.
- **Input-specific behavior:** phone metadata, currency presentation, percentage suffixes, OTP boxes, date selection, and card checks.
- **Composable validation:** built-in checks, developer validators, selected rules, asynchronous checks, and server messages.
- **Predictable values:** no silent text rewrites for email, passwords, URLs, or plain text; explicit display-versus-raw behavior for formatted fields.
- **Privacy-aware defaults:** concealed OTP/CVV when configured, opt-in masking, and locally evaluated card checks without package-managed network requests.

The package is an **input toolkit**, not a complete authentication server, payment processor, contacts database, or security boundary.

## Feature overview

| Capability | What it provides | Key detail |
|---|---|---|
| General text and multiline | Plain text, description, optional limits | No default requiredness or arbitrary length limit |
| Names and usernames | Autofill, optional casing and presets | Unicode-friendly by default |
| Email and URLs | Local format policies | Checks format, not account/site existence |
| Passwords | Visibility, confirm-password matching, optional strength feedback | Strength feedback is not authorization |
| Phone numbers | Country picker, parser, optional contact picker, four policies | Country-aware checks where context exists |
| Number and amounts | Exact decimal strings, value bounds, grouping and rounding | No `double` conversion for monetary values |
| Percentage | `%` visual suffix and precise raw text | `12.5%` is passed as `12.5` |
| Search | Debounced callback, clear, loading state | Application owns the search operation |
| OTP | Separate visual boxes, paste, completion, optional hiding | No SMS/WhatsApp reading |
| Credit cards | Brand detection, grouping, Luhn where applicable, expiry and security-code checks | Local plausibility only; not payment approval |
| Date and time | Manual/calendar/dropdown/wheel dates; time/date-time options | Local, timezone-naive values |
| Masks | Pattern formatting and separate visual privacy masks | Raw values are not replaced by privacy masking |
| Validation | Four modes, legacy presets, async checks, server error messages | Backend must validate too |
| UI | Material themes, RTL, text scaling, decoration overrides | Developer → theme → package fallback |

> **Visual previews:** Use the real Flutter [`example/`](example/) app to explore field states. Add screenshots or animated GIFs only after they have been captured from the running example; no placeholder image or simulated UI is presented as a verified screenshot.

## Installation

### From pub.dev

```bash
flutter pub add smart_field_kit
```

Or add it to `pubspec.yaml` and run `flutter pub get`:

```yaml
dependencies:
  smart_field_kit: ^0.1.0
```

### From a local clone

To develop against a local copy, use a path dependency that points to your cloned package directory:

```yaml
dependencies:
  smart_field_kit:
    path: ../smart_field_kit
```

Import the public entry point in your Dart file:

```dart
import 'package:smart_field_kit/smart_field_kit.dart';
```

No `lib/src/` import should be necessary for a consumer application.

## Quick start: working Form

This example uses Flutter's regular `Form` API. It validates required fields, keeps controller ownership in the application, and doesn't print or store passwords.

```dart
import 'package:material_ui/material_ui.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

void main() => runApp(const MaterialApp(home: ContactFormExample()));

class ContactFormExample extends StatefulWidget {
  const ContactFormExample({super.key});

  @override
  State<ContactFormExample> createState() => _ContactFormExampleState();
}

class _ContactFormExampleState extends State<ContactFormExample> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Local validation passed')),
    );
    // Validate again on your server before using the submitted data.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SmartField example')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              shrinkWrap: true,
              children: [
                SmartField.name(
                  label: 'Full name',
                  isRequired: true,
                ),
                const SizedBox(height: 16),
                SmartField.email(
                  label: 'Email address',
                  controller: _emailController,
                  isRequired: true,
                ),
                const SizedBox(height: 16),
                SmartField.description(
                  label: 'Message',
                  minLines: 3,
                  maxLines: 6,
                  maxWords: 200,
                  showWordCount: true,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submit,
                  child: const Text('Validate'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

### Five rules that matter

1. **Nothing is required unless you request it.** Use `isRequired: true` or a custom validator.
2. **Your controllers are yours.** Dispose developer-created controllers and focus nodes in your own widget state.
3. **Display text and raw values can differ.** Use `onRawChanged`/`onRawSaved` for supported formatted fields.
4. **Asynchronous validation needs an explicit await.** Ordinary `FormState.validate()` does not wait for network checks.
5. **Always validate on the server.** Input validation helps UX but does not replace backend security.

## Choose a field

All these calls use the public `smart_field_kit.dart` import.

| Input | Constructor | Example |
|---|---|---|
| Plain single-line text | `SmartField()` or `.text()` | `SmartField(label: 'Notes')` |
| Description | `.description()` | `SmartField.description(label: 'Details')` |
| Personal name | `.name()` | `SmartField.name(label: 'Name')` |
| Username | `.username()` | `SmartField.username(label: 'Username')` |
| Email | `.email()` | `SmartField.email(label: 'Email')` |
| Password | `.password()` | `SmartField.password(label: 'Password')` |
| Phone | `.phone()` | `SmartField.phone(showCountryPicker: true)` |
| Integer | `.number()` | `SmartField.number(label: 'Quantity')` |
| Decimal/money | `.amount()` | `SmartField.amount(decimalLength: 2)` |
| Percentage | `.percentage()` | `SmartField.percentage(label: 'Rate')` |
| URL | `.url()` | `SmartField.url(label: 'Website')` |
| Search | `.search()` | `SmartField.search(onSearch: (value) {})` |
| OTP | `.otp()` | `SmartField.otp(length: 6)` |
| Card number + expiry + CVV | `.creditCard()` | `SmartField.creditCard()` |
| Date | `.date()` | `SmartField.date(mode: SmartDateMode.calendar)` |
| Time | `.time()` | `SmartField.time(mode: SmartTimeMode.picker)` |
| Date and time | `.dateTime()` | `SmartField.dateTime(mode: SmartTimeMode.picker)` |
| Pattern input | `.text(inputMask: ...)` | `SmartField.text(inputMask: '####-####')` |

Explore the full, exact behavior of each constructor below. Examples show supported options, not a claim that every option exists on every specialized or composite constructor.

## Documentation

### Fields

#### Plain text — `SmartField()` and `.text()`

`SmartField` is a normal text field by default. It allows empty input and unrestricted normal text, including letters, numbers, spaces, punctuation, Unicode, and emoji. Required and length validation are opt-in. It adds no character filters or default length limits.

```dart
import 'package:material_ui/material_ui.dart';
import 'package:smart_field_kit/smart_field_kit.dart';
SmartField(
  label: 'Full Name',
  hintText: 'Enter your name',
)
```

#### Description and multiline text

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

```text
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

#### Name and username

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

```text
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

#### Email addresses

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

```text
"email_address": {
  "expression": "^[A-Za-z0-9][A-Za-z0-9.!#$%&'\*+\\\\-/=?^_\`{|}\~]\*@[A-Za-z0-9-]+\\\\.[A-Za-z]+$",
  "comment": "valid email address",
  "error_lbl": "lbl_provide"
}
```

The default email validator is intentionally practical rather than a complete implementation of every valid internationalized or quoted email-address form. No global email length limit is imposed. Configure `minLength` or `maxLength` only when the application requires them.

#### Passwords

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

```text
"login_password_weak": {
  "expression": "^.{5,}$",
  "comment": "any chars, at least 6",
  "error_lbl": "msg_confirm_password"
},
"login_password": {
  "expression": "^(?=.\*?[A-Z])(?=(.\*[a-z]){1,})(?=(.\*[\\\d]){1,})(?=(.\*[\\\W]){1,})(?!.\*\\\s).{8,}$",
  "comment": "Password should have,at least a upper case letter, a lower case letter, a digit, a special character [@#$%^&+=] length of at least 4no white space allowed",
  "error_lbl": "msg_confirm_password"
}
```

The weak expression accepts five or more characters even though its comment says six. The strong expression requires at least eight characters even though its comment says four. The expressions and metadata are preserved without correcting those mismatches.

#### Numbers and integer text

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

```text
"number": {
  "expression": "^[0-9]$",
  "comment": "8 digits",
  "error_lbl": "lbl_phone_8"
}
```

The expression accepts exactly one digit although its comment says eight. Normal number fields use the multi-digit standard policy.

#### URLs

`SmartField.url()` checks URL **syntax only**. It never opens, fetches, resolves, or previews a URL, and a syntactically valid URL is not proof that a site exists or is safe.

```dart
SmartField.url(label: 'Website', hintText: 'https://example.com')
SmartField.url(
  label: 'Company website',
  isRequired: true,
  allowedSchemes: const {'https'},
  validator: (value) =>
      value!.contains('blocked.example') ? 'This website is not allowed.' : null,
)
SmartField.url(label: 'Website or domain', allowBareDomain: true)
```

- Optional by default; empty input is valid. No length or value limit is applied unless `minLength`/`maxLength` are set.

- Uses `TextInputType.url`, `TextInputAction.done`, no capitalization, autocorrect, or suggestions.

- Text is never edited: no trimming, lowercasing, encoding, scheme prefix, or slash normalization. The controller, `onChanged`, `onSaved`, and validators receive exactly what was entered. Typing is never blocked; use `inputFormatters` for input restrictions.

- By default a nonempty value must be an absolute `http://` or `https://` URL with a well-formed host. Leading/trailing or embedded whitespace, control characters, invisible and direction-changing characters (zero-width space, soft hyphen, byte-order mark, and the Unicode embedding, override, and isolate marks), `<`, `>`, `"`, `\\`, malformed `%` escapes, invalid ports, missing hosts, and other schemes (`javascript:`, `data:`, `file:`, `ftp:`, `mailto:`) are rejected.

- Accepted hosts include subdomains, `localhost`, intranet names, IPv4, bracketed IPv6, and non-default ports. No TLD, hostname length, or public-internet rule is imposed. Unicode hosts and paths are accepted as typed and are not converted to Punycode. IPv4-looking hosts must have octets of 255 or less. `user:pass@host` is syntactically accepted; treat such values as sensitive.

- `allowedSchemes` replaces the permitted schemes, for example `{'https'}`. Added schemes still need a valid authority.

- `allowBareDomain: true` also accepts `example.com`, `example.com:8080/path`, IPv4, and bracketed IPv6 without a scheme. A bare host needs a dot (so `localhost` needs `http://`) and cannot contain `@`. The text is never prefixed with `https://`; your app must decide how to resolve it.

- `urlErrorText` overrides the message. Validation order: required, URL syntax, configured length rules, custom validator.

- `SmartValidators.url()` and `SmartUrlValidation.isValid()` provide the same check without the widget.

If your backend later fetches submitted URLs, enforce a server-side URL policy and defend against SSRF, redirects, and DNS rebinding. Syntax validation does not prevent those attacks. URLs may contain tokens, so avoid logging full values.

#### Search with debounce

`SmartField.search()` is a native single-line search input. It uses the Material search keyboard action, provides a decorative search icon, and shows an accessible clear action only while editable text is present. It has no built-in search engine, network request, results list, history, or default text restriction.

```dart
SmartField.search(
  label: 'Search',
  hintText: 'Search products',
)
```

`onChanged` receives user edits immediately. `onSearch` is an optional debounce event: when it is provided, its default quiet period is 300 milliseconds. Set `debounceDuration: Duration.zero` for an immediate event. Blank and whitespace-only queries do not emit `onSearch`, but their original text remains unchanged and is delivered to `onChanged`. Focus loss, caret movement, and parent rebuilds do not cancel a pending debounce, so `onSearch` may be written inline in `build`; when the quiet period ends, the `onSearch` from the latest build is called once with the current text. A text change restarts the wait. Clear, submit, disposal, disabled or read-only updates, a changed `debounceDuration`, controller replacement, removing `onSearch`, and Form reset cancel it.

```dart
SmartField.search(
  hintText: 'Search customers',
  debounceDuration: const Duration(milliseconds: 400),
  onChanged: (query) {},
  onSearch: (query) {},
  onSubmitted: (query) {},
)
```

`onSubmitted` runs immediately for the keyboard Search action and cancels any pending debounce without sending another `onSearch`. `onCleared` runs only when the built-in clear button is tapped; Backspace to empty is an ordinary `onChanged('')` edit. Programmatic controller changes update the field without calling `onChanged`, `onSearch`, or `onSubmitted`.

The application owns loading and request state. `isLoading` only displays a compact progress indicator; it does not make, cancel, or track requests. Controllers and focus nodes supplied by the application remain application-owned.

```dart
class SearchExample extends StatefulWidget {
  const SearchExample({super.key});
  @override
  State<SearchExample> createState() => _SearchExampleState();
}
class _SearchExampleState extends State<SearchExample> {
  final searchController = TextEditingController();
  bool isSearching = false;
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return SmartField.search(
      controller: searchController,
      hintText: 'Search orders',
      isLoading: isSearching,
      onSearch: (query) {},
      onCleared: () {},
    );
  }
}
```

Set `showClearButton: false`, `searchIcon: null`, or `clearIcon: null` to remove the corresponding built-in affordance. A decoration `prefixIcon` or `suffixIcon` remains available for application-specific customization. Requiredness, length rules, custom validation, input formatters, Form save/reset, themes, and Material 3 behavior use the shared SmartField contract.

#### OTP input

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

The default input formatter accepts only a complete ASCII-digit edit up to the configured length. An edit that contains anything other than digits, whitespace, hyphens, and invisible formatting characters (zero-width and direction marks that messaging apps add around codes) is rejected as a whole; those separators are removed. When a rebuild makes `length` shorter than the code already entered, the text is trimmed to the new length so the controller and form value match the boxes. Digits beyond the configured length are dropped. When exactly one full code is inserted into a field that already holds digits, for example a keyboard suggestion or paste after the user typed the first digit, the inserted code replaces the existing digits instead of being cut short. Leading zeros are preserved. Programmatic controller updates refresh the boxes and validation but do not call `onChanged` or `onCompleted` by default, matching Flutter's user-change callback convention. Set `notifyOnProgrammaticChanges: true` when controller-driven changes should call both callbacks.

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

```text
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

#### Common options

| Option | Behavior |

|---|---|

| `label` | Fills the decoration label when the supplied decoration has no label. |

| `hintText` | Fills the decoration hint when the supplied decoration has no hint. |

| `controller` | Uses a developer-owned `TextEditingController`. A field manages its internal controller when omitted. |

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

#### Standard text-field options

The default, `text`, `description`, `email`, `url`, `name`, `username`, `phone`, `password`, `number`, `percentage`, and `amount` constructors accept these optional Flutter options. Leaving them out keeps the previous behaviour.

| Parameter | Notes |
|---|---|
| `initialValue` | Starting text when you do not pass a `controller`. Passing both fails an assertion, as in `TextFormField`. `FormState.reset` returns to it. Amount fields format it for display |
| `onFieldSubmitted` | Called with the text when the keyboard action is pressed |
| `onEditingComplete` | Replaces Flutter's default editing-complete behaviour, as in `TextFormField` |
| `onTap`, `onTapOutside` | Passed to the underlying field |
| `style` | Text style of the input. Ignored while a privacy mask is shown |
| `textAlign`, `textDirection` | Override the defaults, including the left-to-right default of digit fields |
| `obscuringCharacter` | `SmartField.password` only |

`SmartField.search` accepts the same options except `onFieldSubmitted` and `onTap`, because it already has `onSubmitted` and `onTap`. The OTP, credit-card, date, time, and date-time constructors do not take these options. `contextMenuBuilder` and `maxLengthEnforcement` are not exposed.

#### Email whitespace

With the standard policy, validation ignores spaces before and after the address, and `onSaved` receives the trimmed address. The text in the field and in your controller is not rewritten, and `onChanged` reports it as typed. The legacy policy is unchanged and still rejects surrounding spaces. Asynchronous validation receives the trimmed address too, so a uniqueness check runs on the value that is saved.

#### OTP paste and overwrite

Spaces, hyphens, and non-breaking spaces in pasted text are removed, so `123 456` and `123-456` fill a six-digit field. Extra digits beyond the configured length are dropped. Text containing any other character is rejected as before. When every box is filled, tapping a box and typing a digit replaces that digit. `onCompleted` is called once for each distinct complete code, including a code produced by replacing a digit.

#### Number formatter export

`SmartNumberInputFormatter` is exported from `package:smart_field_kit/smart_field_kit.dart` for use on your own `TextField`.

### Validation

#### Synchronous Flutter Form validation

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

#### Four validation modes

Every constructor accepts `validationMode` and `builtInChecks`:

- `SmartValidationMode.both` (default): the field's built-in rule, then your `validator`.

- `SmartValidationMode.builtIn`: built-in rule only; your `validator` is ignored.

- `SmartValidationMode.custom`: only your `validator`; the built-in format rule is skipped.

- `SmartValidationMode.selected`: only the checks listed in `builtInChecks`, plus your `validator`.

Selectable checks: `fieldFormat` (the field's own format rule: email, URL, phone, number, amount, percentage, OTP, or the password policy) and the password rules `passwordUppercase`, `passwordLowercase`, `passwordDigit`, `passwordSpecialCharacter`, `passwordNoWhitespace`. A special character is a visible symbol or punctuation mark; spaces, control characters, and invisible formatting characters such as a zero-width space do not count. The legacy password policies are unchanged.

Required, `minLength`/`maxLength`, value limits, and word limits are opt-in parameters and apply in every mode. Order: required, built-in rules, length, value range, word limits, password match, your validator, then async validation (still explicit; await `validateAsync()` before submitting). Async checks never run when a synchronous check fails.

```dart
SmartField.password(
  label: 'Password',
  validationMode: SmartValidationMode.selected,
  builtInChecks: const {
    SmartBuiltInCheck.passwordUppercase,
    SmartBuiltInCheck.passwordDigit,
  },
  validator: (value) => value!.contains('password') ? 'Too common' : null,
)
```

#### Legacy validation preset index

The repository preserves **14 original validation patterns** for backward compatibility. They are opt-in; ordinary text and names remain unrestricted unless configured. These legacy expressions and their metadata are shown in the relevant field sections above.

| Legacy rule | Behavior preserved | Important caveat |
|---|---|---|
| `description` | At least three regex `.` characters | A newline does not match `.` by default |
| `formfield` | At least three regex `.` characters | A newline does not match `.` by default |
| `login_username` | ASCII letters/digits, minimum five | Rejects Unicode characters |
| `beneficiary_nickname` | ASCII letters/digits, minimum three | Rejects spaces and punctuation |
| `min_text_field` | One or more ASCII letters | Does not accept accented letters |
| `street_name` | One or more ASCII letters | Not appropriate for most real-world street names |
| `alphanumeric_3` | One or more ASCII letters/digits | Its historic name suggests three, but its rule allows one |
| `email_address` | Original restricted email syntax | Narrower than modern email formats |
| `login_password_weak` | Five or more characters | Historic comment says six; pattern says five |
| `login_password` | Uppercase, lowercase, digit, special character, no whitespace, minimum eight | Historic comment and pattern disagree on length |
| `number` | Exactly one ASCII digit | Historic comment says eight digits |
| `amount_of_money` | ASCII digits and optional one/two fractional digits | Distinct from configurable modern decimal precision |
| `phone_number` | 7–15 ASCII digits | Not a universal numbering rule |
| `opt_token` | Exactly six ASCII digits | Only appropriate for six-digit OTPs |

Do not apply these patterns as automatic international validation rules. The legacy metadata snippets are shown as text because they are excerpts, not standalone JSON documents.

#### Confirm password without a new field type

Use two `SmartField.password()` fields. The second names the first field's controller:

```dart
final password = TextEditingController();
SmartField.password(label: 'Password', controller: password)
SmartField.password(
  label: 'Confirm password',
  matchController: password,
  mismatchErrorText: 'Passwords do not match.',
)
```

The confirmation is invalid when it differs from the original, including when it is empty while the original is filled. Both empty is valid unless `isRequired` is set on the confirmation. When the original changes, the confirmation revalidates only if its `autovalidateMode` is `always`, or `onUserInteraction` after the user has edited it; with the default (disabled) it does not, so call `FormState.validate()`. Passwords are never logged or stored. `SmartValidators.matches()` is the standalone helper.

#### Asynchronous validation

The supported text-input constructors accept an optional `asyncValidation:` configuration. The composite credit-card field uses its own validation and server-error APIs. The checker is your function; the package never makes network calls and cannot cancel your HTTP request. It only manages timing, state, and ignoring outdated results.

```dart
final formKey = GlobalKey<FormState>();
final usernameAsync = SmartFieldAsyncController();
SmartField.username(
  label: 'Username',
  isRequired: true,
  asyncValidation: SmartAsyncValidation(
    controller: usernameAsync,
    debounceDuration: const Duration(milliseconds: 400),
    validator: (value) async {
      final available = await usernameService.isAvailable(value);
      return available ? null : 'Username is already taken.';
    },
  ),
)
Future<void> submit() async {
  if (!formKey.currentState!.validate()) return;
  if (!await usernameAsync.validateAsync()) return;
  if (!formKey.currentState!.validate()) return;
  formKey.currentState!.save();
}
```

Create and dispose the `SmartFieldAsyncController` in your own state. Attach one controller to one field. Several async fields: `final results = await Future.wait([a.validateAsync(), b.validateAsync()]);` and submit only if all are true. Disable your submit button while submitting to prevent duplicate submissions.

`SmartAsyncValidation` options:

- `validator`: `Future<String?> Function(String raw)`; return `null` when valid or an error message.

- `trigger`: `onChanged` (default; debounced), `onUnfocus` (when focus leaves), or `manual` (only `validateAsync()`). When a rebuild changes `trigger` away from `onChanged` while a debounce is waiting, that check does not start.

- `debounceDuration`: default 400 ms; `Duration.zero` checks immediately. Each edit restarts the wait.

- `timeout`: optional; a timeout counts as unavailable.

- `unavailableErrorText`, `loadingIndicator`, `loadingSemanticsLabel`: customize messages and the suffix indicator.

- `controller`: a `SmartFieldAsyncController` exposing `status`, `errorText`, and `validateAsync({force})`.

Status values: `idle`, `pending`, `valid`, `invalid`, `unavailable`.

- Order: required, field syntax and policies, length/value rules and your synchronous `validator`, then async. The checker is never called for empty or synchronously invalid values.

- The checker receives the raw value: the address without surrounding spaces for the standard email policy (the same value `onSaved` receives), otherwise the typed text, the normalized number for `.amount()` and `.percentage()` (no grouping, currency symbol, or `%`), and the unmasked text for masked fields. Phone fields pass the entered text.

- Any edit, clear, reset, controller replacement, or disabling discards the previous result and ignores late completions. When a controller replacement or disabling discards a result whose error is on screen, that error is removed and the field is validated again for its current value, without a new asynchronous request. A parent rebuild never discards a result or restarts a check, whether the `validator` is written inline or kept in a variable: a pending check finishes with the function it started with, and a completed result is kept until the value changes or you call `validateAsync(force: true)`. `validateAsync()` returns `false` if the value changed while it ran.

- A thrown error or timeout gives `unavailable` and the unavailable message; it never counts as valid. Calling `validateAsync()` again retries. An accepted or rejected value is cached until it changes; use `force: true` to ask again.

- `FormState.validate()` stays synchronous. It fails for a rejected or unavailable result of the current value and does not wait for a pending check, so await `validateAsync()` before submitting.

- When a developer chooses to validate a password or OTP asynchronously, the value is passed to the developer-supplied checker. The package does not itself send network requests or log the value. Treat the checker as handling sensitive data.

- Local checks are a convenience: always validate again on your server.

#### Server-controlled errors

```dart
final serverError = SmartServerError();
SmartField.email(label: 'Email', serverError: serverError)
serverError.set('Email already registered');
final applied = await serverError.track(api.checkEmail(value));
serverError.clear();
```

The message uses the normal error UI and semantics on every field, makes `FormState.validate()` fail while shown, and clears on the next user edit (`SmartServerError(clearOnChange: false)` keeps it until you call `clear()`). `track()` ignores a response when a newer `track`, `set`, or `clear` happened first, and returns whether it was applied. Dispose the object in your own state.

#### Standalone validators

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

#### Password-strength feedback

```dart
SmartField.password(
  showStrengthIndicator: true,
  showStrengthChecklist: true,
  strengthCriteria: [
    SmartPasswordCriterion.minLength(10),
    SmartPasswordCriterion.digit,
    SmartPasswordCriterion('No spaces', (value) => !value.contains(' ')),
  ],
)
```

The indicator is optional, informational feedback (weak, fair, good, strong from the share of criteria met) with a polite live-region label such as `Password strength: Good`. With `showStrengthChecklist: true`, each rule is also exposed to screen readers as its own item, labelled with the rule's text and carrying a checked or not-checked state that follows the tick shown on screen; the platform reads that state in the user's language. A change of level is announced; a rule that changes without changing the level is not announced on its own and is read when the user moves to it. The password text is never part of these labels. It is separate from `policy`, `validationMode`, and validation; a password can be "strong" yet rejected by your policy and the reverse. Strength is computed locally from the field text on each change; nothing is logged, stored, or sent. `SmartPasswordStrength.evaluate()` runs without a widget.

#### Changes to an async validator

The `validator` may be written inline in `build`. The package does not compare validator functions, so a rebuild with a new closure keeps the current result and makes no request. One typed value produces one call.

```dart
SmartField.username(
  asyncValidation: SmartAsyncValidation(
    controller: usernameAsync,
    validator: (value) => api.isUsernameFree(value, tenant: tenant),
  ),
)
```

The package cannot tell from the function that your rule changed (for example `tenant` above). Tell it in one of two ways.

Declare what the rule depends on with `revalidationKey`:

```dart
SmartAsyncValidation(
  controller: usernameAsync,
  revalidationKey: tenant,
  validator: (value) => api.isUsernameFree(value, tenant: tenant),
)
```

When a rebuild supplies a key that is not equal to the previous one, the completed result and any pending check are dropped: the message is removed, the status returns to `idle`, and `validateAsync()` no longer returns the old answer. With the `onChanged` trigger one new check then starts for the current value after the debounce. With `onUnfocus` and `manual` nothing is requested until the next trigger. A rebuild with an equal key changes nothing, and the default `null` keeps the behaviour described above.

Or ask again yourself:

```dart
setState(() => tenant = next);
await usernameAsync.validateAsync(force: true);
```

`validateAsync(force: true)` always makes one new request for the current value with the validator from the latest build. It replaces a completed result and a check that is still pending; the reply of the replaced check is ignored and its `validateAsync()` future completes with `false`. Until you call it, the previous result stays in place. If you pass a different validator function instead of changing what one function reads, call `validateAsync(force: true)` after the rebuild that supplies it, for example in `WidgetsBinding.instance.addPostFrameCallback`. With the `manual` and `onUnfocus` triggers a plain `validateAsync()` returns the cached result for an unchanged value, so use `force: true` there as well.

#### Length rules and whitespace

`maxLength` counts every character, including a value made only of spaces. `minLength` and the legacy presets still treat a blank value as "not entered", which `isRequired` covers. `SmartPasswordCriterion.minLength` counts characters as users see them (grapheme clusters), the same as `SmartValidators.minLength`.

### Formatting and masks

#### Amounts and currencies

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

#### Typing a dot with another decimal separator

```dart
SmartField.amount(
  decimalPlaces: 2,
  decimalSeparator: ',',
  groupingSeparator: ' ',
  acceptDotAsDecimal: true,
)
```

`acceptDotAsDecimal` is off by default. When it is on and `decimalSeparator` is not `.`, one typed or pasted `.` is taken as the decimal separator and shown as the configured character, so `12.5` becomes `12,5`. The raw value is still `12.5`. Nothing is reinterpreted when the grouping separator is `.`, when the text already contains the decimal separator, or when it contains more than one dot. A dot that belongs to the currency symbol, as in `Rs.`, is left alone.

When a parent rebuild changes the amount settings (currency symbol or position, grouping, separators, or decimal places), text that was valid under the previous settings is shown again in the new format, and the form value follows it without calling `onChanged`. Decimal places are only removed when they are zeros; `12.55` is never cut to fit `decimalPlaces: 0` and is reported by validation instead.

#### Displayed and raw amount values

- The controller, `onChanged`, custom `validator`, and `onSaved` preserve Flutter's display-text behavior. `onSaved` therefore receives the text shown at that moment: ungrouped while the field has focus (`1234.5`) and formatted after focus leaves (`$1,234.50`). Use `onRawSaved` for a value that does not depend on focus.

- While focused, the display text is ungrouped and has no configured currency text.

- When focus leaves, configured grouping, decimal padding, and currency text are displayed.

- Switching between these two forms on load, focus, and focus loss is not reported as a change: `Form.onChanged` is not called and `AutovalidateMode.onUserInteraction` shows no error until the user edits. A change you make to your own controller is still reported once, as Flutter does.

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

```text
"amount_of_money": {
  "expression": "^\\\d+(\\\\.\\\d{1,2})?$",
  "comment": "Please enter a valid amount (e.g., 123.45)",
  "error_lbl": ""
}
```

The legacy policy remains opt-in. The standard policy follows the configured precision instead of forcing one or two decimal places.

For number and amount fields, validation runs in this order: required, field syntax or selected legacy policy, configured length rules, minimum value, maximum value, then the custom validator. The first error is displayed.

#### Percentages

`SmartField.percentage()` is a single-line decimal input with a visual `%` suffix. The suffix is not part of the controller text, `onChanged`, `onSaved`, or validator values.

```dart
SmartField.percentage(label: 'Growth rate', hintText: 'Enter percentage')
SmartField.percentage(
  label: 'Progress',
  isRequired: true,
  minValue: '0',
  maxValue: '100',
  decimalPlaces: 2,
  allowNegative: false,
)
```

- The raw value is in percent points: `12.5%` is the string `'12.5'`, not `0.125`. The package never multiplies or divides by 100.

- By default the field is optional and accepts `0`, `12.5`, `100`, `250`, and `-5`. There is no default range, decimal limit, or length limit.

- Typed text is preserved exactly: `12.50` stays `12.50` and no `.00` is appended.

- Input accepts ASCII digits, one `.`, and a leading `-` (disabled by `allowNegative: false`). Letters, spaces, exponent notation, and pasted `%` are rejected rather than stripped.

- Partial states such as `-`, `.`, `-.5`, and `12.` are editable but fail validation.

- `decimalPlaces`, when set, limits fractional digits at input and in validation; values are never rounded.

- `minValue` and `maxValue` are exact decimal strings in percent points.

- `percentSymbol` customizes the suffix; a `suffix` or `suffixText` in `decoration` takes precedence.

- Validation order: required, percentage syntax, configured length, minimum, maximum, custom validator.

Whether a value such as `250%` is acceptable is an application business rule.

#### Optional text formatters

All formatters are optional.

- `SmartField.name(capitalizeWords: true)`.

- `SmartField.username(usernameCase: SmartTextCase.lowercase, allowedCharacters: SmartUsernameCharacters.usernameSafe)`. Disallowed edits are rejected rather than stripped. The same rule is checked by validation, so a value set through the controller, pasted, or committed by a keyboard composition that breaks `allowedCharacters` fails with `Use only the allowed characters.`

- `SmartField.text()` / `.description()`: `textCase` (`capitalizeFirstLetter`, `capitalizeWords`, `capitalizeSentences`, `lowercase`, `uppercase`) and `collapseWhitespace`.

- Email, password, OTP, phone, URL, amount, and number have no case or whitespace formatters, so case-sensitive and secret values are never rewritten.

The same classes (`SmartTextCaseFormatter`, `SmartUsernameFormatter`, `SmartWhitespaceFormatter`) work as ordinary `inputFormatters`. They keep the caret, ignore active IME composition, and map selections across edits.

#### Decimal precision, rounding, and grouping

```dart
SmartField.amount(
  label: 'Amount',
  useGrouping: true,
  decimalLength: 2,
  rounding: SmartRoundingMode.halfUp,
  groupingStyle: SmartGroupingStyle.indian,
)
```

- `decimalLength` accepts exactly `false`, `1`, `2`, or `3`; anything else throws `ArgumentError`. With grouping, `1500` shows `1,500`, `1,500.0`, `1,500.00`, or `1,500.000` after editing. `false` allows no decimal digits.

- `decimalPlaces` still works for any digit count. If both are given they must agree, otherwise `ArgumentError`. `decimalLength` has no effect on the formatter when omitted.

- Rounding is off by default: with `SmartRoundingMode.none`, extra digits are rejected while typing, never rounded. `halfUp`, `halfEven`, `down` (toward zero), and `up` (away from zero) round exactly with decimal-string arithmetic, only when editing finishes and for `onRawSaved`/validation; while typing, `onRawChanged` shows the unrounded value.

- `groupingStyle: SmartGroupingStyle.indian` groups as `1,23,45,678`. Grouping separators and decimal separators remain configurable.

- `SmartDecimalUtils.round()`, `SmartDecimalLength.from()`, and `SmartAmountFormatter` work without a widget.

#### Pattern input masks

`SmartField.text(inputMask: '####-####')` formats typed text with a pattern: `#` digit, `A` letter, `*` letter or digit, `\\` escapes a literal, anything else is a literal. The controller and `onSaved` keep the formatted text; `onRawChanged` and `onRawSaved` receive only the entered characters (`12345678`). An incomplete value fails validation (`inputMaskErrorText`); an empty value is valid unless required. Typing, deletion (including over a separator), paste of raw or formatted text, selections, and the caret are handled; invalid characters reject the edit. `SmartInputMask` and `SmartMaskFormatter` work without a widget.

Pattern formatting is not privacy masking: it never hides characters. Use `mask: true` (and the `mask*` utilities) for visual privacy. No country rule is applied unless you write one into the pattern.

#### Visual privacy masking

`SmartField.phone()`, `SmartField.number()`, and `SmartField.amount()` support opt-in visual masking. Masking is disabled by default and does not change validation or formatting rules.

The masked text is drawn in the space the field's text normally uses, between any prefix and suffix icons, and follows the field's `style` and disabled colour. When it is wider than that space it is drawn smaller, down to 60% of its size. If it still does not fit, its start is cut off so the visible last digits stay on screen. A developer `prefix` widget or `prefixText` is kept and shown before it.

```dart
SmartField.phone(
  label: 'Phone number',
  mask: true,
)
SmartField.number(
  label: 'Identifier',
  mask: true,
  maskVisibleSuffixDigits: 4,
  maskCharacter: '•',
)
SmartField.amount(
  label: 'Amount',
  decimalPlaces: 2,
  useGrouping: true,
  mask: true,
)
```

An enabled editable masked field displays its masked value while unfocused and reveals its unmasked value when deliberately focused. It returns to the masked display when focus leaves. Read-only and disabled fields remain masked. Set `revealMaskOnFocus: false` to keep the presentation masked while focused; that state is read-only until the application changes its configuration.

`maskVisibleSuffixDigits` defaults to four for phone and number fields and zero for amounts. `maskCharacter` must contain exactly one Unicode grapheme. Negative suffix counts and empty or multi-grapheme mask characters throw `ArgumentError`. The controller, selection, validation, `onChanged`, `onSaved`, phone parsing, amount display formatting, `onRawChanged`, and `onRawSaved` never receive mask characters. Masked mode disables interactive selection. While the value is concealed, the text field is reported to assistive technology as an obscured field, the same way a password is, and a separate node carries the masked text, so a screen reader announces `******2671` and never the raw value. The field keeps its label, focus, and tap action; focusing a field with `revealMaskOnFocus` reveals and announces the real text. A masked amount field keeps its currency symbol in the masked text.

The independent utilities return masked copies and never mutate their input:

```dart
final phone = maskMobile('03001234567');
final account = maskAccountNumber('000012345678');
final amount = maskAmount('12,345.67 PKR');
final formatted = formatNumber(
  '50000.00',
  decimalPlaces: 2,
  useGrouping: true,
);
```

These values are `*****4567`, `******5678`, `**,***.** PKR`, and `50,000.00`. `formatNumber` is a convenience wrapper around `SmartAmountFormatter`; it does not use binary `double` arithmetic or repair malformed text such as `5,000.oo`.

`maskMobile` treats ASCII `0`–`9` as revealable phone digits, preserves `+`, whitespace, hyphens, and parentheses, and masks every other grapheme so unexpected letters or non-ASCII digits are not disclosed. `maskAccountNumber` treats every non-separator grapheme, including letters and Unicode clusters, as sensitive and preserves spaces and hyphens by default. Both utilities mask all sensitive content in one-to-four-character short values unless `revealShortValues: true` is explicitly selected.

`maskAmount` accepts a structurally valid ASCII-digit amount display, preserves its sign, grouping, decimal separator, whitespace, and one-sided currency text, and masks all digits by default. A leading minus sign may come before the currency text, as in `-$1,234.50`. When `visibleSuffixDigits` is equal to or greater than the number of digits, every digit is masked, as `maskMobile` and `maskAccountNumber` do for short values; `maskAmount('12.50', visibleSuffixDigits: 4)` is `**.**`. Digits from other scripts are never passed through: a value that contains one throws `FormatException`. Custom separators, a visible trailing-digit count, a one-grapheme mask, and an explicitly positioned `currencySymbol` are optional. Malformed numeric displays throw `FormatException` rather than being sanitized into a valid amount.

Masking is a presentation-level privacy aid, not encryption, secure storage, log redaction, authorization, account verification, or backend protection. The owning application retains the raw value and remains responsible for access control, storage, logging, clipboard policy, and server-side security.

#### Word-count and word limits

`SmartField.description()` and `SmartField.text()` accept `minWords`, `maxWords`, `showWordCount`, `minWordsErrorText`, and `maxWordsErrorText`. A word is any run of non-whitespace characters, so newlines, Unicode spaces, other scripts, and emoji are handled. The counter reads `12 / 200 words` (or `12 words` without a maximum). Word limits are separate from `minLength`/`maxLength` and never block typing.

#### State restoration

Pass `restorationId` (inside a `RestorationScope`, for example `MaterialApp.restorationScopeId`) to restore a field's text. Limitations: restoration works only for fields without a developer controller and without a package-owned controller, so `.amount()`, `.phone()`, `.search()`, and masked fields are not restored; use your own `RestorableTextEditingController` for those. `.password()` and `.otp()` ignore `restorationId` and are never restored.

#### Reusable formatting and validation utilities

`SmartValidators` (including `passwordRules`, `matches`, `minWords`, `maxWords`, `url`, `phone`), `SmartUrlValidation`, `SmartPhoneValidation`, `SmartTextUtils` (`countWords`, case helpers, `collapseWhitespace`), `SmartAmountFormatter`, `SmartDecimalUtils`, `maskMobile`, `maskAccountNumber`, `maskAmount`, and `formatNumber` call the same code as the widgets.

#### Saved raw amounts

`onRawSaved` on an amount field returns the same normalised text whether or not the field has focus. With `decimalPlaces: 2`, typing `50000` saves `50000.00` in both states. Without fixed decimals the typed digits are kept (`12.5` saves `12.5`). `onSaved` and a custom `validator` still receive the text currently shown in the field.

### Phone numbers

#### Phone numbers and country handling

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

The controller, `onChanged`, custom validator, and `onSaved` always use the exact text in the phone field. Selecting a country never inserts a prefix or rewrites that text. `SmartPhoneValue` separately exposes the selected country, parsed national number, and E.164 value. Its `e164` is `null` when input is invalid or cannot be parsed safely. Shared dialing codes do not cause an arbitrary country selection. When a country is selected and a contact's number belongs to another allowed country, including one that shares its dialing code (a Canadian `+1` number with the United States selected, or a `+44` number with any other country selected), the number is accepted and the country picker moves to the country the phone parser reports. Without a selected country nothing is guessed. A country outside `allowedCountryCodes` is still refused.

Under `SmartPhonePolicy.auto`, a number typed without a selected country and without a `+` prefix is checked for syntax only. The form can then be valid while `SmartPhoneValue.isValid` is `false` and `e164` is `null`, because no country is known to parse it against. Read `e164` only when it is not `null`.

Phone policies are:

- `SmartPhonePolicy.auto`, the default, validates against the selected country's numbering rules; without a selected country it validates `+` international numbers using the country inferred by the phone parser; without a country or `+` prefix it falls back to syntax-only validation.

- `SmartPhonePolicy.syntaxOnly` validates conventional phone characters without a country length rule.

- `SmartPhonePolicy.countryAware` requires selected country context and validates against that country's metadata.

- `SmartPhonePolicy.legacy` applies the original ASCII-digit rule to the field text exactly.

Validation order is required, selected phone policy, configured length rules, then the custom validator. Empty values remain valid unless `isRequired` is enabled. Metadata validation checks plausible structure, not whether a number exists, is owned, or can receive calls or messages.

Original legacy preset:

```text
"phone_number": {
  "expression": "^[0-9]{7,15}$",
  "comment": "7 to 15 digits",
  "error_lbl": "lbl_phone_8"
}
```

The contact button is shown only on Android and iOS. It opens the operating system's native one-number picker and does not request broad contact-list access, enumerate the address book, upload data, or contact a server. Cancellation leaves the field unchanged. Other failures use `onContactPickerError` when supplied or accessible `SnackBar` feedback. Adding the option does not make the native dependency optional at install time. The native picker comes from `flutter_native_contact_picker` 0.0.13, which requires iOS 13 or later; the example targets iOS 15. The plugin's code is loaded only where `dart:io` exists and is called only on Android and iOS. On web, Windows, Linux and macOS the contact button is not shown, and a `contactPicker` callback you supply still works everywhere.

Country names work in English without extra setup. Apps that need translated country names can add `CountryLocalizations.delegate` from `country_picker` to their `MaterialApp` localization delegates.

Phone support uses [`country_picker` 2.0.28](https://pub.dev/packages/country_picker), [`phone_numbers_parser` 9.0.29](https://pub.dev/packages/phone_numbers_parser), and [`flutter_native_contact_picker` 0.0.13](https://pub.dev/packages/flutter_native_contact_picker). The first two use the MIT license and the native picker uses BSD-3-Clause. Their notices are retained in `THIRD_PARTY_NOTICES.md`.

#### Separators in phone numbers

Before validation and parsing, non-breaking spaces and dots are treated as spaces, and invisible direction marks are ignored. `(415)<non-breaking space>555-2671` and `415.555.2671` validate like `(415) 555-2671`. Digits are never changed and the country check still applies. The text in the field is not rewritten, and `SmartPhoneValue.text` holds it as entered. Extensions such as `x12` are not supported. `SmartPhonePolicy.legacy` is unchanged.

### Cards and dates

#### Credit-card input and local checks

`SmartField.creditCard()` is a composite of card number, expiry, and security code built from the shared fields. All checks run locally and instantly; the package makes no network request. A passing check means the entered text is internally consistent. It does **not** mean the card exists, is active, has funds, or will be approved, and no message claims otherwise.

```dart
SmartField.creditCard(
  isRequired: true,
  acceptedBrands: const {SmartCardBrand.visa, SmartCardBrand.mastercard},
  expiryFormat: SmartExpiryFormat.mmYy,
  onChanged: (card) {
    final brand = card.brand;
    final status = card.numberStatus;
    final last4 = card.last4;
  },
  onSaved: (card) {},
)
```

- **One engine, offline.** Brand detection, lengths, grouping, the checksum, and the security-code size all come from one table in `SmartCardUtils`. It is pure Dart, makes no network request, reads no file, and gives the same result for the same text on Android, iOS, web, and desktop, however fast the text was typed or pasted. The table cannot be replaced or extended by the application.

- **Brands** (prefix ranges, lengths, grouping, and security codes follow Braintree `credit-card-type` 10.3.1, compared again on 2026-11-12):

  | Brand | Number lengths | Grouping | Security code |
  |---|---|---|---|
  | Visa | 16, 18, 19 | 4-4-4-4, then fours | CVV, 3 digits |
  | Mastercard (51-55, 2221-2720) | 16 | 4-4-4-4 | CVC, 3 |
  | American Express (34, 37) | 15 | 4-6-5 | CID, 4 |
  | Diners Club | 14, 16, 19 | 4-6-4 | CVV, 3 |
  | Discover | 16 to 19 | 4-4-4-4, then fours | CID, 3 |
  | JCB | 16 to 19 | 4-4-4-4, then fours | CVV, 3 |
  | UnionPay | 14 to 19 | 4-4-4-4, then fours | CVN, 3 |
  | Maestro | 12 to 19 | 4-4-4-4, then fours | CVC, 3 |
  | Mir | 16 to 19 | 4-4-4-4, then fours | CVP2, 3 |
  | Troy, Elo, Hiper, Hipercard, Naranja | 16 | 4-4-4-4 | CVV, CVE, CVC, CVC, CVV; 3 |
  | Verve | 16, 18, 19 | 4-4-4-4, then fours | CVV, 3 |
  | Unknown brand | 12 to 19 | 4-4-4-4, then fours | 3 or 4 |

  The same data is on `SmartCardBrand` (`lengths`, `gaps`, `cvvLength`, `securityCodeName`). Discover accepts 17 and 18 digits here; the Braintree table lists only 16 and 19. The legacy 13-digit Visa format is not accepted. **RuPay is not supported:** the only source found lists very broad prefixes (60, 65, 81, 82, 508) that overlap Discover, UnionPay, and Maestro, so those numbers are handled as the matching brand or as unknown. Detection says nothing about the issuing bank, or about credit versus debit.

- **Detection has three states.** `SmartCardUtils.matchBrand(text).detection` is `identified`, `ambiguous`, or `unknown`. A brand is identified as soon as the typed digits rule out every other brand, which can take one digit or six: `41` is Visa, `34` is American Express, but `4` could still be Visa, Elo, or Naranja, and `4011` is settled only at the sixth digit (`401178` is Elo, `401170` is Visa). While the prefix is ambiguous the brand is `unknown`, `candidates` lists the possible brands, and `likelyBrand` holds the best match so far. The most specific range wins (Troy over Discover `65`, Verve and Elo over Maestro). A prefix that matches no brand is `unknown` and is checked as a generic 12 to 19 digit card.

- **Number status.** `SmartCardUtils.assessNumber()` and `SmartCreditCardValue.numberStatus` report one of four states on every keystroke, paste, programmatic change, clear, and reset:

  | Status | Meaning |
  |---|---|
  | `empty` | No text |
  | `incomplete` | More digits can still make the number valid. Shown as neutral guidance (`Visa · 8 more digits`), never as an error |
  | `valid` | The length is one the brand allows and the checksum passes. `canBeLonger` says whether the brand also has a longer length |
  | `invalid` | The number cannot become valid: a character other than a digit, space, or hyphen; too many digits; no accepted brand can match; or the checksum fails at the brand's longest length |

  A checksum that fails at a shorter length the brand allows is `incomplete` with `issue: failsChecksum`, because more digits may follow. A 16-digit Visa number with a wrong digit therefore shows `Visa · Check the number or enter 2 more digits` while typing, and `Check the card number.` when the form is validated. A Mastercard or American Express number has one length, so its checksum error appears at once. `FormState.validate()` always requires a `valid` number. With `acceptedBrands`, the brand error appears as soon as none of the possible brands is accepted. `numberStatusBuilder` customizes the guidance text, and `showNumberStatus: false` hides it.

- **Luhn** applies to every brand except UnionPay. UnionPay is exempt because its numbers are not required to pass the checksum (Braintree `card-validator` 10.0.4 skips it for UnionPay unless asked, compared on 2026-11-12); its length and prefix are still checked. A number made only of zeros is invalid. The checksum, the brand number lengths and the security-code lengths are fixed rules and cannot be turned off or replaced; `acceptedBrands` is the only way to narrow what a field accepts.

- **Grouping** follows the brand: `4111 1111 1111 1111`, `3782 822463 10005`, Diners `3056 930902 5904`, and a 19-digit number as `4-4-4-4-3`. Pasted spaces and hyphens are accepted and regrouped. Letters and other characters are rejected, and so is an edit that would exceed the brand's longest length; the text is never shortened and digits are never changed.

- **Moving to the expiry.** With `autoAdvance` (on by default), focus moves from the number to the expiry only when the brand is identified, the number is valid, and the brand has no longer length:

  | Number | Result |
  |---|---|
  | Valid 16-digit Mastercard, valid 15-digit American Express | Moves to the expiry |
  | Valid 16-digit or 18-digit Visa | Stays, because a 19-digit Visa number is possible. Press Next or Tab, or tap the expiry |
  | Valid 19-digit Visa | Moves to the expiry |
  | UnionPay, Discover, JCB, Maestro, Mir, Diners Club, Verve | Moves only at 19 digits |
  | Wrong checksum, unknown brand | Never moves |

  Typing and pasting follow the same rule. Focus never returns to the number by itself, and a rebuild or a replaced controller does not move it. `autoAdvance: false` turns the behavior off; it cannot be set per brand.

- **Expiry:** `MM/YY` or `MM/YYYY`; months 01-12; valid through the last moment of the expiry month (leap years, December to January included); two-digit years mean 2000-2099. Pass `now:` for deterministic tests.

- **Security code:** 4 digits for American Express and 3 for the other brands. Once the brand is identified its code name (`CVC`, `CID`, `CVV`, `CVN`, `CVE`, `CVP2`) is shown as the hint of the security-code field unless you pass `cvvHint`; the label stays `cvvLabel`. Changing the number to a brand with a different code length re-checks an already entered code immediately. It is concealed by default (`concealCvv: true`). Local checks cannot confirm the code with the bank.

- Server messages: `numberServerError`, `expiryServerError`, `cvvServerError` take priority and clear on edit.

- **Security:** card data is never persisted, restored (`restorationId` is not used), logged, or sent. `SmartCreditCardValue`, assessments, and package-owned controllers print redacted text. An application-supplied controller or other application code can still expose sensitive values in its own diagnostics. `onChanged`/`onSaved` hand the full values to your code: treat them as sensitive and never log them. Platform autofill hints are set, so the platform can fill the three inputs. When the card field is removed it tells the platform not to save what was typed (`AutofillContextAction.cancel`); the effect of this on a real device's "save card" prompt has not been verified. **SmartField does not make an app PCI compliant,** and a number that passes these checks is not proof that a card exists, is active, or will be authorized. Authorization must be done by a payment provider. For real payments use processor-hosted or tokenized fields, never store security codes after authorization, and use only synthetic test cards (such as `4111 1111 1111 1111`) in tests and demos.

#### Dates, times, and date-times

One API with four date modes:

```dart
SmartField.date(label: 'Birth date', restriction: SmartDateRestriction.pastOnly)
SmartField.date(mode: SmartDateMode.calendar, minDate: DateTime(2024), maxDate: DateTime(2030))
SmartField.date(mode: SmartDateMode.dropdowns, firstYear: 1950, lastYear: 2035)
SmartField.date(mode: SmartDateMode.wheel, dateFormat: 'yyyy-MM-dd')
SmartField.time(mode: SmartTimeMode.picker, use24Hour: false)
SmartField.dateTime(mode: SmartTimeMode.picker, restriction: SmartDateRestriction.futureOnly)
```

- Modes: `manual` (masked typing), `calendar` (themed Material dialog), `dropdowns` (day, month, year; days follow the month and leap years), `wheel` (scrolling day, month, year in a bottom sheet). Time: `manual`, `picker` (Material clock), `wheel`. Date-time: `manual` or `picker` (date, then time).

- Formats use `dd`, `MM`, `yyyy` once each with any separators (`dd/MM/yyyy`, `MM/dd/yyyy`, `yyyy-MM-dd`). Time is `HH:mm` or, with `use24Hour: false`, `hh:mm AM/PM`. No `intl` dependency; for localization pass `monthNames` and use the app's Material locale for the calendar and clock dialogs.

- Rules: `minDate`, `maxDate` (inclusive), `restriction` (`pastOnly` means before today, `futureOnly` means after today, both relative to `now()` and counted in calendar days, so a daylight-saving change does not move the limit), `minTime`/`maxTime`, `isRequired`, your `validator`, `serverError`, `asyncValidation`, `initialDate`/`initialTime`, `showClearButton`, and `FormState.reset`. Impossible dates such as 30 February are invalid. `minDateTime` is compared to the minute, because the field has no seconds: a limit of 10:30:45 accepts 10:30. `firstYear` must not be after `lastYear`; this is asserted in debug builds, and a reversed pair is put in order in release builds. Calendar and wheel pickers default to 1900 to 2100 when no bounds are set. In wheel mode, when `minDate`, `maxDate`, or `restriction` is set and the wheels stop on a date outside that range, they roll back to the nearest allowed date, and the confirm button is disabled while the selection is out of range, so the wheel never returns a date outside the range. In dropdown mode a stored date outside the selectable years is still shown and is never replaced; `minDate`, `maxDate`, and `restriction` report it, and a date outside an explicit `firstYear`/`lastYear` range fails with the invalid-date message. `FormState.reset` returns a dropdown field to the date it had when it was first shown (the controller text or `initialDate`), and `save` then returns that same value. A picker result is discarded if the field was disabled, made read-only, given another controller, or removed while the picker was open. Calendar, wheel, and clock picker modes run `asyncValidation` automatically after a selection unless the field is disabled or `readOnly`.

- Values: `onDateChanged`, `onTimeChanged`, `onDateTimeChanged` give `DateTime?`/`TimeOfDay?`. Dates are local calendar dates (midnight), so there are no timezone shifts. `onRawChanged`, `onRawSaved`, and async validators receive ISO text: `yyyy-MM-dd`, `HH:mm`, or `yyyy-MM-ddTHH:mm` without an offset. `SmartDateUtils` provides the same helpers. `onChanged` and `onSaved` carry the displayed text. In dropdown mode an external `controller` holds the same display text as the dropdowns and stays in sync with them. `showClearButton` also works in dropdown mode: the button empties all three parts, the controller, and the form value, and calls `onChanged('')` and `onDateChanged(null)`.

- Limits: date-time values are minute precision and timezone-naive; daylight-saving gaps and overlaps are not adjusted, and the app owns timezone conversion. Cancelling a picker leaves the value unchanged. Programmatic controller changes do not fire typed callbacks.

#### Card decoration, labels, and zero numbers

- The `decoration` passed to `SmartField.creditCard` applies in full to the card-number field. The expiry and security-code fields take its borders, padding, fill, and text styles, but not its label, hint, helper, prefix, suffix, or icons.
- The security-code visibility toggle is labelled `Show security code` / `Hide security code`. Change it with `showCvvLabel` and `hideCvvLabel`.
- A number made only of zeros is invalid and reports the checksum message. Brand rules and the UnionPay Luhn exemption are unchanged.

#### Raw date values when a date is removed

`onRawChanged` is called with an empty string when a date, time, or date-time that was valid is cleared or edited into an incomplete value. It is not called again until the value becomes valid.

### Customization and localization

#### Theme and design

All fields except `SmartField.otp()` (which draws its own boxes through `SmartOtpStyle`) share one design resolver. Priority is the field's own `decoration`, then the app's `InputDecorationTheme`, then the package fallback:

- Outline border, 12px radius, 1px normal border, 2px focused and error borders.

- 16px horizontal and 12px vertical content padding.

- Colors from the app `ColorScheme` (`outline`, `primary`, `error`, and a faint `onSurface` for disabled), so light, dark, and custom themes apply.

If the field's `decoration` or the app theme sets any border property, no fallback borders are added; if either sets `contentPadding` (or `isCollapsed`), the fallback padding is not added. Focus styling follows the field's real focus. Fixed heights are never applied, so multiline, large text, error text, and RTL layouts can grow.

#### Right-to-left layouts

Labels, icons, alignment, and error text follow the ambient `Directionality`. Content made of digits is always drawn left to right so it reads in the order it was typed: number, amount, percentage, phone, card number, expiry, security code, date, time, and date-time text, the phone dial code, masked previews, and the OTP boxes. In a right-to-left layout that text is right-aligned inside the field. Plain text, name, email, username, description, URL, and search fields keep Flutter's default direction handling.

#### Accessible actions

The password visibility toggle and the search clear button expose a tap action to assistive technology in addition to their labels. The OTP label, the country button, and the date dropdowns are announced once. Date dropdowns are 48 logical pixels high. A long press on the OTP boxes opens a Paste menu, and `Ctrl`/`Cmd`+`V` keeps working on desktop and web. These behaviours are covered by semantics-tree tests; checks with TalkBack and VoiceOver on real devices are still required.

#### Label and message overrides

The package ships English defaults and has no translation system. Pass your own text through these parameters:

| Where | Parameters |
|---|---|
| Every field | `label`, `hintText`, `requiredErrorText`, `minLengthErrorText`, `maxLengthErrorText`, and any text in `decoration` |
| Field-specific errors | `emailErrorText`, `urlErrorText`, `passwordErrorText`, `mismatchErrorText`, `numberErrorText`, `amountErrorText`, `percentageErrorText`, `phoneErrorText`, `minValueErrorText`, `maxValueErrorText`, `inputMaskErrorText`, `minWordsErrorText`, `maxWordsErrorText`, `validationPresetErrorText` |
| Password | `showPasswordLabel`, `hidePasswordLabel`, `strengthTitle`, `strengthLabels`, `strengthCriteria` (each criterion carries its own label), and for `SmartValidationMode.selected`: `uppercaseErrorText`, `lowercaseErrorText`, `digitErrorText`, `specialCharacterErrorText`, `noWhitespaceErrorText` |
| Text and description | `wordCountBuilder` for the word counter |
| Username | `allowedCharactersErrorText` |
| Search | `clearLabel`, `loadingLabel` |
| Phone | `selectCountryLabel`, `changeCountryLabelBuilder`, `contactPickerLabel`, `clearLabel`, `countrySearchHint`, and `contactPickerMessageBuilder` for the picker messages, and `onContactPickerError` to present them yourself |
| OTP | `digitErrorText`, `otpLengthErrorText`, `legacyErrorText`, `errorText` |
| Dates and times | `invalidErrorText`, `incompleteErrorText`, `minErrorText`, `maxErrorText`, `pastErrorText`, `futureErrorText`, `clearLabel`, `pickerLabel`, `dayLabel`, `monthLabel`, `yearLabel`, `hourLabel`, `minuteLabel`, `periodLabel`, `monthNames` |
| Credit card | `numberLabel`, `expiryLabel`, `cvvLabel`, `showCvvLabel`, `hideCvvLabel`, the hint and error texts, and `numberStatusBuilder` |
| Async validation | `unavailableErrorText`, `loadingSemanticsLabel` |

The strings in this table have overrides, and the English defaults are unchanged. The `AM` and `PM` markers of 12-hour time text and of the time wheel are set with `amLabel` and `pmLabel` on `SmartField.time` and `SmartField.dateTime`. In manual (typed) mode both labels must consist of letters only and have the same length, because the typing mask has a fixed number of slots; the picker and wheel modes accept any text.

- The OTP Paste menu and the wheel-picker buttons use Flutter's `MaterialLocalizations`, so they follow your app's locale.

### Security and privacy

**This is a client-side input library, not a security framework.** Keep these responsibilities separate:

| Feature | The package helps with | Your application must still do |
|---|---|---|
| Passwords | Hide input, optional policies and strength hints | Secure authentication, hashing on the server, rate limiting, safe secret handling |
| OTP | Visual entry, validation, completion callback | Generate and verify codes on the server, expiration and retry controls |
| Credit cards | Brand/length/checksum, expiry, security-code format | Use a compliant payment processor and approved tokenization/hosted fields; never store CVV after authorization |
| Email/phone | Format or plausible number checks | Verify ownership, existence, and authorization |
| URL | Syntax checks only | Defend against malicious links and server-side URL fetching attacks such as SSRF |
| Masks | Hide portions of the display | Encrypt, authorize, store securely and avoid leaking values into logs or analytics |
| Async validation | Call your supplied checker at the right time, reject stale responses | Protect API endpoints and treat all remote results as untrusted |

**Card-checking details:** Luhn is a local checksum and does not authenticate a card. UnionPay is the only brand exempt from Luhn, and the checksum and length rules cannot be disabled. Card checks run offline in pure Dart; only a payment provider can authorize a card. Unknown brands and co-branded prefixes are handled cautiously. RuPay is not explicitly supported in the reported card-brand table. Actual card details must never be used as tests.

**Debugging:** The package reported redaction for its own card-related diagnostics. Application-owned controllers, error reporting, analytics, crash dumps, and custom callbacks can still leak values if an application logs them. Avoid printing values from `onChanged`, `onSaved`, or async validators for secret fields.

**Contacts and SMS:** The package does not request SMS permissions and does not read messages. Its optional native contact picker is not a bulk address-book reader; actual operating-system behavior should still be verified on target devices.

**Backends:** Use server-side validation, authorization, prepared/parameterized SQL statements, safe output encoding, rate limiting, and secure transport as required by your application. Filtering a text field is not SQL injection or XSS protection.

### Platform notes

#### Platform behavior and limitations

Most field controls use Flutter's Material widgets. Some features depend on mobile platform APIs, keyboard behavior or accessibility services.

| Area | Current behavior or limitation |
|---|---|
| Flutter and Dart versions | Requires Flutter 3.47.0 or later and Dart 3.13.0 or later, the first release with the standalone `material_ui` package. Analysis, all package tests, the example tests, and the example web build are run on the minimum (3.47.0), on 3.47.8, and on the latest stable Flutter in CI |
| Flutter web and WebAssembly | The package compiles for web and WebAssembly (`flutter build web --wasm` in CI); the contact-picker plugin is not part of the web build. The package test suite runs on Chrome (1,212 tests pass; 53 are skipped there, each with a stated reason: 40 need the native contact picker, which is not offered on web, 11 read project files through `dart:io`, and 2 send native undo key events that the browser handles itself). The example web build passes. On web, Flutter selects all text when a field gains focus programmatically, and the browser owns the undo shortcut |
| iOS | The example integration tests (card entry, amount formatting, RTL digit order, calendar and country pickers, dropdown dates, password toggle, masking) pass on an iPhone 17 simulator. The native contact picker, the system keyboard, SMS code autofill, and VoiceOver were not exercised |
| Android | The same integration tests pass on an Android API 36 emulator. The merged example manifest declares no contacts permission. The integration tests also pass on a physical Android 14 phone. Third-party keyboards, SMS code autofill, and TalkBack were not exercised |
| macOS | The example builds and the integration tests pass on macOS desktop with `flutter test integration_test -d macos`. Run them from an interactive desktop session; in an unattended session the run has sometimes stalled before the first test. The contact button is not shown on desktop |
| Windows and Linux | Declared in `pubspec.yaml`. The package analysis and tests run on hosted GitHub Actions Windows and Linux runners, and the example is built for both there. No Windows or Linux app was driven by hand. The contact button is not shown, and the native picker plugin is never called |
| Keyboards that compose text (IME) | Text is not changed while the keyboard is still composing. When the composed text is committed and the field's input rule rejects it, the field returns to the text it held before that composition, with the caret where the composition began. This is covered by simulated composition tests; hardware and third-party keyboards were not tested |
| Digits | By default number, amount, percentage, OTP, card, date, and time fields accept ASCII digits `0`-`9` only: Arabic-Indic (`١٢٣`), Persian (`۱۲۳`), and fullwidth digits are not entered and no message is shown, and a phone field keeps them and reports the number as invalid. Set `normalizeDigits: true` on those fields, or on a phone field, to replace these three digit sets with ASCII digits as they are typed or pasted, before any rule runs. Other numerals, and the Arabic decimal and thousands separators, are not converted. Text set through a controller is not rewritten |
| Decimal separator | With `decimalSeparator: ','` the comma is the only decimal key by default; a typed `.` is not treated as the decimal, so a keypad that offers only `.` cannot enter the decimal part. Set `acceptDotAsDecimal: true` on `SmartField.amount` to accept one typed `.` as the decimal. It has no effect when the grouping separator is `.` |
| 12-hour time | The markers default to `AM` and `PM`. Set `amLabel` and `pmLabel` on `SmartField.time` and `SmartField.dateTime` to change them. The Material clock dialog takes its own text from the app's locale |
| Narrow layouts and large text | When a phone field's flag and dial code would take more than half of the space available to them, they are drawn smaller instead of overflowing. The masked text of a masked phone, number, or amount field is drawn smaller, down to 60% of its size, when it would not fit between the field's icons; beyond that its start is cut off and its last digits stay visible. Date dropdowns are drawn smaller together when the field is too narrow for the three controls (about 210 px at normal text size with a clear button). No control is hidden; where the dropdowns are scaled their touch areas are smaller than 48 px |
| Contact picker | Uses the system picker only. Android starts `Intent.ACTION_PICK` and iOS shows `CNContactPickerViewController`; neither needs a contacts permission or an `Info.plist` entry in your app. Plugin manifest and sources checked at 0.0.13. Picking a contact and cancelling the picker were checked on a physical Android 14 phone; it was not exercised on a physical iPhone |
| OTP autofill | Keyboard/platform hints may assist autofill; this package does not itself read SMS or WhatsApp |
| Date-time | Local/timezone-naive date-time at minute precision; the consuming app owns timezone conversion and DST policy |
| State restoration | Password and OTP are intentionally excluded; fields with owned or app-supplied controllers have documented limits |
| RuPay | No specific RuPay card-brand mapping has been claimed; uncertain prefixes remain unknown or match other supported brands |
| Luhn exceptions | UnionPay is the only exempt brand; not configurable |
| Card auto-advance | Only at the identified brand's longest valid length; a 16-digit Visa number waits for Next or Tab |
| Date-time picker modes | `dateTime()` supports manual and picker, not a date-time wheel mode |
| Accessibility | RTL and text scaling are designed into the UI, but full TalkBack/VoiceOver platform checks are still required |

**Do not interpret this table as a certification that every platform has been tested.** Check the latest release notes and platform test matrix before depending on a device-specific behavior.

#### Troubleshooting

| Symptom | What to check |
|---|---|
| Validation doesn't reject an empty value | Empty is optional by default; add `isRequired: true` |
| An email or URL is valid locally but cannot be used | Syntax validation cannot verify inbox/site existence or safety |
| `FormState.validate()` finishes before async validation | Await each `SmartFieldAsyncController.validateAsync()` in your submit workflow |
| Currency or percentage symbols appear in callback text | Understand the displayed `onChanged` versus `onRawChanged` contract for that field |
| Money has too many fractional digits | Check `decimalLength`, `decimalPlaces`, `rounding` and the edit/focus state |
| An amount is not grouped | Enable `useGrouping` and check whether the field is currently focused |
| A phone number fails country validation | Check `SmartPhonePolicy`, selected country and whether the number starts with `+` |
| An OTP isn't auto-read from messages | This package does not implement SMS/WhatsApp reading |
| A masked input reveals its raw text | Editable masked fields can reveal on focus; check `revealMaskOnFocus` |
| A card passes Luhn but payment fails | Luhn does not prove card existence, balance or issuer approval |
| Date-time shifts after converting to UTC | Date/time values are local and timezone-naive; apply app-specific timezone logic |
| Contact picker doesn't open | Test device support, native integration and platform setup |
| A controller is unexpectedly disposed | Confirm who created the controller; application-created controllers remain application-owned |
| Custom border or padding isn't visible | An explicit `InputDecoration` or app `InputDecorationTheme` takes priority over package fallback |

#### Running the integration tests

Inside `example/`, run all real-engine tests with one command:

```bash
flutter test integration_test -d <device>
```

The folder holds one test entry file, `all_test.dart`, which runs every case in a single app launch; `flutter test integration_test/all_test.dart -d <device>` is the same run. The cases live in `credit_card_cases.dart` and `fields_cases.dart`, which can also be run on their own by path. They are deliberately not named `*_test.dart`: on desktop the Flutter tool starts a new copy of the app for every test file in a folder, and the second launch fails with `Unable to start the app on the device`. That is how the tool behaves on desktop and does not depend on the package.

### Moving from 0.0.1

Version 0.1.0 uses `package:material_ui` instead of `package:flutter/material.dart`, which Flutter 3.50 deprecates. This is a breaking change for apps that still use the in-framework Material library:

- Flutter 3.47.0 or later is required (0.0.1 accepted 3.44).
- Public parameters that take Material types, such as `InputDecoration`, now take the `material_ui` versions. In your app, change `import 'package:flutter/material.dart';` to `import 'package:material_ui/material_ui.dart';`, or run `dart fix --apply --code=migrate_design_widgets`.
- An app that is not migrated can wrap itself in `MaterialUiCompatibilityBridge` so themes reach the fields; values of the old types still cannot be passed to `SmartField`. See [Flutter's migration guide](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui).
- The country picker sheet is now part of this package and uses your `material_ui` theme.

## Example application and development

### Run the real Flutter example

```bash
cd example
flutter pub get
flutter run
```

To run on a particular supported target, select an available device with `flutter devices` or use `flutter run -d chrome` for the web example.

### Analyze and test the package

From the package root:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Analyze and build the example separately:

```bash
cd example
flutter pub get
flutter analyze
flutter build web
```

Before a release, check the package with a dry run:

```bash
flutter pub publish --dry-run
```

Add `flutter test --platform chrome` to run the suite in a browser, and `flutter test integration_test -d <device>` inside `example/` to run the real-engine tests on a simulator, emulator, or desktop; see [Platform notes](#running-the-integration-tests).

### Project organization

The published package entry point is:

```text
lib/smart_field_kit.dart
```

Internal files in `lib/src/` implement field behavior, common design, validation, formatting, masks, and specialized components. **Do not import `lib/src/` directly from consumer applications.** The example must depend only on the public package API.

The public named constructors are intentionally flat for ease of use; phone, search, amount, mask, async, password, word-count, percentage, and server-error behaviour live in small internal feature classes.

## Frequently asked questions

### Is plain `SmartField()` just a normal text field?

Yes. It accepts normal text, spaces, symbols, international scripts and emoji by default. It does not force requiredness or a length limit.

### Can I write my own validator?

Yes. Provide `validator:`. Choose `validationMode` to combine, replace or select built-in format rules. Requiredness and explicit length/value limits remain separately configured.

### Are number and currency values converted through floating-point `double`?

The reported formatter uses exact decimal-string handling. This is important for precise amounts, long integer-like text and intentional rounding.

### Can I use a country code without changing the phone input?

Yes. Phone country metadata is separate from the exact text in the field. The developer callback can receive both the entered text and parsed values where parsing succeeds.

### Does the card component verify that a card is real?

No. It checks local structure, supported brand metadata, expiry and security-code format. Payment authorization belongs to a payment service provider.

### Can I use an ordinary Flutter `Form`?

Yes. Common validation and save/reset behavior integrate with Flutter's Form system. Asynchronous validators require explicit `await` before final submission.

### Can I hide a sensitive value without changing the controller?

Yes, for the supported phone/number/amount fields. Privacy masking changes presentation, not the raw stored value. This is not encryption.

### Does this package require a backend?

No. Local validation, fields, formatting and the example run without a backend. A developer-provided asynchronous checker may call a backend when your application needs it.

### Does the package do SMS verification or process real card payments?

No. It provides input controls and local checks, not message retrieval, identity verification, payment authorization or secure payment-token storage.

## Contributing

Contributions, bug reports and reproducible test cases are welcome through the GitHub repository.

A good contribution should:

1. Describe the affected constructor and expected behavior.
2. Include the smallest possible reproducible example.
3. Add or update automated tests for changed behavior.
4. Preserve public API compatibility unless a breaking change is explicitly approved.
5. Run formatting, static analysis and the applicable test suite.
6. Avoid committing real credentials, contact data, card details, OTP codes or proprietary assets.

Check any `AGENTS.md` repository instructions and existing contributing guidance before editing source code. Do not add a guessed issue-tracker or discussion URL: use the verified links in the repository once public.

## Third-party acknowledgments

Card-brand metadata in the reported implementation draws on Braintree's maintained [`credit-card-type`](https://github.com/braintree/credit-card-type) project. Refer to [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) for included attribution and license notices. Recheck third-party notices and licenses during the release audit.

## License

This project is licensed under the MIT License.

Copyright (c) 2026 CodeWingz (SMC-PRIVATE) LIMITED.

Prepared and maintained by Muhammad Afzaal, Founder & CEO of CodeWingz.

See the [LICENSE](LICENSE) file for details.

---

**Built for Flutter developers who want one consistent input-field API without giving up Flutter's own Form, theme, and controller model.**
