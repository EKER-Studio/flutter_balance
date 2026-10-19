#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Script Name: install_git_hooks.sh
# Description: Installs automated Git pre-commit and pre-push hooks to enforce
#              Dart formatting and static analysis guardrails.
# ==============================================================================

HOOKS_DIR=".git/hooks"

if [ ! -d "$HOOKS_DIR" ]; then
    echo "❌ Error: .git directory not found. Please run this script from the repository root."
    exit 1
fi

echo "⚙️  Installing automated Git hooks..."

# 1. Pre-commit hook: Auto-formats staged Dart files so unformatted code cannot be committed
cat << 'EOF' > "$HOOKS_DIR/pre-commit"
#!/usr/bin/env bash
set -e

# Find all staged .dart files
STAGED_DART_FILES=$(git diff --cached --name-only --diff-filter=ACMR | grep '\.dart$' || true)

if [ -n "$STAGED_DART_FILES" ]; then
    echo "🎨 [Git Hook: pre-commit] Formatting staged Dart files..."
    echo "$STAGED_DART_FILES" | xargs dart format
    echo "$STAGED_DART_FILES" | xargs git add
    echo "✅ [Git Hook: pre-commit] Staged Dart files formatted and re-staged successfully."
fi
EOF

chmod +x "$HOOKS_DIR/pre-commit"
echo "✅ Installed pre-commit hook (auto-formats staged Dart files)."

# 2. Pre-push hook: Runs static analysis before pushing to remote
cat << 'EOF' > "$HOOKS_DIR/pre-push"
#!/usr/bin/env bash
set -e

echo "🔍 [Git Hook: pre-push] Running flutter analyze before push..."
flutter analyze
echo "✅ [Git Hook: pre-push] Static analysis passed. Proceeding with push."
EOF

chmod +x "$HOOKS_DIR/pre-push"
echo "✅ Installed pre-push hook (runs flutter analyze before push)."

echo "🎉 All Git guardrail hooks installed successfully!"
