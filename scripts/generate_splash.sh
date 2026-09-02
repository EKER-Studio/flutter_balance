#!/usr/bin/env bash
# Usage: ./scripts/generate_splash.sh [phone|tablet_7|tablet_10|all] [locale]
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$DIR/run_screenshot_target.sh" "integration_test/splash_screenshots_test.dart" "${1:-phone}" "${2:-}"
