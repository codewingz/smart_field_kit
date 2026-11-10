## 0.0.1 (Unreleased)

### Added

* Add `SmartAsyncValidation.revalidationKey` to drop results and re-check when the validation rule changes.
* Add opt-in `normalizeDigits` on number, amount, percentage, phone, OTP, card, date, time, and date-time fields, with `SmartDigitNormalizationFormatter` and `SmartTextUtils.normalizeDigits`, for Arabic-Indic, Persian, and fullwidth digits.
* Add opt-in `acceptDotAsDecimal` on `SmartField.amount` and `SmartAmountFormatter`.
* Add `amLabel` and `pmLabel` on `SmartField.time`, `SmartField.dateTime`, and `SmartTimeFormat`.
* Add API documentation comments to the exported classes, constructors, and functions.
* Add the normal SmartField widget with native TextFormField behavior.
* Add opt-in required and grapheme-aware length validation with reusable validators.
* Add SmartField.email with practical default and opt-in legacy validation policies.
* Add SmartField.password with optional legacy policies and accessible visibility control.
* Add SmartField.number with exact optional value bounds and legacy validation.
* Add SmartField.amount with exact decimal formatting, raw callbacks, grouping, currency, and legacy validation.
* Add SmartField.name and SmartField.username with flexible Unicode defaults and five optional legacy text-validation presets.
* Add SmartField.otp with a native single-input box layout, autofill, exact validation, controlled errors, completion callbacks, responsive styling, and the optional legacy rule.
* Add SmartField.description and SmartField.text with native multiline layout, automatic height growth, shared line configuration, and the final two legacy text presets.
* Add independent phone, account, and amount masking utilities plus opt-in masked presentation for phone, number, and amount fields.
* Add SmartField.search with native search input behavior, accessible clear and loading states, and optional debounced search events.
* Add SmartField.percentage with a visual percent suffix, exact raw decimal strings, and opt-in sign, precision, and range rules.
* Add SmartField.url with raw-value preservation, complete http/https syntax validation, and opt-in scheme and bare-domain policies.
* Add optional asynchronous validation for every SmartField type with debounce, triggers, stale-result protection, loading and unavailable states, and an awaitable SmartFieldAsyncController.
* Add shared fallback design (12px outline, 1px/2px borders, 16x12 padding) that yields to the field decoration and the app theme.
* Add four validation modes with selectable built-in checks, password rule checks, and field matching for confirm password.
* Add word limits and a word counter for SmartField.description and SmartField.text.
* Add optional text-case, username, and whitespace formatters and the SmartTextUtils helpers.
* Add SmartField.amount decimalLength (false, 1, 2, 3), explicit rounding modes, and Indian grouping.
* Add SmartServerError for manual server messages on every field and optional state restoration.
* Add SmartField.creditCard with brand-aware grouping, Luhn and expiry validation, concealed security code, and no persistence of card data.
* Add SmartField.date (manual, calendar, dropdowns, wheel), SmartField.time, and SmartField.dateTime with typed values and timezone-free ISO serialization.
* Add generic pattern masks for SmartField.text with separate raw and display values.
* Add an optional password-strength indicator with developer-defined criteria.
* Add a long-press Paste menu to the OTP field.
* Add optional `initialValue`, `onFieldSubmitted`, `onEditingComplete`, `onTap`, `onTapOutside`, `style`, `textAlign`, `textDirection`, and `obscuringCharacter` parameters to the text-based constructors.
* Add optional text overrides: `wordCountBuilder`, `strengthTitle`, the five password-rule messages, `allowedCharactersErrorText`, `contactPickerMessageBuilder`, `showCvvLabel`, and `hideCvvLabel`.
* Export `SmartNumberInputFormatter`.

### Changed

* Email: with the standard policy, asynchronous validation now receives the address without surrounding spaces, the same value `onSaved` receives.
* Declare Android, iOS, macOS, and web as supported platforms in `pubspec.yaml`.
* Refactor SmartField internals into a shared core with one owned controller and focus node path and a shared design resolver.
* Make SmartPhonePolicy.auto validate international numbers with the parser-inferred country when no country is selected.
* Refactor SmartField internals: one shared private base class with default values, constructors that build their configuration directly, shared listener, input-handle, validation-mode, raw-value, and suffix helpers, and smaller field state (phone, amount display, search debounce, and password strength moved to focused helpers). No public API changes.
* Credit card: UnionPay is now exempt from the Luhn checksum by default because its numbers are not required to pass it; pass `luhnExemptBrands: const {}` to enforce Luhn, and every other brand still requires it. Strength indicator is skipped while a mask is shown, as before the feature refactor.
* Group the card number, expiry, and security-code fields for platform autofill.
* Lower the Dart SDK constraint to `^3.12.0` after verifying analysis, tests, and the example build on Flutter 3.44.0.
* Asynchronous validation no longer compares validator functions: a parent rebuild keeps the pending check and the completed result, and `validateAsync(force: true)` applies a changed rule with one new request, also while a check is pending.
* Search: a parent rebuild no longer cancels a pending debounced `onSearch`; the callback from the latest build is called.
* Call date `onRawChanged` with an empty string when a valid value is cleared or becomes invalid.
* Return the same normalised text from amount `onRawSaved` whether or not the field has focus.
* Apply `maxLength` to whitespace-only text and count grapheme clusters in `SmartPasswordCriterion.minLength`.
* Reject card numbers made only of zeros.
* OTP: remove spaces and hyphens from pasted text, drop extra digits, let a typed digit replace a filled box, and report each distinct completed code.
* Phone: ignore non-breaking spaces, dots, and invisible direction marks during validation and parsing.
* Email: ignore surrounding spaces during validation and pass the trimmed address to `onSaved`.
* Credit card: label the security-code toggle `Show security code` / `Hide security code`, and apply decoration labels and icons to the number field only.

### Fixed

* Fix masked phone, number, and amount text being cut off on narrow screens with large text; it is now drawn smaller to fit.
* Remove a dropped asynchronous error within the same frame instead of one frame later.
* Remove a displayed asynchronous validation error when its result is dropped because the text controller was replaced or the field was disabled; the field then shows the validation state of its current value.
* Expose each password-strength checklist rule to screen readers with a checked or not-checked state.
* Fix layout overflow in the phone field's country prefix at large text sizes and in date dropdowns on very narrow widths.
* Wheel date picker: roll back to the nearest allowed date and disable confirmation when the wheels stop outside `minDate`, `maxDate`, or `restriction`.
* Keep the selected phone country, a revealed password, pending searches, and other per-feature state when an unrelated feature such as `mask`, `serverError`, or `asyncValidation` is added or removed.
* Stop amount display formatting on load, focus, and focus loss from calling `Form.onChanged` or triggering `AutovalidateMode.onUserInteraction`.
* Remove text that a number, amount, username, mask, card, or OTP input rule rejects when a composing keyboard commits it, by returning to the text held before the composition.
* Fix the contact picker storing an inferred country when no country picker is shown, guard it against overlapping opens, keep disabled OTP fields unfocusable, and clear server errors on OTP edits.
* Fix date dropdown mode failing a framework assertion when the stored date is outside the selectable years; the date is kept, shown, and reported through validation.
* Fix date dropdown `FormState.reset()` followed by `save()` returning a date that was no longer visible.
* Discard date, time, date-time, wheel, and country picker results when the field was disabled, made read-only, given another controller, or removed while the picker was open.
* Stop amount and date fields from writing to a developer-owned controller during build, which could throw `setState() or markNeedsBuild() called during build`.
* Run automatic asynchronous validation after a selection in calendar, wheel, and clock picker modes.
* Keep OTP text, selection, and focus when asynchronous validation is added to or removed from a field without an external controller.
* Recompute the card security-code length error when the card-number controller or allowed lengths change.
* Return an invalid result instead of throwing for URLs with oversized numeric host components.
* Enforce `SmartField.username(allowedCharacters:)` through validation as well as input formatting.
* Fix right-to-left layouts reordering digits: OTP boxes, card numbers, phone numbers and dial codes, grouped and negative amounts, percentages, and 12-hour times now keep typed order.
* Expose a tap action to assistive technology on the password visibility toggle and the search clear button; announce the OTP label, country button, and date dropdown labels once; make date dropdowns 48 logical pixels high with a focused border.
* Keep a pending debounced search when only the caret moves.
* Clear an outdated server error when the phone clear button or contact picker changes the value.
* Fix forward Delete on an input-mask literal or card-number space removing the character before the caret.
* Fix caret placement for amounts whose currency symbol contains a decimal separator or a digit.
* Honour `showClearButton` in date dropdown mode, give the month more room in narrow layouts, and roughly halve dropdown rebuild cost.

### Testing & Documentation

* Add SmartField.phone with optional country selection, metadata validation, safe E.164 values, native contact selection, and legacy validation.
* Credit card: add a verified brand metadata table (Troy, Elo, Mir, Hiper, Hipercard, Naranja, Verve added), uncertainty-aware brand detection, instant local number status with neutral guidance, per-brand grouping, brand-aware security-code re-checks, Luhn options, and redacted diagnostics.
* Add a complete interactive Flutter example application demonstrating SmartField constructors, validation modes, formatting, masking, asynchronous validation, credit-card fields, date/time fields, and customization.
* Add responsive example layouts with light/dark theme switching, RTL layout, and adjustable text scaling.
* Add genuine Flutter example screenshots and animated GIF demonstration assets, with screenshot metadata configured for pub.dev.
* Add pub.dev package metadata, including homepage, repository, issue tracker, topics, and screenshot descriptions.
* Configure GitHub Actions CI for formatting, static analysis, package tests, coverage, example tests, web builds, and publication dry runs.
* Expand package documentation with installation instructions, quick-start examples, public API guidance, validation, formatting, masking, customization, and security limitations.
* Add a README quick-start regression test to verify that the documented signup example remains compatible with the public API.
* Add an example application README with setup instructions, feature overview, and screenshot-capture information.
* Add initial `.pubignore` rules for internal development references, historical reports, generated files, and unnecessary example-platform assets.
* Make the test suite pass on Chrome, add Chrome, Windows, macOS, and minimum-SDK jobs to CI, add real-engine integration tests, and add the missing macOS Podfile to the example.
