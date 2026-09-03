#!/usr/bin/env bash

# ==============================================================================
# Script Name: generate_screenshots.sh
# Description: Orchestrator – generates FULL screenshot suite by delegating to
#              modular per-feature generators (via run_screenshot_target.sh).
#              Ensures consistent ScreenshotDeviceFrame emulation (top status
#              bar 09:41 + signal/wifi/battery + bottom gesture pill) across
#              all suites via the 8 modular *_screenshots_test.dart files that
#              use helpers/screenshot_test_helper.dart (KISS/DRY – no monolith).
# Supports:
#   android/phone     (1080 x 2400)  -> Medium_Phone
#   android/tablet_7  (800 x 1280)   -> Small_Tablet  (7")
#   android/tablet_10 (2560 x 1600)  -> Medium_Tablet (10")
# Usage:
#   ./scripts/screenshots/generate_screenshots.sh [phone|tablet_7|tablet_10|all] [locale]
#   Default: phone (all locales)
#   Examples:
#     ./scripts/screenshots/generate_screenshots.sh phone
#     ./scripts/screenshots/generate_screenshots.sh tablet_7 pl
#     ./scripts/screenshots/generate_screenshots.sh all ja
#     ./scripts/screenshots/generate_screenshots.sh all      # all devices, all locales
# Notes:
#   - Per-feature scripts: generate_splash.sh, generate_onboarding.sh,
#     generate_today.sh, generate_calendar.sh, generate_statistics.sh,
#     generate_settings.sh, generate_biometric.sh, generate_home_widgets.sh
#   - Each delegates to run_screenshot_target.sh which handles emulator boot
#     and --dart-define=SCREENSHOT_DEVICE / SCREENSHOT_LOCALE.
#   - Single-module run: ./scripts/screenshots/run_screenshot_target.sh
#     integration_test/calendar_screenshots_test.dart [device] [locale]
# ==============================================================================

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ️  [INFO]${NC} $1"
}

log_step() {
    echo -e "\n${YELLOW}⚙️  [STEP]${NC} $1"
}

log_success() {
    echo -e "${GREEN}✅ [SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}❌ [ERROR]${NC} $1"
}

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ------------------------------------------------------------------------------
# Ordered list of per-feature generators (00_splash -> 07_home_widgets).
# Each script is a thin wrapper around run_screenshot_target.sh and already
# handles [device] [locale] args.
# ------------------------------------------------------------------------------
FEATURE_SCRIPTS=(
    "generate_splash.sh"
    "generate_onboarding.sh"
    "generate_today.sh"
    "generate_calendar.sh"
    "generate_statistics.sh"
    "generate_settings.sh"
    "generate_biometric.sh"
    "generate_home_widgets.sh"
)

# ------------------------------------------------------------------------------
# Parse args: [device] [locale]  – keep compat with old single-arg invocation
# ------------------------------------------------------------------------------
DEVICE_INPUT="${1:-phone}"
LOCALE_FILTER="${2:-}"

if [[ "$DEVICE_INPUT" == "-h" || "$DEVICE_INPUT" == "--help" ]]; then
    echo "Usage: $0 [phone|tablet_7|tablet_10|all] [locale]"
    echo ""
    echo "Generates FULL screenshot suite via modular per-feature targets."
    echo "Each feature is captured with ScreenshotDeviceFrame (status bar 09:41"
    echo "+ signal/wifi/battery + bottom gesture pill) for visual consistency."
    echo ""
    echo "Arguments:"
    echo "  device  phone|tablet_7|tablet_10|all  (default: phone)"
    echo "  locale  en|de|ja|fr|es|pl|pt|nl|it|ko  (default: all)"
    echo ""
    echo "Examples:"
    echo "  $0 phone"
    echo "  $0 tablet_7 pl"
    echo "  $0 all ja"
    echo ""
    echo "Per-feature alternative:"
    echo "  ./scripts/screenshots/generate_calendar.sh phone pl"
    echo "  ./scripts/screenshots/run_screenshot_target.sh integration_test/calendar_screenshots_test.dart phone pl"
    exit 0
fi

case "$DEVICE_INPUT" in
    phone|tablet_7|tablet_10|all) ;;
    *)
        log_error "Unknown device: $DEVICE_INPUT (expected: phone|tablet_7|tablet_10|all)"
        echo "Usage: $0 [phone|tablet_7|tablet_10|all] [locale]"
        exit 1
        ;;
esac

if [[ -n "$LOCALE_FILTER" ]]; then
    case "$LOCALE_FILTER" in
        en|de|ja|fr|es|pl|pt|nl|it|ko) ;;
        *)
            log_error "Unknown locale: $LOCALE_FILTER (expected: en|de|ja|fr|es|pl|pt|nl|it|ko)"
            exit 1
            ;;
    esac
fi

START_TIME=$(date +%s)

log_info "Starting FULL Screenshot Suite (Orchestrator Mode)..."
log_info "Devices: $DEVICE_INPUT | Locale: ${LOCALE_FILTER:-all} | Features: ${#FEATURE_SCRIPTS[@]}"
log_info "Each feature will run via run_screenshot_target.sh with ScreenshotDeviceFrame."

# ------------------------------------------------------------------------------
# Delegate sequentially to each per-feature generator.
# Emulator is detected/reused inside run_screenshot_target.sh – no need to
# boot here. Sequential execution ensures deterministic ordering and allows
# reusing the same emulator across features when possible.
# ------------------------------------------------------------------------------
for SCRIPT in "${FEATURE_SCRIPTS[@]}"; do
    log_step "Feature: $SCRIPT ($DEVICE_INPUT / ${LOCALE_FILTER:-all})"
    if [[ ! -x "$DIR/$SCRIPT" ]]; then
        log_error "Missing or non-executable: $DIR/$SCRIPT"
        exit 1
    fi
    "$DIR/$SCRIPT" "$DEVICE_INPUT" "${LOCALE_FILTER:-}"
done

# ------------------------------------------------------------------------------
# Global verification – count all android screenshots
# Expected: 8 features × ~440 total when locale=all:
#   splash 1×20 + onboarding 8×20 + today 3×20 + calendar 2×20 + statistics 2×20
#   + settings 3×20 + biometric 1×20 + home_widgets 2×20 = 22×20 = 440 per device
# ------------------------------------------------------------------------------
log_step "Global Verification (all devices)..."

TOTAL_ALL=$(find screenshots/android -type f -name "*.png" 2>/dev/null | wc -l | tr -d ' ' || echo "0")
log_success "Total Android screenshots across all devices: $TOTAL_ALL"

if [[ -d "screenshots/android" ]]; then
    find screenshots/android -type f -name "*.png" | sort | head -n 30
    if [[ "$TOTAL_ALL" -gt 30 ]]; then
        echo "... ($TOTAL_ALL total, truncated)"
    fi
    echo ""
    log_info "Per-device breakdown:"
    for D in phone tablet_7 tablet_10; do
        COUNT=$(find "screenshots/android/$D" -type f -name "*.png" 2>/dev/null | wc -l | tr -d ' ' || echo "0")
        echo "  android/$D: $COUNT"
    done
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo -e "\n=============================================================================="
log_success "Full screenshots suite completed in ${DURATION}s (devices: $DEVICE_INPUT, locale: ${LOCALE_FILTER:-all})"
echo -e "=============================================================================="
echo -e "${BLUE}ℹ️  [INFO] For single-module runs use e.g.: ./scripts/generate_calendar.sh $DEVICE_INPUT ${LOCALE_FILTER:-}${NC}"
