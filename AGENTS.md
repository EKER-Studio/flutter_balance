# AI Agent Project Rules — Universal

*This file is identical across every Flutter/Dart project (copy or symlink it verbatim). It contains only
practices that hold regardless of state management (BLoC, Riverpod, ...), architecture details, or which
third-party libraries a given project happens to use. Anything specific to one project — stack, exact
commands, architecture, quirks — belongs in that project's own `agents_project.md`, which sits next to this
file and is OPTIONAL. If a repo has no `agents_project.md`, this file alone still fully applies.*

## Language
All technical comments, documentation, and logic descriptions in the codebase MUST be written in English.

## Documentation Convention
For every public class/method, add a doc comment following the language's standard doc format (dartdoc for
Dart, JSDoc for TypeScript, etc.):
- One sentence summarizing purpose (don't repeat the class/method name).
- One line per non-trivial parameter (`@param` or equivalent).
- Return value documentation only if it isn't obvious from the type.
- No code examples unless the logic is genuinely non-obvious.
- Do not document trivial getters/setters or self-explanatory boilerplate.

## Scope Discipline
- Only read, open, or modify files explicitly named in the task, or files directly imported/referenced by them.
- Do NOT explore or edit files outside the stated scope without first asking for confirmation.
- Exceptions that do NOT require asking first (natural consequences of a task, not scope expansion):
  - Regenerating/updating codegen output files (e.g. `.g.dart`) that correspond to a modified source file.
  - Updating an existing test file that directly tests the modified code, when needed to keep the Mandatory
    Verification Pipeline passing.
- If a task seems to require touching files beyond scope and beyond these exceptions, STOP and report which
  additional files you believe are needed, and why — before making changes.

## Ambiguity Handling
- If a requirement is ambiguous or underspecified, state your interpretation/assumption explicitly before
  proceeding, rather than silently guessing.
- Prefer asking one direct clarifying question over implementing multiple speculative variants.

## Dependency Changes
- Do NOT add, remove, or upgrade a dependency without explicitly flagging it in your response (name, version,
  reason).
- Never introduce a new dependency to solve a problem that can be reasonably solved with existing project
  dependencies or the Dart/Flutter stdlib.

## UI & Logging Hygiene
- Never hardcode raw color values (`Color(0xFF...)`, `Colors.*`) directly in UI/presentation code — use the
  project's centralized/semantic color token system. Its name and location are documented in
  `agents_project.md`.
- Never use `print` / `debugPrint` for logging — use the project's structured logger, if one exists. Its API
  is documented in `agents_project.md`.

## Resource Lifecycle & Disposal
Before considering any feature involving streams, timers, animations, platform connections (Bluetooth,
sockets, etc.), or any other disposable resource complete, verify that every such resource is released along
the relevant teardown path — `dispose()`, `close()`, `onDispose()`, or whichever hook the state-management
layer in use provides. Exactly which resource types apply in a given project (BLE connections, DB watch
streams, background services, event buses, ...) and where precisely they're torn down is documented
per-project in `agents_project.md`.

## Mandatory Verification Pipeline
After any modification within source directories (`lib/**`, `test/**`, or config that affects them), run the
following pipeline, in order, before considering the task complete. Skip a step only after confirming its
tool genuinely isn't configured in this project (e.g. no `l10n.yaml` → skip step 2) — never because it seems
inconvenient or slow:

1. **Install/refresh dependencies** — `flutter pub get` (if `pubspec.yaml` changed).
2. **Regenerate localization** — `flutter gen-l10n` (if `l10n.yaml` is present).
3. **Regenerate generated code** — `dart run build_runner build` (if `build_runner` is a dev dependency).
4. **Format** — `dart format lib test` (scope limited to `lib` and `test`; this auto-formats in place
   rather than just checking).
5. **Static analysis** — `flutter analyze`.
6. **State-management-specific lints** — `dart run custom_lint` (if configured — this is separate from
   `flutter analyze` and is NOT covered by it).
7. **Tests** — `flutter test` (exclude golden tests by default unless the project says otherwise).

A task is not complete until every applicable step is green with zero errors and zero failing tests, AND the
Resource Lifecycle & Disposal check above has been explicitly verified. If a project defines its own
canonical pipeline/script (e.g. `before_push.sh`) in `agents_project.md`, follow its exact commands and
ordering — but treat that as an implementation of the step categories above, never as license to silently
drop one of them.

## Git & Version Control
- Once the full Mandatory Verification Pipeline has passed (all steps green, zero errors, zero failing tests)
  for a completed, atomic logical change, **and this repository has an `agents_project.md`**, commit the
  change without asking for permission first.
- **If `agents_project.md` does not exist in this repository, do NOT commit autonomously — always ask for
  confirmation first, even after a fully green pipeline.**
- Do NOT commit if any pipeline step failed, was skipped, or could not be run — stop and report instead.
- Write descriptive, atomic commit messages (what changed and why, not just "fix"), following Conventional
  Commit style: `git commit -m '<type>(<scope>): <atomic description>'`.
- NEVER force-push, rewrite shared history, or delete branches without explicit confirmation.

## Security
- NEVER hardcode API keys, tokens, passwords, or other secrets in source code.
- NEVER commit `.env` files or other files containing local secrets.
- Use environment variables / the platform's secure storage mechanism for anything sensitive.

## Verification Honesty
- NEVER report that a verification step (build, analyze, lint, test) passed unless you actually executed it
  in this session and observed the output.
- If a step cannot be run (e.g. missing tool, sandboxed environment limitation), say so explicitly instead of
  assuming or claiming success.
- Do not fabricate or paraphrase tool output — quote or summarize only what was actually returned.

## Debug Artifact Cleanup
- Remove debug print/log statements and commented-out code introduced during iteration before considering a
  task complete, unless explicitly asked to leave them for further debugging.
- Do not leave stray TODO comments describing unfinished work without flagging them explicitly in your final
  summary.

## Guardrails
- NEVER delete, skip, or weaken a test to make the verification pipeline pass. Fix the underlying code
  instead.
- NEVER add lint-suppression comments (e.g. `// ignore:`) or disable analyzer/linter rules to silence errors,
  unless explicitly instructed.
- If a fix is not obvious after 2 attempts, stop and report the exact error instead of applying a workaround.

## Formatting & Style
- Follow the official Dart/Flutter style guide and formatter (`dart format`).
- Ensure generated files are correctly linked/imported per framework conventions (e.g.
  `part 'filename.g.dart';`).
