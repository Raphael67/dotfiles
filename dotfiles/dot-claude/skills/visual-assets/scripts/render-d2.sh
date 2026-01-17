#!/bin/bash
# Render D2 diagram to PNG and SVG
# Usage: render-d2.sh input.d2 [asset-name] [theme]

set -e

INPUT="$1"
NAME="${2:-diagram}"
THEME="${3:-200}"  # Terminal theme default
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_DIR="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/my_vault/Resources/${NAME}-${TIMESTAMP}"

if [ -z "$INPUT" ]; then
    echo "Usage: render-d2.sh input.d2 [asset-name] [theme]"
    echo "Popular themes: 0 (default), 1 (neutral), 4 (cool), 100+ (dark), 200 (terminal)"
    exit 1
fi

if ! command -v d2 &> /dev/null; then
    echo "Error: d2 not found"
    echo "Install with: curl -fsSL https://d2lang.com/install.sh | sh -s --"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Copy source
cp "$INPUT" "$OUTPUT_DIR/source.d2"

# Render SVG
echo "Rendering SVG..."
d2 --theme "$THEME" "$INPUT" "$OUTPUT_DIR/${NAME}.svg"

# Render PNG
echo "Rendering PNG..."
d2 --theme "$THEME" "$INPUT" "$OUTPUT_DIR/${NAME}.png"

echo ""
echo "Exported to: $OUTPUT_DIR"
echo "Files:"
ls -la "$OUTPUT_DIR"
