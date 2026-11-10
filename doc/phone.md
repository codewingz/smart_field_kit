# Phone numbers

Part of the [smart_field_kit documentation](../README.md).

## Phone numbers and country handling

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

The contact button is shown only on Android and iOS. It opens the operating system's native one-number picker and does not request broad contact-list access, enumerate the address book, upload data, or contact a server. Cancellation leaves the field unchanged. Other failures use `onContactPickerError` when supplied or accessible `SnackBar` feedback. Adding the option does not make the native dependency optional at install time. The package requires Flutter 3.44 or later because `flutter_native_contact_picker` 0.0.13 does, and that plugin requires iOS 13 or later; the example targets iOS 15.

Country names work in English without extra setup. Apps that need translated country names can add `CountryLocalizations.delegate` from `country_picker` to their `MaterialApp` localization delegates.

Phone support uses [`country_picker` 2.0.28](https://pub.dev/packages/country_picker), [`phone_numbers_parser` 9.0.29](https://pub.dev/packages/phone_numbers_parser), and [`flutter_native_contact_picker` 0.0.13](https://pub.dev/packages/flutter_native_contact_picker). The first two use the MIT license and the native picker uses BSD-3-Clause. Their notices are retained in `THIRD_PARTY_NOTICES.md`.

## Separators in phone numbers

Before validation and parsing, non-breaking spaces and dots are treated as spaces, and invisible direction marks are ignored. `(415)<non-breaking space>555-2671` and `415.555.2671` validate like `(415) 555-2671`. Digits are never changed and the country check still applies. The text in the field is not rewritten, and `SmartPhoneValue.text` holds it as entered. Extensions such as `x12` are not supported. `SmartPhonePolicy.legacy` is unchanged.
