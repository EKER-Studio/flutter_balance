# PureWeight

A local-first, AI-native weight tracking application built with Flutter.

## Architecture

PureWeight follows **Clean Architecture** principles with a **Feature-First** organization:

```
lib/
├── core/                    # Cross-cutting concerns
│   ├── database/            # Isar initialization & schema management
│   ├── exceptions/          # Domain-specific exceptions
│   ├── failures/            # Failure types for error handling
│   ├── services/            # Platform services (biometrics, notifications)
│   └── utils/               # Utilities (CSV import/export, unit conversion)
├── features/
│   └── weight/              # Weight tracking feature
│       ├── domain/
│       │   ├── entities/    # WeightEntry entity
│       │   ├── failures/    # Feature-specific failures
│       │   └── repositories/ # WeightRepository interface
│       ├── data/
│       │   ├── models/      # Isar weight model
│       │   └── repositories/ # IsarWeightRepository implementation
│       └── presentation/
│           ├── bloc/        # WeightBloc, events & states
│           └── widgets/     # Weight-specific UI components
└── presentation/
    ├── bloc/                # App-wide BLoCs (settings)
    ├── screens/             # App screens (settings)
    ├── theme/               # Material 3 theme definitions
    └── widgets/             # Shared widgets (chart, layouts)
```

### Design Principles

- **Local-first**: All data persists on-device using Isar (`isar_community`). No cloud sync.
- **Feature-First**: Each feature encapsulates its own domain, data, and presentation layers.
- **Dependency Inversion**: Domain defines repository interfaces; data layer implements them.
- **State Management**: `flutter_bloc` with `hydrated_bloc` for persistent state.

## Tech Stack

| Category | Package | Purpose |
|----------|---------|---------|
| **Framework** | Flutter 3.44.7 | Cross-platform UI |
| **State Management** | flutter_bloc, hydrated_bloc | Reactive state with persistence |
| **Database** | isar_community | Local NoSQL database |
| **DI** | get_it, injectable | Dependency injection |
| **Serialization** | freezed, json_serializable | Immutable models with codegen |
| **Charts** | fl_chart | Weight trend visualization |
| **Biometrics** | local_auth | Device biometric lock |
| **File Sharing** | share_plus | CSV export via system share sheet |
| **CSV** | csv | CSV import/export |
| **Configuration** | flutter_riverpod | (if applicable) |

## Key Features

### Weight Tracking
- Log daily weight entries with notes.
- View trends via interactive `fl_chart` line chart.
- Filter data by time period (7d, 14d, 30d, 60d, 90d, 180d, 365d, all).
- Statistical summary (average, min, max, latest, trend).

### Data Management
- **CSV Import**: Import weight data from CSV files.
- **CSV Export**: Export weight data to CSV and share via system share sheet.
- **Unit Conversion**: Toggle between metric (kg) and imperial (lbs) units.

### Settings
- Light/Dark/System theme selection.
- Weight unit preference (kg / lbs).
- Height configuration (cm / ft+in).
- Notification preferences.
- Biometric lock toggle.

### Security
- **Biometric Lock**: Protect app access using device biometrics (Face ID, Touch ID, fingerprint).
- Implemented via `BiometricService` + `BiometricLockObserver` (lifecycle-aware).

## Getting Started

### Prerequisites

- Flutter SDK >= 3.44.7
- Dart SDK >= 3.12.2
- Xcode (iOS) / Android Studio (Android)

### Setup

```bash
# Install dependencies
flutter pub get

# Run build_runner (generates Isar models, Injectable bindings, JSON serialization)
dart run build_runner build

# Or watch for changes
dart run build_runner watch
```

### Run

```bash
# iOS
flutter run --dart-define-from-file=dev.json

# Android
flutter run --dart-define-from-file=dev.json
```

## Project Conventions

### Database
- Isar schema versioning uses the `pure_weight_v1` naming convention.
- All collections are defined in the domain layer and mapped to Isar models in the data layer.
- Schema migrations are handled via Isar's built-in migration API.

### State Management
- **`WeightBloc`**: Handles weight entry CRUD operations and time-period filtering.
  - Events: `WeightLogged`, `WeightDeleted`, `LoadWeights`, `PeriodChanged`
  - States: `WeightInitial`, `WeightLoading`, `WeightLoaded`, `WeightError`
- **`AppSettingsBloc`**: Manages persistent app settings via `HydratedBloc`.
  - Events: `AppSettingsInitialized`, `ThemeChanged`, `UnitChanged`, `HeightChanged`, `BiometricLockToggled`, `NotificationsToggled`
  - State: `AppSettingsState` (hydrated to disk automatically).

### Dependency Injection
- `GetIt` serves as the service locator.
- `Injectable` annotations (`@injectable`, `@singleton`) generate binding code via `build_runner`.
- Initialization order:
  1. `Isar` database initialization (`CoreDatabase.init()`)
  2. `Hydrogen` (logging) initialization
  3. `GetIt` registration (`GetIt.instance.init()`)
  4. `HydratedBlocStorage` initialization
  5. `BlocProvider` tree in `App` widget

### Code Generation
Files ending in `.g.dart` are generated by `build_runner`. Never edit them manually.

```bash
# After modifying @injectable classes, freezed models, or Isar collections:
dart run build_runner build
```

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## Code Analysis

```bash
# Analyze code for errors and lint violations
flutter analyze
```

## Biometric Lock Setup

Biometric authentication requires platform configuration:

**iOS**: Add `NSFaceIDUsageDescription` (or `NSBiometricUsageDescription`) to `ios/Runner/Info.plist`.

**Android**: Add `<uses-permission android:name="android.permission.USE_BIOMETRIC" />` to `android/app/src/main/AndroidManifest.xml`.

## CSV Format

Import/Export CSV files use the following format:

```csv
date,weight
2025-01-15,75.5
2025-01-16,75.2
```

- `date`: ISO 8601 format (`YYYY-MM-DD`)
- `weight`: Numeric value (respects current unit setting)

## License

Private / All rights reserved.
