#!/usr/bin/env bash
# Usage: ./scripts/screenshots/generate_settings.sh [phone|tablet_7|tablet_10|all] [locale]
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$DIR/run_screenshot_target.sh" "integration_test/settings_screenshots_test.dart" "${1:-phone}" "${2:-}"
