# PureWeight

A local-first weight tracking application built with Flutter.

## Architecture

Clean Architecture under a Feature-First layout:

```
lib/
├── core/                         # Cross-cutting concerns
│   ├── database/                 # Isar initialization & recovery
│   ├── services/                 # Platform services (biometrics, notifications)
│   └── utils/                    # Utilities (CSV import/export, unit conversion)
├── features/
│   └── weight/                   # Weight tracking feature
│       ├── domain/
│       │   ├── entities/         # WeightEntry entity
│       │   ├── failures/         # Feature-specific failures
│       │   └── repositories/     # WeightRepository interface
│       ├── data/
│       │   ├── models/           # Isar weight model
│       │   └── repositories/     # IsarWeightRepository implementation
│       └── presentation/
│           ├── bloc/             # WeightBloc, events & states
│           └── widgets/          # Weight-specific UI components
└── presentation/
    ├── bloc/                     # App-wide BLoCs (settings)
    ├── screens/                  # App screens (settings)
    ├── theme/                    # Material 3 theme definitions
    └── widgets/                  # Shared widgets (chart, layouts)
```

### Design Principles

- **Local-first**: All data persists on-device using Isar (`isar_community`). No cloud sync.
- **Feature-First**: Each feature encapsulates its own domain, data, and presentation layers.
- **Dependency Inversion**: Domain defines repository interfaces; data layer implements them.
- **State Management**: `flutter_bloc` with `hydrated_bloc` for persistent state across restarts.
- **Dependency Injection**: Manual — `BlocProvider` and `RepositoryProvider.value` in the widget tree.

## Tech Stack

| Category | Package | Purpose |
|----------|---------|---------|
| **Framework** | Flutter 3.44 | Cross-platform UI |
| **State Management** | flutter_bloc, hydrated_bloc | Reactive state with persistence |
| **Database** | isar_community | Local NoSQL database |
| **Charts** | fl_chart | Weight trend visualization |
| **Biometrics** | local_auth | Device biometric lock |
| **File Sharing** | share_plus | CSV export via system share sheet |
| **CSV Parsing** | csv | CSV import/export |
| **Localization** | flutter_localizations + gen-l10n | i18n support (EN, PL) |
| **Notifications** | flutter_local_notifications | Daily weight reminders |

## Key Features

### Weight Tracking
- Log daily weight entries with notes.
- View trends via interactive `fl_chart` line chart with daily aggregation.
- Filter data by time period (7d, 30d, 365d, all).
- Statistical summary (average, min, max, latest, trend).
- BMI auto-calculation from persisted height.

### Data Management
- **CSV Import**: Import weight data from CSV files via `CsvImporter`.
- **CSV Export**: Export weight data to CSV via `CsvExporter` and share via the system share sheet.
  - Column layout: `ID`, `Date`, `Weight (kg)`, `Note`
- **Unit Conversion**: Toggle between metric (kg) and imperial (lbs) units.

### Settings
- Light / Dark / System theme selection.
- Weight unit preference (kg / lbs).
- Height configuration (cm).
- Target weight goal setting.
- Notification preferences with configurable reminder time.
- Biometric lock toggle (Face ID / Touch ID / fingerprint).

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

### Database
- Isar schema versioning uses the `pure_weight_v1` naming convention.
- The `DatabaseModule` handles initialization, lifecycle integrity checks, and automatic backup recovery on corruption.
- On initialization failure the module creates a timestamped `.isar.bak` backup, removes stale lock files, and re-opens a fresh database.
- `compactOnLaunch` is enabled (threshold: 10 MB, ratio: 1.25).

### State Management
- **`WeightBloc`**: Handles weight entry CRUD and time-period filtering.
  - Events: `SubscribeToWeightChanges`, `UpdateUserHeight`, `AddWeight`, `DeleteWeight`, `ChangeChartFilter`, `RefreshWeightData`
  - States: `WeightInitial`, `WeightLoading`, `WeightLoaded`, `WeightError`
- **`AppSettingsBloc`**: Manages persistent app settings via `HydratedBloc`.
  - Events: `UpdateTheme`, `UpdateMeasurementUnit`, `UpdateHeight`, `TargetWeightChanged`, `UpdateBiometricLock`, `ToggleNotifications`, `UpdateNotificationTime`, `SetLocked`
  - State: `AppSettingsState` (hydrated to disk automatically).

### Repository Stream
- `IsarWeightRepository.watchAllEntries()` returns a reactive stream with native database-level sorting via `.sortByDateTimeDesc()`, eliminating memory-sorting overhead in the BLoC layer.
- `_filterEntries` in the BLoC uses a memoization cache to avoid redundant daily-aggregation computation on unrelated state mutations.

### Dependency Injection
No service locator or code-generated DI (no GetIt, Injectable, or Riverpod). Dependencies are wired manually:
1. `DatabaseModule.initialize()` creates the `Isar` instance.
2. `IsarWeightRepository(isar: isar)` wraps it.
3. `App(repository: repository)` passes it via `RepositoryProvider.value`.
4. `BlocProvider` provides `AppSettingsBloc` and `WeightBloc`.

### Code Generation
Only Isar collection models use `build_runner` to generate `.g.dart` files. No Freezed or Injectable annotations are present.

```bash
dart run build_runner build
```

## Testing

```bash
flutter test
```

## CSV Format

Import and export use these 4 columns:

```csv
ID,Date,Weight (kg),Note
1,2026-07-29 08:00,72.5,Morning weigh-in
2,2026-07-28 08:00,73.0,
```

- `ID`: Auto-increment primary key.
- `Date`: ISO 8601 format (`yyyy-MM-dd HH:mm`).
- `Weight (kg): Numeric value in kilograms.
- `Note`: Optional user-provided text.

## Biometric Lock Setup

**iOS**: Add `NSFaceIDUsageDescription` to `ios/Runner/Info.plist`.

**Android**: Add `<uses-permission android:name="android.permission.USE_BIOMETRIC" />` to `android/app/src/main/AndroidManifest.xml`.

## License

Private / All rights reserved.
