#!/usr/bin/env bash

# ==============================================================================
# Helper Runner for Modular Screenshot Generation
# Usage: ./scripts/screenshots/run_screenshot_target.sh <test_file> [device] [locale]
# ==============================================================================

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

if [ $# -lt 1 ]; then
    echo "Usage: $0 <test_file> [phone|tablet_7|tablet_10|all] [locale]"
    exit 1
fi

TEST_TARGET="$1"
DEVICE_INPUT="${2:-phone}"
LOCALE_FILTER="${3:-}"

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
            echo "Medium_Tablet|android/tablet_10|2560x1600"
            ;;
        *)
            echo -e "${RED}❌ [ERROR] Unknown device: $device${NC}"
            exit 1
            ;;
    esac
}

TARGETS=()
case "$DEVICE_INPUT" in
    all)
        TARGETS=("phone" "tablet_7" "tablet_10")
        ;;
    phone|tablet_7|tablet_10)
        TARGETS=("$DEVICE_INPUT")
        ;;
    *)
        TARGETS=("phone")
        ;;
esac

# ------------------------------------------------------------------------------
# 1. Detect / Boot ADB Emulator
# ------------------------------------------------------------------------------
DEVICE_ID=""
if command -v adb &> /dev/null; then
    RUNNING_EMULATORS=$(adb devices | grep -w "device" | grep "emulator-" || true)
    if [ -n "$RUNNING_EMULATORS" ]; then
        DEVICE_ID=$(echo "$RUNNING_EMULATORS" | head -n 1 | awk '{print $1}')
    fi
fi

START_TIME=$(date +%s)
echo -e "${BLUE}ℹ️  [INFO] Target Test: $TEST_TARGET | Devices: ${TARGETS[*]} | Locale: ${LOCALE_FILTER:-all}${NC}"

for TARGET_DEVICE in "${TARGETS[@]}"; do
    CONFIG=$(resolve_device_config "$TARGET_DEVICE")
    IFS='|' read -r EMULATOR_ID SCREENSHOT_PREFIX RESOLUTION <<< "$CONFIG"

    if [ -z "$DEVICE_ID" ]; then
        echo -e "${YELLOW}⚙️  [STEP] Launching emulator $EMULATOR_ID ($RESOLUTION)...${NC}"
        flutter emulators --launch "$EMULATOR_ID" || true
        for _ in $(seq 1 60); do
            DEVICE_ID=$(adb devices | grep -w "device" | grep "emulator-" | head -n 1 | awk '{print $1}')
            if [ -n "$DEVICE_ID" ]; then break; fi
            sleep 2
        done
        for _ in $(seq 1 90); do
            BOOT=$(adb -s "$DEVICE_ID" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)
            if [ "$BOOT" = "1" ]; then break; fi
            sleep 2
        done
    fi

    mkdir -p "screenshots/$SCREENSHOT_PREFIX"

    DEVICE_ARG=""
    if [ -n "$DEVICE_ID" ]; then
        DEVICE_ARG="-d $DEVICE_ID"
    fi

    LOCALE_ARG=""
    if [ -n "$LOCALE_FILTER" ]; then
        LOCALE_ARG="--dart-define=SCREENSHOT_LOCALE=$LOCALE_FILTER"
    fi

    flutter drive \
      --driver=test_driver/integration_test.dart \
      --target="$TEST_TARGET" \
      --dart-define=SCREENSHOT_DEVICE="$SCREENSHOT_PREFIX" \
      $LOCALE_ARG \
      $DEVICE_ARG

    COUNT=$(find "screenshots/$SCREENSHOT_PREFIX" -type f -name "*.png" | wc -l | tr -d ' ')
    echo -e "${GREEN}✅ [SUCCESS] Generated screenshots in screenshots/$SCREENSHOT_PREFIX/ ($COUNT total)${NC}"
done

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
echo -e "${GREEN}✅ [DONE] Finished in ${DURATION}s.${NC}"
