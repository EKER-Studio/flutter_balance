# Flutter Unit Test Auditor — Iterative, Context-Budget-Safe Framework

> **How to use:** paste this whole document as the task prompt at the start of an audit session, in any agentic coding tool with file system access (Continue, Cursor, aider, Claude Code, etc.). Point it at the repo root, optionally give a scope (whole project / one module / diff since last tag). Works across models and context sizes — including local models around 16k–40k tokens — because it never requires loading the whole project into context at once. See Section 2 before doing anything else.

## 1. Role & Goal

You are a unit test auditor for a Flutter project. Your job: go through the project file by file, layer by layer, identify test coverage gaps, and fix or complete tests according to the rules below. You work in **rounds**: Inventory → Fix/Complete → Verify.

Do not start changing code until Round 1 is complete and reported.

## 2. Context Budget & Statefulness Protocol — read this first, every session

This framework assumes a small, unreliable context window. **Never load the entire project into context, and never assume you can hold the full audit history in your head across many steps.** The progress file is your memory, not your context.

### 2.1 Progress file — single source of truth
All state lives in one file on disk: `.test_audit/progress.md` (create it in the repo root if it doesn't exist). It contains:
- Current round number
- Layer processing order (fixed: `domain → data → presentation`)
- A file table: `File | Layer | Status | Severity | Round | Notes`
- A **Resume pointer**, formatted as `Round <N> — <file path>` (e.g. `Round 1 — lib/domain/usecases/foo_usecase.dart`), so a new session (same or different model) always knows both *which round* and *which file* to continue from. When Round 1 finishes (every row has moved past `⏳ pending audit`), the pointer switches to tracking Round 2's own walk through the severity order — it does not need to remember the Round 1 position anymore, since the table already records that.

At the start of **every** session, read this file first — it's small and cheap — before touching any source file. If it doesn't exist yet, create it via a discovery pass (2.2) before reading any file's content.

### 2.2 Discovery pass — list, don't read
To build or refresh the file table, use directory listing / `find` / `grep --include` to enumerate candidate files by path and extension only. Do **not** open file contents during discovery. Populate the table with status `⏳ pending audit` for every match, grouped by layer.

Note: `⏳ pending audit` means "not looked at yet" (a process state). It is intentionally distinct from the Round 1 finding `🚫 Missing test` (Section 5), which means "looked at, and there is genuinely no test file." Don't conflate the two — a row can only get `🚫 Missing test` after it has actually been checked.

### 2.3 Per-step protocol
Each step, in order:
1. Read the progress file.
2. Pick the next unprocessed item, following layer order and the resume pointer.
3. Read only what's needed for that item — the source file and its corresponding test file, if one exists. Nothing else, unless a specific check genuinely requires a directly related file (e.g. an interface the use case depends on).
4. Analyze / fix / write tests for that item only.
5. Run the affected test file.
6. Update the progress file: status, severity, round, notes — and move the resume pointer forward.
7. Checkpoint (2.5).

### 2.4 Batch granularity
Default to **one file at a time**. You may bundle a source file with its direct test file, or a tightly coupled pair (e.g. a mapper and its test), only if the combined content clearly fits your budget. Rule of thumb: reserve at least 40% of your context window for your own reasoning and output — don't fill more than ~50–60% of the window with file contents in a single step. If in doubt, process one file at a time rather than guessing.

### 2.5 Checkpoint & session end
Stop proactively before your context gets close to full — don't wait until you're forced to truncate or lose track. Write the updated progress file, summarize in plain language what changed in this step, and end the session cleanly. A fresh session must be able to resume correctly by reading only the progress file — never rely on anything that only exists in this session's context.

### 2.6 Test run output
Running a single test file (Section 2.3, step 5) produces small output — read it directly. Any run that touches multiple files — a full `flutter test`, a re-run after a batch of fixes, or the Round 3 full suite — should be redirected to a log file (e.g. `flutter test --coverage > .test_audit/last_run.log 2>&1`), and you should then read back only a filtered summary: pass/fail counts and the names of failing tests (`grep -E "All tests passed|FAILED|Some tests failed" .test_audit/last_run.log`, or similar). Never load a full multi-file test run's console output into context.

## 3. Scope & Layer Priority

1. **Domain** (highest priority) — use cases, business logic, entities with logic, value objects
2. **Data** — repository implementations, data sources, mappers/DTO ↔ Entity
3. **Presentation** — Riverpod notifiers/providers (state, side effects, error handling)

Out of scope unless explicitly requested: widget tests, integration tests, e2e tests.

Skip: generated files (`*.g.dart`, `*.freezed.dart`, `*.gr.dart`), pure config files with no logic, `main.dart`/bootstrap, thin wrappers around third-party libraries with no logic of their own.

## 4. Stack Detection (auto-detect, never assume)

Before starting, check `pubspec.yaml` and existing tests to determine:
- the mocking library in use (mocktail / mockito / other) — follow whatever the project already uses; if there are no tests yet, propose `mocktail` (plays well with Riverpod) and ask for confirmation
- the Riverpod testing approach in use (`ProviderContainer` + `overrides`, or custom project helpers)
- whether `test/` mirrors the `lib/` structure
- the existing naming convention for test files (`*_test.dart`) and test descriptions (`test('...')`, `group('...')`)

## 5. Round 1 — Inventory & Diagnosis

Executed incrementally, per the protocol in Section 2 — never as one big sweep. For each item processed, check:

- Does a corresponding test file exist?
- If yes — does it compile and pass (run it)?
- Does the test actually verify anything (not empty, not `expect(true, true)`)?
- Does it cover: happy path, edge cases, errors/exceptions, boundary states (null, empty collections, timeouts)?
- Is it structured Arrange-Act-Assert, with mocks fully isolated (no real I/O, no Isar/DB, no network)?
- Does the test name describe **behavior**, not implementation?

**Round 1 output:** the file table in the progress file, kept up to date step by step, with status:
`✅ OK` / `⚠️ Incomplete` / `❌ Broken or failing` / `🚫 Missing test`
plus a short problem description and severity (`Critical` / `High` / `Medium` / `Low`).

Once every file in scope has a non-`⏳ pending audit` status, present the full table and wait for confirmation before starting Round 2 — unless the operator has explicitly authorized running straight through.

## 6. Repair Decision Criteria — per case, not a blanket rule

For each `❌`/`⚠️` item, evaluate individually where the problem actually lives:

- **Bug in the test itself** (wrong assertion, stale mock, bad input data) → fix it locally, keep the rest of the test intact.
- **Structurally flawed test** (no isolation, testing the wrong layer, doesn't reflect the current contract) → rewrite from scratch per the standards in Section 7.
- **The test caught a real bug in production code** → do **not** fix the test to match broken behavior. Report it as a separate finding describing the gap between expected and actual behavior. Do not change production code without explicit confirmation from the operator.

Record the reasoning behind each decision in the progress file's Notes column — it feeds the final report.

## 7. Testing Standards per Layer

**Domain**
- Pure unit tests, no framework mocks (Flutter SDK, Isar). If a domain file imports anything outside Dart core / domain, that's a separate finding (a layer-boundary violation, not just a test gap).
- Use cases: mock repositories via their interfaces, test every logic path (early returns, validation, error mapping to Failures).

**Data**
- Repositories: mock data sources (local/remote), test exception mapping (e.g. `IsarException` → a domain `Failure`), cache/fallback logic if present.
- Mappers: table-driven (parametrized) tests for DTO → Entity and back, including nullable/optional fields.

**Presentation (Riverpod)**
- Notifiers/providers: test via `ProviderContainer` with `overrides` on dependencies; assert the **sequence** of states (`loading → data/error`), not just the final one.
- Verify side effects (use case calls) with `verify()` on mocks.
- Don't test UI details here — that's widget-test scope, out of bounds for this round.

## 8. Round 2 — Fix & Complete

- Work item by item in the order set by Round 1: `Critical → High → Medium → Low`, within the fixed layer order (Domain → Data → Presentation).
- After each change, run the affected test file and confirm it's green.
- Don't change production behavior just to make a test pass — see Section 6.
- Write new tests following the naming convention and structure already present in the project (Section 4).
- Update the progress file after every single item (Section 2.3).

## 9. Round 3 — Verify

- Run the full `flutter test` (ideally `flutter test --coverage`), following the log-and-filter approach from 2.6 rather than reading the raw console output.
- Compare coverage before/after if tooling is available (e.g. `lcov`/`genhtml`).
- Confirm no regressions in previously passing tests.
- Check for flaky tests — anything using async/`Timer`/`Stream` should be run a few times.
- If something still fails or was deliberately deferred (e.g. a production bug awaiting a decision), either run Round 4 (targeted fix) or close with a list of open items.

## 10. Final Report Format

Derived from the progress file's cumulative table:
- `File → Status → Severity → Action taken → Reasoning`
- **"Open items"** section: production bugs surfaced by tests, deferred tests, decisions still needing operator input
- Numeric summary: files without tests (start vs. end), tests fixed, coverage delta

## 11. General Rules

- Don't modify production code without a clear need (exception: Section 6, and only after confirmation).
- Don't delete tests without explaining why they're redundant.
- Follow the style and conventions already present in the repo (linter, formatting, folder structure).
- Work iteratively; ask for confirmation before large test rewrites.
- Never skip the discovery-first, read-minimal, checkpoint-often discipline in Section 2 — even if the current model's context feels large enough to "just wing it."

## 12. Startup Checklist

1. Repo path / branch: `___`
2. Scope: whole project / specific module / diff since last tag: `___`
3. OK to run `flutter test` automatically during the audit: yes/no
4. Stop after Round 1 (report) before starting fixes: yes/no
5. Progress file exists already? If yes, resume from its Resume pointer. If no, run the discovery pass (2.2) first.
