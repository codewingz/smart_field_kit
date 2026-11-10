# Platform notes

Part of the [smart_field_kit documentation](../README.md).

## Platform behavior and limitations

Most field controls use Flutter's Material widgets. Some features depend on mobile platform APIs, keyboard behavior or accessibility services.

| Area | Current behavior or limitation |
|---|---|
| Flutter and Dart versions | Requires Flutter 3.44.0 or later and Dart 3.12.0 or later. Analysis, all package tests, the example tests, and the example web build pass on Flutter 3.44.0 (Dart 3.12.0) and on Flutter 3.47.8 (Dart 3.13.7). Flutter 3.44 is the oldest version the bundled contact-picker plugin accepts |
| Flutter web | The package test suite runs on Chrome (984 tests pass; 47 are skipped there: 34 need the native contact picker, which is not offered on web, 11 read project files through `dart:io`, and 2 send native undo key events that the browser handles itself). The example web build passes. On web, Flutter selects all text when a field gains focus programmatically, and the browser owns the undo shortcut |
| iOS | The example integration tests (card entry, amount formatting, RTL digit order, calendar and country pickers, dropdown dates, password toggle, masking) pass on an iPhone 17 simulator. The native contact picker, the system keyboard, SMS code autofill, and VoiceOver were not exercised |
| Android | The same integration tests pass on an Android API 36 emulator. The merged example manifest declares no contacts permission. The native contact picker, third-party keyboards, SMS code autofill, and TalkBack were not exercised |
| macOS | The example builds and the integration tests pass on macOS desktop with `flutter test integration_test -d macos`. Run them from an interactive desktop session; in an unattended session the run has sometimes stalled before the first test. The contact button is not shown on desktop |
| Windows and Linux | Not tested locally. CI is configured to run the package tests on Windows; no hosted run has been verified yet |
| Keyboards that compose text (IME) | Text is not changed while the keyboard is still composing. When the composed text is committed and the field's input rule rejects it, the field returns to the text it held before that composition, with the caret where the composition began. This is covered by simulated composition tests; hardware and third-party keyboards were not tested |
| Digits | By default number, amount, percentage, OTP, card, date, and time fields accept ASCII digits `0`-`9` only: Arabic-Indic (`١٢٣`), Persian (`۱۲۳`), and fullwidth digits are not entered and no message is shown, and a phone field keeps them and reports the number as invalid. Set `normalizeDigits: true` on those fields, or on a phone field, to replace these three digit sets with ASCII digits as they are typed or pasted, before any rule runs. Other numerals, and the Arabic decimal and thousands separators, are not converted. Text set through a controller is not rewritten |
| Decimal separator | With `decimalSeparator: ','` the comma is the only decimal key by default; a typed `.` is not treated as the decimal, so a keypad that offers only `.` cannot enter the decimal part. Set `acceptDotAsDecimal: true` on `SmartField.amount` to accept one typed `.` as the decimal. It has no effect when the grouping separator is `.` |
| 12-hour time | The markers default to `AM` and `PM`. Set `amLabel` and `pmLabel` on `SmartField.time` and `SmartField.dateTime` to change them. The Material clock dialog takes its own text from the app's locale |
| Narrow layouts and large text | When a phone field's flag and dial code would take more than half of the space available to them, they are drawn smaller instead of overflowing. Date dropdowns are drawn smaller together when the field is too narrow for the three controls (about 210 px at normal text size with a clear button). Nothing is clipped or hidden; in those cases the dropdown touch areas are smaller than 48 px |
| Contact picker | Depends on the native system picker and requires available platform behavior |
| OTP autofill | Keyboard/platform hints may assist autofill; this package does not itself read SMS or WhatsApp |
| Date-time | Local/timezone-naive date-time at minute precision; the consuming app owns timezone conversion and DST policy |
| State restoration | Password and OTP are intentionally excluded; fields with owned or app-supplied controllers have documented limits |
| RuPay | No specific RuPay card-brand mapping has been claimed; uncertain prefixes remain unknown or match other supported brands |
| Luhn exceptions | UnionPay exempt by default; developer can override |
| Date-time picker modes | `dateTime()` supports manual and picker, not a date-time wheel mode |
| Accessibility | RTL and text scaling are designed into the UI, but full TalkBack/VoiceOver platform checks are still required |

**Do not interpret this table as a certification that every platform has been tested.** Check the latest release notes and platform test matrix before depending on a device-specific behavior.

## Troubleshooting

| Symptom | What to check |
|---|---|
| `flutter pub add smart_field_kit` cannot find the package | The package is pre-publication; use the local `path:` dependency until it is released |
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
| UnionPay should be strict | Pass `luhnExemptBrands: const {}` to enable Luhn for UnionPay |
| Date-time shifts after converting to UTC | Date/time values are local and timezone-naive; apply app-specific timezone logic |
| Contact picker doesn't open | Test device support, native integration and platform setup |
| A controller is unexpectedly disposed | Confirm who created the controller; application-created controllers remain application-owned |
| Custom border or padding isn't visible | An explicit `InputDecoration` or app `InputDecorationTheme` takes priority over package fallback |

## Running the integration tests

Inside `example/`, run all real-engine tests with one command:

```bash
flutter test integration_test -d <device>
```

The folder holds one test entry file, `all_test.dart`, which runs every case in a single app launch; `flutter test integration_test/all_test.dart -d <device>` is the same run. The cases live in `credit_card_cases.dart` and `fields_cases.dart`, which can also be run on their own by path. They are deliberately not named `*_test.dart`: on desktop the Flutter tool starts a new copy of the app for every test file in a folder, and the second launch fails with `Unable to start the app on the device`. That is how the tool behaves on desktop and does not depend on the package.
