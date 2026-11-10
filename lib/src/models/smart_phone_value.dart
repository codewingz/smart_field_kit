/// A country that can be selected for a phone field.
class SmartPhoneCountry {
  const SmartPhoneCountry({
    required this.isoCode,
    required this.name,
    required this.dialCode,
    required this.flagEmoji,
  });

  final String isoCode;
  final String name;
  final String dialCode;
  final String flagEmoji;

  @override
  bool operator ==(Object other) {
    return other is SmartPhoneCountry && other.isoCode == isoCode;
  }

  @override
  int get hashCode => isoCode.hashCode;
}

/// The parsed state of a phone field. [e164] is set only when [isValid].
class SmartPhoneValue {
  const SmartPhoneValue({
    required this.text,
    required this.country,
    required this.nationalNumber,
    required this.e164,
    required this.isValid,
  });

  final String text;
  final SmartPhoneCountry? country;
  final String? nationalNumber;
  final String? e164;
  final bool isValid;
}

/// Why the contact picker did not return a number.
enum SmartPhonePickerErrorCode {
  unsupportedPlatform,
  unavailableNumber,
  invalidNumber,
  disallowedCountry,
  platformFailure,
}

/// A contact-picker failure with a user-safe message.
class SmartPhonePickerError {
  const SmartPhonePickerError(this.code, this.message, [this.cause]);

  final SmartPhonePickerErrorCode code;
  final String message;
  final Object? cause;
}

/// Called with the parsed phone value after an edit or a country change.
typedef SmartPhoneChanged = void Function(SmartPhoneValue value);

/// Called when the selected country changes.
typedef SmartPhoneCountryChanged = void Function(SmartPhoneCountry? country);

/// Returns a phone number chosen by the user, or `null` when cancelled.
typedef SmartPhoneContactPicker = Future<String?> Function();
