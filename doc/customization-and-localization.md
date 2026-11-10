# Customization and localization

Part of the [smart_field_kit documentation](../README.md).

## Theme and design

All fields except `SmartField.otp()` (which draws its own boxes through `SmartOtpStyle`) share one design resolver. Priority is the field's own `decoration`, then the app's `InputDecorationTheme`, then the package fallback:

- Outline border, 12px radius, 1px normal border, 2px focused and error borders.

- 16px horizontal and 12px vertical content padding.

- Colors from the app `ColorScheme` (`outline`, `primary`, `error`, and a faint `onSurface` for disabled), so light, dark, and custom themes apply.

If the field's `decoration` or the app theme sets any border property, no fallback borders are added; if either sets `contentPadding` (or `isCollapsed`), the fallback padding is not added. Focus styling follows the field's real focus. Fixed heights are never applied, so multiline, large text, error text, and RTL layouts can grow.

## Right-to-left layouts

Labels, icons, alignment, and error text follow the ambient `Directionality`. Content made of digits is always drawn left to right so it reads in the order it was typed: number, amount, percentage, phone, card number, expiry, security code, date, time, and date-time text, the phone dial code, masked previews, and the OTP boxes. In a right-to-left layout that text is right-aligned inside the field. Plain text, name, email, username, description, URL, and search fields keep Flutter's default direction handling.

## Accessible actions

The password visibility toggle and the search clear button expose a tap action to assistive technology in addition to their labels. The OTP label, the country button, and the date dropdowns are announced once. Date dropdowns are 48 logical pixels high. A long press on the OTP boxes opens a Paste menu, and `Ctrl`/`Cmd`+`V` keeps working on desktop and web. These behaviours are covered by semantics-tree tests; checks with TalkBack and VoiceOver on real devices are still required.

## Label and message overrides

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

