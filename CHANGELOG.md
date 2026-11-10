* Add a complete interactive Flutter example application demonstrating SmartField constructors, validation modes, formatting, masking, asynchronous validation, credit-card fields, date/time fields, and customization.
* Add responsive example layouts with light/dark theme switching, RTL layout, and adjustable text scaling.
* Add genuine Flutter example screenshots and animated GIF demonstration assets, with screenshot metadata configured for pub.dev.
* Add pub.dev package metadata, including homepage, repository, issue tracker, topics, and screenshot descriptions.
* Configure GitHub Actions CI for formatting, static analysis, package tests, coverage, example tests, web builds, and publication dry runs.
* Expand package documentation with installation instructions, quick-start examples, public API guidance, validation, formatting, masking, customization, and security limitations.
* Add a README quick-start regression test to verify that the documented signup example remains compatible with the public API.
* Add an example application README with setup instructions, feature overview, and screenshot-capture information.
* Add initial `.pubignore` rules for internal development references, historical reports, generated files, and unnecessary example-platform assets.
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
* Add a long-press Paste menu to the OTP field.
* Keep a pending debounced search when only the caret moves.
* Clear an outdated server error when the phone clear button or contact picker changes the value.
* Fix forward Delete on an input-mask literal or card-number space removing the character before the caret.
* Fix caret placement for amounts whose currency symbol contains a decimal separator or a digit.
* Honour `showClearButton` in date dropdown mode, give the month more room in narrow layouts, and roughly halve dropdown rebuild cost.
* Group the card number, expiry, and security-code fields for platform autofill.
* Lower the Dart SDK constraint to `^3.12.0` after verifying analysis, tests, and the example build on Flutter 3.44.0.
* Make the test suite pass on Chrome, add Chrome, Windows, macOS, and minimum-SDK jobs to CI, add real-engine integration tests, and add the missing macOS Podfile to the example.
