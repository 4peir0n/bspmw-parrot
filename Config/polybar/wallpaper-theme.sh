#!/usr/bin/env sh
# Build the polybar palette from the currently active wallpaper.
# Green and cyan hues are deliberately excluded.
# Usage: wallpaper-theme.sh [wallpaper-path] [--apply-only]
#   --apply-only writes the configs but does not restart polybar (session start).

POLYBAR_DIR="$HOME/.config/polybar"
COLORS_FILE="$POLYBAR_DIR/colors.ini"
PALETTE_FILE="$POLYBAR_DIR/palette.env"
WALLPAPER=""
APPLY_ONLY=0

if [ "${1:-}" = "--apply-only" ]; then
    APPLY_ONLY=1
elif [ -n "${1:-}" ]; then
    WALLPAPER="$1"
fi
if [ "${2:-}" = "--apply-only" ]; then
    APPLY_ONLY=1
fi

if [ -z "$WALLPAPER" ]; then
    WALLPAPER=$(sed -n "s/.*--bg-[a-z]* *'\([^']*\)'.*/\1/p" "$HOME/.fehbg" 2>/dev/null | head -1)
fi
if [ -z "$WALLPAPER" ]; then
    WALLPAPER="$HOME/Desktop/Wallpapers/Devil-girl.jpg"
fi
[ -f "$WALLPAPER" ] || exit 0

PAL=$(python3 - "$WALLPAPER" <<'PY'
import sys
import colorsys
from collections import Counter
from PIL import Image

path = sys.argv[1]


def hexof(rgb):
    return '#%02X%02X%02X' % tuple(int(c * 255 + 0.5) for c in rgb)


try:
    im = Image.open(path).convert('RGB')
    im.thumbnail((140, 140))
    counts = Counter(im.quantize(colors=18).convert('RGB').getdata())
except Exception:
    counts = Counter()

candidates = []
for (r, g, b), weight in counts.items():
    h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    deg = h * 360
    if 70 <= deg <= 200:      # green + cyan are intentionally excluded
        continue
    if v < 0.16 or s < 0.28:
        continue
    candidates.append((weight, deg, (r / 255, g / 255, b / 255)))

candidates.sort(reverse=True)
base = candidates[0][2] if candidates else (1.0, 0.69, 0.33)  # warm fallback

h, s, v = colorsys.rgb_to_hsv(*base)


def variant(target_v, target_s):
    # Fixed targets keep active / occupied / empty visually distinct even
    # when the source wallpaper is already very bright and saturated.
    return hexof(colorsys.hsv_to_rgb(h, target_s, target_v))


accent = variant(0.88, 0.82)
occupied = variant(1.00, 0.40)   # light tint of the same hue
dim = variant(0.55, 0.18)        # dim, nearly neutral tint

warm = [c for c in candidates if c[1] >= 320 or c[1] <= 60]
urgent = '#FF6B5C'
if warm:
    wh, ws, wv = colorsys.rgb_to_hsv(*warm[0][2])
    urgent = hexof(colorsys.hsv_to_rgb(wh, 0.78, 0.85))

print('ACCENT=%s' % accent)
print('OCCUPIED=%s' % occupied)
print('DIM=%s' % dim)
print('URGENT=%s' % urgent)
PY
)

ACCENT=$(printf '%s\n' "$PAL" | sed -n 's/^ACCENT=//p')
OCCUPIED=$(printf '%s\n' "$PAL" | sed -n 's/^OCCUPIED=//p')
DIM=$(printf '%s\n' "$PAL" | sed -n 's/^DIM=//p')
URGENT=$(printf '%s\n' "$PAL" | sed -n 's/^URGENT=//p')

# Never write an empty palette: keep the previous one if extraction failed.
if [ -z "$ACCENT" ] || [ -z "$OCCUPIED" ] || [ -z "$DIM" ] || [ -z "$URGENT" ]; then
    exit 0
fi

NEW_PALETTE=$(printf 'ACCENT=%s\nOCCUPIED=%s\nDIM=%s\nURGENT=%s\n' \
    "$ACCENT" "$OCCUPIED" "$DIM" "$URGENT")
OLD_PALETTE=""
if [ -f "$PALETTE_FILE" ]; then
    OLD_PALETTE=$(cat "$PALETTE_FILE")
fi
# Idempotent: no file writes and no bar restart when nothing changed.
if [ "$NEW_PALETTE" = "$OLD_PALETTE" ]; then
    exit 0
fi

printf '%s\n' "$NEW_PALETTE" > "$PALETTE_FILE"

if [ -f "$COLORS_FILE" ]; then
    python3 - "$COLORS_FILE" "$ACCENT" "$OCCUPIED" "$DIM" "$URGENT" <<'PY'
import re
import sys

path = sys.argv[1]
values = {
    'fg': sys.argv[2],
    'ac': sys.argv[2],
    'ghost': sys.argv[3],
    'muted': sys.argv[4],
    'red': sys.argv[5],
}
with open(path) as fh:
    lines = fh.read().splitlines()
out = []
for line in lines:
    match = re.match(r'^([A-Za-z0-9_-]+)(\s*=\s*)(.*)$', line)
    if match and match.group(1) in values:
        out.append(match.group(1) + match.group(2) + values[match.group(1)])
    else:
        out.append(line)
with open(path, 'w') as fh:
    fh.write('\n'.join(out) + '\n')
PY
fi

# Keep window borders in sync with the same palette.
if command -v bspc >/dev/null 2>&1; then
    bspc config focused_border_color "$ACCENT" 2>/dev/null || true
    bspc config active_border_color "$DIM" 2>/dev/null || true
    bspc config normal_border_color "$DIM" 2>/dev/null || true
fi

if [ "$APPLY_ONLY" -eq 0 ] && [ -x "$POLYBAR_DIR/Bar.sh" ]; then
    "$POLYBAR_DIR/Bar.sh" >/dev/null 2>&1 &
fi
