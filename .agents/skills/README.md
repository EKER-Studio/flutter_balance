# Agent Skills

Skills are auto-discovered runbooks (`<skill-name>/SKILL.md`) that describe *how* to execute a
procedure. Agent personas in `.agents/agents/` decide *who* executes it; the project rules in
`AGENTS.md` and `agents_project.md` always define the constraints.

## Project-native skills

| Skill | Purpose |
| :--- | :--- |
| `bloc-audit` | 12-dimension architecture, BLoC lifecycle, Isar, security and test audit. |
| `unit-test-audit` | Layer-by-layer unit test coverage auditor and test generator. |
| `i18n-audit` | Localization auditor for hardcoded strings, ARB completeness and `supportedLocales`. |
| `dartdoc-cleanup` | File-by-file comment translation and DartDoc cleanup. |

## Vendored Flutter Team skills

The following 10 skills are copied **verbatim** from
[`flutter/agent-plugins`](https://github.com/flutter/agent-plugins) (`skills/` directory), commit
[`90fa51d`](https://github.com/flutter/agent-plugins/commit/90fa51dc9d1bd6694cee226397e08ec8193e9e69)
(2026-10-26), and are licensed under BSD-3-Clause — see
[`LICENSE.flutter-agent-plugins`](LICENSE.flutter-agent-plugins).

| Skill | Purpose |
| :--- | :--- |
| `flutter-add-integration-test` | Configure Flutter Driver and author `integration_test` E2E flows. |
| `flutter-add-widget-preview` | Add interactive `@Preview` widgets using `widget_previews.dart`. |
| `flutter-add-widget-test` | Author component-level tests with `WidgetTester`. |
| `flutter-apply-architecture-best-practices` | Generic Flutter layer-boundary guidance (reference only — see precedence below). |
| `flutter-build-responsive-layout` | Adaptive layouts with `LayoutBuilder`, `MediaQuery` and flex widgets. |
| `flutter-fix-layout-issues` | Diagnose and fix overflow and unbounded-constraint errors. |
| `flutter-implement-json-serialization` | Manual `fromJson` / `toJson` mapping with `dart:convert`. |
| `flutter-setup-declarative-routing` | Declarative routing and deep linking with `go_router`. |
| `flutter-setup-localization` | Bootstrap `flutter_localizations`, `intl`, `l10n.yaml` and `gen-l10n`. |
| `flutter-use-http-package` | Execute HTTP requests with the `http` package. |

## Precedence

1. `AGENTS.md` and `agents_project.md` always override any skill instruction.
2. Project-native skills override vendored generic skills when both apply.
3. Vendored skills are generic Flutter guidance, not project policy. In particular:
   - `flutter-apply-architecture-best-practices` recommends MVVM with `ChangeNotifier`. This project
     mandates **Clean Architecture + BLoC (`flutter_bloc`)**; use the skill only for layer-boundary
     concepts, never to replace BLoC.
   - `flutter-setup-localization` describes bootstrapping a new app. This project already uses
     `l10n.yaml`, ARB files and `flutter gen-l10n`; use the skill as a reference only.
   - Steps that require Dart/Flutter MCP tools are optional. When MCP is not configured, use the
     `flutter` CLI and the existing `integration_test/` and `test/` conventions instead.

## Syncing with upstream

```bash
UPSTREAM=/tmp/flutter-agent-plugins
git clone https://github.com/flutter/agent-plugins "$UPSTREAM"
git -C "$UPSTREAM" checkout --detach 90fa51dc9d1bd6694cee226397e08ec8193e9e69
for skill in "$UPSTREAM"/skills/flutter-*; do
  name=$(basename "$skill")
  mkdir -p ".agents/skills/$name"
  cp "$skill/SKILL.md" ".agents/skills/$name/SKILL.md"
done
git -C "$UPSTREAM" rev-parse HEAD
```

Review the diff, then update the commit hash in this file and add a `CHANGELOG.md` entry. Do not
edit vendored `SKILL.md` files locally: project-specific deviations belong in agent prompts or in
this README so that upstream updates remain a clean copy.
