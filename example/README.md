# smart_field_kit example

An interactive showcase for the `smart_field_kit` package. It imports only `package:smart_field_kit/smart_field_kit.dart` and needs no API keys, accounts, or network.

```sh
flutter pub get
flutter run
```

Pages: Text, Passwords, Phone, Numbers, OTP & search, Validation (modes, async, server errors), Cards & dates, Design, and Utilities. Resize the window to see the phone, tablet, and desktop layouts; the Design page toggles light/dark, RTL, and text scale. Card examples use synthetic numbers only; nothing entered is stored or logged.

Tests: `flutter test`. Screenshots in the repository's `screenshots/` folder were captured from the running web build with `tool/capture_screenshots.js` (Playwright against Chrome; the script expects the web build served on port 8765).
