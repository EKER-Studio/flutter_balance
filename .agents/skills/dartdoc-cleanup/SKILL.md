---
name: dartdoc-cleanup
description: >
  Audyt i porządkowanie komentarzy oraz dokumentacji DartDoc w kodzie Flutter/Dart.
  Usuwa zbędne i oczywiste komentarze, tłumaczy polskie komentarze/DartDoc na angielski,
  zachowuje wartościową dokumentację architektoniczną.
  Używaj ZAWSZE, gdy użytkownik mówi: "uporządkuj komentarze", "wyczyść komentarze",
  "przetłumacz komentarze na angielski", "sprawdź dartdoc", "dartdoc cleanup", "clean comments".
---

# Skill: Flutter/Dart Comment & DartDoc Cleanup

## Purpose & Objective

Process the Flutter codebase **file by file** to clean up comments and DartDoc:
1. Remove redundant comments (contextual judgment).
2. Detect non-English comments/DartDoc and **translate or remove** them based on real value.

End result: clean code with English-only comments, zero informational noise, and genuine
documentation value preserved where needed.

---

## State Lifecycle & Safety Check

### Lifecycle: Fresh Run vs Resume
- **Fresh Pass:** When a new cleanup pass is triggered, archive or reset `.audit-comments/log.md`.
- **Resume:** Continue from `log.md` only when resuming an explicitly interrupted run.

### Safety Check

**Include:** `lib/**/*.dart` (ask whether `test/**/*.dart` is also in scope)

**Skip (never touch):**
- Auto-generated: `*.g.dart`, `*.freezed.dart`, `*.gr.dart`, `*.mocks.dart`, `*.config.dart`
- Files under `.dart_tool/`, `build/`
- Generated localization files (clearly marked as generated)
- License/copyright headers at the top of files

---

## Before You Start — Safety Check

Run `git status`. If not clean, **stop and ask** — this task should produce one clean,
reviewable diff. Ideally runs on a dedicated branch.

Ensure `.gitignore` has a `.audit-*/` entry; add one if missing and commit it alone.

---

## Operating Mode — Memory-Safe Iteration (IMPORTANT)

1. **Never load the whole project into context.** Start by listing file *paths* only.
2. **Process exactly one file at a time.** Read → evaluate → edit → save → next file.
3. **Plan only from the path list** — never from file contents not yet processed.
4. **Append-only progress log.** After each file, append one line to `.audit-comments/log.md`.
   Chat message for that file: one short line (e.g. `✅ lib/foo/bar.dart — removed 3, translated 2`).
5. **Resume from the log.** Read `.audit-comments/log.md` first; skip files marked `done`.
6. **Oversized files (>250 lines):** process in two grep-based passes instead of reading whole:
   - Pass 1: `grep -n "^\s*///"` — extract DartDoc blocks only
   - Pass 2: `grep -n "//"` — extract inline comments only
   Read only the surrounding lines needed to judge a given comment.
7. **Commit per file.** After each file is edited, logged, commit it alone:
   `chore: clean up comments in lib/foo/bar.dart`

---

## Comment Evaluation Rules (`//`, `/* */`)

Judge contextually. For each comment, ask in order:

1. Does it explain **"why"**, not "what" (a design decision, workaround, non-obvious dependency)?
   → **keep**, translate if needed.
2. Does it just restate the obvious "what", already clear from the name?
   → **remove**.
3. Is it commented-out dead code?
   → **remove**, unless explicitly marked as an intentional placeholder — then keep and translate.
4. Is it a stale TODO/FIXME/HACK referring to an already-resolved issue?
   → **remove**.
5. Is it a current, meaningful TODO/FIXME?
   → **keep**, translate if needed.
6. Genuinely unsure between remove/keep?
   → **keep**, translate and tighten, log it as "needs manual review" in `notes:`.

---

## DartDoc (`///`) Rules for Public API

Applies to public classes, methods, fields, top-level functions (not `_`-prefixed).

- **Non-English DartDoc with real value** (contract, edge case, side effect) → **translate** and tighten.
- **Non-English DartDoc that adds nothing** (restates name, empty, trivial) → **remove** the whole block.
- **English DartDoc:** keep, unless worthless — then remove.
- Short and precise beats long and padded.

**`///` on private members (`_`-prefixed):** treat as a regular comment (apply the
Evaluation Rules above, not the public-API rules). If the rules say keep it, translate it.

---

## Never Touch

- License/copyright headers.
- Tooling directives: `// ignore:`, `// ignore_for_file:`, `// coverage:ignore`.
- Auto-generated code.
- String literals in code (UI text, error messages) — out of scope.

---

## Progress & Report Log

Maintain `.audit-comments/log.md` as an append-only per-file record:

```
- [x] lib/path/to/file.dart — removed: 3, translated: 2, notes: none
```

Use `notes:` for edge cases kept despite ambiguity, for later manual review.

If `log.md` grows too large, archive older entries to `log-archive-<N>.md` in the same
folder and keep only the unprocessed tail plus a one-line pointer in `log.md`.
`log.md` must always be the first thing you read when resuming.

---

## Step-by-Step Process

1. Check git status is clean.
2. List all in-scope `.dart` file paths.
3. Read `.audit-comments/log.md` if it exists; skip files already marked `done`.
4. For each remaining file, in path-alphabetical order:
   - Read the file (or two-pass grep approach if >250 lines).
   - Identify all comments and DartDoc.
   - Apply evaluation rules.
   - Apply the edits.
   - Save the file.
   - Append one line to the log.
   - Commit the change for this file alone.
5. After the whole project is processed, run:
   ```bash
   dart format lib test
   flutter analyze
   ```
   Report any new errors/warnings introduced by the changes.
6. Print the final summary. Don't delete `.audit-comments/` automatically — leave it
   for manual review of the `notes:` entries.

---

## Final Summary (required)

Report:
- Total files scanned
- Total comments removed
- Total comments/DartDoc translated
- List of edge cases kept despite ambiguity (from `notes:` entries) — for manual review
