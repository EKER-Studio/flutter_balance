---
name: bloc-audit
description: >
  12-wymiarowy wyczerpujący audyt techniczny i architektoniczny aplikacji Flutter + BLoC + Isar.
  Weryfikuje Clean Architecture, antywzorce BLoC, zarządzanie zasobami/cyklem życia, zapytania Isar,
  dead code, bezpieczeństwo i testy.
  Używaj ZAWSZE, gdy użytkownik mówi: "audyt architektury", "sprawdź architekturę",
  "audyt BLoC", "przegląd kodu", "sprawdź jakość kodu", "architektura", "bloc audit",
  "architecture audit", "code review".
---

# Skill: BLoC Architecture Audit

## Purpose & Objective

Execute an exhaustive, multi-dimensional technical audit of the `flutter_balance` codebase.
Evaluate adherence to Clean Architecture, BLoC best practices, Isar DB efficiency, and stability.
Focus strictly on factual code evidence, violations, stability risks, and concrete remediations.
No conversational padding or basic tutorial explanations.

## How to Analyze — Mandatory Constraints

- Analyze only files within the scope explicitly authorized by the user. When the user requests
  an audit of this repository, inspect the relevant workspace files; do not require the user to
  paste files that are already available in the workspace.
- If a required file is unavailable or outside the authorized scope, state:
  `NOT AVAILABLE — cannot verify` instead of assuming contents.
- Do NOT hallucinate file structures, implementations,
  or package behaviors not visible in the provided code.
- Do NOT suggest replacing the declared tech stack.
  Isar, BLoC (flutter_bloc), and Clean Architecture are fixed
  constraints, not negotiable design choices.
- Do NOT propose new features — audit only existing code.
- Do NOT audit third-party package internals.

If the provided codebase exceeds your context window, explicitly
state which dimensions were NOT fully analyzed rather than
producing incomplete findings silently — and persist that fact in
the state file so the next session picks up exactly where this one stopped.

Before starting Dimension 1, check whether commonly load-bearing files were
provided: `pubspec.yaml`, `analysis_options.yaml`, `l10n.yaml`, CI workflow
files, `before_push.sh`. If any are missing, ask for them once, up front.

## Tech Stack Context

| Layer          | Technology                                        |
|----------------|---------------------------------------------------|
| Architecture   | Clean Architecture — feature-first (Domain / Data / Presentation) |
| State Mgmt     | BLoC (`flutter_bloc` / `hydrated_bloc`)           |
| Database       | Isar — local-first persistence                    |
| Async/React    | Streams, periodic/background timers, DB listeners |
| Localization   | `flutter_localizations` + `gen-l10n` (ARB files)  |
| CI/CD          | GitHub Actions + pre-push hooks (`before_push.sh`)|
| Code Gen       | `build_runner` — Isar schema, injectable, l10n    |

## Audit Iteration Protocol

Prioritize findings in this strict order:

1. CRITICAL — Dimensions 1, 2, 3 (pipeline & architecture)
2. CRITICAL — Dimensions 4, 5, 10 (runtime stability & security)
3. CRITICAL — all remaining dimensions
4. All WARNING items
5. OPTIMIZATION items last

## State & Resumability

**MANDATORY** — the state/findings files on disk are the only persistent record; the chat
session is not.

### Lifecycle: Fresh Run vs Resume
- **Fresh Audit:** When the user requests a new audit (e.g. "zrób audyt", "sprawdź architekturę"),
  do not delete, clear, or overwrite existing `.audit-architect-bloc/` data. If prior state exists,
  preserve it and ask before replacing it or choose a separate run-specific location.
- **Resume:** Only read an existing `state.md` and resume from its pointer if continuing
  an explicitly interrupted session.

### Execution Rules
- Write every finding to `.audit-architect-bloc/findings.md` in full detail
  (ID, evidence, confidence, fix) as soon as it's found.
- Granularity: append after finishing each **file** within the current dimension.
- Keep chat output brief while working: one line per file, e.g.:
  `✅ D3, lib/features/onboarding/onboarding_bloc.dart — 2 findings → findings.md`
- The exception is the final REQUIRED OUTPUT FORMAT report — read that in full, in chat.

Structure `.audit-architect-bloc/state.md` as:
```
## Dimension progress
| # | Dimension | Status | Findings so far |
|---|---|---|---|
| 1 | CI/CD & Config Integrity | ✅ Done | 3 |
| 3 | BLoC anti-patterns | ⏳ In progress | 2 |
| 4 | Lifecycle & Resource Mgmt | ⬜ Not started | - |

## Resume pointer
Next: Dimension 3, continue from lib/features/onboarding/...
```

## Audit Dimensions — Execute All

### DIMENSION 1 — CI/CD & Configuration Integrity

- Verify `.github/workflows/ci.yml` and `before_push.sh` step ordering.
- Confirm `build_runner` executes before analysis and tests.
- Flag missing secrets, unguarded env vars, or steps that silently pass on failure.
- Check if CI logs could accidentally expose `--dart-define` values or API keys.
- Audit `analysis_options.yaml`: detect unimplemented `custom_lint` rules, verify
  `exclude` patterns don't suppress production files.
- Audit `pubspec.yaml` and `l10n.yaml`: verify code gen config for Isar/injectable/l10n,
  flag `any` version constraints on non-dev deps, detect `dependency_overrides`.

### DIMENSION 2 — Clean Architecture Boundary Violations

- Verify zero imports of `package:flutter`, `material.dart`, or BLoC inside domain layer.
- Detect any screen/widget/BLoC directly importing Isar collection classes or `*.g.dart`
  collection types or concrete repository implementations.
- Confirm Data layer implements Domain interfaces only; flag domain importing `data/`.
- Verify BLoCs/Cubits depend only on abstract domain repository interfaces.
- Flag any domain or data class making routing decisions or holding `BuildContext`.

### DIMENSION 3 — BLoC Anti-Patterns & State Management Gaps

- Flag BLoC states that are not immutable (missing `sealed class`, `final` fields, `copyWith`).
- Flag `context.read<T>()` used directly inside `build()`.
- Flag `context.watch<T>()` used outside `build()`.
- Detect UI side-effects (navigation, snackbars, dialogs) triggered inside `BlocBuilder`.
- Verify stream subscriptions inside BLoCs are properly canceled in `close()`.

### DIMENSION 4 — Lifecycle & Resource Management

- Verify every `AnimationController`, `TextEditingController`, `ScrollController`,
  `FocusNode`, `PageController`, and `StreamSubscription` has a corresponding `dispose()`.
- Identify active periodic timers or stream listeners that fail to pause on
  `AppLifecycleState.paused` / `.inactive`.
- Detect every `BuildContext` usage across an `await` boundary without a `mounted` guard.
- Flag `Navigator.of(context)` or `ScaffoldMessenger` calls after async gaps.

### DIMENSION 5 — Isar DB & Data Layer Inefficiencies

- Flag synchronous Isar operations on the main UI thread.
- Verify collections used for sorted/filtered queries declare `@Index` annotations.
- Detect N+1 query patterns inside loops.
- Flag unbounded `.findAll()` calls without pagination or size limits.
- Verify multi-object writes are wrapped in a single `isar.writeTxn()`.
- Confirm all Isar exceptions are caught at the Data layer and mapped to domain `Failure` types.

### DIMENSION 6 — Dead Code, Disconnected Views & Broken Flows

- Audit every screen, dialog, and bottom sheet for reachability from the primary user flow.
- Verify every `GoRoute` path maps to an implemented screen; audit `redirect` logic.
- Identify BLoC/Cubit states emitted but never consumed by any widget.
- Detect `setState` calls mutating data that belongs in a BLoC.
- Flag public methods, classes, or files with zero internal references.

### DIMENSION 7 — Robustness, Safety & Code Smells

*Hardcoded-string findings here are a triage signal only — use the `i18n-audit` skill for the full audit.*

- Flag empty `catch` blocks; flag bare `catch (e)` without logging.
- Detect `double.parse()` / `int.parse()` without `tryParse` fallbacks.
- Flag forced `!` unwraps without an adjacent comment documenting the invariant.
- Flag `as TypeName` casts without prior type checks.
- Flag numeric literals in layout, styling, or animation duration not referenced to named constants.
- Detect `print()` statements in non-debug code paths.
- Flag `debugPrint()` or `log()` statements outputting sensitive health data.

### DIMENSION 8 — Test Suite Assessment

*Use the `unit-test-audit` skill for iterative test writing.*

- Identify untested critical business paths.
- Flag critical BLoCs/Cubits with zero unit test coverage (missing `blocTest`).
- Verify repository unit tests exercise both success and failure paths.
- Flag tests using `expect(result, isA<SomeType>())` without asserting on content.
- Flag golden tests without a fixed viewport size or seeded locale.
- Flag tests using `Future.delayed` or real timers instead of `FakeAsync`.

### DIMENSION 9 — Documentation vs. Reality

- Flag features described as "fully implemented" that are missing, stubbed, or misconfigured.
- Flag architectural rules declared in docs that are actively violated in the codebase.
- Identify `TODO` / `FIXME` / `HACK` comments in code that contradict documentation claims.
- Flag discrepancies between documented API contracts and their actual implementations.

### DIMENSION 10 — Security & Data Privacy

- Detect sensitive user data stored in plaintext Isar collections without documented justification.
- Verify `LocalAuthentication` error paths handle all terminal cases.
- Flag if biometric auth can be bypassed via direct route navigation.
- Detect hardcoded API keys, tokens, or secrets in any Dart or config file.
- Flag `print`/`debugPrint`/`log` calls outputting PII or health data outside `kDebugMode` guards.

### DIMENSION 11 — Dependency & Version Hygiene

- Flag `any` constraints on non-dev dependencies.
- Flag overly tight exact-version pins without documented justification.
- Detect `dependency_overrides` entries without a documented reason.
- Identify deprecated BLoC APIs (e.g. `mapEventToState`).
- Flag deprecated Flutter framework APIs (e.g. `WillPopScope` instead of `PopScope`).
- Flag packages in `dependencies` that should be in `dev_dependencies`.

### DIMENSION 12 — Platform, Layout & Accessibility

- Identify layouts vulnerable to `RenderFlex overflow` during keyboard appearance or
  system font scaling.
- Flag `Column`/`Row` with variable-length text without `Flexible` or `Expanded`.
- Flag hardcoded pixel values for spacing, font sizes, or touch targets.
  Minimum touch target: 48×48 logical pixels (Material spec).
- Verify all `MethodChannel` calls implement error handlers on both Dart and native side.
- Flag interactive widgets missing `Semantics` labels (icon-only buttons, custom painters).
- Flag hardcoded `Colors.white` / `Colors.black` or hardcoded hex colors.
- Verify `Theme.of(context)` is used for all color and text style references.

## Required Output Format

Generate the report in strict Markdown, in this exact order. Build every section from
`.audit-architect-bloc/findings.md`'s cumulative findings — not just the current session.

---

## 🔴 AUDIT HEADER

| Field              | Value |
|--------------------|-------|
| Audit Round        | [N] |
| Overall Status     | [BLOCKED / WARNINGS / CLEAN] |
| Base Commit / PR   | [SHA, branch, or PR reference] |
| Files Analyzed     | [N files explicitly provided] |
| Dimensions Covered | [list all; flag any marked NOT ANALYZED] |

## 📊 AUDIT SUMMARY DASHBOARD

| Dimension | Status | Critical | Warning | Opt |
|---|---|---|---|---|
| 1. CI/CD & Config | 🔴/✅ | N | N | N |
| 2. Architecture Boundaries | 🔴/✅ | N | N | N |
| 3. BLoC Patterns | 🔴/✅ | N | N | N |
| 4. Lifecycle & Memory | 🔴/✅ | N | N | N |
| 5. Isar & Data Layer | 🔴/✅ | N | N | N |
| 6. Dead Code & Navigation | 🔴/✅ | N | N | N |
| 7. Robustness & Safety | 🔴/✅ | N | N | N |
| 8. Test Suite | 🔴/✅ | N | N | N |
| 9. Docs vs Reality | 🔴/✅ | N | N | N |
| 10. Security & Privacy | 🔴/✅ | N | N | N |
| 11. Dependencies | 🔴/✅ | N | N | N |
| 12. Platform & Accessibility | 🔴/✅ | N | N | N |
| **TOTAL** | | **N** | **N** | **N** |

## 🚨 CRITICAL findings — use structure:
- **ID:** C-[N] · **Dimension:** · **File & Location:** · **Evidence:** · **Confidence:** · **Risk:** · **Fix:**

## ⚠️ WARNING findings — use structure:
- **ID:** W-[N] · **Dimension:** · **File & Location:** · **Issue:** · **Confidence:** · **Fix:**

## 💡 OPTIMIZATION findings:
- **ID:** O-[N] · **Dimension:** · **Suggestion:**

## ✅ WHAT IS CORRECT & WELL-IMPLEMENTED
## 🟡 CONSCIOUS TECH DEBT

## 🩹 VERDICT & PATCH

**Pipeline Status:** `BLOCKED` / `PASSING WITH WARNINGS` / `CLEAN`

Provide Option A (`.patch` snippet) when the fix is fully derivable from provided files.
Provide Option B (manual instructions) when a clean patch isn't safe to generate.
Never fabricate a diff against a file you don't have complete content for. Follow `AGENTS.md`
for scope, preservation of existing user changes, verification, and commit authorization; this
skill does not authorize destructive cleanup or commits before the required pipeline passes.

---

**If asked to apply patches:** treat patching as a separate task. Apply focused changes and follow
`AGENTS.md` for the complete verification pipeline and commit authorization; do not commit before
all required verification steps pass.
