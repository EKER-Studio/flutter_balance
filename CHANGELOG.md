# Changelog

## [Unreleased]

---

## [1.2.0] — 2026-09-18

### 🇵🇱 Polski (Google Play Release Notes & Architektura)
- 🔒 **Bezpieczeństwo i szyfrowanie:** Przeniesiono klucz szyfrujący bazę danych Isar wyłącznie do bezpiecznego magazynu sprzętowego (`flutter_secure_storage` w Android Keystore / iOS Keychain), z bezpieczną migracją i usunięciem starego pliku jawnego. Dodano politykę ujawniania podatności w `SECURITY.md`.
- 🏗️ **Architektura & Clean Architecture:** Odsprzężono `OnboardingBloc` od sąsiednich BLoC-ów. Wydzielono serwis domenowy `BmiCalculator` i ujednolicono logikę obliczeń BMI w całej aplikacji. Przeniesiono serwisy CSV do warstwy domeny/integracji oraz `AppThemeMode` do warstwy core.
- 📦 **Wydanie & Android App Bundle:** Wdrożono budowanie paczek wydawniczych Android App Bundle (AAB) z zaciemnianiem kodu (R8 obfuscation) oraz automatycznym uploadem symboli debugowania (`mapping.txt`).
- 🛡️ **Stabilność i rejestrowanie awarii:** Zastąpiono niesystemowe wywołania `debugPrint` ustrukturyzowanym rejestratorem `AppCrashReporter` (Firebase Crashlytics) w całym kodzie inicjalizacyjnym i asynchronicznym.
- 🔧 **Konfiguracja i CI/CD:** Wdrożono automatyczną weryfikację kompilacji debug APK w CI (`before_push.sh` i GitHub Actions), utwardzono reguły analizatora statycznego oraz zoptymalizowano `build.yaml` i `dart_test.yaml`.
- 📱 **Metadane sklepu i zrzuty ekranu:** Skonfigurowano kompletną strukturę metadanych Fastlane Supply, zaktualizowano zlokalizowane zrzuty ekranu dla 10 języków oraz grafikę promocyjną (Feature Graphic).
- 🌐 **Lokalizacja:** Wyodrębniono brakujące teksty w ustawieniach i zaktualizowano mechanizm śledzenia nieprzetłumaczonych fraz.
- 🤖 **Zasoby AI (#built_in_public):** Dodano framework głębokiego audytu architektonicznego Flutter + Riverpod + Isar do katalogu `prompts/`.

### 🇬🇧 English (Google Play Release Notes & Architecture)
- 🔒 **Security & Storage:** Anchored the Isar database encryption key exclusively within hardware-backed secure storage (`flutter_secure_storage` via Android Keystore / iOS Keychain) with automatic quarantine/removal of legacy plaintext files. Added vulnerability disclosure policy in `SECURITY.md`.
- 🏗️ **Clean Architecture & Decoupling:** Decoupled `OnboardingBloc` from sibling BLoCs. Extracted `BmiCalculator` as a dedicated domain service unifying BMI calculations across the app. Relocated CSV services to domain/integrations and `AppThemeMode` to the core theme layer.
- 📦 **Release & Android App Bundle:** Added production Android App Bundle (AAB) target with R8 code obfuscation and automated debug symbols (`mapping.txt`) upload.
- 🛡️ **Code Quality & Crash Reporting:** Replaced raw `debugPrint` calls with structured `AppCrashReporter` (Firebase Crashlytics) across bootstrap and async error boundaries.
- 🔧 **CI/CD & Verification:** Integrated automated Android debug APK build verification into CI and `before_push.sh`, enforced strict static analysis linter rules, and optimized `build.yaml` and `dart_test.yaml`.
- 📱 **Store Metadata & Screenshots:** Configured complete Fastlane Supply metadata, refreshed localized Play Store screenshots across 10 locales, and added high-res feature graphics.
- 🌐 **Localization:** Externalized remaining hardcoded UI strings in settings screens and configured untranslated strings tracking.
- 🤖 **AI-Native Engineering:** Added comprehensive Flutter + Riverpod + Isar deep architecture audit prompt to the `prompts/` suite.

---

## [1.1.1] — 2026-09-04

### 🇵🇱 Polski (Google Play Release Notes)
- 🔒 **Bezpieczeństwo:** Utwardzono reguły kopii zapasowej (wykluczenie kluczy sprzętowych), poprawiono obsługę błędów biometrii i ignorowanie artefaktów podpisywania.
- ♿ **Dostępność:** Wymuszono minimalne obszary dotyku 48dp.
- 🧭 **Nawigacja:** Podłączono martwe trasy i obsłużono nienaświetlone stany.
- 📊 **Wydajność danych:** Zoptymalizowano zapytania Isar do zakresów dat (indeksowane `where`).
- 🧩 **Stabilność BLoC:** Zamieniono `read` na `watch`/`select` wewnątrz `build`.
- 📈 **Statystyki:** Obsługa `WeightError` z danymi z cache i stanem pustym.
- 🌐 **Lokalizacja:** Usunięto martwe klucze `chartSemanticsTitle` i `yesterday`.
- 🔧 **Konfiguracja:** Wykluczono wygenerowane pliki l10n z analizatora, poprawiono ścieżkę `before_push.sh`.

### 🇬🇧 English (Google Play Release Notes)
- 🔒 **Security:** Hardened backup rules (hardware key exclusion), improved biometric error handling, ignored signing artifacts.
- ♿ **Accessibility:** Enforced 48dp minimum touch targets.
- 🧭 **Navigation:** Wired dead routes and handled unlistened states.
- 📊 **Data performance:** Optimized Isar queries for date ranges (indexed `where`).
- 🧩 **BLoC stability:** Replaced `read` with `watch`/`select` inside `build`.
- 📈 **Statistics:** Handled `WeightError` with cached entries and empty state.
- 🌐 **Localization:** Removed dead keys `chartSemanticsTitle` and `yesterday`.
- 🔧 **Config:** Excluded generated l10n from analyzer, fixed `before_push.sh` path.

---

## [1.1.0] — What's New / Co nowego

### 🇵🇱 Polski (Google Play Release Notes)
- 🎯 **Rozszerzona klasyfikacja BMI:** Dodano pełne 6 kategorii BMI zgodnych ze standardami WHO oraz wyliczanie optymalnego zakresu zdrowej wagi.
- 📊 **Usprawnione wykresy i trendy:** Czytelniejsze skale osi oraz interaktywne chipy ze szczegółowym podglądem postępów.
- 📅 **Odświeżony kalendarz:** Wygodniejszy przegląd historii wpisów i szybka edycja pomiarów z poziomu dnia.
- ✨ **Ulepszony proces powitalny (Onboarding):** Przejrzysty układ ekranów ułatwiający konfigurację wagi początkowej i przypomnień.
- 🔒 **Bezpieczeństwo i prywatność:** Dodano wbudowaną politykę prywatności oraz bezpieczną obsługę autoryzacji biometrycznej.
- ⚡ **Płynność i stabilność:** Poprawki wydajności, precyzji synchronizacji ze zdrowiem oraz optymalizacje interfejsu.

---

### 🇬🇧 English (Google Play Release Notes)
- 🎯 **WHO BMI Classification:** Expanded to 6 official WHO BMI categories with personalized healthy weight range calculation.
- 📊 **Enhanced Charts & Trends:** Cleaner chart scales and interactive trend chips for instant category insights.
- 📅 **Refreshed Calendar:** Improved month view with multi-entry day cards and seamless inline editing.
- ✨ **Polished Onboarding:** Streamlined setup flow with clearer initial weight and reminder configuration.
- 🔒 **Privacy & Security:** Native in-app Privacy Policy and enhanced biometric lock protection.
- ⚡ **Performance & Stability:** Improved health sync reliability, smoother transitions, and minor bug fixes.

---

## [1.0.0] - 2026-08-20

### 🇵🇱 Polski
- 🚀 Pierwsze oficjalne wydanie aplikacji w sklepie Google Play.
- 🌓 Nowoczesny design z pełną obsługą trybu jasnego i ciemnego.
- 📱 Responsywny interfejs zoptymalizowany dla telefonów i tabletów.
- 🛡️ Pełna prywatność – lokalna baza danych działająca bez konieczności połączenia z internetem.

### 🇬🇧 English
- 🚀 Initial release on Google Play Store.
- 🌓 Modern UI with full light and dark mode support.
- 📱 Responsive layout tailored for phones and tablets.
- 🛡️ 100% local-first encrypted storage with offline reliability.

