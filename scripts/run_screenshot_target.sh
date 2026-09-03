#!/usr/bin/env bash
# DEPRECATED: Use scripts/screenshots/run_screenshot_target.sh instead. Kept for backward compat.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$DIR/screenshots/run_screenshot_target.sh" "$@"
