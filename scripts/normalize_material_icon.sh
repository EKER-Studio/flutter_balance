#!/usr/bin/env bash
set -euo pipefail

INPUT="${1:-}"
OUTPUT="${2:-}"

if [[ -z "$INPUT" || -z "$OUTPUT" ]]; then
  echo "Usage:"
  echo "  $0 input.svg output.svg"
  exit 1
fi

if [[ ! -f "$INPUT" ]]; then
  echo "❌ Brak pliku: $INPUT"
  exit 1
fi

if [[ "$INPUT" == "$OUTPUT" ]]; then
  echo "❌ Plik wejściowy i wyjściowy muszą być różne."
  exit 1
fi

python3 - "$INPUT" "$OUTPUT" <<'PY'
import sys
import xml.etree.ElementTree as ET

input_file = sys.argv[1]
output_file = sys.argv[2]

TARGET_SIZE = 1024
PADDING = 128
SOURCE_SIZE = 960
SCALE = (TARGET_SIZE - 2 * PADDING) / SOURCE_SIZE

tree = ET.parse(input_file)
root = tree.getroot()

# ------------------------------------------------------------
# Walidacja Material Icons
#
# Google Material Icons używają układu:
#
#   viewBox="0 -960 960 960"
#
# Nie wymagamy identycznego formatowania tekstowego,
# tylko tych samych wartości numerycznych.
# ------------------------------------------------------------

view_box_raw = root.get("viewBox", "")
view_box = view_box_raw.split()

if len(view_box) != 4:
    raise SystemExit(
        f"❌ Nieprawidłowy viewBox: {view_box_raw!r}\n"
        '   Oczekiwano geometrii: 0 -960 960 960'
    )

try:
    x, y, width, height = map(float, view_box)
except ValueError:
    raise SystemExit(
        f"❌ Nieprawidłowy viewBox: {view_box_raw!r}"
    )

if (x, y, width, height) != (0, -960, 960, 960):
    raise SystemExit(
        "❌ To nie wygląda na surową ikonę Material Icons.\n"
        f"   viewBox: {view_box_raw!r}\n"
        "   Oczekiwano geometrii: 0 -960 960 960"
    )

# ------------------------------------------------------------
# Sprawdzenie zawartości
# ------------------------------------------------------------

children = list(root)

if not children:
    raise SystemExit("❌ SVG nie zawiera żadnych elementów.")

# ------------------------------------------------------------
# Nowy canvas 1024×1024
# ------------------------------------------------------------

new_root = ET.Element(
    "svg",
    {
        "xmlns": "http://www.w3.org/2000/svg",
        "width": str(TARGET_SIZE),
        "height": str(TARGET_SIZE),
        "viewBox": f"0 0 {TARGET_SIZE} {TARGET_SIZE}",
    },
)

# ------------------------------------------------------------
# Material Icons:
#
#   960 × 960
#
# Docelowo:
#
#   768 × 768
#
# Padding:
#
#   (1024 - 768) / 2 = 128px
#
# translate(0, 960) przenosi oryginalny układ
# Y=-960..0 do standardowego układu SVG.
# ------------------------------------------------------------

group = ET.SubElement(
    new_root,
    "g",
    {
        "transform": (
            f"translate({PADDING}, {PADDING}) "
            f"scale({SCALE:g}) "
            f"translate(0, {SOURCE_SIZE:g})"
        )
    },
)

# ------------------------------------------------------------
# Zachowujemy zawartość SVG 1:1.
#
# NIE zmieniamy:
#   - fill
#   - stroke
#   - opacity
#   - path
#   - innych atrybutów
# ------------------------------------------------------------

for child in children:
    group.append(child)

# ------------------------------------------------------------
# Zapis
# ------------------------------------------------------------

ET.register_namespace("", "http://www.w3.org/2000/svg")

ET.ElementTree(new_root).write(
    output_file,
    encoding="utf-8",
    xml_declaration=False,
)

print(f"✅ {input_file} → {output_file}")
print(f"   Canvas:  {TARGET_SIZE}×{TARGET_SIZE}")
print(f"   Padding: {PADDING}px")
print(f"   Scale:   {SCALE:g}×")
print("   Kolory:  zachowane 1:1")
PY