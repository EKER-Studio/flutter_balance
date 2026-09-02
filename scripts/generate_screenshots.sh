#!/usr/bin/env bash

# ==============================================================================
# Script Name: generate_screenshots.sh
# Description: Automated multi-locale screenshot generator on Android emulator.
# Supports:
#   android/phone     (1080 x 2400)  -> Medium_Phone
#   android/tablet_7  (800 x 1280)   -> Small_Tablet  (7")
#   android/tablet_10 (2560 x 1600)  -> Small_Tablet* (10" - requires custom AVD)
# iOS targets (iphone/ipad) are handled separately via iOS Simulator workflow.
# Usage:
#   ./scripts/generate_screenshots.sh [phone|tablet_7|tablet_10|all]
#   Default: phone
#   Examples:
#     ./scripts/generate_screenshots.sh phone
#     ./scripts/generate_screenshots.sh tablet_7
#     ./scripts/generate_screenshots.sh all
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

# ------------------------------------------------------------------------------
# Device mapping: logical name -> AVD id -> screenshot prefix -> resolution
# ------------------------------------------------------------------------------
resolve_device_config() {
    local device="$1"
    case "$device" in
        phone)
            echo "Medium_Phone|android/phone|1080x2400"
            ;;
        tablet_7)
            echo "Small_Tablet|android/tablet_7|800x1280"
            ;;
        tablet_10)
            # Small_Tablet is the only tablet AVD currently available.
            # For true 10" (2560x1600), create a custom AVD:
            #   flutter emulators --create --name Medium_Tablet
            # and update this mapping.
            echo "Small_Tablet|android/tablet_10|2560x1600 (emulated via Small_Tablet)"
            ;;
        *)
            log_error "Unknown device: $device (expected: phone|tablet_7|tablet_10|all)"
            exit 1
            ;;
    esac
}

# ------------------------------------------------------------------------------
# Parse args
# ------------------------------------------------------------------------------
TARGETS=()
if [ $# -eq 0 ]; then
    TARGETS=("phone")
else
    case "$1" in
        all)
            TARGETS=("phone" "tablet_7" "tablet_10")
            ;;
        phone|tablet_7|tablet_10)
            TARGETS=("$1")
            ;;
        -h|--help)
            echo "Usage: $0 [phone|tablet_7|tablet_10|all]"
            echo ""
            echo "Generates screenshots into screenshots/android/<device>/<locale>/"
            echo "Each device captures both light and dark themes (per integration_test/screenshots_test.dart)."
            exit 0
            ;;
        *)
            log_error "Unknown argument: $1"
            echo "Usage: $0 [phone|tablet_7|tablet_10|all]"
            exit 1
            ;;
    esac
fi

START_TIME=$(date +%s)

log_info "Starting Automated Multi-Locale Screenshot Capture..."
log_info "Targets: ${TARGETS[*]}"

for TARGET_DEVICE in "${TARGETS[@]}"; do
    CONFIG=$(resolve_device_config "$TARGET_DEVICE")
    IFS='|' read -r EMULATOR_ID SCREENSHOT_PREFIX RESOLUTION <<< "$CONFIG"

    log_step "Device: $TARGET_DEVICE ($RESOLUTION) -> $EMULATOR_ID -> screenshots/$SCREENSHOT_PREFIX/"

    # ------------------------------------------------------------------------------
    log_step "1. Detecting/Booting Emulator ($EMULATOR_ID)..."
    # ------------------------------------------------------------------------------
    DEVICE_ID=""

    if command -v adb &> /dev/null; then
        RUNNING_EMULATORS=$(adb devices | grep -w "device" | grep "emulator-" || true)
        if [ -n "$RUNNING_EMULATORS" ]; then
            DEVICE_ID=$(echo "$RUNNING_EMULATORS" | head -n 1 | awk '{print $1}')
            log_info "Detected running ADB emulator: $DEVICE_ID"
        fi
    fi

    if [ -z "$DEVICE_ID" ]; then
        log_info "No running emulator found. Launching $EMULATOR_ID..."
        flutter emulators --launch "$EMULATOR_ID" || true

        log_info "Waiting for emulator to boot..."
        if command -v adb &> /dev/null; then
            adb wait-for-device
            while [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]; do
                sleep 2
            done
            DEVICE_ID=$(adb devices | grep -w "device" | grep "emulator-" | head -n 1 | awk '{print $1}')
            log_info "Android emulator booted with ID: $DEVICE_ID"
        else
            sleep 15
            DEVICE_ID="emulator-5554"
        fi
    fi

    # ------------------------------------------------------------------------------
    log_step "2. Executing Screenshot Integration Test Pipeline ($SCREENSHOT_PREFIX)..."
    # ------------------------------------------------------------------------------
    mkdir -p "screenshots/$SCREENSHOT_PREFIX"

    DEVICE_ARG=""
    if [ -n "$DEVICE_ID" ]; then
        DEVICE_ARG="-d $DEVICE_ID"
    fi

    flutter drive \
      --driver=test_driver/integration_test.dart \
      --target=integration_test/screenshots_test.dart \
      --dart-define=SCREENSHOT_DEVICE="$SCREENSHOT_PREFIX" \
      $DEVICE_ARG

    # ------------------------------------------------------------------------------
    log_step "3. Verifying Captured Screenshots in screenshots/$SCREENSHOT_PREFIX/..."
    # ------------------------------------------------------------------------------
    TOTAL_COUNT=$(find "screenshots/$SCREENSHOT_PREFIX" -type f -name "*.png" | wc -l | tr -d ' ')
    log_success "Captured $TOTAL_COUNT screenshots for $SCREENSHOT_PREFIX (expected ~440: 10 locales x 22 screens x 2 themes)."

    find "screenshots/$SCREENSHOT_PREFIX" -type f -name "*.png" | sort | head -n 20
    if [ "$TOTAL_COUNT" -gt 20 ]; then
        echo "... ($TOTAL_COUNT total, truncated)"
    fi
done

# ------------------------------------------------------------------------------
log_step "4. Global Verification (all devices)..."
# ------------------------------------------------------------------------------
TOTAL_ALL=$(find screenshots/android -type f -name "*.png" | wc -l | tr -d ' ')
log_success "Total Android screenshots across all devices: $TOTAL_ALL"
find screenshots/android -type f -name "*.png" | sort | head -n 30
if [ "$TOTAL_ALL" -gt 30 ]; then
    echo "... ($TOTAL_ALL total, truncated)"
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo -e "\n=============================================================================="
log_success "Screenshots generation completed in ${DURATION}s for targets: ${TARGETS[*]}"
echo -e "=============================================================================="
