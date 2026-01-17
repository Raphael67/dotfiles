# pw-writer (playwriter) Reference

Extension-based Playwright MCP using user's Chrome browser.

## Architecture

- **Extension**: Chrome extension connects to localhost:19988 WebSocket
- **Single Tool**: `execute` - runs JavaScript with full Playwright API
- **State**: `state` object persists between calls
- **Context**: `page`, `context`, `state`, `require`, `console` available

## Connection Requirements

1. Install Chrome extension from playwriter
2. Click extension icon on tab to control
3. MCP connects via localhost:19988

```json
{
  "mcpServers": {
    "pw-writer": {
      "command": "npx",
      "args": ["-y", "playwriter@latest"]
    }
  }
}
```

## Core Utilities

### getCleanHTML (RECOMMENDED - 40x Token Savings)

Extract cleaned HTML with optional search filtering.

```javascript
await getCleanHTML({
  locator: page.locator('body'),  // Playwright Locator or Page
  search?: /pattern/i,            // Filter results (first 10 matches)
  showDiffSinceLastCall?: boolean,// Show diff since last call
  includeStyles?: boolean,        // Keep CSS classes/styles (default: false)
  maxAttrLen?: number,            // Max attribute length (default: 200)
  maxContentLen?: number          // Max text content (default: 500)
})
```

**Features:**
- Removes scripts, styles, SVGs, head tags
- Keeps only essential attributes (aria-*, data-*, href, role, title, alt)
- Pagination: `.split('\n').slice(offset, limit).join('\n')`

**Examples:**
```javascript
// Extract table
const table = await getCleanHTML({ locator: page.locator('table.products') });

// Search for specific content
const prices = await getCleanHTML({
  locator: page.locator('body'),
  search: /price|\$|euro/i
});

// Track changes
const diff = await getCleanHTML({
  locator: page.locator('.results'),
  showDiffSinceLastCall: true
});
```

### accessibilitySnapshot (Navigation)

Get structured text description with aria-ref for interaction.

```javascript
await accessibilitySnapshot({
  page,                          // Required
  search?: /pattern/i,           // Filter (first 10 matches)
  showDiffSinceLastCall?: boolean
})
```

**Output format:**
```
- banner [ref=e3]:
    - link "Home" [ref=e5] [cursor=pointer]:
        - /url: /
    - navigation [ref=e12]:
        - link "Docs" [ref=e13] [cursor=pointer]
```

**Using aria-ref (NO QUOTES on ref value):**
```javascript
await page.locator('aria-ref=e13').click()
await page.locator('aria-ref=e42').fill('text')
await page.locator('aria-ref=e7').hover()
```

**Pagination:**
```javascript
const snapshot = await accessibilitySnapshot({ page });
console.log(snapshot.split('\n').slice(0, 50).join('\n'));   // First 50 lines
console.log(snapshot.split('\n').slice(50, 100).join('\n')); // Next 50 lines
```

### screenshotWithAccessibilityLabels (Visual Layouts)

Take screenshot with Vimium-style labels overlaid on interactive elements.

```javascript
await screenshotWithAccessibilityLabels({
  page,
  interactiveOnly?: boolean  // Only show interactive elements
})
// Image + snapshot automatically included in response
```

**Color-coded labels:**
- Yellow: Links
- Orange: Buttons
- Coral: Text inputs (textbox, combobox, searchbox)
- Pink: Checkboxes, radios, switches
- Peach: Sliders
- Salmon: Menu items
- Amber: Tabs, options

**Use for:**
- Complex visual layouts (grids, galleries, dashboards)
- When DOM order doesn't match visual order
- Understanding spatial hierarchy

### waitForPageLoad (Smart Load Detection)

Wait for page load, ignoring analytics/ads.

```javascript
await waitForPageLoad({
  page,
  timeout?: 30000,      // Default: 30s
  pollInterval?: 100,   // Default: 100ms
  minWait?: 500         // Default: 500ms
})
// Returns: { success, readyState, pendingRequests, waitTimeMs, timedOut }
```

**Why use this:**
- Ignores analytics from known domains (Google Analytics, etc.)
- Checks `document.readyState === 'complete'`
- Monitors pending network requests
- More reliable than `waitForLoadState('networkidle')`

### getLatestLogs (Console Debugging)

Retrieve captured browser console logs.

```javascript
await getLatestLogs({
  page?: Page,           // Optional page filter
  count?: number,        // Max logs to return
  search?: /pattern/i    // Filter by pattern
})
// Returns: string[] of console messages
```

**Notes:**
- Captures up to 5000 logs per page
- Cleared on navigation
- Custom collection: `state.logs = []; page.on('console', m => state.logs.push(m.text()))`

### getCDPSession (Raw CDP Access)

Send Chrome DevTools Protocol commands directly.

```javascript
const cdp = await getCDPSession({ page });
const metrics = await cdp.send('Page.getLayoutMetrics');
const cookies = await cdp.send('Network.getCookies');
```

**Common CDP commands:**
- `Network.getCookies` - Get all cookies
- `Page.captureScreenshot` - Raw screenshot
- `DOM.getDocument` - DOM tree
- `Performance.getMetrics` - Performance data

## Network Interception (API Discovery)

Intercept network requests to reverse-engineer APIs.

### Setup Pattern
```javascript
state.requests = [];
state.responses = [];

page.on('request', req => {
  if (req.url().includes('/api/')) {
    state.requests.push({
      url: req.url(),
      method: req.method(),
      headers: req.headers()
    });
  }
});

page.on('response', async res => {
  if (res.url().includes('/api/')) {
    try {
      state.responses.push({
        url: res.url(),
        status: res.status(),
        body: await res.json()
      });
    } catch {}
  }
});
```

### Analyze Captured Data
```javascript
console.log(`Captured ${state.responses.length} API calls`);
state.responses.forEach(r => console.log(r.status, r.url.slice(0, 80)));

// Inspect specific response
const resp = state.responses.find(r => r.url.includes('products'));
console.log(JSON.stringify(resp.body, null, 2).slice(0, 2000));
```

### Replay API Directly (Pagination)
```javascript
const { url, headers } = state.requests.find(r => r.url.includes('feed'));
const data = await page.evaluate(
  async ({ url, headers }) => {
    const res = await fetch(url, { headers });
    return res.json();
  },
  { url, headers }
);
console.log(data);
```

### Reading Response Bodies
By default, response body buffering is disabled (for SSE). To read bodies:

```javascript
const cdp = await getCDPSession({ page });
await cdp.send('Network.disable');
await cdp.send('Network.enable', {
  maxTotalBufferSize: 10000000,   // 10MB
  maxResourceBufferSize: 5000000  // 5MB per resource
});

const [response] = await Promise.all([
  page.waitForResponse(r => r.url().includes('/api/data')),
  page.click('button.load-data')
]);
const body = await response.text();
```

### Cleanup
```javascript
page.removeAllListeners('request');
page.removeAllListeners('response');
```

## Handling Dynamic Content

### Accordions / Expandable Sections
```javascript
// Find and click accordion header
const snapshot = await accessibilitySnapshot({ page, search: /expand|menu|section/i });
console.log(snapshot);
await page.locator('aria-ref=e14').click();

// Wait for content to load
await waitForPageLoad({ page, timeout: 3000 });

// Now extract expanded content
const content = await getCleanHTML({ locator: page.locator('.accordion-content') });
```

### Infinite Scroll
```javascript
state.allItems = [];
let previousCount = 0;

while (true) {
  // Extract current items
  const items = await page.$$eval('.item', els => els.map(e => e.textContent));
  state.allItems.push(...items.slice(previousCount));
  previousCount = items.length;

  // Scroll to bottom
  await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
  await waitForPageLoad({ page, timeout: 3000 });

  // Check if more loaded
  const newCount = await page.$$eval('.item', els => els.length);
  if (newCount === previousCount) break;
}

console.log(`Total items: ${state.allItems.length}`);
```

### Lazy-Loaded Images
```javascript
// Scroll element into view
await page.locator('.lazy-image').scrollIntoViewIfNeeded();
await page.waitForFunction(
  el => el.complete && el.naturalHeight > 0,
  await page.locator('.lazy-image').elementHandle()
);
```

## Cookie and Dialog Handling

### Dialogs (alert, confirm, prompt)
```javascript
// Setup handler BEFORE triggering action
page.on('dialog', async dialog => {
  console.log('Dialog:', dialog.message());
  await dialog.accept();  // or dialog.dismiss()
});

await page.click('button.trigger-dialog');
```

### Cookie Consent Banners
```javascript
// Option 1: Click accept button
const snapshot = await accessibilitySnapshot({ page, search: /accept|agree|cookie/i });
if (snapshot.includes('Accept')) {
  await page.locator('aria-ref=e42').click();  // Use ref from snapshot
}

// Option 2: Hide overlay via CSS
await page.addStyleTag({ content: '.cookie-banner { display: none !important; }' });
```

## Multiple Pages/Tabs

### Find Specific Page
```javascript
const pages = context.pages().filter(p => p.url().includes('menu'));
if (pages.length !== 1) throw new Error(`Expected 1 page, found ${pages.length}`);
state.menuPage = pages[0];
```

### Create New Page
```javascript
state.newPage = await context.newPage();
await state.newPage.goto('https://example.com');
```

### Handle Popups
```javascript
const [popup] = await Promise.all([
  page.waitForEvent('popup'),
  page.click('a[target=_blank]')
]);
await popup.waitForLoadState();
console.log('Popup URL:', popup.url());
```

## Best Practices

### Always Check Page State After Actions
```javascript
console.log('url:', page.url());
console.log(await accessibilitySnapshot({ page }).then(x => x.split('\n').slice(0, 30).join('\n')));
```

### Use Multiple Execute Calls
- Break complex operations into multiple calls
- Helps debug which step failed
- Allows state inspection between steps

### Screenshots
```javascript
await page.screenshot({ path: 'shot.png', scale: 'css' });  // Always use scale: 'css'
```

### Navigation
```javascript
await page.goto('https://example.com', { waitUntil: 'domcontentloaded' });
await waitForPageLoad({ page, timeout: 5000 });
```

### Loading Files
```javascript
const fs = require('node:fs');
const content = fs.readFileSync('./data.txt', 'utf-8');
await page.locator('textarea').fill(content);
```

## Advanced Utilities

### getLocatorStringForElement
Convert ephemeral aria-ref to stable Playwright selector:
```javascript
const selector = await getLocatorStringForElement(page.locator('aria-ref=e14'));
// Returns: "getByRole('button', { name: 'Save' })"
```

### getReactSource (Dev Mode Only)
Get React component source location:
```javascript
const source = await getReactSource({ locator: page.locator('aria-ref=e5') });
// Returns: { fileName, lineNumber, columnNumber, componentName }
```

### createDebugger
Set breakpoints, step through code:
```javascript
const dbg = createDebugger({ cdp: await getCDPSession({ page }) });
await dbg.enable();
const scripts = await dbg.listScripts({ search: 'app' });
await dbg.setBreakpoint({ file: scripts[0].url, line: 42 });
```

### createEditor
Live-edit page scripts/CSS:
```javascript
const editor = createEditor({ cdp: await getCDPSession({ page }) });
await editor.enable();
await editor.edit({
  url: 'https://example.com/app.js',
  oldString: 'DEBUG = false',
  newString: 'DEBUG = true'
});
```

## Reset Connection

If connection issues occur:
```javascript
const { page, context } = await resetPlaywright();
```

Or use the `reset` MCP tool.
