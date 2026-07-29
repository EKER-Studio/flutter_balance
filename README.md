# PureWeight

A local-first weight tracking application built with Flutter using Clean Architecture and BLoC.

## Architecture

Clean Architecture under a Feature-First layout:

```
lib/
├── app.dart                      # Root application widget
├── main.dart                     # App entry point & database initialization
├── core/                         # Cross-cutting concerns
│   ├── database/                 # Database module & recovery logic
│   ├── models/                   # Core models (MeasurementUnit)
│   ├── services/                 # Platform services (BiometricService, NotificationService, BiometricLockObserver)
│   └── utils/                    # Utilities (CsvExporter, CsvImporter, UnitConverter)
├── features/
│   └── weight/                   # Weight tracking feature
│       ├── data/
│       │   ├── models/           # WeightEntryModel (Isar schema model)
│       │   └── repositories/     # IsarWeightRepository implementation
│       ├── domain/
│       │   ├── entities/         # WeightEntry domain entity
│       │   ├── repositories/     # WeightRepository interface contract
│       │   └── weight_error_type.dart # Typed domain error enum
│       └── presentation/
│           ├── bloc/             # WeightBloc, WeightEvent & WeightState
│           ├── screens/          # WeightDashboardScreen
│           └── widgets/          # AddWeightSheet, HealthSummaryCard
├── l10n/                         # Localization ARB assets (app_en.arb, app_pl.arb)
└── presentation/
    ├── bloc/settings/            # AppSettingsBloc, AppSettingsEvent, AppSettingsState, AppThemeMode, BmiCategory
    ├── core/                     # ClampedLayout responsive wrapper
    ├── screens/                  # SettingsScreen, BiometricShieldScreen
    ├── theme/                    # AppTheme (Light & Dark Material 3)
    └── widgets/                  # WeightChart
```

### Design Principles

- **Local-first**: All weight entries persist on-device using Isar (`isar_community`). No cloud dependency.
- **Feature-First**: Features encapsulate data, domain, and presentation boundaries.
- **Dependency Inversion**: Domain defines repository contracts; data layer provides concrete implementations.
- **State Management**: `flutter_bloc` with `hydrated_bloc` for persistent application configuration.
- **Dependency Injection**: Manual DI in `main.dart` — dependencies instantiated explicitly and passed down via widget constructors and BLoC providers.

## Tech Stack

| Category | Package | Purpose |
|----------|---------|---------|
| **Framework** | Flutter 3.44 | Cross-platform UI framework |
| **State Management** | flutter_bloc, hydrated_bloc | BLoC pattern with automated JSON hydration |
| **Dependency Injection** | Manual DI | Dependencies wired explicitly in `main.dart`, passed via constructors and BLoC providers |
| **Database** | isar_community | High-performance local NoSQL database |
| **Charts** | fl_chart | Interactive weight history visualizations |
| **Biometrics** | local_auth | Native biometric authentication (Face ID, Touch ID, fingerprint) |
| **File Sharing** | share_plus | System share sheet integration for CSV exports |
| **CSV Handling** | csv | CSV encoding and parsing pipeline |
| **Localization** | flutter_localizations + gen-l10n | Internationalization (English, Polish) |
| **Notifications** | flutter_local_notifications | Local scheduled daily reminders |

## Key Features

### Weight Tracking
- Log daily weight measurements with optional text notes.
- Interactive line charts powered by `fl_chart` with daily entry aggregation.
- Filter data by timeframe (`Week`, `Month`, `Year`, `All`).
- Summary metrics: BMI calculation, BMI category badge, target weight progress, and remaining weight delta.
- Automated BMI calculation from configured height.

### Data Management
- **CSV Import**: Batch import entries via `CsvImporter` with row validation.
- **CSV Export**: Export data via `CsvExporter` and share through system share sheets.
  - Column format: `ID`, `Date`, `Weight (kg)`, `Note`
- **Unit System**: Seamless switching between Metric (kg, cm) and Imperial (lb, ft/in).

### Settings & Security
- Theme options: Light, Dark, or System mode.
- Height configuration (cm).
- Target weight goal tracking.
- Daily reminder notifications with custom time selection.
- Native biometric lock shielding on app cold start and backgrounding with `persistAcrossBackgrounding` set to `false`.

## Getting Started

### Prerequisites

- Flutter SDK >= 3.12
- Xcode (iOS) / Android Studio (Android)

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
- Isar schema configuration uses the `pure_weight_v1` store name.
- `DatabaseModule` manages initialization, integrity verification, and fallback database recovery (`.isar.bak`).
- Native database-level sorting via `.where().sortByDateTimeDesc()` runs directly inside Isar query streams.

### State Management
- **`WeightBloc`**: Controls weight entries and chart period filtering.
  - Events: `SubscribeToWeightChanges`, `UpdateUserHeight`, `AddWeight`, `DeleteWeight`, `ChangeChartFilter`, `RefreshWeightData`
  - States: `WeightInitial`, `WeightLoading`, `WeightLoaded`, `WeightError`
- **`AppSettingsBloc`**: Manages user configuration via `HydratedBloc`.
  - Events: `UpdateTheme`, `UpdateMeasurementUnit`, `UpdateHeight`, `TargetWeightChanged`, `UpdateBiometricLock`, `ToggleNotifications`, `UpdateNotificationTime`, `SetLocked`
  - State: `AppSettingsState` (persisted to storage).

### Code Generation

Generate code for Isar schema models:

```bash
dart run build_runner build
```

## Testing

Run full verification suite:

```bash
./before_push.sh
```

Or execute unit tests directly:

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

## License

Private / All rights reserved.
