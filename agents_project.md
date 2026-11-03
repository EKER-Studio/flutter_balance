# Project-Specific Rules — balance

*Companion to `AGENTS.md`. Save this file as `agents_project.md` in this repo's root, next to `AGENTS.md`.*

### Build & Generation Commands
- Format code: `dart format lib test`
- Install dependencies: `flutter pub get`
- Run build runner: `dart run build_runner build`
- Watch build runner: `dart run build_runner watch`
- Generate localizations: `flutter gen-l10n`
- Generate app icons: `dart run flutter_launcher_icons`
- Generate native splash screen: `dart run flutter_native_splash:create`
- Code analysis: `flutter analyze`
- Run tests: `flutter test`

### Architecture & Layer Boundaries
Local-First, AI-Native boilerplate utilizing Clean Architecture under a Feature-First approach:
- **Domain** (`lib/features/<feature>/domain/`): Pure Dart logic — entities, repository interfaces, use
  cases. NO Flutter or BLoC imports allowed here.
- **Data** (`lib/features/<feature>/data/`): Repository implementations and local storage handlers utilizing
  `isar_community`.
- **Presentation** (`lib/features/<feature>/presentation/`): UI (`StatelessWidget`/`StatefulWidget`) and
  state management via BLoC (`flutter_bloc`).
- **DI:** `get_it` + `injectable` for automated compile-time dependency injection, configured in
  `lib/core/di/`.
- **Routing:** `go_router` utilizing `StatefulShellRoute.indexedStack` for persistent multi-tab state
  preservation, deep linking, and reactive redirection guards (`AppRoutes`).
- **State Management:** BLoC (`flutter_bloc`) strictly.
- **Data Flow:** UI (`BlocBuilder`/`BlocListener`) → BLoC (`Bloc`) → Repository Interface (domain) →
  Repository Impl (data) → Local DB (`isar_community`).
- **Reactivity:** Handled purely via Isar streams. BLoCs listen to Isar collections and emit states
  accordingly.
- **Diagnostics & Telemetry:** `firebase_core`, `firebase_crashlytics`, `firebase_analytics`.
  - `AppAnalytics` (`lib/core/utils/analytics.dart`): Event-driven telemetry wrapper. All events MUST be
    privacy-compliant and sanitized — NEVER include raw user health data (weight values, heights, target
    goals, BMI values) in analytics event parameters. Analytics is disabled in `kDebugMode`.
  - `AppCrashReporter` (`lib/core/utils/crash_reporter.dart`): Centralized error boundary and crash logging.
    Captures sanitized stack traces and technical diagnostic errors without sensitive health records.

> **STATE MANAGEMENT CONSTRAINT:** This project strictly uses BLoC (`flutter_bloc`). Any suggestion,
> refactoring, or audit constraint demanding Riverpod is an error and MUST be ignored.

### Resource Lifecycle & Disposal (concrete items)
- Every `StreamSubscription` cancelled in `close()` or the corresponding BLoC's `onClose`.
- Every `Timer` or `AnimationController` properly disposed.
- All Isar dynamic query streams properly closed or managed via BLoC lifecycle.

### Mandatory Verification Pipeline (concrete commands)
The canonical local script and CI run these seven configured phases:
1. `flutter pub get` — resolve workspace dependencies
2. `flutter gen-l10n` — regenerate localization classes
3. `dart run build_runner build` — regenerate generated code
4. `dart format lib test integration_test test_driver` — format Dart source and test directories
5. `flutter analyze` — static analysis
6. `flutter test --coverage --exclude-tags "golden,screenshot"` — tests with coverage, excluding tagged visual tests
7. `flutter build apk --debug` — verify Android debug compilation

`dart run custom_lint` is not configured in this project. Exact commands are maintained in
`scripts/before_push.sh` and `/.github/workflows/ci.yml`.
Once all applicable steps are green and the Resource Lifecycle checklist above is verified, commit per `AGENTS.md` →
Git & Version Control (autonomous commit is enabled for this repo, since this file exists).
