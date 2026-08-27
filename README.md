<p align="center">
  <img src=".github/balance-feature-graphic.png" alt="Balance — Smart BMI & Weight Tracker" width="100%" />
</p>

<h1 align="center">Balance</h1>

<p align="center">
  <strong>A local-first weight tracking application built with Flutter using Clean Architecture and BLoC.</strong>
</p>

<p align="center">
  <a href="https://play.google.com/store/apps/details?id=com.ekerstudio.balance">
    <img src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" height="60" alt="Get it on Google Play" />
  </a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.47.1-02569B?logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/Architecture-Clean%20%2F%20Feature--First-blue" alt="Architecture" />
  <img src="https://img.shields.io/badge/State-BLoC-blueviolet" alt="State Management" />
  <img src="https://img.shields.io/badge/Storage-Isar%20NoSQL-green" alt="Storage" />
  <img src="https://img.shields.io/badge/Platforms-iOS%20%7C%20Android-black" alt="Platforms" />
</p>

---

## Screenshots

### Splash & Onboarding Flow

| Splash (Dark) | Welcome (Light) | CSV Import (Light) | Starting Weight (Dark) | Daily Reminders (Dark) |
| :---: | :---: | :---: | :---: | :---: |
| <img src=".github/assets/00_splash/splash_dark.png" width="180" alt="Splash Screen Dark" /> | <img src=".github/assets/01_onboarding/01_welcome_light.png" width="180" alt="Onboarding Welcome Light" /> | <img src=".github/assets/01_onboarding/03_csv_import_light.png" width="180" alt="CSV Import Step Light" /> | <img src=".github/assets/01_onboarding/04_starting_point_dark.png" width="180" alt="Starting Weight Step Dark" /> | <img src=".github/assets/01_onboarding/06_notifications_dark.png" width="180" alt="Notifications Setup Dark" /> |

### Today Dashboard & Analytics

| Today Dashboard (Light) | Add Measurement (Dark) | BMI Categories (Dark) | Statistics Overview (Light) | Trend & BMI Analysis (Dark) |
| :---: | :---: | :---: | :---: | :---: |
| <img src=".github/assets/02_today/01_dashboard_light.png" width="180" alt="Today Dashboard Light" /> | <img src=".github/assets/02_today/02_add_measurement_dark.png" width="180" alt="Add Measurement Dark" /> | <img src=".github/assets/02_today/03_bmi_categories_dark.png" width="180" alt="BMI Categories Modal Dark" /> | <img src=".github/assets/04_statistics/01_overview_light.png" width="180" alt="Statistics Overview Light" /> | <img src=".github/assets/04_statistics/02_bmi_chart_dark.png" width="180" alt="Trend and BMI Analysis Dark" /> |

### Calendar & Reminders

| Calendar Month (Light) | Measurement Sheet (Light) | Calendar Month (Dark) | Scheduled Notification (Light) |
| :---: | :---: | :---: | :---: |
| <img src=".github/assets/03_calendar/01_month_view_light.png" width="180" alt="Calendar Month View Light" /> | <img src=".github/assets/03_calendar/02_add_measurement_sheet_light.png" width="180" alt="Add Measurement Sheet Light" /> | <img src=".github/assets/03_calendar/03_month_view_dark.png" width="180" alt="Calendar Month View Dark" /> | <img src=".github/assets/07_other/01_notification_light.png" width="180" alt="System Notification Banner" /> |

### Settings & Security

| Settings (Light) | CSV Import Preview (Dark) | Privacy Policy (Dark) | Biometric Shield (Light) | Biometric Auth (Dark) |
| :---: | :---: | :---: | :---: | :---: |
| <img src=".github/assets/05_settings/01_preferences_light.png" width="180" alt="Settings Preferences Light" /> | <img src=".github/assets/05_settings/02_csv_import_preview_dark.png" width="180" alt="CSV Import Preview Dark" /> | <img src=".github/assets/05_settings/03_privacy_policy_dark.png" width="180" alt="Privacy Policy Dark" /> | <img src=".github/assets/06_biometric/01_biometric_lock_light.png" width="180" alt="Biometric Lock Shield Light" /> | <img src=".github/assets/06_biometric/02_biometric_failed_dark.png" width="180" alt="Biometric Authentication Prompt Dark" /> |

---

## Architecture

Clean Architecture strictly organized under a **Feature-First** (vertical slice) layout:

```
lib/
├── app.dart                      # Root application widget (MaterialApp, theme, locale & providers)
├── main.dart                     # App entry point, splash preservation & crash reporting
├── firebase_options.dart         # Auto-configured Firebase credentials per platform
├── core/                         # Cross-cutting concerns & infrastructure
│   ├── config/                   # AppEnvironment (dev, prod configurations)
│   ├── database/                 # Database module & Isar initialization
│   ├── di/                       # Dependency injection setup via GetIt & Injectable
│   ├── errors/                   # Unified app error types & exception handlers
│   ├── integrations/             # Native platform & 3rd-party integration services
│   │   ├── biometrics/           # Local authentication (Face ID/Fingerprint) & lock observer
│   │   ├── csv/                  # CSV parser, validation & import/export pipelines
│   │   ├── health/               # Apple HealthKit & Android Health Connect sync service
│   │   └── notifications/        # Local scheduled notifications & timezone management
│   ├── models/                   # Core shared models (MeasurementUnit)
│   ├── presentation/             # Global app UI & shared design system
│   │   ├── navigation/           # AppRoutes and route definitions
│   │   ├── screens/              # AppSplashScreen, AppInitializationErrorScreen, BiometricShieldScreen
│   │   ├── theme/                # AppTheme (Light & Dark Material 3 tokens) & AppColors
│   │   └── widgets/              # Reusable components (AppTopBar, ClampedLayout)
│   └── utils/                    # Shared utilities (AppAnalytics, AppCrashReporter, AppBlocObserver)
├── features/                     # Feature modules (Feature-First architecture)
│   ├── calendar/                 # Calendar monthly view, day history & entry sheet
│   ├── dashboard/                # Today's overview, BMI gauge & quick-add weight cards
│   ├── navigation/               # Main navigation scaffold (BottomBar & NavigationRail)
│   ├── onboarding/               # 8-step initial setup wizard
│   ├── settings/                 # User preferences, reminders, backup, wipe data & privacy policy
│   ├── statistics/               # Analytical charts, BMI trend cards & period filters
│   └── weight/                   # Core weight tracking domain, data & state
│       ├── data/                 # WeightEntryModel (Isar schema) & IsarWeightRepository
│       ├── domain/               # WeightEntry entities, repository contracts & health sync coordinator
│       └── presentation/         # Shared WeightBloc, events, states & AddWeightSheet
└── l10n/                         # Localization ARB assets (app_en.arb, app_pl.arb)
```

### Design Principles

- **Local-first**: All weight entries persist on-device using Isar (`isar_community`). No cloud dependency.
- **Feature-First**: Strict vertical slicing. Features (`calendar`, `dashboard`, `settings`, etc.) encapsulate their own presentation boundaries, while core business logic remains in the `weight` domain.
- **Dependency Inversion**: Domain defines repository contracts; data layer provides concrete implementations.
- **State Management**: `flutter_bloc` with `hydrated_bloc` for persistent application configuration.
- **Dependency Injection**: `get_it` + `injectable` for compile-time service configuration and modular locator container.
- **Routing & Navigation**: `go_router` with `StatefulShellRoute.indexedStack` preserving individual tab navigation history, deep linking (`/today?action=add`, `/calendar?date=YYYY-MM-DD`), and reactive auth/onboarding redirection guards.

## Tech Stack

| Category | Package | Purpose |
|----------|---------|---------|
| **Framework** | Flutter 3.47.1 | Cross-platform UI framework |
| **State Management** | flutter_bloc, hydrated_bloc | BLoC pattern with automated JSON hydration |
| **Dependency Injection** | get_it, injectable | Service locator and compile-time dependency injection |
| **Routing & Navigation** | go_router | Declarative routing, stateful nested shells, deep linking, and reactive guards |
| **Database** | isar_community | High-performance local NoSQL database |
| **Security & Encryption** | encrypt, crypto, flutter_secure_storage | AES-256 local encryption and hardware-backed Keystore/Keychain key isolation |
| **Charts** | fl_chart | Interactive weight history visualizations |
| **Biometrics** | local_auth | Native biometric authentication (Face ID, Touch ID, fingerprint) |
| **Health** | health | Integration with Apple HealthKit & Android Health Connect |
| **CSV Handling** | csv, file_picker | CSV encoding, streaming parser, and native Storage Access Framework file picker |
| **Localization** | flutter_localizations + gen-l10n | Internationalization (English, Polish) |
| **Notifications** | flutter_local_notifications, timezone | Local scheduled daily reminders & timezone resolution |
| **Diagnostics & Crash Reporting** | firebase_crashlytics | Anonymous crash reporting and technical diagnostics |
| **Analytics** | firebase_analytics | Privacy-first telemetry and UI interaction metrics (no health data) |
| **Platform Services** | firebase_core | Firebase platform integration and initialization |

## Key Features

### Weight Tracking & Analytics
- Log daily weight measurements with optional text notes.
- Interactive line charts powered by `fl_chart` with daily entry aggregation and trend insights.
- Filter data by timeframe (`Week`, `Month`, `Year`, `All`).
- **Official WHO BMI Classification**: 6-tier BMI categories (Underweight, Normal, Overweight, Obese Class I/II/III) with dynamic category badges.
- **Healthy Weight Range**: Automatic calculation and visual guidance for target healthy weight boundaries.
- Summary metrics: BMI calculation, BMI category badge, target weight progress, and remaining weight delta.
- Automated BMI calculation from configured height.

### Data Management & Integrations
- **Health Sync**: Native synchronization with Apple Health (iOS) and Health Connect (Android).
- **CSV Import**: Batch import entries via `CsvImporter` with row validation and isolate background parsing.
- **CSV Export**: Export entries via `CsvExporter` to a CSV file on disk and share via native OS share dialog.
  - Column format: `ID`, `Date`, `Weight (kg)`, `Note`
- **Unit System**: Seamless switching between Metric (kg, cm) and Imperial (lb, ft/in).

### Settings, Onboarding & Security
- **Declarative Navigation & Deep Linking**: Powered by `go_router` 14.x with persistent `StatefulShellRoute` multi-tab state preservation, URI query parsing (`/today?action=add`, `/calendar?date=YYYY-MM-DD`), and reactive auth/onboarding redirection guards.
- **Android 15 Edge-to-Edge & Display Cutouts**: Full compliance with Android 15 (API 35) edge-to-edge drawing, transparent system bars (`enableEdgeToEdge`), camera cutout/notch adaptation (`shortEdges`), and responsive `SafeArea` boundary guards.
- **Predictive Back & Per-App Language**: Modern predictive back gesture support (`PopScope`) and native per-app language configuration (`locales_config.xml`) for Android 13+.
- **8-Step Onboarding**: A comprehensive wizard guiding users through unit selection, initial logging, CSV imports, and permission setups.
- **Theme Options**: Light, Dark, or System mode with Material 3 dynamic styling.
- **Target Tracking**: Configurable target weight goals with dynamic milestone progress.
- **Reminders**: Daily reminder notifications with custom time selection and timezone persistence.
- **Biometric Lock**: Native biometric lock shielding on app cold start and backgrounding with `stickyAuth` set to `true` (persists the authentication prompt across brief backgrounding).

### Privacy, Analytics & Diagnostics
- **100% Local-First Health Data**: All weight entries, target goals, height settings, BMI calculations, and calendar history are stored exclusively in the local on-device database (`isar_community`). No health measurements are sent to external servers or cloud databases.
- **Hardware-Isolated AES-256 Encryption**: Security keys are anchored in hardware-backed Android Keystore / iOS Keychain via `flutter_secure_storage`.
- **Firebase Analytics (`AppAnalytics`)**: Tracks non-sensitive usage metrics (screen navigations, UI interactions, feature engagement) to improve application UX. In strict adherence to privacy principles, **all raw health measurements (weights, heights, BMI numbers, goal targets) are omitted from telemetry payloads**. Analytics collection is automatically disabled in debug mode (`kDebugMode`).
- **Firebase Crashlytics (`AppCrashReporter`)**: Captures non-fatal error reports and fatal crash stack traces for real-time defect diagnosis and performance stability. Crash logs contain technical error diagnostics and stack traces without any identifiable user health information.

## Getting Started

### Prerequisites

- Dart SDK >= 3.12 (Flutter >= 3.47.1)
- Android Studio Ladybug+ (Android API 26–35) / Xcode 15+ (iOS)

### Setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Run

```bash
flutter run
```

## Project Conventions

### Database Engine
- Isar schema configuration uses the `balance_v1` store name (encrypted schema; legacy `pure_weight_v1` and `pure_weight_v2` stores are quarantined on first launch).
- `DatabaseModule` manages initialization, integrity verification, and fallback database recovery (`.isar.bak`).
- Native database-level sorting via `.where().sortByDateTimeDesc()` runs directly inside Isar query streams.

### State Management
- **`WeightBloc`**: Controls weight entries and chart period filtering.
  - Events: `SubscribeToWeightChanges`, `UpdateUserHeight`, `AddWeight`, `DeleteWeight`, `ChangeChartFilter`, `RefreshWeightData`
  - States: `WeightInitial`, `WeightLoading`, `WeightLoaded`, `WeightError`
- **`AppSettingsBloc`**: Manages user configuration via `HydratedBloc`.
  - Events: `UpdateTheme`, `UpdateMeasurementUnit`, `UpdateHeight`, `TargetWeightChanged`, `UpdateBiometricLock`, `ToggleNotifications`, `UpdateNotificationTime`, `SetLocked`, etc.
  - State: `AppSettingsState` (persisted to storage).

### Code Generation

Generate code for Isar schema models:

```bash
dart run build_runner build
```

Regenerate the app icon (light, dark, monochrome, and adaptive variants) and the native splash screen after updating the source images in `assets/icon/`:

```bash
# Generate App Icons
dart run flutter_launcher_icons

# Generate Native Splash Screen
dart run flutter_native_splash:create
```

## Testing

Run full verification suite (over 1047+ tests):

```bash
./scripts/before_push.sh
```

Or execute unit/widget tests directly:

```bash
flutter test
```

## CSV Specifications

CSV import and export conform to the following 4-column layout:

```csv
ID,Date,Weight (kg),Note
1,2026-07-29 08:00,72.5,Morning weigh-in
2,2026-07-28 08:00,73.0,
```

- `ID`: Auto-increment integer primary key.
- `Date`: Timestamp formatted as `yyyy-MM-dd HH:mm`.
- `Weight (kg)`: Numeric value in kilograms (1 decimal place).
- `Note`: Optional user note string.

## Biometric Security Setup

**iOS**: Include `NSFaceIDUsageDescription` in `ios/Runner/Info.plist`.

**Android**: Declare `<uses-permission android:name="android.permission.USE_BIOMETRIC" />` in `android/app/src/main/AndroidManifest.xml`.

## AI-Native Engineering & Developer Resources (#built_in_public)

As part of our commitment to building in public and advancing agentic workflows, this repository includes battle-tested, token-budget-safe audit frameworks and prompts in the [`prompts/`](prompts/) directory:

- **[BLoC Architecture Deep Audit](prompts/flutter_architect_deep_bloc_audit.md)**: Exhaustive 12-dimension technical and architectural audit framework tailored for Flutter + BLoC + Isar apps.
- **[Riverpod Architecture Deep Audit](prompts/flutter_architect_deep_riverpod_audit.md)**: Complete 12-dimension audit framework for Flutter + Riverpod 3.x + Isar apps.
- **[Unit Test Auditor Framework](prompts/flutter_unit_test_audit_framework_en.md)**: Iterative, bounded-context audit and test generation framework for Flutter unit tests.
- **[i18n / L10n Localization Audit](prompts/flutter_i18n_l10n_audit_en.md)**: Chunked, stateful localization auditor for `.arb` + `flutter gen-l10n` toolchains.
- **[Comments & DartDoc Cleanup Prompt](prompts/flutter_comments_dartdoc_cleanup_prompt_en.md)**: Memory-safe, file-by-file comment translation and documentation refactoring prompt.

## License

Private / All rights reserved.
