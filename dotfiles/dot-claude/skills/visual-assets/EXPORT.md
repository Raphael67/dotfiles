# Export & Rendering Reference

CLI commands and pipelines for exporting visual assets.

---

## Output Directory Structure

All assets saved to:
```
~/Library/Mobile Documents/iCloud~md~obsidian/Documents/my_vault/Resources/
└── {asset-name}-{YYYYMMDD-HHMMSS}/
    ├── source.{ext}        # Source file
    ├── {asset-name}.png    # Raster export
    ├── {asset-name}.svg    # Vector export
    └── {asset-name}.mp4    # Video (if animated)
```

---

## Mermaid CLI (mmdc)

### Installation
```bash
npm install -g @mermaid-js/mermaid-cli
```

### Basic Usage
```bash
mmdc -i input.mmd -o output.png
mmdc -i input.mmd -o output.svg
mmdc -i input.mmd -o output.pdf
```

### Options
```bash
# Theme (default, dark, forest, neutral)
mmdc -i input.mmd -o output.png -t dark

# Background color
mmdc -i input.mmd -o output.png -b transparent
mmdc -i input.mmd -o output.png -b '#ffffff'

# Scale (for PNG quality)
mmdc -i input.mmd -o output.png -s 2

# Custom CSS
mmdc -i input.mmd -o output.png -C custom.css

# Width
mmdc -i input.mmd -o output.png -w 1920

# Config file
mmdc -i input.mmd -o output.png -c config.json
```

### Config File Example
```json
{
  "theme": "dark",
  "themeVariables": {
    "primaryColor": "#4A90D9",
    "primaryTextColor": "#fff",
    "primaryBorderColor": "#7C0000"
  }
}
```

### Full Render Script
```bash
#!/bin/bash
# scripts/render-mermaid.sh

INPUT="$1"
NAME="${2:-diagram}"
OUTPUT_DIR="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/my_vault/Resources/${NAME}-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$OUTPUT_DIR"
cp "$INPUT" "$OUTPUT_DIR/source.mmd"

mmdc -i "$INPUT" -o "$OUTPUT_DIR/${NAME}.png" -t dark -b transparent -s 2
mmdc -i "$INPUT" -o "$OUTPUT_DIR/${NAME}.svg" -t dark -b transparent

echo "Exported to: $OUTPUT_DIR"
```

---

## PlantUML

### Installation
```bash
# macOS
brew install plantuml

# Or download JAR
curl -L -o plantuml.jar https://sourceforge.net/projects/plantuml/files/plantuml.jar/download
```

### Basic Usage
```bash
# Using brew-installed plantuml
plantuml input.puml           # Creates input.png
plantuml -tsvg input.puml     # Creates input.svg
plantuml -tpdf input.puml     # Creates input.pdf

# Using JAR
java -jar plantuml.jar input.puml
java -jar plantuml.jar -tsvg input.puml
```

### Options
```bash
# Output format
-tpng        # PNG (default)
-tsvg        # SVG
-tpdf        # PDF
-ttxt        # ASCII art
-teps        # EPS

# Output directory
-o /path/to/output

# Dark mode
-darkmode

# Custom config
-config config.cfg

# Charset
-charset UTF-8

# Quality/DPI
-Sdpi=300
```

### Full Render Script
```bash
#!/bin/bash
# scripts/render-plantuml.sh

INPUT="$1"
NAME="${2:-diagram}"
OUTPUT_DIR="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/my_vault/Resources/${NAME}-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$OUTPUT_DIR"
cp "$INPUT" "$OUTPUT_DIR/source.puml"

plantuml -tpng -o "$OUTPUT_DIR" "$INPUT"
mv "$OUTPUT_DIR"/*.png "$OUTPUT_DIR/${NAME}.png" 2>/dev/null

plantuml -tsvg -o "$OUTPUT_DIR" "$INPUT"
mv "$OUTPUT_DIR"/*.svg "$OUTPUT_DIR/${NAME}.svg" 2>/dev/null

echo "Exported to: $OUTPUT_DIR"
```

---

## D2

### Installation
```bash
curl -fsSL https://d2lang.com/install.sh | sh -s --
```

### Basic Usage
```bash
d2 input.d2 output.svg
d2 input.d2 output.png
d2 input.d2 output.pdf
```

### Options
```bash
# Theme (0-300+)
d2 --theme 0 input.d2 output.svg      # Default
d2 --theme 1 input.d2 output.svg      # Neutral
d2 --theme 4 input.d2 output.svg      # Cool classics
d2 --theme 100 input.d2 output.svg    # Dark mode
d2 --theme 200 input.d2 output.svg    # Terminal

# Layout engine
d2 --layout dagre input.d2 output.svg   # Default
d2 --layout elk input.d2 output.svg     # Better for complex
d2 --layout tala input.d2 output.svg    # Best customization

# Sketch mode (hand-drawn look)
d2 --sketch input.d2 output.svg

# Pad (margin in pixels)
d2 --pad 50 input.d2 output.svg

# Scale
d2 --scale 2 input.d2 output.png

# Watch mode
d2 --watch input.d2 output.svg
```

### Full Render Script
```bash
#!/bin/bash
# scripts/render-d2.sh

INPUT="$1"
NAME="${2:-diagram}"
THEME="${3:-200}"  # Terminal theme default
OUTPUT_DIR="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/my_vault/Resources/${NAME}-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$OUTPUT_DIR"
cp "$INPUT" "$OUTPUT_DIR/source.d2"

d2 --theme "$THEME" "$INPUT" "$OUTPUT_DIR/${NAME}.svg"
d2 --theme "$THEME" "$INPUT" "$OUTPUT_DIR/${NAME}.png"

echo "Exported to: $OUTPUT_DIR"
```

---

## Manim

### Installation
```bash
pip install manim

# Dependencies (macOS)
brew install ffmpeg cairo pango
```

### Basic Usage
```bash
# Render scene
manim render scene.py SceneName

# Quality presets
manim -ql scene.py SceneName   # 480p 15fps (preview)
manim -qm scene.py SceneName   # 720p 30fps (medium)
manim -qh scene.py SceneName   # 1080p 60fps (high)
manim -qk scene.py SceneName   # 4K 60fps (production)

# Preview (opens video after render)
manim -pql scene.py SceneName
```

### Output Formats
```bash
# GIF
manim -qh --format=gif scene.py SceneName

# MP4 (default)
manim -qh --format=mp4 scene.py SceneName

# WebM
manim -qh --format=webm scene.py SceneName

# PNG sequence
manim -qh --format=png scene.py SceneName

# Save last frame only
manim -qh -s scene.py SceneName
```

### Options
```bash
# Output directory
manim --media_dir /path/to/output scene.py SceneName

# Output filename
manim -o custom_name scene.py SceneName

# Resolution
manim -r 1920,1080 scene.py SceneName

# Frame rate
manim --fps 30 scene.py SceneName

# Background color
manim -c WHITE scene.py SceneName
manim --background_color "#000000" scene.py SceneName

# Transparent background (PNG only)
manim -t scene.py SceneName
```

### Full Render Script
```python
#!/usr/bin/env python3
# scripts/render-manim.py

import subprocess
import sys
import os
from datetime import datetime

def render_manim(input_file, scene_name, asset_name=None, quality='h', format='gif'):
    name = asset_name or scene_name.lower()
    timestamp = datetime.now().strftime('%Y%m%d-%H%M%S')
    output_dir = os.path.expanduser(
        f'~/Library/Mobile Documents/iCloud~md~obsidian/Documents/my_vault/Resources/{name}-{timestamp}'
    )

    os.makedirs(output_dir, exist_ok=True)

    # Copy source
    with open(input_file, 'r') as f:
        source = f.read()
    with open(f'{output_dir}/source.py', 'w') as f:
        f.write(source)

    # Render
    cmd = [
        'manim', f'-q{quality}',
        f'--format={format}',
        f'--media_dir={output_dir}',
        '-o', name,
        input_file, scene_name
    ]

    subprocess.run(cmd, check=True)
    print(f'Exported to: {output_dir}')

if __name__ == '__main__':
    render_manim(sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else None)
```

---

## p5.js (Headless Export)

### Using Puppeteer

```javascript
// scripts/render-p5.js
const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

async function renderP5(sketchPath, outputName, frames = 1) {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 17);
    const outputDir = path.join(
        process.env.HOME,
        'Library/Mobile Documents/iCloud~md~obsidian/Documents/my_vault/Resources',
        `${outputName}-${timestamp}`
    );

    fs.mkdirSync(outputDir, { recursive: true });
    fs.copyFileSync(sketchPath, path.join(outputDir, 'source.js'));

    const sketchCode = fs.readFileSync(sketchPath, 'utf8');

    const html = `
<!DOCTYPE html>
<html>
<head>
    <script src="https://cdn.jsdelivr.net/npm/p5@1.9.0/lib/p5.min.js"></script>
</head>
<body>
<script>
${sketchCode}

// Capture frames
let frameIndex = 0;
const totalFrames = ${frames};

const originalDraw = window.draw;
window.draw = function() {
    if (originalDraw) originalDraw();
    if (frameIndex < totalFrames) {
        window.capturedFrame = document.querySelector('canvas').toDataURL('image/png');
        frameIndex++;
    }
};
</script>
</body>
</html>`;

    const browser = await puppeteer.launch();
    const page = await browser.newPage();
    await page.setContent(html);
    await page.waitForTimeout(1000);

    // Capture PNG
    const dataUrl = await page.evaluate(() => window.capturedFrame);
    const base64 = dataUrl.replace(/^data:image\/png;base64,/, '');
    fs.writeFileSync(path.join(outputDir, `${outputName}.png`), base64, 'base64');

    await browser.close();
    console.log(`Exported to: ${outputDir}`);
}

// Usage: node render-p5.js sketch.js output-name
renderP5(process.argv[2], process.argv[3] || 'p5-sketch');
```

---

## D3.js (Server-Side)

### Using jsdom

```javascript
// scripts/render-d3.js
const { JSDOM } = require('jsdom');
const d3 = require('d3');
const fs = require('fs');
const path = require('path');
const { createCanvas } = require('canvas');

function renderD3(chartCode, outputName, width = 800, height = 600) {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 17);
    const outputDir = path.join(
        process.env.HOME,
        'Library/Mobile Documents/iCloud~md~obsidian/Documents/my_vault/Resources',
        `${outputName}-${timestamp}`
    );

    fs.mkdirSync(outputDir, { recursive: true });
    fs.writeFileSync(path.join(outputDir, 'source.js'), chartCode);

    // Create DOM
    const dom = new JSDOM('<!DOCTYPE html><html><body></body></html>');
    const document = dom.window.document;

    // Create SVG
    const svg = d3.select(document.body)
        .append('svg')
        .attr('xmlns', 'http://www.w3.org/2000/svg')
        .attr('width', width)
        .attr('height', height);

    // Execute chart code
    eval(chartCode);

    // Save SVG
    const svgString = document.body.innerHTML;
    fs.writeFileSync(path.join(outputDir, `${outputName}.svg`), svgString);

    // Convert to PNG using canvas
    const canvas = createCanvas(width, height);
    const ctx = canvas.getContext('2d');
    // ... SVG to canvas conversion ...

    console.log(`Exported to: ${outputDir}`);
}

module.exports = { renderD3 };
```

---

## Format Conversion

### SVG to PNG (High Quality)
```bash
# Using Inkscape
inkscape input.svg -o output.png --export-dpi=300

# Using ImageMagick
convert -density 300 input.svg output.png

# Using rsvg-convert (librsvg)
rsvg-convert -d 300 -p 300 input.svg -o output.png
```

### PNG to WebP
```bash
# Using cwebp
cwebp -q 90 input.png -o output.webp

# Using ImageMagick
convert input.png -quality 90 output.webp
```

### Video to GIF
```bash
# Using ffmpeg
ffmpeg -i input.mp4 -vf "fps=15,scale=800:-1:flags=lanczos" -c:v gif output.gif

# High quality with palette
ffmpeg -i input.mp4 -vf "fps=15,scale=800:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" output.gif
```

### MP4 to WebM
```bash
ffmpeg -i input.mp4 -c:v libvpx-vp9 -crf 30 -b:v 0 output.webm
```

---

## Quick Reference

| Tool | PNG | SVG | PDF | GIF | MP4 |
|------|-----|-----|-----|-----|-----|
| Mermaid | `mmdc -o x.png` | `mmdc -o x.svg` | `mmdc -o x.pdf` | - | - |
| PlantUML | `plantuml -tpng` | `plantuml -tsvg` | `plantuml -tpdf` | - | - |
| D2 | `d2 x.d2 x.png` | `d2 x.d2 x.svg` | `d2 x.d2 x.pdf` | - | - |
| Manim | `-s` (last frame) | - | - | `--format=gif` | `--format=mp4` |
| p5.js | Puppeteer | - | - | saveGif() | ffmpeg |
| D3.js | canvas | jsdom | - | - | - |
