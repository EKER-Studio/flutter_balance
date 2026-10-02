# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

---

## [1.3.1] — 2026-10-02

### Added
- **Home Screen Widget Tip:** Added a dismissible recommendation card on the Today screen reminding users on supported devices to pin the quick-access Balance widget.

### Fixed
- **Biometric Lock Grace Period:** Added a 30-second grace period in `BiometricLockObserver` preventing disruptive re-authentication prompts during brief app switcher transitions or incoming system notifications.
- **Onboarding Height Input Stability:** Sanitized decimal separators across locales (`.` and `,`) and ensured inline range errors only surface upon form submission rather than during typing.

---

## [1.3.0] — 2026-09-30

### Added
- **Privacy & Diagnostics in Onboarding:** Dedicated onboarding wizard step allowing users to opt into anonymous usage analytics (Firebase Analytics) and crash reporting (Firebase Crashlytics), adhering to privacy-by-default (opt-in) across all 10 supported languages.
- **Native Home Widget Localization:** Dynamic localization for header titles, BMI categories, dates, and goal achievement statuses in Android and iOS home screen widgets (`WidgetSyncService`).
- **Tests & Screenshot Fixtures:** Unit tests for privacy step widget, updated wizard integration tests, screenshot generators, and golden screenshot fixtures for settings screen.

### Changed
- **Android 15 Edge-to-Edge Compliance:** Removed deprecated `LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES` from native styles, updated `androidx.activity:activity-ktx` to 1.10.1 with full support for Android 15 edge-to-edge window insets, and compiled against Android SDK 37.
- **Linter & Code Optimization:** Enforced compile-time `const` constructors and immutable literals, optimized 94 widget declarations across the app, and removed legacy switch break statements per Dart 3 standards.
- **Telemetry Sanitization:** Sanitized analytics event parameters to completely exclude sensitive health and routine values, logging only high-level error types and diagnostics.

---

## [1.2.0] — 2026-09-18

### Security
- **Secure Hardware Storage:** Anchored Isar database encryption key exclusively within hardware-backed secure storage (`flutter_secure_storage` via Android Keystore / iOS Keychain) with automatic quarantine/removal of legacy plaintext files. Added vulnerability disclosure policy in `SECURITY.md`.

### Changed
- **Clean Architecture & Decoupling:** Decoupled `OnboardingBloc` from sibling BLoCs via presentation-layer event orchestration. Extracted `BmiCalculator` domain service unifying BMI calculations across the app. Relocated CSV services to domain and integration layers, and `AppThemeMode` to the core layer.
- **Android App Bundle Release:** Configured production Android App Bundle (AAB) target with R8 code obfuscation and automated debug symbols (`mapping.txt`) upload.
- **Code Quality & Crash Reporting:** Replaced raw `debugPrint` calls with structured `AppCrashReporter` (Firebase Crashlytics) across bootstrap and async error boundaries.
- **CI/CD & Verification:** Integrated automated Android debug APK build verification into CI and `before_push.sh`, enforced strict static analysis linter rules, and optimized `build.yaml` and `dart_test.yaml`.
- **Store Metadata & Screenshots:** Configured complete Fastlane Supply metadata, refreshed localized Play Store screenshots across 10 locales, and added high-res feature graphics.
- **Localization:** Externalized remaining hardcoded UI strings in settings screens and configured untranslated strings tracking.
- **AI-Native Engineering:** Added comprehensive Flutter + Riverpod + Isar deep architecture audit prompt to the `prompts/` suite.

---

## [1.1.1] — 2026-09-04

### Security
- **Security Hardening:** Hardened backup rules (hardware key exclusion), improved biometric error handling, and ignored signing artifacts.

### Changed
- **Accessibility:** Enforced 48dp minimum touch targets across all interactive elements.
- **Navigation:** Wired dead routes and handled unlistened BLoC states.
- **Data Layer:** Optimized Isar queries for date ranges using indexed `where` clauses.
- **BLoC State Management:** Replaced `context.read` with `context.watch`/`select` inside `build` methods.
- **Statistics View:** Handled `WeightError` gracefully with cached entries and empty state fallback.
- **Localization:** Removed dead translation keys `chartSemanticsTitle` and `yesterday`.
- **Configuration:** Excluded generated l10n files from analyzer and corrected `before_push.sh` path.

---

## [1.1.0] — 2026-08-28

### Added
- **WHO BMI Classification:** Expanded to 6 official WHO BMI categories with personalized healthy weight range calculation.
- **Enhanced Charts & Trends:** Cleaner chart scales and interactive trend chips for instant category insights.
- **Refreshed Calendar:** Improved month view with multi-entry day cards and seamless inline editing.
- **Polished Onboarding:** Streamlined setup flow with clearer initial weight and reminder configuration.
- **Privacy & Security:** Native in-app Privacy Policy and enhanced biometric lock protection.

### Changed
- **Performance & Stability:** Improved health sync reliability, smoother transitions, and minor bug fixes.

---

## [1.0.0] — 2026-08-20

### Added
- **Initial Release:** First production release on Google Play Store.
- **Design System:** Modern UI with full light and dark mode support.
- **Adaptive Layout:** Responsive layout tailored for mobile phones and tablets.
- **Local-First Persistence:** 100% local-first encrypted storage with offline reliability via Isar Database.
