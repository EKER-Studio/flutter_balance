#!/usr/bin/env bash

# ==============================================================================
# Script Name: before_push.sh
# Description: Comprehensive static verification and test execution pipeline.
# Guidance: Run this script prior to freezing code or pushing to remote branches.
# ==============================================================================

# Exit immediately if a command exits with a non-zero status,
# treat unset variables as an error, and catch failures in pipelines.
set -euo pipefail

# Define ANSI color codes for rich console formatting
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Track script execution time
START_TIME=$(date +%s)

log_info() {
    echo -e "${BLUE}🚀 [INFO]${NC} $1"
}

log_step() {
    echo -e "\n${YELLOW}⚙️  [STEP $1]${NC} $2"
}

log_success() {
    echo -e "${GREEN}✅ [SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}❌ [ERROR]${NC} $1"
}

# Trap unexpected errors to display a clean failure message
error_handler() {
    log_error "Verification pipeline failed at the last executed command."
    exit 1
}
trap error_handler ERR

log_info "Launching comprehensive pre-push verification pipeline..."

# ------------------------------------------------------------------------------
log_step "1" "Cleaning environment and fetching dependencies..."
# ------------------------------------------------------------------------------
flutter clean > /dev/null
flutter pub get > /dev/null
log_success "Workspace cleaned and dependencies resolved."

# ------------------------------------------------------------------------------
log_step "2" "Generating localization files (i18n)..."
# ------------------------------------------------------------------------------
flutter gen-l10n
log_success "Localization classes generated successfully."

# ------------------------------------------------------------------------------
log_step "3" "Regenerating code declarations (Build Runner)..."
# ------------------------------------------------------------------------------
# Deletes conflicting outputs automatically to prevent compilation deadlocks
dart run build_runner build --delete-conflicting-outputs > /dev/null
log_success "Code generation completed."

# ------------------------------------------------------------------------------
log_step "4" "Verifying code formatting standards..."
# ------------------------------------------------------------------------------
# Ensures the code strictly obeys Dart formatting guidelines without altering files
dart format --output=none --set-exit-if-changed .
log_success "Codebase formatting aligns with style specifications."

# ------------------------------------------------------------------------------
log_step "5" "Executing static analysis (Linter)..."
# ------------------------------------------------------------------------------
# Evaluates project architecture against analysis_options.yaml rules
flutter analyze
log_success "Static analysis passed with zero warnings or errors."

# ------------------------------------------------------------------------------
log_step "6" "Running complete unit and widget test suites (Excluding Goldens)..."
# ------------------------------------------------------------------------------
# Executes all non-visual automated tests inside the /test directory
flutter test --exclude-tags golden
log_success "All automated unit and widget tests completed successfully."

# ==============================================================================
# Pipeline Completion
# ==============================================================================
END_TIME=$(date +%s)
ELAPSED_DURATION=$((END_TIME - START_TIME))

echo -e "\n=============================================================================="
log_success "All verification phases passed successfully! Codebase is ready for push."
log_info "Total execution duration: ${ELAPSED_DURATION} seconds."
echo -e "=============================================================================="