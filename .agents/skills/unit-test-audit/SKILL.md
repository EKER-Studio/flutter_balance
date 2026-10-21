---
name: unit-test-audit
description: >
  Audytor i generator testów jednostkowych w Flutterze (Domain → Data → Presentation/BLoC).
  Identyfikuje luki w pokryciu testami, analizuje jakość asercji, naprawia i dopisuje brakujące testy.
  Używaj ZAWSZE, gdy użytkownik mówi: "audyt testów jednostkowych", "sprawdź testy",
  "pokrycie testami", "dopisz testy", "brakujące testy", "unit test audit", "test coverage",
  "przetestuj kod".
---

# Skill: Flutter Unit Test Auditor

## 0. Before You Start — Safety Check

Inspect the worktree before editing so existing changes are preserved. Do not stop solely because
it is dirty, and do not modify `.gitignore` or commit audit setup files unless the user asks.

---

## 1. Purpose & Objective

Audit unit test coverage layer by layer (Domain → Data → Presentation/BLoC), identify
gaps in assertions or edge cases, and implement missing unit tests.
Execution proceeds in **rounds**: Inventory → Fix/Complete → Verify.

**Do not start changing code until Round 1 is complete and reported.**

---

## 2. Context Budget & Statefulness Protocol — read every session

**Never load the entire project into context.** The progress file is your memory.

### 2.1 Lifecycle: Fresh Run vs Resume
- **Fresh Audit:** When a new test audit is triggered (e.g. "zrób audyt testów"),
  preserve any existing `.audit-test/` data. Ask before replacing it, or use a separate run-specific
  location if a fresh state file is needed.
- **Resume:** Only resume from `progress.md`'s pointer if continuing an explicitly
  interrupted run.

### 2.2 Progress folder
All state lives in `.audit-test/progress.md`:
- Current round number
- Layer order (fixed: `domain → data → presentation`)
- File table: `File | Layer | Status | Severity | Round | Notes`
- **Resume pointer:** `Round <N> — <file path>`

Split by layer (`domain.md`, `data.md`, `presentation.md`) if the table gets unwieldy —
but `progress.md` must always be the first thing you read.

### 2.3 Discovery pass — list, don't read

Use `find` / `grep --include` to enumerate files by path only. Status: `⏳ pending audit`.
This is distinct from `🚫 Missing test` — that only appears after actually checking.

### 2.3 Per-step protocol

1. Read `progress.md`.
2. Pick next item per layer order and resume pointer.
3. Read only the source file and its test file (nothing else unless strictly needed).
4. Analyze / fix / write tests for that item only.
5. Run the affected test file.
6. Do not commit during per-file processing. Follow `AGENTS.md` for the required verification
  pipeline and commit authorization after the complete change is verified.
7. Update `progress.md` and move the resume pointer.

### 2.4 Batch granularity

Default: **one file at a time**. Reserve ≥40% context for reasoning and output.

### 2.5 Test run output

Single test file: read output directly.
Multi-file run: redirect to log and filter:
```bash
flutter test --exclude-tags golden
grep -E "All tests passed|FAILED|Some tests failed" .audit-test/last_run.log
```

---

## 3. Scope & Layer Priority

1. **Domain** — use cases, business logic, entities with logic, value objects
2. **Data** — repository implementations, data sources, mappers/DTO ↔ Entity
3. **Presentation** — BLoC/Cubit states & events

Skip: `*.g.dart`, `*.freezed.dart`, `*.gr.dart`, `main.dart`/bootstrap, thin wrappers.
Out of scope unless requested: widget tests, integration tests, e2e tests.

---

## 4. Stack Detection (auto-detect, never assume)

Before starting, check `pubspec.yaml` and existing tests:
- State management: BLoC / Cubit → use `blocTest` from `bloc_test`
- Mocking library: check existing tests (mocktail / mockito); if no tests yet, propose `mocktail`
- Whether `test/` mirrors `lib/` structure
- Naming convention for test files and descriptions

---

## 5. Round 1 — Inventory & Diagnosis

For each item, check:
- Does a corresponding test file exist?
- If yes — confirm generated files (`*.g.dart`, `*.mocks.dart`) are current; regenerate
  via `build_runner` if in doubt. A stale generated file is a common false `❌ Broken`.
- Does it compile and pass?
- Does it actually verify anything (not `expect(true, true)`)?
- Does it cover: happy path, edge cases, errors/exceptions, boundary states?
- Is it Arrange-Act-Assert with mocks fully isolated (no real I/O, no Isar, no network)?
- Does the test name describe **behavior**, not implementation?

**Status values:** `✅ OK` / `⚠️ Incomplete` / `❌ Broken or failing` / `🚫 Missing test`
**Severity:** `Critical` / `High` / `Medium` / `Low`

Present the full table and wait for confirmation before starting Round 2 — unless the
operator has explicitly authorized running straight through.

---

## 6. Repair Decision Criteria

- **Stale generated code** → regenerate, re-run. Only proceed if failure persists.
- **Bug in the test itself** → fix it locally, keep the rest of the test intact.
- **Structurally flawed test** → rewrite from scratch per Section 7 standards.
- **Test caught a real production bug** → do NOT fix the test to match broken behavior.
  Report as a separate finding. Do not change production code without confirmation.

---

## 7. Testing Standards per Layer

**Domain**
- Pure unit tests, no Flutter SDK or Isar mocks.
- Use cases: mock repositories via their interfaces; test every logic path,
  early returns, validation, error mapping to Failures.

**Data**
- Repositories: mock data sources; test `IsarException` → domain `Failure` mapping,
  cache/fallback logic.
- Mappers: table-driven (parametrized) tests for DTO → Entity and back,
  including nullable/optional fields.

**Presentation (BLoC / Cubit)**
- Use `blocTest`; assert emitted state sequence (`expect: () => [...]`).
- Verify seed states and check event handlers.
- Verify side effects (use case calls) with `verify()` on mocks.
- No UI detail testing here — that's widget-test scope.

---

## 8. Round 2 — Fix & Complete

- Order: `Critical → High → Medium → Low`, within layer order (Domain → Data → Presentation).
- After each change, run the affected test file and confirm green.
- Don't change production behavior just to make a test pass.
- Follow the naming convention and structure already present in the project.

## 9. Round 3 — Verify

- Run the project verification pipeline from `agents_project.md`; use its golden-test exclusions.
- Confirm no regressions. Check for flaky tests (async/`Timer`/`Stream`).
- If anything still fails → Round 4 (targeted fix) or close with open items list.

## 10. Final Report Format

From the progress file's cumulative table:
- `File → Status → Severity → Action taken → Reasoning`
- **Open items:** production bugs surfaced, deferred tests, decisions needing input
- **Numeric summary:** files without tests (start vs. end), tests fixed, coverage delta

## 11. Startup Checklist

Clarify before starting:
1. Scope: whole project / specific module / diff since last tag
2. OK to run `flutter test` automatically: yes/no
3. Stop after Round 1 before fixes: yes/no
4. `.audit-test/progress.md` exists? If yes, resume from Resume pointer. If no, run discovery pass.
