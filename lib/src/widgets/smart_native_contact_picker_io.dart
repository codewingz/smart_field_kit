import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';

final class SmartNativeContactSelection {
  const SmartNativeContactSelection(this.phoneNumber);

  final String? phoneNumber;
}

Future<SmartNativeContactSelection?> selectNativePhoneNumber() async {
  final contact = await FlutterNativeContactPicker().selectPhoneNumber();
  if (contact == null) {
    return null;
  }
  return SmartNativeContactSelection(contact.selectedPhoneNumber);
}
