#!/bin/bash
# Render Mermaid diagram to PNG and SVG
# Usage: render-mermaid.sh input.mmd [asset-name] [theme]

set -e

INPUT="$1"
NAME="${2:-diagram}"
THEME="${3:-dark}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_DIR="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/my_vault/Resources/${NAME}-${TIMESTAMP}"

if [ -z "$INPUT" ]; then
    echo "Usage: render-mermaid.sh input.mmd [asset-name] [theme]"
    echo "Themes: default, dark, forest, neutral"
    exit 1
fi

if ! command -v mmdc &> /dev/null; then
    echo "Error: mermaid-cli (mmdc) not found"
    echo "Install with: npm install -g @mermaid-js/mermaid-cli"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Copy source
cp "$INPUT" "$OUTPUT_DIR/source.mmd"

# Render PNG (high quality)
echo "Rendering PNG..."
mmdc -i "$INPUT" -o "$OUTPUT_DIR/${NAME}.png" -t "$THEME" -b transparent -s 2

# Render SVG
echo "Rendering SVG..."
mmdc -i "$INPUT" -o "$OUTPUT_DIR/${NAME}.svg" -t "$THEME" -b transparent

echo ""
echo "Exported to: $OUTPUT_DIR"
echo "Files:"
ls -la "$OUTPUT_DIR"
