# PROMPT: Flutter/Dart Comment & DartDoc Cleanup Audit

A reusable, project-independent prompt. Paste into an agentic coding tool (Cline, Aider, Continue, Claude Code, etc.) at the root of any Flutter project. Designed to stay safe under small context windows (~16k–40k tokens).

---

## Role & Goal

Go through a Flutter project **file by file** and clean up comments and DartDoc:
1. Remove redundant comments (contextual judgment — not a rigid rule list).
2. Detect comments/DartDoc written in a language other than English and **translate or remove** them, depending on whether they carry real value.

End result: code with English-only comments, no informational noise, and documentation value preserved (or improved) where it's actually needed.

## Scope

**Include:**
- `lib/**/*.dart`
- optionally `test/**/*.dart` (ask if it's not clear from the task whether tests are in scope)

**Skip (never touch):**
- auto-generated files: `*.g.dart`, `*.freezed.dart`, `*.gr.dart`, `*.mocks.dart`, `*.config.dart`
- files under `.dart_tool/`, `build/`
- generated localization files (`flutter_gen`, `intl`, `l10n` — when clearly marked as generated)
- license/copyright headers at the top of files, if present

## Before You Start — Safety Check

Run `git status` before touching anything. If the working tree is not clean (uncommitted changes present), **stop and ask** before making any edits — this task should produce one clean, reviewable diff, not a mix of unrelated changes. Ideally this task runs on a dedicated branch.

## Operating Mode — Memory-Safe Iteration (IMPORTANT)

This task can involve dozens or hundreds of files, and you may be running with a small context window. Follow these rules strictly — they are not optional:

1. **Never load the whole project into context.** Start by listing file *paths* only (a glob/tree listing), not file contents.
2. **Process exactly one file at a time.** Read → evaluate → edit → save → move to the next file. Do not hold more than one file's full content in your working context at the same time. Do not "read ahead" into other files to plan changes.
3. **Plan only from the path list.** Any prioritization or batching decision is made off file paths/sizes, never off file contents you haven't processed yet.
4. **Append-only progress log.** After finishing each file, append one line to a log file on disk (see below) instead of keeping the running report in your own context. This keeps your context footprint flat regardless of project size.
5. **Resume from the log.** At the start of a run, read the log first and skip any file already marked `done`. This lets the task be stopped and resumed across multiple sessions without re-reading finished files.
6. **Oversized individual files.** If a file is longer than **250 lines**, process it in two passes instead of loading it whole:
   - Pass 1: only `///` DartDoc blocks and file-level comments.
   - Pass 2: only inline `//` / `/* */` comments.
   Re-open the file fresh for pass 2 — don't try to carry pass-1 reasoning in context. (250 lines is a hard threshold, not a judgment call — it accounts for the low end of a 16k–40k token context window once these instructions are also loaded.)
7. **Commit per file.** After each file is edited, saved, and logged, make a small git commit for that file alone (e.g. `chore: clean up comments in lib/foo/bar.dart`). This bounds the damage of an interrupted run — if the session dies mid-project, everything up to the last commit is safe and reviewable, and the log tells you exactly where to resume.

## Comment Evaluation Rules (`//`, `/* */`)

No rigid checklist — judge contextually. For each comment, ask in this order:

1. **Does it explain "why", not "what"** (a design decision, a workaround, an edge case, a non-obvious dependency)? → keep, translate if needed.
2. **Does it just restate the obvious "what"**, already clear from variable/method names? → remove.
3. **Is it commented-out dead code?** → remove, unless explicitly marked as an intentional placeholder / future extension point (e.g. a comment next to an unused DI module reserved for a future feature) — then keep and translate.
4. **Is it a stale TODO/FIXME/HACK** referring to an already-resolved issue? → remove.
5. **Is it a current, meaningful TODO/FIXME?** → keep, translate if needed.
6. **When genuinely unsure** between remove/keep → keep, but translate and tighten it, and log it as a case for manual review.

## DartDoc (`///`) Rules for Public API

Applies to classes, public methods, fields, top-level functions — anything that actually surfaces in generated documentation (i.e. not prefixed with `_`).

- **Non-English DartDoc:**
  - if it carries real value (contract, edge case, side effect, usage example) → **translate** and tighten; add anything trivially obvious from the code that's missing (e.g. a parameter description)
  - if it adds nothing (restates the method/class name, empty, trivial) → **remove** the whole DartDoc block
- **English DartDoc:** keep, unless it's worthless as above — then remove.
- Short and precise beats long and padded — don't inflate it artificially.

**`///` on private members (`_`-prefixed):** these never reach generated docs, so treat them exactly like a regular comment — run them through the Comment Evaluation Rules above (redundancy first), not the public-API rules. If the rules say to keep it, translate it if it's not in English; the `///` syntax itself doesn't matter for this decision.

## Never Touch

- License/copyright headers.
- Tooling directives: `// ignore:`, `// ignore_for_file:`, `// coverage:ignore`, analyzer/linter annotations.
- Auto-generated code.
- String literals in code (UI text, error messages) — these are not comments and are out of scope.

## Progress & Report Log

Create (or reuse) `LOG_COMMENT_CLEANUP.md` in the project root. After each processed file, append one line:

```
- [x] lib/path/to/file.dart — removed: 3, translated: 2, notes: none
```

Use `notes:` for edge cases kept despite ambiguity, so they can be checked by hand later.

## Step-by-Step Process

1. Check git status is clean (see "Before You Start").
2. List all in-scope `.dart` file paths.
3. Read `LOG_COMMENT_CLEANUP.md` if it exists; skip files already marked `done`.
4. For each remaining file, in path-alphabetical order:
   - read the file (in two passes if over 250 lines — see rule 6 above),
   - identify all comments and DartDoc,
   - apply the evaluation rules (redundancy + language; private `///` follows the comment rules, public `///` follows the DartDoc rules),
   - apply the edits,
   - save the file,
   - append one line to the log,
   - commit the change for this file alone.
5. After the whole project is processed, run `dart format .` and `dart analyze` (if available in the environment) and report any new errors/warnings introduced by the changes.
6. Print the final summary (see below), then delete `LOG_COMMENT_CLEANUP.md` — it's a working artifact, not documentation, once the run is complete.

## Final Summary (required)

Report:
- total files scanned,
- total comments removed,
- total comments/DartDoc translated,
- list of edge cases kept despite ambiguity (pulled from the `notes:` entries in the log) — for manual review.

---

*This prompt is project-independent. Before use in a new repo, just confirm the `lib/`/`test/` paths and generated-file patterns match that repo's actual structure.*
