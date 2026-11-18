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

- Rules: `minDate`, `maxDate` (inclusive), `restriction` (`pastOnly` means before today, `futureOnly` means after today, both relative to `now()` and counted in calendar days, so a daylight-saving change does not move the limit), `minTime`/`maxTime`, `isRequired`, your `validator`, `serverError`, `asyncValidation`, `initialDate`/`initialTime`, `showClearButton`, and `FormState.reset`. Impossible dates such as 30 February are invalid. `minDateTime` is compared to the minute, because the field has no seconds: a limit of 10:30:45 accepts 10:30. `firstYear` must not be after `lastYear`; this is asserted in debug builds, and a reversed pair is put in order in release builds. Calendar and wheel pickers default to 1900 to 2100 when no bounds are set. In wheel mode, when `minDate`, `maxDate`, or `restriction` is set and the wheels stop on a date outside that range, they roll back to the nearest allowed date, and the confirm button is disabled while the selection is out of range, so the wheel never returns a date outside the range. In dropdown mode a stored date outside the selectable years is still shown and is never replaced; `minDate`, `maxDate`, and `restriction` report it, and a date outside an explicit `firstYear`/`lastYear` range fails with the invalid-date message. `FormState.reset` returns a dropdown field to the date it had when it was first shown (the controller text or `initialDate`), and `save` then returns that same value. A picker result is discarded if the field was disabled, made read-only, given another controller, or removed while the picker was open. Calendar, wheel, and clock picker modes run `asyncValidation` automatically after a selection unless the field is disabled or `readOnly`.

- Values: `onDateChanged`, `onTimeChanged`, `onDateTimeChanged` give `DateTime?`/`TimeOfDay?`. Dates are local calendar dates (midnight), so there are no timezone shifts. `onRawChanged`, `onRawSaved`, and async validators receive ISO text: `yyyy-MM-dd`, `HH:mm`, or `yyyy-MM-ddTHH:mm` without an offset. `SmartDateUtils` provides the same helpers. `onChanged` and `onSaved` carry the displayed text. In dropdown mode an external `controller` holds the same display text as the dropdowns and stays in sync with them. `showClearButton` also works in dropdown mode: the button empties all three parts, the controller, and the form value, and calls `onChanged('')` and `onDateChanged(null)`.

- Limits: date-time values are minute precision and timezone-naive; daylight-saving gaps and overlaps are not adjusted, and the app owns timezone conversion. Cancelling a picker leaves the value unchanged. Programmatic controller changes do not fire typed callbacks.

## Card decoration, labels, and zero numbers

- The `decoration` passed to `SmartField.creditCard` applies in full to the card-number field. The expiry and security-code fields take its borders, padding, fill, and text styles, but not its label, hint, helper, prefix, suffix, or icons.
- The security-code visibility toggle is labelled `Show security code` / `Hide security code`. Change it with `showCvvLabel` and `hideCvvLabel`.
- A number made only of zeros is invalid and reports the checksum message. Brand rules and the UnionPay Luhn exemption are unchanged.

## Raw date values when a date is removed

`onRawChanged` is called with an empty string when a date, time, or date-time that was valid is cleared or edited into an incomplete value. It is not called again until the value becomes valid.
