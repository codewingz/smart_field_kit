# Validation

Part of the [smart_field_kit documentation](../README.md).

## Synchronous Flutter Form validation

Validation runs in this order: required, minimum length, maximum length, then the custom validator. The first error is displayed. Optional blank values skip length validation. Length validation uses Unicode grapheme clusters, so a visible emoji is counted as one character.

```dart
final formKey = GlobalKey<FormState>();
Form(
  key: formKey,
  child: SmartField(
    label: 'Display name',
    isRequired: true,
    requiredErrorText: 'Enter a display name',
    minLength: 2,
    maxLength: 50,
    validator: (value) {
      if (value == 'Unknown') {
        return 'Please enter a valid name';
      }
      return null;
    },
  ),
)
```

The field uses the inherited `ThemeData`, `InputDecorationTheme`, Material version, keyboard behavior, and `Form` lifecycle.

`SmartField.text()` is the named equivalent for general text and adds optional `validationPreset` and `validationPresetErrorText` parameters. Plain `SmartField()` and `SmartField.text()` remain single-line by default. Either can use the native `minLines`, `maxLines`, and `expands` options when a different layout is required.

## Four validation modes

Every constructor accepts `validationMode` and `builtInChecks`:

- `SmartValidationMode.both` (default): the field's built-in rule, then your `validator`.

- `SmartValidationMode.builtIn`: built-in rule only; your `validator` is ignored.

- `SmartValidationMode.custom`: only your `validator`; the built-in format rule is skipped.

- `SmartValidationMode.selected`: only the checks listed in `builtInChecks`, plus your `validator`.

Selectable checks: `fieldFormat` (the field's own format rule: email, URL, phone, number, amount, percentage, OTP, or the password policy) and the password rules `passwordUppercase`, `passwordLowercase`, `passwordDigit`, `passwordSpecialCharacter`, `passwordNoWhitespace`.

Required, `minLength`/`maxLength`, value limits, and word limits are opt-in parameters and apply in every mode. Order: required, built-in rules, length, value range, word limits, password match, your validator, then async validation (still explicit; await `validateAsync()` before submitting). Async checks never run when a synchronous check fails.

```dart
SmartField.password(
  label: 'Password',
  validationMode: SmartValidationMode.selected,
  builtInChecks: const {
    SmartBuiltInCheck.passwordUppercase,
    SmartBuiltInCheck.passwordDigit,
  },
  validator: (value) => value!.contains('password') ? 'Too common' : null,
)
```

## Legacy validation preset index

The repository preserves **14 original validation patterns** for backward compatibility. They are opt-in; ordinary text and names remain unrestricted unless configured. These legacy expressions and their metadata are shown in the relevant field sections above.

| Legacy rule | Behavior preserved | Important caveat |
|---|---|---|
| `description` | At least three regex `.` characters | A newline does not match `.` by default |
| `formfield` | At least three regex `.` characters | A newline does not match `.` by default |
| `login_username` | ASCII letters/digits, minimum five | Rejects Unicode characters |
| `beneficiary_nickname` | ASCII letters/digits, minimum three | Rejects spaces and punctuation |
| `min_text_field` | One or more ASCII letters | Does not accept accented letters |
| `street_name` | One or more ASCII letters | Not appropriate for most real-world street names |
| `alphanumeric_3` | One or more ASCII letters/digits | Its historic name suggests three, but its rule allows one |
| `email_address` | Original restricted email syntax | Narrower than modern email formats |
| `login_password_weak` | Five or more characters | Historic comment says six; pattern says five |
| `login_password` | Uppercase, lowercase, digit, special character, no whitespace, minimum eight | Historic comment and pattern disagree on length |
| `number` | Exactly one ASCII digit | Historic comment says eight digits |
| `amount_of_money` | ASCII digits and optional one/two fractional digits | Distinct from configurable modern decimal precision |
| `phone_number` | 7–15 ASCII digits | Not a universal numbering rule |
| `opt_token` | Exactly six ASCII digits | Only appropriate for six-digit OTPs |

Do not apply these patterns as automatic international validation rules. The legacy metadata snippets are shown as text because they are excerpts, not standalone JSON documents.

## Confirm password without a new field type

Use two `SmartField.password()` fields. The second names the first field's controller:

```dart
final password = TextEditingController();
SmartField.password(label: 'Password', controller: password)
SmartField.password(
  label: 'Confirm password',
  matchController: password,
  mismatchErrorText: 'Passwords do not match.',
)
```

An empty confirmation passes unless `isRequired` is set. The confirmation revalidates when the original changes (typing, programmatic changes, or `FormState.reset`) as long as it is not empty. Passwords are never logged or stored. `SmartValidators.matches()` is the standalone helper.

## Asynchronous validation

The supported text-input constructors accept an optional `asyncValidation:` configuration. The composite credit-card field uses its own validation and server-error APIs. The checker is your function; the package never makes network calls and cannot cancel your HTTP request. It only manages timing, state, and ignoring outdated results.

```dart
final formKey = GlobalKey<FormState>();
final usernameAsync = SmartFieldAsyncController();
SmartField.username(
  label: 'Username',
  isRequired: true,
  asyncValidation: SmartAsyncValidation(
    controller: usernameAsync,
    debounceDuration: const Duration(milliseconds: 400),
    validator: (value) async {
      final available = await usernameService.isAvailable(value);
      return available ? null : 'Username is already taken.';
    },
  ),
)
Future<void> submit() async {
  if (!formKey.currentState!.validate()) return;
  if (!await usernameAsync.validateAsync()) return;
  if (!formKey.currentState!.validate()) return;
  formKey.currentState!.save();
}
```

Create and dispose the `SmartFieldAsyncController` in your own state. Attach one controller to one field. Several async fields: `final results = await Future.wait([a.validateAsync(), b.validateAsync()]);` and submit only if all are true. Disable your submit button while submitting to prevent duplicate submissions.

`SmartAsyncValidation` options:

- `validator`: `Future<String?> Function(String raw)`; return `null` when valid or an error message.

- `trigger`: `onChanged` (default; debounced), `onUnfocus` (when focus leaves), or `manual` (only `validateAsync()`).

- `debounceDuration`: default 400 ms; `Duration.zero` checks immediately. Each edit restarts the wait.

- `timeout`: optional; a timeout counts as unavailable.

- `unavailableErrorText`, `loadingIndicator`, `loadingSemanticsLabel`: customize messages and the suffix indicator.

- `controller`: a `SmartFieldAsyncController` exposing `status`, `errorText`, and `validateAsync({force})`.

Status values: `idle`, `pending`, `valid`, `invalid`, `unavailable`.

- Order: required, field syntax and policies, length/value rules and your synchronous `validator`, then async. The checker is never called for empty or synchronously invalid values.

- The checker receives the raw value: the address without surrounding spaces for the standard email policy (the same value `onSaved` receives), otherwise the typed text, the normalized number for `.amount()` and `.percentage()` (no grouping, currency symbol, or `%`), and the unmasked text for masked fields. Phone fields pass the entered text.

- Any edit, clear, reset, controller replacement, or disabling discards the previous result and ignores late completions. When a controller replacement or disabling discards a result whose error is on screen, that error is removed and the field is validated again for its current value, without a new asynchronous request. A parent rebuild never discards a result or restarts a check, whether the `validator` is written inline or kept in a variable: a pending check finishes with the function it started with, and a completed result is kept until the value changes or you call `validateAsync(force: true)`. `validateAsync()` returns `false` if the value changed while it ran.

- A thrown error or timeout gives `unavailable` and the unavailable message; it never counts as valid. Calling `validateAsync()` again retries. An accepted or rejected value is cached until it changes; use `force: true` to ask again.

- `FormState.validate()` stays synchronous. It fails for a rejected or unavailable result of the current value and does not wait for a pending check, so await `validateAsync()` before submitting.

- When a developer chooses to validate a password or OTP asynchronously, the value is passed to the developer-supplied checker. The package does not itself send network requests or log the value. Treat the checker as handling sensitive data.

- Local checks are a convenience: always validate again on your server.

## Server-controlled errors

```dart
final serverError = SmartServerError();
SmartField.email(label: 'Email', serverError: serverError)
serverError.set('Email already registered');
final applied = await serverError.track(api.checkEmail(value));
serverError.clear();
```

The message uses the normal error UI and semantics on every field, makes `FormState.validate()` fail while shown, and clears on the next user edit (`SmartServerError(clearOnChange: false)` keeps it until you call `clear()`). `track()` ignores a response when a newer `track`, `set`, or `clear` happened first, and returns whether it was applied. Dispose the object in your own state.

## Standalone validators

`SmartValidators` can be used independently of `SmartField`.

```dart
final validator = SmartValidators.compose([
  SmartValidators.requiredField(message: 'Value required'),
  SmartValidators.minLength(2),
  SmartValidators.maxLength(50),
]);
final error = validator('value');
```

Validation does not remove or rewrite input. Client-side validation is not SQL-injection protection; backend systems must use parameterized queries and trusted server-side validation.

## Password-strength feedback

```dart
SmartField.password(
  showStrengthIndicator: true,
  showStrengthChecklist: true,
  strengthCriteria: [
    SmartPasswordCriterion.minLength(10),
    SmartPasswordCriterion.digit,
    SmartPasswordCriterion('No spaces', (value) => !value.contains(' ')),
  ],
)
```

The indicator is optional, informational feedback (weak, fair, good, strong from the share of criteria met) with a polite live-region label such as `Password strength: Good`. With `showStrengthChecklist: true`, each rule is also exposed to screen readers as its own item, labelled with the rule's text and carrying a checked or not-checked state that follows the tick shown on screen; the platform reads that state in the user's language. A change of level is announced; a rule that changes without changing the level is not announced on its own and is read when the user moves to it. The password text is never part of these labels. It is separate from `policy`, `validationMode`, and validation; a password can be "strong" yet rejected by your policy and the reverse. Strength is computed locally from the field text on each change; nothing is logged, stored, or sent. `SmartPasswordStrength.evaluate()` runs without a widget.

## Changes to an async validator

The `validator` may be written inline in `build`. The package does not compare validator functions, so a rebuild with a new closure keeps the current result and makes no request. One typed value produces one call.

```dart
SmartField.username(
  asyncValidation: SmartAsyncValidation(
    controller: usernameAsync,
    validator: (value) => api.isUsernameFree(value, tenant: tenant),
  ),
)
```

The package cannot tell from the function that your rule changed (for example `tenant` above). Tell it in one of two ways.

Declare what the rule depends on with `revalidationKey`:

```dart
SmartAsyncValidation(
  controller: usernameAsync,
  revalidationKey: tenant,
  validator: (value) => api.isUsernameFree(value, tenant: tenant),
)
```

When a rebuild supplies a key that is not equal to the previous one, the completed result and any pending check are dropped: the message is removed, the status returns to `idle`, and `validateAsync()` no longer returns the old answer. With the `onChanged` trigger one new check then starts for the current value after the debounce. With `onUnfocus` and `manual` nothing is requested until the next trigger. A rebuild with an equal key changes nothing, and the default `null` keeps the behaviour described above.

Or ask again yourself:

```dart
setState(() => tenant = next);
await usernameAsync.validateAsync(force: true);
```

`validateAsync(force: true)` always makes one new request for the current value with the validator from the latest build. It replaces a completed result and a check that is still pending; the reply of the replaced check is ignored and its `validateAsync()` future completes with `false`. Until you call it, the previous result stays in place. If you pass a different validator function instead of changing what one function reads, call `validateAsync(force: true)` after the rebuild that supplies it, for example in `WidgetsBinding.instance.addPostFrameCallback`. With the `manual` and `onUnfocus` triggers a plain `validateAsync()` returns the cached result for an unchanged value, so use `force: true` there as well.

## Length rules and whitespace

`maxLength` counts every character, including a value made only of spaces. `minLength` and the legacy presets still treat a blank value as "not entered", which `isRequired` covers. `SmartPasswordCriterion.minLength` counts characters as users see them (grapheme clusters), the same as `SmartValidators.minLength`.
