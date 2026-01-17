#!/usr/bin/env node
/**
 * Render D3.js chart to SVG (server-side)
 * Usage: node render-d3.js chart.js [asset-name] [width] [height]
 */

const { JSDOM } = require('jsdom');
const d3 = require('d3');
const fs = require('fs');
const path = require('path');

function renderD3(chartPath, outputName, width = 800, height = 600) {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 17);
    const outputDir = path.join(
        process.env.HOME,
        'Library/Mobile Documents/iCloud~md~obsidian/Documents/my_vault/Resources',
        `${outputName}-${timestamp}`
    );

    fs.mkdirSync(outputDir, { recursive: true });

    // Copy source
    fs.copyFileSync(chartPath, path.join(outputDir, 'source.js'));

    const chartCode = fs.readFileSync(chartPath, 'utf8');

    console.log(`Rendering ${chartPath}...`);
    console.log(`Output: ${width}x${height}`);

    // Create virtual DOM
    const dom = new JSDOM('<!DOCTYPE html><html><body></body></html>');
    const document = dom.window.document;

    // Create SVG element
    const body = d3.select(document.body);
    const svg = body.append('svg')
        .attr('xmlns', 'http://www.w3.org/2000/svg')
        .attr('width', width)
        .attr('height', height)
        .attr('viewBox', `0 0 ${width} ${height}`);

    // Expose globals for the chart code
    global.d3 = d3;
    global.svg = svg;
    global.width = width;
    global.height = height;
    global.document = document;

    // Execute chart code
    try {
        // Wrap in function to allow return statements
        const chartFunction = new Function('d3', 'svg', 'width', 'height', chartCode);
        chartFunction(d3, svg, width, height);
    } catch (error) {
        console.error('Error executing chart code:', error);
        process.exit(1);
    }

    // Get SVG string
    const svgString = body.html();

    // Save SVG
    fs.writeFileSync(path.join(outputDir, `${outputName}.svg`), svgString);

    console.log(`\nExported to: ${outputDir}`);
    console.log('Files:');
    fs.readdirSync(outputDir).forEach(f => console.log(`  ${f}`));

    console.log(`\nTo convert to PNG: rsvg-convert -w ${width} "${outputDir}/${outputName}.svg" -o "${outputDir}/${outputName}.png"`);
}

// CLI
const args = process.argv.slice(2);

if (args.length < 1) {
    console.log('Usage: node render-d3.js chart.js [asset-name] [width] [height]');
    console.log('');
    console.log('Arguments:');
    console.log('  chart.js    - D3.js chart code file');
    console.log('  asset-name  - (optional) Output name (default: chart filename)');
    console.log('  width       - (optional) SVG width (default: 800)');
    console.log('  height      - (optional) SVG height (default: 600)');
    console.log('');
    console.log('The chart code has access to: d3, svg, width, height');
    console.log('');
    console.log('Example chart.js:');
    console.log(`
const data = [30, 50, 20, 80, 45];
const x = d3.scaleBand()
    .domain(data.map((d, i) => i))
    .range([40, width - 20])
    .padding(0.2);
const y = d3.scaleLinear()
    .domain([0, d3.max(data)])
    .range([height - 30, 20]);

svg.selectAll('rect')
    .data(data)
    .join('rect')
    .attr('x', (d, i) => x(i))
    .attr('y', d => y(d))
    .attr('width', x.bandwidth())
    .attr('height', d => y(0) - y(d))
    .attr('fill', 'steelblue');
`);
    process.exit(1);
}

const chartPath = args[0];
const outputName = args[1] || path.basename(chartPath, '.js');
const width = parseInt(args[2]) || 800;
const height = parseInt(args[3]) || 600;

renderD3(chartPath, outputName, width, height);
