#!/usr/bin/env bash

# ==============================================================================
# Script Name: generate_screenshots.sh
# Description: Automated multi-locale screenshot generator on Android emulator.
# Target: Medium Phone (1080 x 2400)
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

START_TIME=$(date +%s)

log_info "Starting Automated Multi-Locale Screenshot Capture..."

# ------------------------------------------------------------------------------
log_step "1. Detecting Target Emulator (Medium_Phone)..."
# ------------------------------------------------------------------------------
DEVICE_ID=""

# Check if an emulator is already attached via ADB
if command -v adb &> /dev/null; then
    RUNNING_EMULATORS=$(adb devices | grep -w "device" | grep "emulator-" || true)
    if [ -n "$RUNNING_EMULATORS" ]; then
        DEVICE_ID=$(echo "$RUNNING_EMULATORS" | head -n 1 | awk '{print $1}')
        log_info "Detected running ADB emulator: $DEVICE_ID"
    fi
fi

if [ -z "$DEVICE_ID" ]; then
    log_info "No running emulator found. Launching Medium_Phone..."
    flutter emulators --launch Medium_Phone || true
    
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
log_step "2. Executing Screenshot Integration Test Pipeline..."
# ------------------------------------------------------------------------------
mkdir -p screenshots

DEVICE_ARG=""
if [ -n "$DEVICE_ID" ]; then
    DEVICE_ARG="-d $DEVICE_ID"
fi

flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/screenshots_test.dart \
  $DEVICE_ARG

# ------------------------------------------------------------------------------
log_step "3. Verifying Captured Screenshots in screenshots/..."
# ------------------------------------------------------------------------------
TOTAL_COUNT=$(find screenshots -type f -name "*.png" | wc -l | tr -d ' ')
log_success "Captured $TOTAL_COUNT total screenshots across all locales in screenshots/."

find screenshots -type f -name "*.png" | sort

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo -e "\n=============================================================================="
log_success "Screenshots generation completed in ${DURATION}s."
echo -e "=============================================================================="
