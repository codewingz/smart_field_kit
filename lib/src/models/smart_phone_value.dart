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

enum SmartPhonePickerErrorCode {
  unsupportedPlatform,
  unavailableNumber,
  invalidNumber,
  disallowedCountry,
  platformFailure,
}

class SmartPhonePickerError {
  const SmartPhonePickerError(this.code, this.message, [this.cause]);

  final SmartPhonePickerErrorCode code;
  final String message;
  final Object? cause;
}

typedef SmartPhoneChanged = void Function(SmartPhoneValue value);
typedef SmartPhoneCountryChanged = void Function(SmartPhoneCountry? country);
typedef SmartPhoneContactPicker = Future<String?> Function();
