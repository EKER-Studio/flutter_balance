#!/usr/bin/env bash
# Usage: ./scripts/generate_calendar.sh [phone|tablet_7|tablet_10|all] [locale]
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$DIR/run_screenshot_target.sh" "integration_test/calendar_screenshots_test.dart" "${1:-phone}" "${2:-}"
