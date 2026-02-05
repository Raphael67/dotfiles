# Web Scraping MCP Tools Reference

Two Playwright-based MCP tools for web scraping: **pw-writer** (extension-based, complex sites) and **pw-fast** (headless, simple sites).

---

## pw-writer (playwriter)

Extension-based Playwright MCP using user's Chrome browser.

### Architecture

- **Extension**: Chrome extension connects to localhost:19988 WebSocket
- **Single Tool**: `execute` — runs JavaScript with full Playwright API
- **State**: `state` object persists between calls
- **Context**: `page`, `context`, `state`, `require`, `console` available

### Setup

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

### getCleanHTML (RECOMMENDED — 40x Token Savings)

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

```javascript
const cdp = await getCDPSession({ page });
const metrics = await cdp.send('Page.getLayoutMetrics');
const cookies = await cdp.send('Network.getCookies');
```

**Common CDP commands:**
- `Network.getCookies` — Get all cookies
- `Page.captureScreenshot` — Raw screenshot
- `DOM.getDocument` — DOM tree
- `Performance.getMetrics` — Performance data

### Network Interception (API Discovery)

```javascript
// Setup listener
state.requests = [];
state.responses = [];

page.on('request', req => {
  if (req.url().includes('/api/')) {
    state.requests.push({
      url: req.url(), method: req.method(), headers: req.headers()
    });
  }
});

page.on('response', async res => {
  if (res.url().includes('/api/')) {
    try {
      state.responses.push({
        url: res.url(), status: res.status(), body: await res.json()
      });
    } catch {}
  }
});
```

**Reading response bodies (SSE buffering):**
```javascript
const cdp = await getCDPSession({ page });
await cdp.send('Network.disable');
await cdp.send('Network.enable', {
  maxTotalBufferSize: 10000000,   // 10MB
  maxResourceBufferSize: 5000000  // 5MB per resource
});
```

**Cleanup:**
```javascript
page.removeAllListeners('request');
page.removeAllListeners('response');
```

### Dynamic Content

**Accordions / Expandable Sections:**
```javascript
const snapshot = await accessibilitySnapshot({ page, search: /expand|menu/i });
await page.locator('aria-ref=e14').click();
await waitForPageLoad({ page, timeout: 3000 });
const content = await getCleanHTML({ locator: page.locator('.accordion-content') });
```

**Infinite Scroll:**
```javascript
state.allItems = [];
let previousCount = 0;
while (true) {
  const items = await page.$$eval('.item', els => els.map(e => e.textContent));
  state.allItems.push(...items.slice(previousCount));
  previousCount = items.length;
  await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
  await waitForPageLoad({ page, timeout: 3000 });
  const newCount = await page.$$eval('.item', els => els.length);
  if (newCount === previousCount) break;
}
```

### Cookie and Dialog Handling

**Dialogs:**
```javascript
// Setup handler BEFORE triggering action
page.on('dialog', async dialog => {
  console.log('Dialog:', dialog.message());
  await dialog.accept();  // or dialog.dismiss()
});
await page.click('button.trigger-dialog');
```

**Cookie Consent:**
```javascript
// Option 1: Click accept button
const snapshot = await accessibilitySnapshot({ page, search: /accept|agree|cookie/i });
await page.locator('aria-ref=e42').click();

// Option 2: Hide overlay via CSS
await page.addStyleTag({ content: '.cookie-banner { display: none !important; }' });
```

### Multiple Pages/Tabs

```javascript
// Find specific page
const pages = context.pages().filter(p => p.url().includes('menu'));
state.menuPage = pages[0];

// Create new page
state.newPage = await context.newPage();
await state.newPage.goto('https://example.com');

// Handle popups
const [popup] = await Promise.all([
  page.waitForEvent('popup'),
  page.click('a[target=_blank]')
]);
```

### Advanced Utilities

```javascript
// Convert aria-ref to stable selector
const selector = await getLocatorStringForElement(page.locator('aria-ref=e14'));
// Returns: "getByRole('button', { name: 'Save' })"

// React source location (dev mode only)
const source = await getReactSource({ locator: page.locator('aria-ref=e5') });

// Debugger
const dbg = createDebugger({ cdp: await getCDPSession({ page }) });
await dbg.enable();

// Live editor
const editor = createEditor({ cdp: await getCDPSession({ page }) });
await editor.edit({ url: '...', oldString: '...', newString: '...' });

// Reset connection
const { page, context } = await resetPlaywright();
```

### Best Practices

- **Check page state after actions**: `console.log('url:', page.url());`
- **Break complex operations** into multiple execute calls
- **Screenshots**: Always use `scale: 'css'`
- **Navigation**: Use `waitUntil: 'domcontentloaded'` then `waitForPageLoad`
- **Loading files**: `const fs = require('node:fs');`

---

## pw-fast (fast-playwright-mcp)

Headless Chromium MCP optimized for batch execution and token efficiency.

### Architecture

- **Browser**: Headless Chromium (auto-launched)
- **Tools**: 30+ specialized tools (not a single execute tool)
- **Optimization**: `expectation` parameter controls response size
- **Batch**: `browser_batch_execute` for combining operations

### Tool Categories

**Core Automation:**
- `browser_navigate` — Navigate to URLs
- `browser_click` — Click elements
- `browser_type` — Type text into inputs
- `browser_hover` — Hover over elements
- `browser_press_key` — Press keyboard keys
- `browser_select_option` — Select dropdown options
- `browser_drag` — Drag and drop
- `browser_file_upload` — Upload files
- `browser_handle_dialog` — Handle alerts/confirms/prompts
- `browser_wait_for` — Wait for text/conditions

**Inspection:**
- `browser_snapshot` — Accessibility snapshot
- `browser_take_screenshot` — Screenshots with compression
- `browser_find_elements` — Discover elements by criteria
- `browser_inspect_html` — Extract HTML with depth control
- `browser_diagnose` — Page complexity analysis
- `browser_console_messages` — Console output
- `browser_network_requests` — Network activity

**Tabs:**
- `browser_tab_list` / `browser_tab_new` / `browser_tab_select` / `browser_tab_close`

**Batch:**
- `browser_batch_execute` — Execute multiple operations in sequence

### Unified Selector System

All element-targeting tools use the same selector system with fallback support.

```typescript
// 1. REF — System-generated element ID (fastest)
{ "ref": "e42" }

// 2. ROLE — ARIA role with optional text
{ "role": "button", "text": "Submit" }

// 3. CSS — Standard CSS selectors
{ "css": "#submit-btn" }

// 4. TEXT — Text content search
{ "text": "Click here" }
{ "text": "Email", "tag": "input" }
```

**Fallback arrays** (first match wins):
```json
{
  "selectors": [
    { "ref": "e42" },
    { "css": "#submit-btn" },
    { "role": "button", "text": "Submit" }
  ]
}
```

**Strict mode violations** — when multiple elements match:
1. Use more specific selector: `{ "css": "form.login button[type='submit']" }`
2. Use `browser_find_elements` to discover the right ref
3. Switch to pw-writer if site is too complex

### Batch Execution

```json
{
  "name": "browser_batch_execute",
  "arguments": {
    "steps": [
      {
        "tool": "browser_navigate",
        "arguments": { "url": "https://example.com" },
        "expectation": { "includeSnapshot": false }
      },
      {
        "tool": "browser_type",
        "arguments": {
          "selectors": [{ "css": "#username" }],
          "text": "user@example.com"
        }
      },
      {
        "tool": "browser_click",
        "arguments": {
          "selectors": [{ "role": "button", "text": "Sign In" }]
        },
        "expectation": { "includeSnapshot": true }
      }
    ],
    "globalExpectation": {
      "includeSnapshot": false,
      "includeConsole": false,
      "includeTabs": false
    },
    "stopOnFirstError": false
  }
}
```

**Best practices:**
- Combine 3-7 operations per batch
- Use `globalExpectation` to reduce tokens across all steps
- Enable snapshot only on final step
- Use `continueOnError: true` for optional elements

### Expectation Parameter

Controls what gets returned in responses (70-80% token reduction).

```typescript
{
  "expectation": {
    "includeSnapshot": false,     // Accessibility tree (biggest impact)
    "includeConsole": false,      // Console messages
    "includeTabs": false,         // Tab list
    "includeDownloads": false,    // Download info
    "includeCode": false,         // Playwright code generation

    "snapshotOptions": {
      "selector": ".main-content", // Scope to specific area
      "maxLength": 1500,           // Truncate at character boundary
      "format": "aria"             // aria | text | html
    },

    "consoleOptions": {
      "levels": ["error", "warn"],
      "maxMessages": 10,
      "patterns": ["error"],
      "removeDuplicates": true
    },

    "diffOptions": {
      "enabled": true,             // Show only changes (80% reduction)
      "format": "minimal",         // unified | split | minimal
      "maxDiffLines": 50,
      "context": 3
    },

    "imageOptions": {
      "format": "jpeg",
      "quality": 60,
      "maxWidth": 800,
      "maxHeight": 600
    }
  }
}
```

### Element Discovery

```json
{
  "name": "browser_find_elements",
  "arguments": {
    "searchCriteria": {
      "text": "Submit",
      "role": "button"
    },
    "maxResults": 5,
    "enableEnhancedDiscovery": true
  }
}
```

Returns refs like `found_1`, `found_2` for subsequent calls.

### Defaults Reference

All tools default to minimal output:
```typescript
{
  includeSnapshot: false,
  includeConsole: false,
  includeDownloads: false,
  includeTabs: false,
  includeCode: false
}
```
Exception: `browser_snapshot` always includes snapshot.
