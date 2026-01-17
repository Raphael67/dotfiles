#!/usr/bin/env node
/**
 * Render p5.js sketch to PNG using Puppeteer
 * Usage: node render-p5.js sketch.js [asset-name] [width] [height] [frames]
 */

const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

async function renderP5(sketchPath, outputName, width = 800, height = 600, frames = 1) {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 17);
    const outputDir = path.join(
        process.env.HOME,
        'Library/Mobile Documents/iCloud~md~obsidian/Documents/my_vault/Resources',
        `${outputName}-${timestamp}`
    );

    fs.mkdirSync(outputDir, { recursive: true });

    // Copy source
    fs.copyFileSync(sketchPath, path.join(outputDir, 'source.js'));

    const sketchCode = fs.readFileSync(sketchPath, 'utf8');

    const html = `
<!DOCTYPE html>
<html>
<head>
    <script src="https://cdn.jsdelivr.net/npm/p5@1.9.0/lib/p5.min.js"></script>
    <style>
        body { margin: 0; padding: 0; overflow: hidden; }
        canvas { display: block; }
    </style>
</head>
<body>
<script>
// Inject canvas size
window._targetWidth = ${width};
window._targetHeight = ${height};
window._totalFrames = ${frames};
window._capturedFrames = [];

// Override createCanvas to use our dimensions
const originalCreateCanvas = window.createCanvas;
window.createCanvas = function(w, h, renderer) {
    return originalCreateCanvas.call(this, window._targetWidth, window._targetHeight, renderer);
};

${sketchCode}

// Capture frames
let _frameIndex = 0;
const _originalDraw = window.draw;
window.draw = function() {
    if (_originalDraw) _originalDraw();

    if (_frameIndex < window._totalFrames) {
        const canvas = document.querySelector('canvas');
        if (canvas) {
            window._capturedFrames.push(canvas.toDataURL('image/png'));
        }
        _frameIndex++;
    }

    if (_frameIndex >= window._totalFrames) {
        window._renderComplete = true;
        noLoop();
    }
};
</script>
</body>
</html>`;

    console.log(`Rendering ${sketchPath}...`);
    console.log(`Output: ${width}x${height}, ${frames} frame(s)`);

    const browser = await puppeteer.launch({
        headless: 'new',
        args: ['--no-sandbox']
    });

    try {
        const page = await browser.newPage();
        await page.setViewport({ width, height });
        await page.setContent(html);

        // Wait for rendering to complete
        await page.waitForFunction('window._renderComplete === true', {
            timeout: 30000
        });

        // Get captured frames
        const capturedFrames = await page.evaluate(() => window._capturedFrames);

        // Save frames
        if (frames === 1) {
            const base64 = capturedFrames[0].replace(/^data:image\/png;base64,/, '');
            fs.writeFileSync(path.join(outputDir, `${outputName}.png`), base64, 'base64');
        } else {
            for (let i = 0; i < capturedFrames.length; i++) {
                const base64 = capturedFrames[i].replace(/^data:image\/png;base64,/, '');
                const frameName = `${outputName}-${String(i).padStart(4, '0')}.png`;
                fs.writeFileSync(path.join(outputDir, frameName), base64, 'base64');
            }
            console.log(`Saved ${capturedFrames.length} frames`);
            console.log(`To create GIF: ffmpeg -framerate 30 -i "${outputDir}/${outputName}-%04d.png" -vf "scale=${width}:-1" "${outputDir}/${outputName}.gif"`);
        }

        console.log(`\nExported to: ${outputDir}`);
        console.log('Files:');
        fs.readdirSync(outputDir).forEach(f => console.log(`  ${f}`));

    } finally {
        await browser.close();
    }
}

// CLI
const args = process.argv.slice(2);

if (args.length < 1) {
    console.log('Usage: node render-p5.js sketch.js [asset-name] [width] [height] [frames]');
    console.log('');
    console.log('Arguments:');
    console.log('  sketch.js   - p5.js sketch file');
    console.log('  asset-name  - (optional) Output name (default: sketch filename)');
    console.log('  width       - (optional) Canvas width (default: 800)');
    console.log('  height      - (optional) Canvas height (default: 600)');
    console.log('  frames      - (optional) Number of frames to capture (default: 1)');
    process.exit(1);
}

const sketchPath = args[0];
const outputName = args[1] || path.basename(sketchPath, '.js');
const width = parseInt(args[2]) || 800;
const height = parseInt(args[3]) || 600;
const frames = parseInt(args[4]) || 1;

renderP5(sketchPath, outputName, width, height, frames).catch(console.error);
