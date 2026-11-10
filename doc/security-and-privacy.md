# Security and privacy

Part of the [smart_field_kit documentation](../README.md).


**This is a client-side input library, not a security framework.** Keep these responsibilities separate:

| Feature | The package helps with | Your application must still do |
|---|---|---|
| Passwords | Hide input, optional policies and strength hints | Secure authentication, hashing on the server, rate limiting, safe secret handling |
| OTP | Visual entry, validation, completion callback | Generate and verify codes on the server, expiration and retry controls |
| Credit cards | Brand/length/checksum, expiry, security-code format | Use a compliant payment processor and approved tokenization/hosted fields; never store CVV after authorization |
| Email/phone | Format or plausible number checks | Verify ownership, existence, and authorization |
| URL | Syntax checks only | Defend against malicious links and server-side URL fetching attacks such as SSRF |
| Masks | Hide portions of the display | Encrypt, authorize, store securely and avoid leaking values into logs or analytics |
| Async validation | Call your supplied checker at the right time, reject stale responses | Protect API endpoints and treat all remote results as untrusted |

**Card-checking details:** Luhn is a local checksum and does not authenticate a card. UnionPay is exempt from Luhn by default in the reported implementation; `luhnExemptBrands: const {}` opts into checking it. Unknown brands and co-branded prefixes are handled cautiously. RuPay is not explicitly supported in the reported card-brand table. Actual card details must never be used as tests.

**Debugging:** The package reported redaction for its own card-related diagnostics. Application-owned controllers, error reporting, analytics, crash dumps, and custom callbacks can still leak values if an application logs them. Avoid printing values from `onChanged`, `onSaved`, or async validators for secret fields.

**Contacts and SMS:** The package does not request SMS permissions and does not read messages. Its optional native contact picker is not a bulk address-book reader; actual operating-system behavior should still be verified on target devices.

**Backends:** Use server-side validation, authorization, prepared/parameterized SQL statements, safe output encoding, rate limiting, and secure transport as required by your application. Filtering a text field is not SQL injection or XSS protection.
