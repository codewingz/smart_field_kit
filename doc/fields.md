# Fields

Part of the [smart_field_kit documentation](../README.md).

## Plain text — `SmartField()` and `.text()`

`SmartField` is a normal text field by default. It allows empty input and unrestricted normal text, including letters, numbers, spaces, punctuation, Unicode, and emoji. Required and length validation are opt-in. It adds no character filters or default length limits.

```dart
import 'package:flutter/material.dart';
import 'package:smart_field_kit/smart_field_kit.dart';
SmartField(
  label: 'Full Name',
  hintText: 'Enter your name',
)
```

## Description and multiline text

`SmartField.description()` is a free-form native multiline field for notes, explanations, support messages, product descriptions, comments, and similar text. It accepts empty input, Unicode scripts, spaces, punctuation, numbers, symbols, apostrophes, line breaks, and emoji by default. It does not trim, capitalize, filter, or impose a text-length rule.

```dart
SmartField.description(
  label: 'Description',
  hintText: 'Enter details',
)
```

The description starts at three visible lines with `minLines: 3`, uses `maxLines: null`, and grows and shrinks through Flutter's native `TextFormField` layout as newlines, wrapping, and pasted paragraphs change. Enter inserts a newline by default. Existing constructors remain one line unless configured otherwise.

Set a finite `maxLines` to stop outer growth and scroll internally without losing content:

```dart
SmartField.description(
  label: 'Notes',
  minLines: 3,
  maxLines: 8,
)
```

With `maxLines: null`, growth continues only while the parent layout permits it. A fixed-height or otherwise bounded parent can cap the field and cause internal scrolling. `expands: true` is different from automatic growth: it fills a bounded parent's available height and requires explicit `minLines: null` and `maxLines: null`.

```dart
SizedBox(
  height: 240,
  child: SmartField.description(
    minLines: null,
    maxLines: null,
    expands: true,
  ),
)
```

Requiredness, grapheme-aware validation lengths, custom validation, and formatters remain opt-in. Line-break characters count as user-visible characters for `minLength` and `maxLength`; these rules report errors and do not truncate input.

```dart
SmartField.description(
  label: 'Additional notes',
  isRequired: true,
  minLines: 3,
  maxLines: 6,
  minLength: 10,
  validator: (value) {
    if ((value ?? '').contains('FORBIDDEN_APP_SPECIFIC_VALUE')) {
      return 'Please revise this note';
    }
    return null;
  },
)
```

The original `description` and `formfield` rules are available only as legacy presets. They preserve their exact expression and metadata:

```dart
SmartField.description(
  label: 'Legacy description',
  validationPreset: SmartTextValidationPreset.description,
)
SmartField.text(
  label: 'Legacy form field',
  validationPreset: SmartTextValidationPreset.formfield,
)
```

```text
"description": {
  "expression": "^.{3,}$",
  "comment": "any chars, at least 3",
  "error_lbl": "msg_money_transfer_services"
},
"formfield": {
  "expression": "^.{3,}$",
  "comment": "any chars, at least 3",
  "error_lbl": "lbl_provide"
}
```

Under Dart's default regular-expression behavior, `.` does not match a newline. A multiline value can therefore fail either legacy preset even when it contains three or more visible characters. The expression is intentionally not rewritten with `dotAll`; use `minLength` or a custom validator for a multiline minimum. The legacy `errorLabel` values are identifiers rather than translated messages, and `validationPresetErrorText` supplies an application-owned visible message.

Description validation follows required → selected legacy preset → configured length rules → custom validator. Input validation is not SQL-injection or XSS protection. Applications remain responsible for parameterized database queries, contextual output encoding, safe rendering, authorization, and trusted server-side validation.

## Name and username

`SmartField.name()` uses Flutter's name keyboard, word-capitalization suggestion, and name autofill hint. It does not change capitalization or rewrite stored text. International names, non-Latin scripts, combining marks, spaces, apostrophes, hyphens, punctuation, and emoji remain available by default with no minimum or maximum length.

```dart
SmartField.name(
  label: 'Full name',
)
```

`SmartField.username()` uses the normal text keyboard and username autofill hint with automatic capitalization, autocorrect, and suggestions disabled. It preserves exact case and characters. No default username length, allowed-character, lowercase, or uniqueness policy is imposed.

```dart
SmartField.username(
  label: 'Username',
  isRequired: true,
)
```

Applications can add their own `validator`, `minLength`, `maxLength`, error messages, autofill hints, and `inputFormatters`. Input formatters are opt-in because they can reject text while typing. Backend systems remain responsible for username uniqueness, authorization, SQL safety, output encoding, and impersonation controls.

The five original ASCII-only rules are available through the optional `validationPreset` parameter:

```dart
SmartField.username(
  label: 'Legacy username',
  validationPreset: SmartTextValidationPreset.loginUsername,
  validationPresetErrorText: 'Use at least five letters or numbers',
)
```

Validation runs in this order: required, selected preset, configured length rules, then the custom validator. Presets report errors without filtering or rewriting the field text. Their `errorLabel` values preserve legacy identifiers and are not translated user-facing messages.

```text
"login_username": {
  "expression": "^[a-zA-Z0-9]{5,}$",
  "comment": "at least 5 chars alphanumeric",
  "error_lbl": "lbl_username"
},
"beneficiary_nickname": {
  "expression": "^[a-zA-Z0-9]{3,}$",
  "comment": "At least 3 chars alphanumeric",
  "error_lbl": "beneficiary_nickname"
},
"min_text_field": {
  "expression": "^[a-zA-Z]{1,}$",
  "comment": "at least 1 chars",
  "error_lbl": "lbl_provide"
},
"street_name": {
  "expression": "^[a-zA-Z]{1,}$",
  "comment": "at least 1 chars",
  "error_lbl": "lbl_provide"
},
"alphanumeric_3": {
  "expression": "^[a-zA-Z0-9]{1,}$",
  "comment": "at least 1 chars alphanumeric",
  "error_lbl": "lbl_provide"
}
```

- `loginUsername` accepts only ASCII letters and digits with a minimum of five characters.

- `beneficiaryNickname` accepts only ASCII letters and digits with a minimum of three characters.

- `minTextField` and `streetName` accept one or more ASCII letters, rejecting spaces, digits, apostrophes, accents, and hyphens. They are too restrictive for many modern names and streets and are never defaults.

- `alphanumeric3` accepts one or more ASCII letters or digits. Despite its legacy key suggesting three, its exact expression has a minimum of one.

## Email addresses

`SmartField.email()` uses Flutter's email keyboard and autofill hint, disables autocorrect, and applies no capitalization. Empty input remains optional unless `isRequired` is enabled. The default policy accepts practical formats including plus-addressing and subdomains without changing the stored value.

```dart
SmartField.email(
  label: 'Email Address',
  isRequired: true,
)
```

The optional legacy policy preserves the supplied `email_address` rule exactly. It is intentionally narrower than the default policy and rejects addresses containing subdomains.

```dart
SmartField.email(
  label: 'Legacy Email',
  policy: SmartEmailPolicy.legacy,
)
```

Original legacy preset:

```text
"email_address": {
  "expression": "^[A-Za-z0-9][A-Za-z0-9.!#$%&'\*+\\\\-/=?^_\`{|}\~]\*@[A-Za-z0-9-]+\\\\.[A-Za-z]+$",
  "comment": "valid email address",
  "error_lbl": "lbl_provide"
}
```

The default email validator is intentionally practical rather than a complete implementation of every valid internationalized or quoted email-address form. No global email length limit is imposed. Configure `minLength` or `maxLength` only when the application requires them.

## Passwords

`SmartField.password()` obscures text by default, uses Flutter's password keyboard and autofill hint, and disables capitalization, autocorrect, and keyboard suggestions. Its accessible show/hide control can be removed with `showVisibilityToggle: false`. Toggling visibility does not change the password, selection, controller, or focus.

No complexity or length rule is enabled by default. Empty input remains optional unless `isRequired` is enabled.

```dart
SmartField.password(
  label: 'Password',
  isRequired: true,
)
```

The supplied legacy policies are explicitly opt-in:

```dart
SmartField.password(
  label: 'Password',
  isRequired: true,
  policy: SmartPasswordPolicy.strong,
)
```

Validation runs in this order: required, selected password policy, configured length limits, then the custom validator. The first error is displayed. Password text is never trimmed, replaced, or filtered.

Original legacy presets:

```text
"login_password_weak": {
  "expression": "^.{5,}$",
  "comment": "any chars, at least 6",
  "error_lbl": "msg_confirm_password"
},
"login_password": {
  "expression": "^(?=.\*?[A-Z])(?=(.\*[a-z]){1,})(?=(.\*[\\\d]){1,})(?=(.\*[\\\W]){1,})(?!.\*\\\s).{8,}$",
  "comment": "Password should have,at least a upper case letter, a lower case letter, a digit, a special character [@#$%^&+=] length of at least 4no white space allowed",
  "error_lbl": "msg_confirm_password"
}
```

The weak expression accepts five or more characters even though its comment says six. The strong expression requires at least eight characters even though its comment says four. The expressions and metadata are preserved without correcting those mismatches.

## Numbers and integer text

`SmartField.number()` accepts normal multi-digit integers, `0`, leading zeros, deletion, selection, and paste. It does not convert the text to an integer, so identifier-like values such as `000123` remain unchanged. Negative values, length limits, numeric value limits, and required validation are opt-in.

```dart
SmartField.number(
  label: 'Quantity',
)
```

Numeric bounds use exact decimal strings and do not use `double` arithmetic:

```dart
SmartField.number(
  label: 'Quantity',
  allowNegative: true,
  minValue: '-100',
  maxValue: '1000000000000000000000000000000',
)
```

The optional legacy policy preserves the supplied rule exactly:

```dart
SmartField.number(
  policy: SmartNumberPolicy.legacy,
)
```

```text
"number": {
  "expression": "^[0-9]$",
  "comment": "8 digits",
  "error_lbl": "lbl_phone_8"
}
```

The expression accepts exactly one digit although its comment says eight. Normal number fields use the multi-digit standard policy.

## URLs

`SmartField.url()` checks URL **syntax only**. It never opens, fetches, resolves, or previews a URL, and a syntactically valid URL is not proof that a site exists or is safe.

```dart
SmartField.url(label: 'Website', hintText: 'https://example.com')
SmartField.url(
  label: 'Company website',
  isRequired: true,
  allowedSchemes: const {'https'},
  validator: (value) =>
      value!.contains('blocked.example') ? 'This website is not allowed.' : null,
)
SmartField.url(label: 'Website or domain', allowBareDomain: true)
```

- Optional by default; empty input is valid. No length or value limit is applied unless `minLength`/`maxLength` are set.

- Uses `TextInputType.url`, `TextInputAction.done`, no capitalization, autocorrect, or suggestions.

- Text is never edited: no trimming, lowercasing, encoding, scheme prefix, or slash normalization. The controller, `onChanged`, `onSaved`, and validators receive exactly what was entered. Typing is never blocked; use `inputFormatters` for input restrictions.

- By default a nonempty value must be an absolute `http://` or `https://` URL with a well-formed host. Leading/trailing or embedded whitespace, control characters, `<`, `>`, `"`, `\\`, malformed `%` escapes, invalid ports, missing hosts, and other schemes (`javascript:`, `data:`, `file:`, `ftp:`, `mailto:`) are rejected.

- Accepted hosts include subdomains, `localhost`, intranet names, IPv4, bracketed IPv6, and non-default ports. No TLD, hostname length, or public-internet rule is imposed. Unicode hosts and paths are accepted as typed and are not converted to Punycode. IPv4-looking hosts must have octets of 255 or less. `user:pass@host` is syntactically accepted; treat such values as sensitive.

- `allowedSchemes` replaces the permitted schemes, for example `{'https'}`. Added schemes still need a valid authority.

- `allowBareDomain: true` also accepts `example.com`, `example.com:8080/path`, IPv4, and bracketed IPv6 without a scheme. A bare host needs a dot (so `localhost` needs `http://`) and cannot contain `@`. The text is never prefixed with `https://`; your app must decide how to resolve it.

- `urlErrorText` overrides the message. Validation order: required, URL syntax, configured length rules, custom validator.

- `SmartValidators.url()` and `SmartUrlValidation.isValid()` provide the same check without the widget.

If your backend later fetches submitted URLs, enforce a server-side URL policy and defend against SSRF, redirects, and DNS rebinding. Syntax validation does not prevent those attacks. URLs may contain tokens, so avoid logging full values.

## Search with debounce

`SmartField.search()` is a native single-line search input. It uses the Material search keyboard action, provides a decorative search icon, and shows an accessible clear action only while editable text is present. It has no built-in search engine, network request, results list, history, or default text restriction.

```dart
SmartField.search(
  label: 'Search',
  hintText: 'Search products',
)
```

`onChanged` receives user edits immediately. `onSearch` is an optional debounce event: when it is provided, its default quiet period is 300 milliseconds. Set `debounceDuration: Duration.zero` for an immediate event. Blank and whitespace-only queries do not emit `onSearch`, but their original text remains unchanged and is delivered to `onChanged`. Focus loss does not cancel a pending debounce; clear, submit, disposal, disabled updates, callback changes, controller replacement, and Form reset do.

```dart
SmartField.search(
  hintText: 'Search customers',
  debounceDuration: const Duration(milliseconds: 400),
  onChanged: (query) {},
  onSearch: (query) {},
  onSubmitted: (query) {},
)
```

`onSubmitted` runs immediately for the keyboard Search action and cancels any pending debounce without sending another `onSearch`. `onCleared` runs only when the built-in clear button is tapped; Backspace to empty is an ordinary `onChanged('')` edit. Programmatic controller changes update the field without calling `onChanged`, `onSearch`, or `onSubmitted`.

The application owns loading and request state. `isLoading` only displays a compact progress indicator; it does not make, cancel, or track requests. Controllers and focus nodes supplied by the application remain application-owned.

```dart
class SearchExample extends StatefulWidget {
  const SearchExample({super.key});
  @override
  State<SearchExample> createState() => _SearchExampleState();
}
class _SearchExampleState extends State<SearchExample> {
  final searchController = TextEditingController();
  bool isSearching = false;
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return SmartField.search(
      controller: searchController,
      hintText: 'Search orders',
      isLoading: isSearching,
      onSearch: (query) {},
      onCleared: () {},
    );
  }
}
```

Set `showClearButton: false`, `searchIcon: null`, or `clearIcon: null` to remove the corresponding built-in affordance. A decoration `prefixIcon` or `suffixIcon` remains available for application-specific customization. Requiredness, length rules, custom validation, input formatters, Form save/reset, themes, and Material 3 behavior use the shared SmartField contract.

## OTP input

`SmartField.otp()` is a native Flutter verification-code input backed by one `EditableText`, one controller, and one focus node. It displays separate boxes while preserving native selection, replacement, deletion, keyboard paste, controller updates, autofill, and `Form` behavior. It uses six visible ASCII digits by default, remains optional, and does not read SMS, email, or WhatsApp messages.

```dart
SmartField.otp(
  label: 'Verification code',
  onCompleted: (code) {
    verify(code);
  },
)
```

Set a positive custom length when needed. Invalid lengths throw `ArgumentError`.

```dart
SmartField.otp(
  length: 4,
  isRequired: true,
  obscureText: true,
)
```

OTP-specific options:

| Option | Behavior |

|---|---|

| `length` | Positive exact OTP length. Defaults to `6`. |

| `obscureText` | Replaces displayed digits with bullets without changing the controller value. |

| `policy` | Selects standard validation or the opt-in six-digit legacy rule. |

| `digitErrorText` | Customizes the non-ASCII-digit error. |

| `otpLengthErrorText` | Customizes the exact-length error. |

| `legacyErrorText` | Customizes the legacy-policy error. |

| `errorText` | Displays a parent-controlled server error until the parent clears it. |

| `onCompleted` | Receives locally valid values on incomplete-to-complete transitions. |

| `notifyOnProgrammaticChanges` | Allows controller-driven changes to call `onChanged` and `onCompleted`. Defaults to `false`. |

| `style` | Supplies optional box and state styling through `SmartOtpStyle`. |

The common `SmartField` options for label, hint, controller, focus node, autofocus, enabled/read-only state, keyboard action, `onChanged`, `onSaved`, required validation, additional length validation, custom validator, autovalidation, and decoration remain available. For OTP rendering, `decoration` supplies label, hint, error, and their text styles; `SmartOtpStyle` controls the boxes.

The default input formatter accepts only a complete ASCII-digit edit up to the configured length. A malformed or oversized paste is rejected as a whole instead of removing selected characters. Leading zeros are preserved. Programmatic controller updates refresh the boxes and validation but do not call `onChanged` or `onCompleted` by default, matching Flutter's user-change callback convention. Set `notifyOnProgrammaticChanges: true` when controller-driven changes should call both callbacks.

`onCompleted` runs only when the value transitions from incomplete or invalid to complete and locally valid. Rebuilds do not repeat it. Deleting a digit and completing the code again creates a new completion transition. The callback uses the unchanged controller text.

Validation order is required, ASCII digits, exact OTP length, optional legacy policy, developer length rules, then the custom validator. Parent-owned server errors stay visible until the parent clears them:

The reusable `SmartValidators.otp(length: 6)` validator provides the same optional-empty, ASCII-digit, exact-length, and selected-policy checks without the widget. Its `digitMessage`, `lengthMessage`, and `legacyMessage` parameters customize errors.

```dart
SmartField.otp(
  errorText: verificationError,
)
```

The supplied legacy rule is opt-in and requires `length: 6`. Selecting it with another length throws `ArgumentError`.

```dart
SmartField.otp(
  policy: SmartOtpPolicy.legacy,
)
```

```text
"opt_token": {
  "expression": "^[0-9]{6}$",
  "comment": "6 digits",
  "error_lbl": "lbl_token_needed"
}
```

Use `SmartOtpStyle` to configure box dimensions, spacing, borders, radius, fill colors, digit text, cursor color, and transition timing. Unset colors come from the active theme, and animations are disabled when the platform requests reduced motion.

`SmartOtpStyle` exposes `boxWidth`, `boxHeight`, `spacing`, `borderWidth`, `focusedBorderWidth`, `borderRadius`, `borderColor`, `focusedBorderColor`, `filledBorderColor`, `errorBorderColor`, `disabledBorderColor`, `fillColor`, `focusedFillColor`, `filledFillColor`, `errorFillColor`, `disabledFillColor`, `textStyle`, `cursorColor`, `animationDuration`, and `animationCurve`.

```dart
SmartField.otp(
  style: const SmartOtpStyle(
    boxWidth: 52,
    boxHeight: 60,
    spacing: 10,
    borderRadius: BorderRadius.all(Radius.circular(16)),
  ),
)
```

The control exposes one semantic text field, supports RTL and text scaling, and shrinks boxes and spacing to avoid horizontal overflow. WhatsApp codes can be pasted by the user or assigned through an app-owned controller; the package requests no message permissions and performs no message retrieval.

## Common options

| Option | Behavior |

|---|---|

| `label` | Fills the decoration label when the supplied decoration has no label. |

| `hintText` | Fills the decoration hint when the supplied decoration has no hint. |

| `controller` | Uses a developer-owned `TextEditingController`. A field manages its internal controller when omitted. |

| `focusNode` | Uses a developer-owned `FocusNode`. Flutter manages focus internally when omitted. |

| `autofocus` | Uses Flutter's native autofocus behavior. Defaults to `false`. |

| `enabled` | Uses Flutter's normal enabled state. `null` keeps the native default. |

| `readOnly` | Uses Flutter's read-only behavior. Defaults to `false`. |

| `keyboardType` | Forwards the requested `TextInputType`. |

| `textCapitalization` | Forwards native text capitalization behavior. |

| `autocorrect` | Enables native autocorrection for normal fields by default. |

| `enableSuggestions` | Enables native keyboard suggestions for normal fields by default. |

| `autofillHints` | Forwards native platform autofill hints. |

| `textInputAction` | Forwards the requested keyboard action. |

| `minLines` | Sets the native minimum visible line count. It does not validate text length. |

| `maxLines` | Sets the native maximum visible line count. `null` allows growth up to parent constraints. |

| `expands` | Fills a bounded parent's height and requires both line settings to be `null`. |

| `inputFormatters` | Applies only developer-supplied native input formatters. |

| `onChanged` | Receives native user-initiated text changes. |

| `onSaved` | Runs when the surrounding `Form` is saved. |

| `isRequired` | Rejects null, empty, and whitespace-only values when `true`. Defaults to `false`. |

| `requiredErrorText` | Sets the required-field error message. |

| `minLength` | Sets an optional minimum user-visible character count. |

| `minLengthErrorText` | Sets the minimum-length error message. |

| `maxLength` | Sets an optional maximum user-visible character count without filtering input. |

| `maxLengthErrorText` | Sets the maximum-length error message. |

| `validator` | Runs after required and length validation when supplied. |

| `autovalidateMode` | Uses Flutter's native automatic validation behavior. |

| `decoration` | Customizes the native `InputDecoration`. Defaults to an empty decoration. |

`label` and `hintText` fill missing values in `decoration`. Values already supplied by `decoration` take precedence.

Controllers and focus nodes supplied by the developer remain developer-owned and must be disposed by their owner. When they are omitted, Flutter's native `TextFormField` lifecycle applies.

## Standard text-field options

The default, `text`, `description`, `email`, `url`, `name`, `username`, `phone`, `password`, `number`, `percentage`, and `amount` constructors accept these optional Flutter options. Leaving them out keeps the previous behaviour.

| Parameter | Notes |
|---|---|
| `initialValue` | Starting text when you do not pass a `controller`. Passing both fails an assertion, as in `TextFormField`. `FormState.reset` returns to it. Amount fields format it for display |
| `onFieldSubmitted` | Called with the text when the keyboard action is pressed |
| `onEditingComplete` | Replaces Flutter's default editing-complete behaviour, as in `TextFormField` |
| `onTap`, `onTapOutside` | Passed to the underlying field |
| `style` | Text style of the input. Ignored while a privacy mask is shown |
| `textAlign`, `textDirection` | Override the defaults, including the left-to-right default of digit fields |
| `obscuringCharacter` | `SmartField.password` only |

`SmartField.search` accepts the same options except `onFieldSubmitted` and `onTap`, because it already has `onSubmitted` and `onTap`. The OTP, credit-card, date, time, and date-time constructors do not take these options. `contextMenuBuilder` and `maxLengthEnforcement` are not exposed.

## Email whitespace

With the standard policy, validation ignores spaces before and after the address, and `onSaved` receives the trimmed address. The text in the field and in your controller is not rewritten, and `onChanged` reports it as typed. The legacy policy is unchanged and still rejects surrounding spaces.

## OTP paste and overwrite

Spaces, hyphens, and non-breaking spaces in pasted text are removed, so `123 456` and `123-456` fill a six-digit field. Extra digits beyond the configured length are dropped. Text containing any other character is rejected as before. When every box is filled, tapping a box and typing a digit replaces that digit. `onCompleted` is called once for each distinct complete code, including a code produced by replacing a digit.

## Number formatter export

`SmartNumberInputFormatter` is exported from `package:smart_field_kit/smart_field_kit.dart` for use on your own `TextField`.
