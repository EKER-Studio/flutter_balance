# Security Policy

## Supported Versions

Only the latest released version of Balance receives security updates.

| Version | Supported          |
| ------- | ------------------ |
| 1.1.x   | :white_check_mark: |
| < 1.1   | :x:                |

## Reporting a Vulnerability

We take the security and privacy of user health data very seriously.

If you believe you have discovered a security vulnerability in Balance, please do NOT create a public issue on GitHub. Instead, report it privately:

1. Send an email to **security@ekerstudio.com** (or open a private security advisory on GitHub).
2. Include a detailed description of the vulnerability, steps to reproduce, and potential impact.
3. Allow up to 48 hours for an initial response from the development team.
4. We will coordinate a fix and release before any public disclosure.

## Security Architecture Highlights

- **Local-First & Offline:** Health data (weight records, heights, notes) never leaves the device unless explicitly exported by the user.
- **AES-256 Field Encryption:** Weight values and notes are encrypted with AES-256 before they are written to Isar; encryption keys are isolated in platform-native hardware keychains (Android Keystore / iOS Keychain). The Isar database file itself is not encrypted, and record IDs plus measurement timestamps remain stored in plaintext to support indexed queries.
- **Local Settings:** UI preferences persisted through `HydratedBloc` (including height and target weight) are stored unencrypted on the device and are not covered by the field-level encryption above.
- **Privacy-First Analytics:** Telemetry events never log sensitive biometric or health indicators (weight values, BMI, target goals).
