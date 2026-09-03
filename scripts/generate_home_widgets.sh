#!/usr/bin/env bash
# DEPRECATED: Use scripts/screenshots/generate_home_widgets.sh instead. Kept for backward compat.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$DIR/screenshots/generate_home_widgets.sh" "$@"
