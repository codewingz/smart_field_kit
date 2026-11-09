## 0.0.1

* Add the normal SmartField widget with native TextFormField behavior.
* Add opt-in required and grapheme-aware length validation with reusable validators.
* Add SmartField.email with practical default and opt-in legacy validation policies.
* Add SmartField.password with optional legacy policies and accessible visibility control.
* Add SmartField.number with exact optional value bounds and legacy validation.
* Add SmartField.amount with exact decimal formatting, raw callbacks, grouping, currency, and legacy validation.
* Add SmartField.phone with optional country selection, metadata validation, safe E.164 values, native contact selection, and legacy validation.
* Add SmartField.name and SmartField.username with flexible Unicode defaults and five optional legacy text-validation presets.
* Add SmartField.otp with a native single-input box layout, autofill, exact validation, controlled errors, completion callbacks, responsive styling, and the optional legacy rule.
* Add SmartField.description and SmartField.text with native multiline layout, automatic height growth, shared line configuration, and the final two legacy text presets.
* Add independent phone, account, and amount masking utilities plus opt-in masked presentation for phone, number, and amount fields.
* Add SmartField.search with native search input behavior, accessible clear and loading states, and optional debounced search events.
* Add SmartField.percentage with a visual percent suffix, exact raw decimal strings, and opt-in sign, precision, and range rules.
* Add SmartField.url with raw-value preservation, complete http/https syntax validation, and opt-in scheme and bare-domain policies.
* Add optional asynchronous validation for every SmartField type with debounce, triggers, stale-result protection, loading and unavailable states, and an awaitable SmartFieldAsyncController.
* Refactor SmartField internals into a shared core with one owned controller and focus node path and a shared design resolver.
* Add shared fallback design (12px outline, 1px/2px borders, 16x12 padding) that yields to the field decoration and the app theme.
* Make SmartPhonePolicy.auto validate international numbers with the parser-inferred country when no country is selected.
* Add four validation modes with selectable built-in checks, password rule checks, and field matching for confirm password.
* Add word limits and a word counter for SmartField.description and SmartField.text.
* Add optional text-case, username, and whitespace formatters and the SmartTextUtils helpers.
* Add SmartField.amount decimalLength (false, 1, 2, 3), explicit rounding modes, and Indian grouping.
* Add SmartServerError for manual server messages on every field and optional state restoration.
* Add SmartField.creditCard with brand-aware grouping, Luhn and expiry validation, concealed security code, and no persistence of card data.
* Add SmartField.date (manual, calendar, dropdowns, wheel), SmartField.time, and SmartField.dateTime with typed values and timezone-free ISO serialization.
* Add generic pattern masks for SmartField.text with separate raw and display values.
* Add an optional password-strength indicator with developer-defined criteria.
* Fix the contact picker storing an inferred country when no country picker is shown, guard it against overlapping opens, keep disabled OTP fields unfocusable, and clear server errors on OTP edits.
* Credit card: add a verified brand metadata table (Troy, Elo, Mir, Hiper, Hipercard, Naranja, Verve added), uncertainty-aware brand detection, instant local number status with neutral guidance, per-brand grouping, brand-aware security-code re-checks, Luhn options, and redacted diagnostics.
* Refactor SmartField internals: one shared private base class with default values, constructors that build their configuration directly, shared listener, input-handle, validation-mode, raw-value, and suffix helpers, and smaller field state (phone, amount display, search debounce, and password strength moved to focused helpers). No public API changes.
