# smart_field_kit

**One flexible Flutter form-field toolkit. Familiar Flutter APIs, purpose-built input types, and reusable validation—without rebuilding the same form logic in every app.**

[![Flutter package](https://img.shields.io/badge/Flutter-package-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-null--safe-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
![Release status](https://img.shields.io/badge/release-pre--publication-orange)

Build anything from a plain text field to a country-aware phone input, exact-decimal amount, OTP entry, credit-card form, or date picker using the same `SmartField` family.

```dart
SmartField.email(label: 'Email', isRequired: true);
SmartField.phone(label: 'Phone', showCountryPicker: true);
SmartField.amount(label: 'Amount', decimalLength: 2, useGrouping: true);
SmartField.otp(length: 6, onCompleted: (value) {});
```

> **Release status:** Version 0.0.1 is unreleased; the package has not been published to pub.dev. Requires Flutter 3.44.0 or later and Dart 3.12.0 or later. Tested platforms and known limits are listed in [Platform notes](doc/platform-notes.md).

**Why this package?** Use a single, familiar set of input widgets while keeping Flutter's `Form`, `TextEditingController`, `FocusNode`, `InputDecoration`, keyboard, theme, and validation conventions. Ordinary text stays unrestricted by default; special rules are opt-in or specific to a selected field type.

## Contents

- [Why SmartField Kit](#why-smartfield-kit)
- [Feature overview](#feature-overview)
- [Installation](#installation)
- [Quick start: working Form](#quick-start-working-form)
- [Choose a field](#choose-a-field)
- [Documentation](#documentation)
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

### Before publication: local development

Until the package is published, add a **local path dependency** from a consuming Flutter app's `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  smart_field_kit:
    path: ../smart_field_kit
```

Then run:

```bash
flutter pub get
```

The relative path must point to your actual cloned package directory. If the package is moved, update the path.

### After publication on pub.dev

Once a verified public release exists, install it using:

```bash
flutter pub add smart_field_kit
```

Do not use this public-installation command to imply the package is already published.

Import the public entry point in your Dart file:

```dart
import 'package:smart_field_kit/smart_field_kit.dart';
```

No `lib/src/` import should be necessary for a consumer application.

## Quick start: working Form

This example uses Flutter's regular `Form` API. It validates required fields, keeps controller ownership in the application, and doesn't print or store passwords.

```dart
import 'package:flutter/material.dart';
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

| Page | What it covers |
|---|---|
| [Fields](doc/fields.md) | Plain, text, description, name, username, email, password, number, URL, search and OTP fields; options shared by every constructor |
| [Validation](doc/validation.md) | Form validation, the four validation modes, legacy presets, confirm password, asynchronous validation and safe submission, server errors, standalone validators, password strength |
| [Formatting and masks](doc/formatting-and-masks.md) | Amounts, currencies, percentages, raw and displayed values, decimal precision and rounding, input masks, privacy masking, word limits, state restoration |
| [Phone numbers](doc/phone.md) | Phone policies, country selection, E.164 values, contact picker |
| [Cards and dates](doc/cards-and-dates.md) | Credit-card fields, date, time and date-time modes |
| [Customization and localization](doc/customization-and-localization.md) | Theme and fallback design, right-to-left layouts, accessible actions, label overrides |
| [Security and privacy](doc/security-and-privacy.md) | What client-side validation does and does not protect, sensitive values |
| [Platform notes](doc/platform-notes.md) | Supported Flutter and Dart versions, tested platforms, known limitations, troubleshooting |

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

For publishing preparation, **dry run only** until the project owner authorizes a release:

```bash
flutter pub publish --dry-run
```

Add `flutter test --platform chrome` to run the suite in a browser, and `flutter test integration_test -d <device>` inside `example/` to run the real-engine tests on a simulator, emulator, or desktop.

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

Contributions, bug reports and reproducible test cases are welcome once the repository is made public.

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
