#!/usr/bin/env bash
set -euo pipefail

ICON_DIR="assets/icon"

# ------------------------------------------------------------
# SVG → PNG
# ------------------------------------------------------------

svg_to_png() {
  local source="$1"
  local target="$2"

  echo "→ $target"

  rsvg-convert \
    -w 1024 \
    -h 1024 \
    "$ICON_DIR/$source.svg" \
    -o "$ICON_DIR/$target.png"
}

# ------------------------------------------------------------
# Sprawdzenie narzędzia
# ------------------------------------------------------------

if ! command -v rsvg-convert >/dev/null 2>&1; then
  echo "❌ Brak rsvg-convert. Zainstaluj librsvg."
  exit 1
fi

# ------------------------------------------------------------
# Sprawdzenie źródeł
# ------------------------------------------------------------

for file in \
  app_icon.svg \
  app_icon_dark.svg \
  app_icon_foreground.svg \
  app_icon_monochrome.svg \
  splash_light.svg \
  splash_dark.svg
do
  if [[ ! -f "$ICON_DIR/$file" ]]; then
    echo "❌ Brak pliku: $ICON_DIR/$file"
    exit 1
  fi
done

# ------------------------------------------------------------
# Generowanie PNG
# Każdy PNG powstaje bezpośrednio z odpowiadającego SVG.
# Bez colorize, flatten, resize ani dodatkowej obróbki.
# ------------------------------------------------------------

svg_to_png app_icon            app_icon
svg_to_png app_icon_dark       app_icon_dark
svg_to_png app_icon_foreground app_icon_foreground
svg_to_png app_icon_monochrome app_icon_monochrome
svg_to_png splash_light        splash_light
svg_to_png splash_dark         splash_dark

# Splash korzysta z istniejących, właściwych źródeł.
cp "$ICON_DIR/app_icon_foreground.png" "$ICON_DIR/splash_dark.png"

# ------------------------------------------------------------
# Flutter
# ------------------------------------------------------------

echo "→ flutter_launcher_icons"
dart run flutter_launcher_icons

echo "→ flutter_native_splash"
dart run flutter_native_splash:create

echo "✅ Ikony i splash screen wygenerowane."