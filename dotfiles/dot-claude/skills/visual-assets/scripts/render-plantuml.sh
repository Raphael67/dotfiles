#!/bin/bash
# Render PlantUML diagram to PNG and SVG
# Usage: render-plantuml.sh input.puml [asset-name]

set -e

INPUT="$1"
NAME="${2:-diagram}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_DIR="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/my_vault/Resources/${NAME}-${TIMESTAMP}"

if [ -z "$INPUT" ]; then
    echo "Usage: render-plantuml.sh input.puml [asset-name]"
    exit 1
fi

if ! command -v plantuml &> /dev/null; then
    echo "Error: plantuml not found"
    echo "Install with: brew install plantuml"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Copy source
cp "$INPUT" "$OUTPUT_DIR/source.puml"

# Render PNG
echo "Rendering PNG..."
plantuml -tpng -o "$OUTPUT_DIR" "$INPUT"

# Rename output (plantuml uses input filename)
BASENAME=$(basename "$INPUT" .puml)
if [ -f "$OUTPUT_DIR/${BASENAME}.png" ]; then
    mv "$OUTPUT_DIR/${BASENAME}.png" "$OUTPUT_DIR/${NAME}.png"
fi

# Render SVG
echo "Rendering SVG..."
plantuml -tsvg -o "$OUTPUT_DIR" "$INPUT"

if [ -f "$OUTPUT_DIR/${BASENAME}.svg" ]; then
    mv "$OUTPUT_DIR/${BASENAME}.svg" "$OUTPUT_DIR/${NAME}.svg"
fi

echo ""
echo "Exported to: $OUTPUT_DIR"
echo "Files:"
ls -la "$OUTPUT_DIR"
