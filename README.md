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
  <img src="https://img.shields.io/badge/Flutter-3.47.8-02569B?logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/Architecture-Clean%20%2F%20Feature--First-blue" alt="Architecture" />
  <img src="https://img.shields.io/badge/State-BLoC-blueviolet" alt="State Management" />
  <img src="https://img.shields.io/badge/Storage-Isar%20NoSQL-green" alt="Storage" />
  <img src="https://img.shields.io/badge/Platforms-iOS%20%7C%20Android-black" alt="Platforms" />
</p>

---

## Screenshots

| Today Dashboard (Light) | Statistics Overview (Light) | WHO BMI Categories (Light) | Calendar & History (Light) |
| :---: | :---: | :---: | :---: |
| <img src=".github/assets/01_dashboard.png" width="190" alt="Today Dashboard (Light)" /> | <img src=".github/assets/02_statistics.png" width="190" alt="Statistics Overview (Light)" /> | <img src=".github/assets/03_bmi_categories.png" width="190" alt="WHO BMI Categories (Light)" /> | <img src=".github/assets/04_calendar.png" width="190" alt="Calendar and History (Light)" /> |

| Achievements Gallery (Light) | Edit Measurement (Light) | Home Screen Widget (Dark) | Settings & Health Connect (Dark) |
| :---: | :---: | :---: | :---: |
| <img src=".github/assets/05_achievements.png" width="190" alt="Achievements Gallery (Light)" /> | <img src=".github/assets/06_measurement_sheet.png" width="190" alt="Edit Measurement (Light)" /> | <img src=".github/assets/07_home_widget.png" width="190" alt="Home Screen Widget (Dark)" /> | <img src=".github/assets/08_settings.png" width="190" alt="Settings & Health Connect (Dark)" /> |

---

## Architecture

Clean Architecture strictly organized under a **Feature-First** (vertical slice) layout:

```
lib/
├── app.dart                      # Root application widget (MaterialApp, theme, locale & providers)
├── main.dart                     # App entry point, splash preservation & crash reporting
├── firebase_options.dart         # Auto-configured Firebase credentials per platform
├── core/                         # Cross-cutting concerns & infrastructure
│   ├── bloc/                     # Global BLoC lifecycle observer (AppBlocObserver)
│   ├── config/                   # AppEnvironment (dev, prod configurations)
│   ├── database/                 # Database module & Isar initialization
│   ├── di/                       # Dependency injection setup via GetIt & Injectable
│   ├── errors/                   # Unified app error types & exception handlers
│   ├── integrations/             # Native platform & 3rd-party integration services
│   │   ├── analytics/            # Privacy-first telemetry service (AnalyticsService)
│   │   ├── biometrics/           # Local authentication (Face ID/Fingerprint) & lock observer
│   │   ├── csv/                  # CSV parser, CsvImportService validation & import/export pipelines
│   │   ├── health/               # Apple HealthKit & Android Health Connect sync service
│   │   ├── notifications/        # Local scheduled notifications & timezone management
│   │   └── widgets/              # Android home screen glanceable widgets synchronization service
│   ├── models/                   # Core shared models (MeasurementUnit, TimePeriod)
│   ├── presentation/             # Global app UI & shared design system
│   │   ├── navigation/           # AppRoutes, AppRouter and route definitions
│   │   ├── screens/              # AppSplashScreen, AppInitializationErrorScreen, BiometricShieldScreen
│   │   ├── theme/                # AppTheme (Light & Dark Material 3 tokens), layout tokens & feedback
│   │   └── widgets/              # Reusable components (AppTopBar, ClampedLayout, PillSegmentedControl)
│   └── utils/                    # Shared utilities (AppAnalytics, AppCrashReporter, FieldCipher, UnitConverter)
├── features/                     # Feature modules (Feature-First architecture)
│   ├── calendar/                 # Calendar monthly view, day history & entry sheet
│   ├── dashboard/                # Today's overview, BMI gauge & quick-add weight cards
│   ├── navigation/               # Main navigation scaffold (BottomBar & NavigationRail)
│   ├── onboarding/               # Ephemeral onboarding wizard & OnboardingBloc
│   ├── settings/                 # User preferences, reminders, backup, wipe data & privacy policy
│   ├── statistics/               # Analytics, BMI charts, period comparison & achievements
│   │   ├── domain/               # Milestone & period comparison entities and calculation services
│   │   └── presentation/         # StatisticsScreen, Achievements gallery sheet, trend & habit cards
│   └── weight/                   # Core weight tracking domain, data & state
│       ├── data/                 # WeightEntryModel (Isar schema), IsarWeightRepository & CSV services
│       ├── domain/               # WeightEntry entities, BmiCalculator, domain calculation services & repository contracts
│       └── presentation/         # Shared WeightBloc, events, states & AddWeightSheet
└── l10n/                         # Localization ARB assets (EN, DE, JA, FR, ES, PL, PT-BR, NL, IT, KO)
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
| **Framework** | Flutter 3.47.8 | Cross-platform UI framework |
| **State Management** | flutter_bloc, hydrated_bloc | BLoC pattern with automated JSON hydration |
| **Dependency Injection** | get_it, injectable | Service locator and compile-time dependency injection |
| **Routing & Navigation** | go_router | Declarative routing, stateful nested shells, deep linking, and reactive guards |
| **Database** | isar_community | High-performance local NoSQL database |
| **Security & Encryption** | encrypt, crypto, flutter_secure_storage | AES-256 local encryption and hardware-backed Keystore/Keychain key isolation |
| **Charts** | fl_chart | Interactive weight history visualizations |
| **Biometrics** | local_auth | Native biometric authentication (Face ID, Touch ID, fingerprint) |
| **Health** | health | Integration with Apple HealthKit & Android Health Connect |
| **Home Widgets** | home_widget | Android home screen glanceable widgets (2x1, 3x2) |
| **CSV Handling** | csv, file_picker | CSV encoding, background-isolate parsing, and native Storage Access Framework file picker |
| **Localization** | flutter_localizations + gen-l10n | Internationalization (10 languages: EN, DE, JA, FR, ES, PL, PT-BR, NL, IT, KO) |
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
- **Milestone Achievements & Gamification**: 19 unlockable achievement badges across 3 categories (*Goals & Progress*, *Consistency & Habits*, *Routines & Time*) with an interactive Achievements Gallery and progress counter.
- **Habit Streaks & Consistency**: Real-time tracking of current weigh-in streak, personal best streak, and consistency percentage across all entries.
- **Period Comparison Analytics**: Compare progress across customizable time intervals (7 days vs previous 7 days, 30 days vs previous 30 days) with average weight, delta indicators, and highest/lowest records.
- Summary metrics: BMI calculation, BMI category badge, target weight progress, and remaining weight delta.
- Automated BMI calculation from configured height.

### Data Management & Integrations
- **Home Screen Widgets**: Native Android desktop widgets (compact 2x1 and detailed 3x2) powered by `home_widget`, displaying current weight, 7-day delta, WHO BMI category badge, and goal progress bar with automatic background synchronization.
- **Health Sync**: Native synchronization with Apple Health (iOS) and Health Connect (Android).
- **CSV Import**: Batch import entries via `CsvImporter` with row validation and isolate background parsing.
- **CSV Export**: Export entries via `CsvExporter` to a CSV file on disk and share via native OS share dialog.
  - Column format: `ID`, `Date`, `Weight (kg)`, `Note`
- **Unit System**: Seamless switching between Metric (kg, cm) and Imperial (lb, ft/in).

### Settings, Onboarding & Security
- **Declarative Navigation & Deep Linking**: Powered by `go_router` 18.x with persistent `StatefulShellRoute` multi-tab state preservation, URI query parsing (`/today?action=add`, `/calendar?date=YYYY-MM-DD`), and reactive auth/onboarding redirection guards.
- **Android 15 Edge-to-Edge & Display Cutouts**: Full compliance with Android 15 (API 35) edge-to-edge drawing, transparent system bars (`enableEdgeToEdge`), camera cutout/notch adaptation (`shortEdges`), and responsive `SafeArea` boundary guards.
- **Predictive Back & Per-App Language**: Modern predictive back gesture support (`PopScope`) and native per-app language configuration (`locales_config.xml`) for Android 13+.
- **Step-by-Step Onboarding**: A comprehensive wizard guiding users through unit selection, initial logging, CSV imports, and permission setups.
- **Theme Options**: Light, Dark, or System mode with Material 3 dynamic styling.
- **Target Tracking**: Configurable target weight goals with dynamic milestone progress.
- **Reminders**: Daily reminder notifications with custom time selection and timezone persistence.
- **Biometric Lock**: Native biometric lock shielding on app cold start and backgrounding with `stickyAuth` set to `true` (persists the authentication prompt across brief backgrounding).

### Privacy, Analytics & Diagnostics
- **100% Local-First Health Data**: All weight entries, target goals, height settings, BMI calculations, and calendar history are stored exclusively in the local on-device database (`isar_community`). No health measurements are sent to external servers or cloud databases.
- **Hardware-Isolated AES-256 Field Encryption**: Weight values and notes are encrypted before they are written to Isar; encryption keys are anchored in hardware-backed Android Keystore / iOS Keychain via `flutter_secure_storage`. Record IDs and measurement timestamps remain plaintext to support indexed queries, the Isar file itself is not encrypted, and hydrated settings (such as height and target weight) are not covered by this encryption.
- **Firebase Analytics (`AppAnalytics`)**: Tracks non-sensitive usage metrics (screen navigations, UI interactions, feature engagement) to improve application UX. In strict adherence to privacy principles, **all raw health measurements (weights, heights, BMI numbers, goal targets) are omitted from telemetry payloads**. Analytics collection is automatically disabled in debug mode (`kDebugMode`).
- **Firebase Crashlytics (`AppCrashReporter`)**: Captures non-fatal error reports and fatal crash stack traces for real-time defect diagnosis and performance stability. Crash logs contain technical error diagnostics and stack traces without any identifiable user health information.

## Getting Started

### Prerequisites

- Dart SDK >= 3.12.2 (Flutter >= 3.47.8) — pinned via `.flutter-version`
- Android Studio Ladybug+ (Android API 26–35) / Xcode 15+ (iOS)

### Setup

```bash
flutter pub get
dart run build_runner build
```

### Run

```bash
flutter run
```

## Project Conventions

### Database Engine
- Isar schema configuration uses the `balance_v1` store name (field-encrypted schema; legacy `pure_weight_v1` and `pure_weight_v2` stores are quarantined on first launch).
- `DatabaseModule` manages initialization, integrity verification, and fallback database recovery (`.isar.bak`).
- Native database-level sorting via `.where().sortByDateTimeDesc()` runs directly inside Isar query streams.

### State Management
- **`WeightBloc`**: Controls weight entries, chart period filtering, and platform sync pipelines.
  - Events: `SubscribeToWeightChanges`, `UpdateUserHeight`, `AddWeight`, `UpdateWeight`, `DeleteWeight`, `ChangeChartFilter`, `RefreshWeightData`, `ClearAllWeightData`, `ImportWeightEntries`, `SyncHealthEntries`, `AnalyzeCsvFile`, `ConfirmCsvImport`
  - States: `WeightInitial`, `WeightLoading`, `WeightLoaded`, `WeightError`, `CsvAnalysisInProgress`, `CsvAnalysisReady`, `CsvAnalysisError`, `WeightImportSuccess`
- **`AppSettingsBloc`**: Manages persistent user preferences via `HydratedBloc`.
  - Events: `UpdateTheme`, `UpdateFirstDayOfWeek`, `UpdateMeasurementUnit`, `UpdateHeight`, `UpdateWeightGoalMode`, `TargetWeightChanged`, `ToggleNotifications`, `UpdateNotificationTime`, `UpdateBiometricLock`, `UpdateBiometricSupport`, `SetLocked`, `ToggleHealthSync`, `CheckHealthSyncStatus`, `UpdateLastHealthSyncTimestamp`, `UpdateWeeklyPaceWindow`, `ToggleAnalytics`, `ToggleCrashReporting`, `CompleteOnboarding`, `DismissWidgetPromo`, `ResetAppSettings`
  - State: `AppSettingsState` (persisted on-device via `HydratedBloc`; see the encryption scope above).
- **`OnboardingBloc`**: Controls the ephemeral multi-step initial setup wizard state machine.
  - Events: `OnboardingStarted`, `OnboardingStepAdvanced`, `OnboardingStepRewound`, `OnboardingUnitSelected`, `OnboardingCsvImported`, `OnboardingInitialWeightSet`, `OnboardingTargetWeightSet`, `OnboardingHealthSyncToggled`, `OnboardingBiometricsToggled`, `OnboardingCompleted`
  - State: `OnboardingState` (holds temporary wizard draft values and emits UI states; the completion coordinator applies the resulting persistence plan).

### Code Generation

Generate code for Isar schema models and dependency injection:

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

## Testing & Quality Assurance

Run the comprehensive 7-phase quality and verification pipeline before freezing or pushing code:

```bash
./scripts/before_push.sh
```

The script automatically executes and validates:
1. `flutter pub get` — Resolves workspace dependencies
2. `flutter gen-l10n` — Regenerates localization classes
3. `dart run build_runner build` — Regenerates Isar and Injectable code
4. `dart format lib test integration_test test_driver` — Formats all Dart source and test directories
5. `flutter analyze` — Static linter verification (0 warnings/errors)
6. `flutter test --coverage --exclude-tags "golden,screenshot"` — Automated test suite with coverage, excluding tagged visual tests
7. `flutter build apk --debug` — Android compilation integrity check

Or execute unit/widget tests directly:

```bash
flutter test --exclude-tags golden,screenshot
```

### Screenshots

Generate localized screenshots for Play Store (10 locales × 2 themes):

```bash
# Full suite (all features, phone)
./scripts/screenshots/generate_screenshots.sh phone

# Single feature or locale
./scripts/screenshots/generate_settings.sh phone pl
./scripts/screenshots/run_screenshot_target.sh integration_test/calendar_screenshots_test.dart phone pl
```

Screenshots are rendered with `ScreenshotDeviceFrame` (status bar 09:41, gesture pill) and stored in `screenshots/` (ignored) — curated assets for README are in `.github/assets/`.

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

## AI-Native Engineering & Agent Toolkit (#built_in_public)

As part of our commitment to building in public and advancing agentic software engineering, this repository has transitioned from monolithic, copy-pasted prompts to a modular toolkit of role prompts and executable **Skills** located in [`.agents/`](.agents/).

### System Architecture

```text
.agents/
├── agents/                     # Portable role prompts (not runtime registrations)
│   ├── architect.md            # Orchestrator: task decomposition, intent routing & delegation guidance
│   ├── data-engineer.md        # Domain & Data: Isar persistence, AES encryption, sync coordinators & pure Dart
│   ├── ui-engineer.md          # Presentation: Flutter widgets, BLoC reactivity, design tokens & accessibility
│   ├── tester.md               # Quality: Mandatory Verification Pipeline execution & test generation
│   └── devops.md               # DevOps & Automation: Git hooks, formatting enforcement & CI/CD workflows
└── skills/                     # Executable runbooks (`<name>/SKILL.md`; discovery depends on harness)
    ├── bloc-audit/             # 12-dimension technical and architecture audit (Isar + BLoC)
    ├── unit-test-audit/        # Layer-by-layer test coverage auditor (Domain → Data → Presentation)
    ├── i18n-audit/             # Chunked localization auditor (hardcoded strings, ARB consistency)
    ├── dartdoc-cleanup/        # Memory-safe, file-by-file comment translation & cleanup
    └── flutter-*/              # 10 official Flutter Team skills (vendored, see below)
```

### Runtime Support

The files in `.agents/` are portable prompts and runbooks, not a runtime plugin. Native custom-agent
registrations (such as `.agent.md` manifests or plugin packages) are not checked in, so an agent only
delegates work when the active harness exposes subagents. Skill discovery likewise depends on the
harness supporting the `.agents/skills/<name>/SKILL.md` convention.

| Runtime | Project rules | Agent roles | Skills |
| :--- | :--- | :--- | :--- |
| OpenCode | `AGENTS.md` + `agents_project.md` | Load `.agents/agents/*.md` as prompts; delegation via available subagents | Discovered from `.agents/skills/` |
| Cursor | `.cursor/rules/agents.mdc` forwards to `AGENTS.md` | Reference `.agents/agents/*.md` manually | Reference `SKILL.md` files manually |
| Claude Code | `CLAUDE.md` imports `AGENTS.md` | Reference `.agents/agents/*.md` manually | Reference `SKILL.md` files manually |
| Gemini | `GEMINI.md` imports `AGENTS.md` | Reference `.agents/agents/*.md` manually | Reference `SKILL.md` files manually |
| Other harnesses | Follow `AGENTS.md` | Reference `.agents/agents/*.md` manually | Reference `SKILL.md` files manually |

### Vendored Flutter Team Skills

The 10 official skills from [`flutter/agent-plugins`](https://github.com/flutter/agent-plugins) are
vendored verbatim in `.agents/skills/flutter-*/` so that harnesses which discover the `.agents/skills/`
convention (for example OpenCode in this workspace) can use them without an external plugin
installation. In harnesses without that convention, reference the relevant `SKILL.md` file explicitly.

| Skill | Use it for |
| :--- | :--- |
| `flutter-add-integration-test` | Flutter Driver / `integration_test` E2E flows. |
| `flutter-add-widget-preview` | Interactive `@Preview` widgets. |
| `flutter-add-widget-test` | Component tests with `WidgetTester`. |
| `flutter-apply-architecture-best-practices` | Layer-boundary reference (BLoC remains mandatory). |
| `flutter-build-responsive-layout` | Adaptive layouts for phones, tablets and foldables. |
| `flutter-fix-layout-issues` | Overflow and unbounded-constraint diagnostics. |
| `flutter-implement-json-serialization` | Manual `fromJson` / `toJson` mapping. |
| `flutter-setup-declarative-routing` | `go_router` navigation and deep linking. |
| `flutter-setup-localization` | `flutter_localizations`, ARB and `gen-l10n` reference. |
| `flutter-use-http-package` | HTTP requests with the `http` package. |

Vendored skills are BSD-3-Clause; attribution and sync instructions live in
[`.agents/skills/README.md`](.agents/skills/README.md). Project rules in `AGENTS.md` and
`agents_project.md` always take precedence over generic skill guidance.

### Key Principles

1. **Separation of Concerns (Personas vs. Skills):** Personas define *who* executes and delegates work; Skills define *how* procedures are executed as reusable, objective runbooks.
2. **Single Source of Truth (SSOT):** Subagents never maintain duplicate copies of build commands or architectural rules; they bind strictly to [`AGENTS.md`](AGENTS.md) and [`agents_project.md`](agents_project.md).
3. **Bounded Work Partitioning:** Massive tasks (such as a 12-dimension code audit) are never forced into a single context window. They are split into bounded passes over the repository; when the runtime exposes subagents, the passes can run as parallel or sequential jobs, and otherwise they run sequentially in one context. The `@architect` role defines the split.
4. **State Persistence & Resumability:** Audits persist incremental findings to disk (`.audit-*/findings.md`), enabling clean recovery from timeouts and zero token waste.
5. **Natural Language Triggers:** Developers interact in natural language (English or Polish) without needing to memorize technical skill identifiers.

### How to Run

Simply instruct the AI agent in natural language inside an agentic workspace (OpenCode, Cursor, Claude Code, Gemini, Antigravity). The role and skill files are available as reference everywhere; automatic skill discovery and subagent delegation depend on the harness.

| Intent | Example Prompt | Execution Flow |
| :--- | :--- | :--- |
| **Full Architecture Audit** | *"Architekt, sprawdź architekturę BLoC"* or *"@architect run architecture audit"* | `@architect` partitions the audit into 3 bounded workstreams (Domain/Data, Presentation/BLoC, Infra/Security) and aggregates them into a final dashboard. Subagents are used only when the runtime supports delegation. |
| **Unit Test Coverage Audit** | *"Sprawdź stan testów jednostkowych"* or *"audit unit test coverage"* | Runs `unit-test-audit` sequentially: Domain → Data → Presentation. |
| **Localization Verification** | *"Sprawdź brakujące klucze tłumaczeń"* or *"audit i18n strings"* | Runs `i18n-audit` chunk-by-chunk on ARB files and UI strings. |
| **Feature Development** | *"@architect add export to PDF feature"* | `@architect` decomposes the specification, then applies the data, UI and test roles in order, delegating only where the runtime exposes those agents, and commits atomically at the end. |
| **DevOps & Formatting** | *"@devops enforce formatting guardrails"* | Configures Git hooks via `scripts/install_git_hooks.sh` to prevent unformatted code from being committed. |

## Branches

- `develop` — default integration branch. All feature PRs target `develop`.
- `release` — release branch. APK & AAB built via `release.yml` on push to `release` or tag `v*`.
- `feature/*` — feature branches from `develop`.

See [CONTRIBUTING](.github/CONTRIBUTING.md) for workflow and PR templates.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
