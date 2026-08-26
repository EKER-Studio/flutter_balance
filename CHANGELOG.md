# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### 🚀 Architecture & Routing
- **Declarative Navigation:** Migrated to `go_router` utilizing `StatefulShellRoute.indexedStack` for persistent multi-tab state preservation and deep linking.
- **Dependency Injection:** Integrated automated compile-time DI container via `get_it` + `injectable`.
- **Domain Layer Purification:** Extracted pure domain services (`HealthSyncCoordinator`, `CsvWeightImporter`, `CsvErrorType`, `Failure` domain taxonomy).
- **Multi-Environment Isolation:** Separated debug and release environments (`AppEnvironment`), package names, bundle IDs, and Firebase configurations for Android and iOS.

### ✨ Features & UI Improvements
- **Onboarding Experience:** Built generic responsive `OnboardingStepLayout` with top-aligned content spacing and pinned bottom footers across all wizard steps.
- **WHO BMI Classification:** Upgraded to 6 World Health Organization BMI categories with personalized healthy weight range calculation.
- **Interactive BMI Legend:** Added modal dialog with active category highlighting and responsive scroll support.
- **Dynamic Charts:** Configured integer-aligned y-axis intervals and interactive trend delta chips that link directly to category details.
- **Goal Progress Enhancements:** Added interactive unset goal prompt state and visual achievement reward animations.
- **Calendar & History:** Redesigned month view grid, day entry cards, and note badge styling with multi-entry indicators (0–4+).
- **Settings & Help:**
  - Added native in-app **Privacy Policy** screen.
  - Added **Open Source Licenses** viewer.
  - Added **"View on GitHub"** direct link in the Help section.
  - Added optional helper text to `TargetWeightSheet`.
- **Statistics & Habits:** Refactored streaks and habits overview cards with Material 3 subtle iconography and localized date formatting.

### 🔒 Security, Privacy & Diagnostics
- **Privacy-Compliant Telemetry:** Implemented sanitized `AppAnalytics` wrapper guaranteeing zero sensitive health metrics (weights, heights, BMI) in analytics parameters.
- **Centralized Error Reporting:** Added `AppCrashReporter` with non-fatal crash boundaries and privacy filtering.
- **Database Backup & Migration:** Enabled native Android Auto Backup with portable key encryption and pre-import automatic database snapshots.
- **Health Sync Mirroring:** Synchronized measurement edits by updating outdated records in Apple HealthKit and Android Health Connect.

### 🛠 Tooling & CI/CD
- **CI Pipeline:** Added automated test coverage calculation with GitHub step summary reporting and coverage artifact uploads.
- **Flutter Engine:** Upgraded to Flutter `3.47.1`.
- **Documentation & Assets:** Added full 20-screenshot preview gallery and Google Play badge in `README.md`.

---

## [1.0.0] - 2026-08-20

### Added
- Complete UI redesign with light and dark mode support.
- Responsive layout adaptations for tablets and wide landscape orientations.
- Local-first encrypted storage powered by Isar NoSQL database.
- Initial release on Google Play Store.
