# PureWeight — Comprehensive Codebase Audit Report

**Audit Date:** 2026-07-30  
**Repository:** `/Users/piotrekert/workspace/flutter_pure_weight`  
**Flutter Version:** 3.44 | **SDK:** ^3.12.2  
**App Version:** 1.0.0+1  

---

## D1: CI/CD Pipeline

| Check | Status | Notes |
|---|---|---|
| Automated CI workflow (GitHub Actions) | ✅ `.github/workflows/ci.yml` | Triggers on push/PR to `main`. Steps: checkout → Java 17 → Flutter setup → `pub get` → `gen-l10n` → `build_runner` → `dart format` → `flutter analyze` → `import_lint` → `flutter test -j 1` → `flutter build apk --debug` → upload APK artifact (7-day retention). |
| Pre-push verification script | ✅ `before_push.sh` | Same steps as CI plus exit code parsing workaround for import_lint. |
| Pipeline idempotency | ✅ | All steps run sequentially; `--delete-conflicting-outputs` flag used. |
| Caching | ✅ | Pub cache and `.dart_tool` cached via `actions/cache@v4` with keyed restore. |

---

## D2: Clean Architecture Boundaries

| Check | Status | Notes |
|---|---|---|
| Domain layer pure Dart, no Flutter/BLoC | ✅ PASS | `weight_entry.dart`, `weight_repository.dart`, `weight_error_type.dart` have zero Flutter/BLoC imports. |
| Repository interface in domain | ✅ | `WeightRepository` is an abstract class in `domain/repositories/`. |
| Repository impl in data layer | ✅ | `IsarWeightRepository` in `data/repositories/`. |
| import_lint rule configured | ✅ | `avoid_infrastructure_imports_in_presentation` blocks `presentation/**` from importing `data/**` at severity `error`. |
| Layer violation scan (manual) | ✅ PASS | No presentation→data imports found. Data layer properly depends on domain interfaces. |
| Data flow direction | ✅ | UI → BLoC → Repository Interface → Repository Impl → Isar. |
| `IsarWeightRepository` imports `flutter/foundation.dart` | ⚠️ Minor | `kDebugMode`/`debugPrint` used for logging. Acceptable for debug logging, but pure Dart `log` package would be cleaner. |

---

## D3: State Management (BLoC)

| Check | Status | Notes |
|---|---|---|
| Pattern adherence | ✅ | Strict BLoC: Events → Bloc → States. No ad-hoc state. |
| HydratedBloc for persistent prefs | ✅ | `AppSettingsBloc` persists theme, height, unit, notification prefs, biometric lock. |
| BlocProvider tree | ✅ | DI via `BlocProvider` at root, `RepositoryProvider` for `WeightRepository`. |
| BLoC-to-BLoC coupling | ✅ | No direct bloc-to-bloc calls; communication through shared repository or widget tree. |
| `AppSettingsBloc` extends `HydratedBloc` | ✅ | JSON serialization of state. |
| Event/State sealed classes | ✅ | `WeightEvent` and `WeightState` are sealed. |
| TimePeriod enum with extension | ✅ | Clean `TimePeriodX` extension providing `lookbackDuration`. |
| Memoization in `WeightBloc._filterEntries` | ⚠️ Minor | Manual memoization with `listEquals` comparison. Works but adds complexity; fine for the use case. |

---

## D4: Lifecycle & Memory Management

| Check | Status | Notes |
|---|---|---|
| Stream subscriptions cancelled | ✅ | `WeightBloc` uses `emit.forEach` (BLoC-managed). `BiometricLockObserver._subscription` cancelled in `dispose()`. |
| WidgetsBindingObserver properly removed | ✅ | `BiometricLockObserver.dispose()` calls `removeObserver()`. |
| Double-dispose guard | ✅ | `_disposed` flag in `BiometricLockObserver`. |
| TextEditingControllers disposed | ✅ | All controllers in `_HeightDialog`, `AddWeightSheet`, `TargetWeightDialog`, `WeightDashboardScreen` disposed. |
| Timer/AnimationController cleanup | ✅ N/A | No timers or animation controllers found. |
| FocusNodes disposed | ✅ | `_CustomSettingsTileState` and `_CustomSwitchTileState` dispose their focus nodes. |
| NotificationService singleton | ✅ | No lifecycle issues with singleton pattern. |
| DatabaseModule static methods | ✅ | No instance state to leak. |
| HydratedBloc storage | ✅ | Initialized once in `main.dart`. |

**No lifecycle/memory issues found.**

---

## D5: Isar Database & Data Layer

| Check | Status | Notes |
|---|---|---|
| Schema definition | ✅ | `WeightEntryModel` with `encryptedWeight`, `encryptedNote`, `dateTime` (indexed). |
| Store name versioning | ✅ | `pure_weight_v2`; v1→v2 migration legacy quarantine implemented. |
| Field-level encryption | ✅ | AES-256 CBC via `encrypt` package, IV prepended to ciphertext. |
| Encryption key management | ✅ | Key stored in `flutter_secure_storage`, auto-generated with `Random.secure()`. |
| Reactive stream | ✅ | `watchAllEntries()` with `.watch(fireImmediately: true)`, sorted descending, limited to 500. |
| CRUD operations | ⚠️ **Missing: Update** | No `updateEntry()` method. Users cannot edit existing entries. |
| Error handling | ✅ | All operations catch `IsarError` and rethrow typed `WeightRepositoryException`. |
| Backup & recovery | ✅ | `DatabaseModule.backupCorruptedDatabase()` + `ensureInstanceIntegrity()` on app resume. |
| Compact on launch | ✅ | 10 MB threshold with 1.25 min ratio. |
| Legacy quarantine | ✅ | v1 `.legacy_unencrypted.bak` created — prevents silent 0.0 kg decryption. |
| `_entityToModel` updates `id` correctly | ✅ | `id == 0` → `Isar.autoIncrement`, else preserves existing id. |

---

## D6: Dead Code Detection

| File | Status |
|---|---|
| `weight_dashboard_screen.dart` | ❌ **DEAD CODE** — Defined at `lib/features/weight/presentation/screens/weight_dashboard.dart` but **never imported** anywhere. `MainNavigationScreen` uses `TodayScreen` instead. This is a leftover from an earlier UI iteration. 480 lines, includes `_HeightDialog` (dead as well within this dead screen). |
| `calendar/` widget subdirectory | ✅ Used — imported by `CalendarScreen`. |
| `statistics_shimmer_skeleton.dart` | ✅ Used — imported by `StatisticsScreen`. |
| `today_shimmer_skeleton.dart` | ✅ Used — imported by `TodayScreen`. |
| `latest_measurement_card.dart` | ✅ Used — imported by `TodayScreen`. |
| `weight_chart.dart` | ✅ Used — imported by `WeightDashboardScreen` (dead) AND `TodayScreen` (live). |
| `initial_weight_data.dart` | ✅ Used — imported by `main.dart`. |

**Recommendation:** Delete `weight_dashboard_screen.dart` (and its associated `_HeightDialog` which also appears in `settings_screen.dart`). Verify no remaining references before removal.

---

## D7: Error Handling & Robustness

| Check | Status | Notes |
|---|---|---|
| Typed error domain | ✅ | `WeightErrorType` enum with 7 values, `WeightRepositoryException` carries type + message + sourceError. |
| BLoC error states | ✅ | All BLoC event handlers catch errors and emit `WeightError` with appropriate type. |
| Repository error wrapping | ✅ | All `IsarError`/unexpected errors wrapped in `WeightRepositoryException`. |
| Stream error handling | ✅ | `emit.forEach` has `onError` callback → `WeightError` with `streamError`. |
| Biometric error handling | ✅ | `PlatformException` cases enumerated (LockedOut, PermanentlyLockedOut, NotEnrolled, etc.). |
| Database fallback | ✅ | `initialize()` retries after backup on failure. |
| Notification error suppression | ✅ | All `NotificationService` calls wrapped in try-catch (logged in debug). |
| FieldCipher decryption fallback | ⚠️ **Minor risk** | `_modelToEntity` silently returns `0.0` kg on decryption failure instead of propagating an error. Corrupted data would show as 0.0 kg without user awareness. |
| No global error handler | ❌ **Missing** | No `Zone`-level error handler or Flutter `ErrorWidget.builder` override. Uncaught async errors would crash silently. |
| Input validation | ✅ | Weight range (20–300 kg), date not in future, CSV row validation. |

---

## D8: Test Coverage

| Check | Status | Notes |
|---|---|---|
| Total test files | 20 | Located under `test/` directory. |
| BLoC tests | ✅ | `weight_bloc_test.dart` (comprehensive, 10+ test cases), `app_settings_bloc_test.dart`. |
| Repository tests | ✅ | `isar_weight_repository_test.dart` (cryptographic verification, multi-key isolation, graceful skip when native libs absent). |
| Database module tests | ✅ | `database_module_test.dart` (backup, lock file removal, legacy quarantine — 10+ test cases). |
| Field cipher tests | ✅ | `field_cipher_test.dart` (encrypt/decrypt roundtrip, wrong key, malformed input). |
| CSV tests | ✅ | `csv_exporter_test.dart`, `csv_importer_test.dart`. |
| Widget tests | ✅ | `add_weight_sheet_test.dart`, `health_summary_card_test.dart`, `calendar_widgets_test.dart`, `latest_measurement_card_test.dart`, `today_shimmer_skeleton_test.dart`. |
| Screen tests | ✅ | `today_screen_test.dart`, `statistics_screen_test.dart`, `main_navigation_screen_test.dart`. |
| **Missing coverage:** | | |
| `settings_screen.dart` | ❌ | Complex screen (400+ lines) with no widget test. |
| `weight_chart.dart` | ❌ | Not directly tested (350+ lines, complex chart logic). |
| `biometric_shield_screen.dart` | ❌ | No test. |
| `notification_service.dart` | ❌ | No test. |
| `biometric_service.dart` | ❌ | No test. |
| `weight_error_localizer.dart` | ❌ | No test. |
| `csv_exporter.dart` `exportAndShare` | ❌ | `generateCsv` is tested but `exportAndShare` is not. |

**Test quality:** Good use of `mocktail`, `bloc_test`, proper Arrange-Act-Assert patterns. Repository tests gracefully skip when native Isar binaries unavailable.

---

## D9: Documentation

| Check | Status | Notes |
|---|---|---|
| dartdoc on all public classes | ✅ | One-sentence summaries with `@param` docs. |
| AGENTS.md | ✅ | Architecture, build commands, layer boundaries, verification pipeline. |
| README.md | ✅ | Comprehensive: architecture, tech stack table, features, setup, CSV format, biometric setup. |
| `@visibleForTesting` annotations | ✅ | `quarantineLegacyDatabaseForTesting`, `backupCorruptedDatabase`. |
| Inline comments | ✅ | Minimal, mostly architecture rationale (e.g., `dependency_overrides` explanation, v1→v2 migration reasoning). |
| No stale docs | ✅ | Docs match current implementation. |

---

## D10: Security

| Check | Status | Notes |
|---|---|---|
| Field-level encryption | ✅ | AES-256 CBC for `weight` and `note` fields. |
| Key storage | ✅ | `flutter_secure_storage` (platform Keychain/Keystore). |
| No hardcoded secrets | ✅ | Keys generated at runtime via `Random.secure()`. |
| Biometric lock | ✅ | Face ID / fingerprint with lifecycle-aware `BiometricLockObserver`. |
| `persistAcrossBackgrounding: false` | ✅ | Re-authentication required after backgrounding. |
| Debug info in release builds | ✅ | All `debugPrint` calls guarded by `kDebugMode`. |
| No passcode fallback | ⚠️ **Minor** | If biometrics fail/lock out, user cannot access the app. No passcode/PIN fallback path. |
| Input sanitization | ✅ | CSV imports validate weight range, CSV line parsing handles quoted fields. |

---

## D11: Dependencies

| Check | Status | Notes |
|---|---|---|
| Dependency count | 19 direct + 8 dev | Reasonable for a Flutter app. |
| Key packages | ✅ | `flutter_bloc 9.x`, `isar_community 3.x`, `fl_chart`, `encrypt`, `flutter_secure_storage`, `local_auth`. |
| No unused dependencies | ✅ | All packages referenced in code. |
| `dependency_overrides` | ⚠️ | `analyzer: 10.2.0` pinned due to `isar_community_generator 3.3.2` vs `import_lint 2.0.0` conflict. This is a known tension point — blocks updating either package until the upper bound is resolved. |
| Version freshness | ✅ | Packages appear reasonably up-to-date (Flutter 3.44, BLoC 9.x). |

---

## D12: Platform-Specific & Accessibility

| Check | Status | Notes |
|---|---|---|
| Semantic labels | ✅ | `Semantics` widgets on chart, filter chips, buttons, BMI badges. |
| `ExcludeSemantics` for decorative elements | ✅ | Icons and decorative containers excluded. |
| `MergeSemantics` for grouped elements | ✅ | ListTiles, stat tiles merged. |
| Theme support | ✅ | Light + Dark Material 3 with `AppThemeMode` (system/light/dark). |
| Responsive layout | ✅ | `ClampedLayout` (600px max width), `OrientationBuilder` for chart height. |
| Localization | ✅ | English + Polish via ARB, `flutter gen-l10n`. |
| Localization completeness | ✅ | EN and PL ARB files have identical key sets (193 lines each). |
| `nullable-getter: false` | ✅ | No null-check boilerplate for translations. |
| Notification permissions | ✅ | `permission_handler` for Android 13+, `requestNotificationsPermission`. |
| Biometric platform config docs | ✅ | README documents iOS `NSFaceIDUsageDescription` and Android permission. |
| Touch target size | ✅ | Minimum 48×48 on buttons, chips, interactive tiles. |

---

## Summary

| Dimension | Verdict | Key Issues |
|---|---|---|
| D1 CI/CD | ✅ **PASS** | `.github/workflows/ci.yml` fully configured with caching, APK artifact upload. |
| D2 Architecture | ✅ **PASS** | Clean boundaries. One minor (acceptable) Flutter import in data layer. |
| D3 State Mgmt | ✅ **PASS** | Proper BLoC patterns. No violations. |
| D4 Lifecycle | ✅ **PASS** | No leaks found. All subscriptions/controllers disposed. |
| D5 Isar/Data | ⚠️ **MINOR** | Missing `updateEntry()` operation. |
| D6 Dead Code | ❌ **FOUND** | `weight_dashboard_screen.dart` is unused (480 lines). |
| D7 Robustness | ⚠️ **MINOR** | No global error handler; decryption failure silently yields 0.0 kg. |
| D8 Tests | ⚠️ **COVERAGE GAPS** | 7 untested files (settings_screen, weight_chart, biometric screens, notification/biometric services). |
| D9 Docs | ✅ **PASS** | Good coverage, no stale docs. |
| D10 Security | ✅ **PASS** | Strong encryption, biometrics, secret management. No passcode fallback. |
| D11 Dependencies | ⚠️ **TENSION** | `analyzer` version pinned in `dependency_overrides`. |
| D12 Platform/A11Y | ✅ **PASS** | Good semantic labels, responsive layout, full bi-lingual l10n. |

### Critical Must-Fix
1. **Dead code** — Delete `weight_dashboard_screen.dart` (and verify no remnants).

### Should-Fix
3. **Global error handler** — Add `FlutterError.onError` / `PlatformDispatcher.onError` handler.
4. **Test gaps** — Add tests for `settings_screen`, `weight_chart`, `biometric_shield_screen`.
5. **Missing `updateEntry()`** — Add edit capability for existing weight entries.
6. **Passcode fallback** — Consider adding device passcode fallback when biometrics are locked out.
7. **Decryption failure handling** — Propagate error instead of silently returning 0.0 kg.
