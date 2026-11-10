# Formatting and masks

Part of the [smart_field_kit documentation](../README.md).

## Amounts and currencies

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

## Displayed and raw amount values

- The controller, `onChanged`, custom `validator`, and `onSaved` preserve Flutter's display-text behavior.

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

## Percentages

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

## Optional text formatters

All formatters are optional.

- `SmartField.name(capitalizeWords: true)`.

- `SmartField.username(usernameCase: SmartTextCase.lowercase, allowedCharacters: SmartUsernameCharacters.usernameSafe)`. Disallowed edits are rejected rather than stripped. The same rule is checked by validation, so a value set through the controller, pasted, or committed by a keyboard composition that breaks `allowedCharacters` fails with `Use only the allowed characters.`

- `SmartField.text()` / `.description()`: `textCase` (`capitalizeFirstLetter`, `capitalizeWords`, `capitalizeSentences`, `lowercase`, `uppercase`) and `collapseWhitespace`.

- Email, password, OTP, phone, URL, amount, and number have no case or whitespace formatters, so case-sensitive and secret values are never rewritten.

The same classes (`SmartTextCaseFormatter`, `SmartUsernameFormatter`, `SmartWhitespaceFormatter`) work as ordinary `inputFormatters`. They keep the caret, ignore active IME composition, and map selections across edits.

## Decimal precision, rounding, and grouping

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

## Pattern input masks

`SmartField.text(inputMask: '####-####')` formats typed text with a pattern: `#` digit, `A` letter, `*` letter or digit, `\\` escapes a literal, anything else is a literal. The controller and `onSaved` keep the formatted text; `onRawChanged` and `onRawSaved` receive only the entered characters (`12345678`). An incomplete value fails validation (`inputMaskErrorText`); an empty value is valid unless required. Typing, deletion (including over a separator), paste of raw or formatted text, selections, and the caret are handled; invalid characters reject the edit. `SmartInputMask` and `SmartMaskFormatter` work without a widget.

Pattern formatting is not privacy masking: it never hides characters. Use `mask: true` (and the `mask*` utilities) for visual privacy. No country rule is applied unless you write one into the pattern.

## Visual privacy masking

`SmartField.phone()`, `SmartField.number()`, and `SmartField.amount()` support opt-in visual masking. Masking is disabled by default and does not change validation or formatting rules.

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

`maskVisibleSuffixDigits` defaults to four for phone and number fields and zero for amounts. `maskCharacter` must contain exactly one Unicode grapheme. Negative suffix counts and empty or multi-grapheme mask characters throw `ArgumentError`. The controller, selection, validation, `onChanged`, `onSaved`, phone parsing, amount display formatting, `onRawChanged`, and `onRawSaved` never receive mask characters. Masked mode disables interactive selection and must not expose raw sensitive characters through accessibility semantics while the value remains concealed.

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

`maskAmount` accepts a structurally valid ASCII-digit amount display, preserves its sign, grouping, decimal separator, whitespace, and one-sided currency text, and masks all digits by default. Custom separators, a visible trailing-digit count, a one-grapheme mask, and an explicitly positioned `currencySymbol` are optional. Malformed numeric displays throw `FormatException` rather than being sanitized into a valid amount.

Masking is a presentation-level privacy aid, not encryption, secure storage, log redaction, authorization, account verification, or backend protection. The owning application retains the raw value and remains responsible for access control, storage, logging, clipboard policy, and server-side security.

## Word-count and word limits

`SmartField.description()` and `SmartField.text()` accept `minWords`, `maxWords`, `showWordCount`, `minWordsErrorText`, and `maxWordsErrorText`. A word is any run of non-whitespace characters, so newlines, Unicode spaces, other scripts, and emoji are handled. The counter reads `12 / 200 words` (or `12 words` without a maximum). Word limits are separate from `minLength`/`maxLength` and never block typing.

## State restoration

Pass `restorationId` (inside a `RestorationScope`, for example `MaterialApp.restorationScopeId`) to restore a field's text. Limitations: restoration works only for fields without a developer controller and without a package-owned controller, so `.amount()`, `.phone()`, `.search()`, and masked fields are not restored; use your own `RestorableTextEditingController` for those. `.password()` and `.otp()` ignore `restorationId` and are never restored.

## Reusable formatting and validation utilities

`SmartValidators` (including `passwordRules`, `matches`, `minWords`, `maxWords`, `url`, `phone`), `SmartUrlValidation`, `SmartPhoneValidation`, `SmartTextUtils` (`countWords`, case helpers, `collapseWhitespace`), `SmartAmountFormatter`, `SmartDecimalUtils`, `maskMobile`, `maskAccountNumber`, `maskAmount`, and `formatNumber` call the same code as the widgets.

## Saved raw amounts

`onRawSaved` on an amount field returns the same normalised text whether or not the field has focus. With `decimalPlaces: 2`, typing `50000` saves `50000.00` in both states. Without fixed decimals the typed digits are kept (`12.5` saves `12.5`). `onSaved` and a custom `validator` still receive the text currently shown in the field.
