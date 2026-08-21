# Flutter/Dart code style (Continue supplemental rules)
These rules supplement AGENTS.md (SSOT). If there is any conflict, AGENTS.md wins.

## Formatting and lint
- Keep code compliant with `dart format`.
- Prefer explicit types in public APIs; avoid `dynamic`.

## Widgets and UI
- Keep widgets small; if `build()` grows, extract private widgets/methods.
- Use `const` where possible.
- Do not do heavy work inside `build()`.
- Keep spacing and styling consistent (Theme/Design System if present).

## Testing
- New logic => unit tests.
- UI behavior changes => widget tests when feasible.
- Tests must be deterministic (avoid timers/delays unless required).