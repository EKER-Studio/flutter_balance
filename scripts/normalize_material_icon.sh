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

# ------------------------------------------------------------
# Read source SVG
# ------------------------------------------------------------

tree = ET.parse(input_file)
root = tree.getroot()

# ------------------------------------------------------------
# Validate Material Icon viewBox
#
# Expected:
#   0 -960 960 960
# ------------------------------------------------------------

view_box_raw = root.get("viewBox", "")
view_box = view_box_raw.split()

if len(view_box) != 4:
    raise SystemExit(
        f"❌ Nieprawidłowy viewBox: {view_box_raw!r}\n"
        "   Oczekiwano: 0 -960 960 960"
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
        "   Oczekiwano: 0 -960 960 960"
    )

# ------------------------------------------------------------
# Validate content
# ------------------------------------------------------------

children = list(root)

if not children:
    raise SystemExit("❌ SVG nie zawiera żadnych elementów.")

# ------------------------------------------------------------
# Create normalized SVG
# ------------------------------------------------------------

new_root = ET.Element(
    "{http://www.w3.org/2000/svg}svg",
    {
        "width": str(TARGET_SIZE),
        "height": str(TARGET_SIZE),
        "viewBox": f"0 0 {TARGET_SIZE} {TARGET_SIZE}",
    },
)

# ------------------------------------------------------------
# Preserve visual properties from source SVG.
#
# In particular:
#   fill
#   stroke
#   stroke-width
#   opacity
#   fill-rule
#   clip-rule
# etc.
#
# We intentionally do NOT modify them.
# ------------------------------------------------------------

PRESENTATION_ATTRIBUTES = {
    "fill",
    "fill-rule",
    "clip-rule",
    "stroke",
    "stroke-width",
    "stroke-linecap",
    "stroke-linejoin",
    "stroke-miterlimit",
    "stroke-dasharray",
    "stroke-dashoffset",
    "stroke-opacity",
    "fill-opacity",
    "opacity",
    "color",
}

for attribute in PRESENTATION_ATTRIBUTES:
    value = root.get(attribute)
    if value is not None:
        new_root.set(attribute, value)

# ------------------------------------------------------------
# Geometry
#
# Original:
#   960 × 960
#
# Target:
#   768 × 768
#
# Padding:
#   128px on every side
#
# Material coordinates:
#   Y = -960 ... 0
#
# We map them directly into:
#   Y = 128 ... 896
#
# Equivalent to:
#   translate(128, 896) scale(0.8)
# ------------------------------------------------------------

group = ET.SubElement(
    new_root,
    "{http://www.w3.org/2000/svg}g",
    {
        "transform": (
            f"translate({PADDING}, {TARGET_SIZE - PADDING}) "
            f"scale({SCALE:g})"
        )
    },
)

# ------------------------------------------------------------
# Preserve source elements exactly.
#
# No changes to:
#   path
#   fill
#   stroke
#   opacity
#   etc.
# ------------------------------------------------------------

for child in children:
    group.append(child)

# ------------------------------------------------------------
# Write valid SVG
# ------------------------------------------------------------

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