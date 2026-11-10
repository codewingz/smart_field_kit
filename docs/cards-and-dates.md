# Cards and dates

Part of the [smart_field_kit documentation](../README.md).

## Credit-card input and local checks

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

- **Brands** (data derived from maintained Braintree card-brand metadata, reviewed on 2026-11-09): Visa, Mastercard (51-55 and 2221-2720), American Express, Diners Club, Discover, JCB, UnionPay, Maestro, Troy, Elo, Mir, Hiper, Hipercard, Naranja, Verve. Each has its own prefix ranges, accepted lengths, display grouping, and security-code size (`SmartCardBrand.lengths`, `gaps`, `cvvLength`). Supported lengths follow the implemented verified metadata. The legacy 13-digit Visa format is not accepted by default; other length differences are handled according to the maintained card-brand table. **RuPay is not supported:** the only source found lists very broad prefixes (60, 65, 81, 82, 508) that overlap Discover, UnionPay, and Maestro with no verifiable narrower ranges, so those numbers are handled as the matching brand or as unknown.

- **Detection never forces a brand early.** `SmartCardUtils.matchBrand()` returns the candidate brands. While a prefix can still become another network (for example `4` could be Visa, Elo, or Naranja) the brand is `unknown` and `likelyBrand` shows the best guess; the brand is set as soon as the prefix is unambiguous (`4111`, `401178`, `34`). The most specific verified range wins (Troy over Discover `65`, Verve and Elo over Maestro). Detection says nothing about credit versus debit. Unknown brands accept 12 to 19 digits and a 3- or 4-digit code.

- **Instant status.** `SmartCardUtils.assessNumber()` and `SmartCreditCardValue.numberStatus` report `empty`, `incomplete`, `valid`, or `invalid` on every keystroke, paste, programmatic change, clear, and reset. Incomplete numbers show neutral guidance (`Visa · 8 more digits`), never an error. When a valid length is reached the Luhn checksum is checked and a failure is shown immediately. For brands with several valid lengths a failing number is flagged at the main length (16, 15, or 14) or the longest, and stays neutral at the other lengths while the user may still be typing. Strict `FormState.validate()` always requires a complete valid number. `numberStatusBuilder` customizes the guidance text, and `showNumberStatus: false` hides it.

- **Luhn** applies to every brand except UnionPay by default. UnionPay is exempt because its numbers are not required to pass the Luhn checksum (the maintained Braintree `card-validator` skips Luhn for UnionPay unless asked, checked 2026-11-09). Pass `luhnExemptBrands: const {}` to enforce Luhn on UnionPay too, or `validateLuhn: false` to disable the checksum for every brand; length and prefix checks still apply to UnionPay.

- **Grouping** follows each brand: `4111 1111 1111 1111`, `3782 822463 10005`, Diners `3056 930902 5904`. Numbers beyond 16 digits continue in groups of four. Pasted spaces and dashes are accepted; letters are rejected; digits are never changed.

- **Expiry:** `MM/YY` or `MM/YYYY`; months 01-12; valid through the last moment of the expiry month (leap years, December to January included); two-digit years mean 2000-2099. Pass `now:` for deterministic tests.

- **Security code:** 4 digits for American Express, 3 for the other supported brands, or any lengths from `cvvLengths`. Changing the number to a brand with a different code length re-checks an already entered code immediately. It is concealed by default (`concealCvv: true`). Local checks cannot confirm the code with the bank.

- Server messages: `numberServerError`, `expiryServerError`, `cvvServerError` take priority and clear on edit.

- **Security:** card data is never persisted, restored (`restorationId` is not used), logged, or sent. `SmartCreditCardValue`, assessments, and package-owned controllers print redacted text. An application-supplied controller or other application code can still expose sensitive values in its own diagnostics. `onChanged`/`onSaved` hand the full values to your code: treat them as sensitive and never log them. Platform autofill hints are set. **SmartField does not make an app PCI compliant;** for real payments use processor-hosted or tokenized fields, never store security codes after authorization, and use only synthetic test cards (such as `4111 1111 1111 1111`) in tests and demos.

## Dates, times, and date-times

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

- Rules: `minDate`, `maxDate` (inclusive), `restriction` (`pastOnly` means before today, `futureOnly` means after today, both relative to `now()`), `minTime`/`maxTime`, `isRequired`, your `validator`, `serverError`, `asyncValidation`, `initialDate`/`initialTime`, `showClearButton`, and `FormState.reset`. Impossible dates such as 30 February are invalid. Calendar and wheel pickers default to 1900 to 2100 when no bounds are set. In dropdown mode a stored date outside the selectable years is still shown and is never replaced; `minDate`, `maxDate`, and `restriction` report it, and a date outside an explicit `firstYear`/`lastYear` range fails with the invalid-date message. `FormState.reset` returns a dropdown field to the date it had when it was first shown (the controller text or `initialDate`), and `save` then returns that same value. A picker result is discarded if the field was disabled, made read-only, given another controller, or removed while the picker was open. Calendar, wheel, and clock picker modes run `asyncValidation` automatically after a selection unless the field is disabled or `readOnly`.

- Values: `onDateChanged`, `onTimeChanged`, `onDateTimeChanged` give `DateTime?`/`TimeOfDay?`. Dates are local calendar dates (midnight), so there are no timezone shifts. `onRawChanged`, `onRawSaved`, and async validators receive ISO text: `yyyy-MM-dd`, `HH:mm`, or `yyyy-MM-ddTHH:mm` without an offset. `SmartDateUtils` provides the same helpers. `onChanged` and `onSaved` carry the displayed text. In dropdown mode an external `controller` holds the same display text as the dropdowns and stays in sync with them. `showClearButton` also works in dropdown mode: the button empties all three parts, the controller, and the form value, and calls `onChanged('')` and `onDateChanged(null)`.

- Limits: date-time values are minute precision and timezone-naive; daylight-saving gaps and overlaps are not adjusted, and the app owns timezone conversion. Cancelling a picker leaves the value unchanged. Programmatic controller changes do not fire typed callbacks.
