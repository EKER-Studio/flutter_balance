# Contributing

## Branches
- `develop` — default, integration branch. All PRs target `develop`.
- `release` — release branch. APK is built via `release.yml` on push to `release` or tag `v*`.
- `feature/*` — feature branches from `develop`.

## Workflow
1. Branch from `develop`: `git checkout -b feature/my-feature develop`
2. Commit with Conventional Commits (`feat:`, `fix:`, `chore:`)
3. Push and open PR against `develop` — choose template: Feature / Bug fix / Chore
4. Ensure checks pass: `dart format`, `flutter analyze`, `flutter test --exclude-tags golden,screenshot`
5. For UI changes, update screenshots: `scripts/screenshots/generate_*.sh`

## Screenshots
Generated via `scripts/screenshots/` — not committed as artifacts except curated `.github/assets/` for README.

## Release
Merge `develop` → `release` or push tag `v*` to trigger APK build and GitHub Release.
