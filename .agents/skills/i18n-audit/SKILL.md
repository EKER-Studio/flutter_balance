---
name: i18n-audit
description: >
  Audyt i weryfikacja tłumaczeń, lokalizacji i tekstów w Flutterze (ARB + flutter gen-l10n).
  Wykrywa zahardkodowane teksty w UI, brakujące klucze tłumaczeń w językach, nieużywane klucze ARB,
  niezgodności parametrów i rejestrację w supportedLocales.
  Używaj ZAWSZE, gdy użytkownik mówi: "brakujące klucze tłumaczeń", "sprawdź tłumaczenia",
  "sprawdź teksty", "przetłumacz teksty", "audyt i18n", "l10n", "hardcoded strings",
  "teksty w aplikacji", "sprawdź angielski/polski w UI".
---

# Skill: Flutter i18n / L10n Audit

## Role

You are an i18n auditor for a Flutter project using `flutter gen-l10n` (`.arb` files,
`AppLocalizations`, `intl`). You work iteratively: **audit → fix → verify**, round by
round, until the project reaches the "Definition of Done".

---

## Context & Memory Discipline (read this before doing anything else)

**Rule 1 — Search, don't read.**
Default to `rg`/`grep` with `-n -C 1` instead of opening full files.

**Rule 2 — Process in bounded chunks.**
- **Category A:** one feature directory at a time (~150–250 lines max per chunk).
- **Category C:** batch keys in groups of ~25–30 per `rg` call:
  `rg -n "\.(key1|key2|...)\b" lib --glob '!**/l10n/generated/**' --glob '!**/*.g.dart'`
- **Category B:** read `.arb` files directly; batch if >150 keys.
- **Category E:** single-file check — always cheap.

**Rule 3 — Externalize state immediately.**
Maintain `.audit-i18n/state.md`, appending findings after each chunk:
```
## Config (from Round 0)
arb-dir: lib/l10n  |  template: app_en.arb  |  access: context.l10n.key

## Chunk checklist — Category A
- [x] lib/features/onboarding/  (3 findings)
- [ ] lib/features/dashboard/

## Findings — Category A
| # | Priority | File:line | Snippet | Proposed key | Status |
```
Split into per-category files (`findings-a.md`, `findings-c.md`, ...) if `state.md`
grows too large. `state.md` must always be the first thing you read.

**Rule 4 — Keep chat output brief:** one line per chunk, e.g.
`✅ lib/features/onboarding/ — 3 findings → state.md`. Full detail in the report only.

---

## Before You Start — Safety Check

Run `git status`. If tree is not clean, **stop and ask**.
Ensure `.gitignore` has a `.audit-*/` entry; add one if missing and commit it alone.

---

## Round 0 — Configuration Recon

1. Read `l10n.yaml`: establish `arb-dir`, `template-arb-file`, `output-class`.
2. List every `app_<locale>.arb` file.
3. Confirm the access pattern (e.g. `context.l10n.key`).
4. Identify excluded paths: `*.g.dart`, `*.freezed.dart`, `l10n/generated`, `test/`, `build/`.
5. Build chunk queue for Category A; extract full key list from `app_en.arb` for Category C.
6. Create `.audit-i18n/state.md` with config summary + empty checklists.

---

## Priority Scale

- **Critical** — compile/runtime break or real user-visible gap (mismatched placeholders,
  locale in `supportedLocales` with no `.arb`, empty translation rendered in UI).
- **High** — breaks i18n consistency (hardcoded UI string, missing key in target language).
- **Medium** — technical debt, no immediate user impact (dead key, identical en/pl value).
- **Low** — cosmetic (inconsistent key ordering).

---

## Audit Categories

### A. Hardcoded strings (missing i18n)

**Suspect locations:** `Text('...')`, `hintText:`, `labelText:`, `tooltip:`, dialogs,
snackbars, `AppBar(title: Text('...'))`, form validation messages.

**Exclude:** `debugPrint`/`log`, `Key('...')`, route names, asset paths, URLs, single
punctuation, strings in comments/tests. Proper nouns: flag as "needs confirmation".

For each finding: file:line, snippet, proposed `lowerCamelCase` ARB key.

### B. Translation completeness

For every `app_<locale>.arb` vs `app_en.arb`:
1. **Missing keys** → propose translation immediately (tag `needs-native-review: true`).
2. **Empty values** → propose translation (tag `needs-native-review: true`).
3. **Suspiciously identical values** → flag "needs manual review".
4. **Mismatched placeholder metadata** → **Critical**.

### C. Unused keys (dead translations)

Batch-search every key from `app_en.arb` in `lib/` (~25–30 keys per `rg` call).
Zero hits → candidate for removal. Don't auto-remove dynamically-built keys.
Remove confirmed-dead keys from **all** `.arb` files simultaneously, including `@key` blocks.

### D. ARB structural consistency

Report while doing A–C:
- keys in a target file missing from `en` (orphan),
- duplicate keys within one file,
- inconsistent ordering (optional suggestion).

### E. Locale registration (`supportedLocales`)

Find `MaterialApp`/`MaterialApp.router` and compare:
1. `.arb` exists but not in `supportedLocales` → **High**.
2. In `supportedLocales` but no `.arb` → **Critical**.
3. `AppLocalizations.delegate` missing from `localizationsDelegates` → **Critical**.

---

## Iterative Process (rounds)

**Round 1 — Audit.** Read and report only. Zero code changes. Output: report below.

**Round 2 — Fix.** Apply fixes: externalize strings, fill translations, remove dead keys,
fix placeholders. One chunk → verify → commit → next chunk.

**Round 3 — Verify.** Re-run A, B, C, E heuristics from scratch. Repeat Round 2 for
any remaining issues.

---

## Report Format

```
## Round N — [Audit/Fix/Verify]

### A. Hardcoded strings
| # | Priority | File:line | Snippet | Proposed key | Status |

### B. Translation completeness
| # | Priority | Key | Language | Issue | Status |

### C. Unused keys
| # | Priority | Key | Occurrences in lib/ | Status |

### D. Structural consistency
| # | Priority | Description | Status |

### E. Locale registration
| # | Priority | Language | Issue | Status |

### Needs manual review
| # | Category | Key/Location | Why it needs a decision |

### Round summary
Critical: X | High: Y | Medium: Z | Low: W | Fixed: A | Remaining: B
```

---

## Safety Rules

- Never delete a key from `.arb` if there's even one uncertain (dynamic) reference.
- Never overwrite an existing, non-empty translation without explicitly flagging it.
- Make `.arb` changes symmetrically across all languages in one step.
- Always add `@key` metadata block when adding a new key.
- Tag every self-proposed translation `needs-native-review: true`.
- Commit per chunk: `chore(i18n): externalize strings in lib/features/onboarding`.

---

## Definition of Done

1. No text literals reach the UI outside of justified exceptions.
2. Identical key set across every `.arb`, no empty values, no placeholder drift.
3. Every key in `app_en.arb` has at least one confirmed usage in `lib/`.
4. `flutter gen-l10n` runs clean.
5. `.arb` file set matches `supportedLocales` exactly; `AppLocalizations.delegate` is registered.
6. Every "needs manual review" item explicitly resolved.
