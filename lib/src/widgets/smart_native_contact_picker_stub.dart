final class SmartNativeContactSelection {
  const SmartNativeContactSelection(this.phoneNumber);

  final String? phoneNumber;
}

Future<SmartNativeContactSelection?> selectNativePhoneNumber() {
  throw UnsupportedError(
    'The native contact picker is not available on this platform.',
  );
}
