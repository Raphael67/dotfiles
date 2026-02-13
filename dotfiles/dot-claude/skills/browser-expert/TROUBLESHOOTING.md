# Browser Expert Troubleshooting Guide

Common issues and solutions across all browser tools.

## Quick Diagnosis

| Symptom | Likely Cause | Solution |
|---------|--------------|----------|
| "strict mode violation" | Multiple elements match | More specific selector or switch to pw-writer |
| "Element reference no longer valid" | DOM changed | Re-capture snapshot before interaction |
| Navigation hangs | External redirect | Switch to pw-writer |
| Content not in snapshot | Not expanded/loaded | Click to expand, then extract |
| Response too large | Token budget | Use `getCleanHTML` or `expectation` filtering |
| Page blocked by modal | Cookie consent | Find and click accept button |
| Extension not detected | Chrome extension issue | Reinstall, restart Chrome |
| WebSocket connection fails | Firefox MCP extension | Reload temporary add-on |
| Port conflict | Multiple debug sessions | Kill orphan processes |

---

## Strict Mode Violations (pw-fast)

### Symptom
```
Error: strict mode violation: 3 elements matched selector
Candidates:
- ref=e42: button.submit "Submit"
- ref=e43: div.btn "Submit"
```

### Solutions

**Option 1: More specific selector**
```json
// Before (too generic)
{ "selectors": [{ "text": "Submit" }] }

// After (specific path)
{ "selectors": [{ "css": "form.login button[type='submit']" }] }
```

**Option 2: Use browser_find_elements first**
```json
{
  "name": "browser_find_elements",
  "arguments": {
    "searchCriteria": { "text": "Submit", "role": "button" },
    "maxResults": 5
  }
}
// Then use the specific ref: { "ref": "found_1" }
```

**Option 3: Switch to pw-writer** — handles multiple matches gracefully with aria-ref.

---

## Element Ref Invalidation

### Symptom
```
Error: Element reference e42 is no longer valid
```

### Cause
DOM modified between snapshot and action (React re-render, SPA navigation).

### Solutions

**Re-capture snapshot immediately before action:**
```javascript
const snapshot = await accessibilitySnapshot({ page, search: /submit/i });
await page.locator('aria-ref=e42').click();
```

**Use stable selectors instead of refs:**
```javascript
await page.getByRole('button', { name: 'Submit' }).click();
```

**Chain snapshot and action in pw-fast batch:**
```json
{
  "steps": [
    { "tool": "browser_snapshot", "arguments": {} },
    { "tool": "browser_click", "arguments": {
      "selectors": [{ "role": "button", "text": "Submit" }]
    }}
  ]
}
```

---

## External Redirects

### Symptom
Navigation hangs, page context closed, URL changes to different domain.

### Solution
**Switch to pw-writer** — handles multi-page flows natively:

```javascript
await page.goto('https://main-site.com/menu');
const pages = context.pages();
const menuPage = pages.find(p => p.url().includes('menu'));
```

---

## Cookie Consent Dialogs

### pw-fast
```json
{
  "steps": [
    { "tool": "browser_find_elements", "arguments": {
      "searchCriteria": { "text": "Accept", "role": "button" }
    }},
    { "tool": "browser_click", "arguments": {
      "selectors": [{ "role": "button", "text": "Accept" }]
    }, "continueOnError": true }
  ]
}
```

### pw-writer
```javascript
const snapshot = await accessibilitySnapshot({ page, search: /accept|agree|cookie/i });
await page.locator('aria-ref=e15').click();

// Or hide overlay
await page.addStyleTag({
  content: '.cookie-banner, .consent-modal { display: none !important; }'
});
```

---

## Accordion/Tab Content Not Visible

### Cause
Content is collapsed/hidden until user interaction.

### Solution
```javascript
// 1. Find and click to expand
const snapshot = await accessibilitySnapshot({ page, search: /menu|expand|show/i });
await page.locator('aria-ref=e10').click();

// 2. Wait for content
await waitForPageLoad({ page, timeout: 2000 });

// 3. Extract
const content = await getCleanHTML({ locator: page.locator('.accordion-content') });
```

---

## Network Timeouts

### Cause
Analytics, ads, or tracking scripts that never complete.

### pw-writer
```javascript
// Instead of (may hang):
await page.waitForLoadState('networkidle');

// Use (smart detection):
await waitForPageLoad({ page, timeout: 5000 });
```

### pw-fast
```json
{
  "tool": "browser_wait_for",
  "arguments": { "text": "Welcome" }
}
```

---

## Token Budget Exceeded

### pw-writer
```javascript
// Instead of (5000+ tokens):
const snapshot = await accessibilitySnapshot({ page });

// Use (200-500 tokens):
const html = await getCleanHTML({
  locator: page.locator('.content'),
  search: /price|item/i
});
```

### pw-fast
```json
{
  "expectation": {
    "includeSnapshot": true,
    "snapshotOptions": {
      "selector": ".main-content",
      "maxLength": 1500
    }
  }
}
```

---

## Page Context Closed

### Symptom
```
Error: Target page, context or browser has been closed
```

### pw-writer
```javascript
const { page, context } = await resetPlaywright();
```

### pw-fast
```json
{
  "name": "browser_navigate",
  "arguments": { "url": "about:blank" }
}
```

---

## Dialog Not Handled

### pw-writer
```javascript
// Set handler BEFORE action
page.on('dialog', async dialog => {
  console.log('Dialog:', dialog.message());
  await dialog.accept();
});
await page.click('button');
```

### pw-fast
```json
{
  "steps": [
    { "tool": "browser_click", "arguments": {...} },
    { "tool": "browser_handle_dialog", "arguments": { "accept": true } }
  ]
}
```

---

## Downloads Not Working

### pw-writer
```javascript
const [download] = await Promise.all([
  page.waitForEvent('download'),
  page.click('button.download')
]);
const path = await download.path();
await download.saveAs(`/tmp/${download.suggestedFilename()}`);
```

---

## Empty Accessibility Snapshot

### Cause
Page still loading, content in iframes, or closed shadow DOM.

### Solutions
```javascript
// Wait for content
await waitForPageLoad({ page, timeout: 5000 });
const snapshot = await accessibilitySnapshot({ page });

// Check for iframes
const frame = page.frameLocator('#content-frame');
const frameContent = await frame.locator('body').innerHTML();

// Use HTML extraction instead
const html = await getCleanHTML({ locator: page.locator('body') });
```

---

## Rate Limiting / Bot Detection

### pw-writer advantage
Uses user's actual Chrome with cookies/session — pre-logged in, normal browser fingerprint.

### Add delays
```javascript
await page.waitForTimeout(2000);
```

### Use network interception to find APIs
```javascript
// APIs often have less bot protection than frontend
page.on('response', async res => {
  if (res.url().includes('/api/')) {
    state.responses.push({ url: res.url(), body: await res.json() });
  }
});
```

---

## Claude Chrome Issues

| Issue | Solution |
|-------|----------|
| Extension not detected | Reinstall Chrome extension, restart Chrome, verify v1.0.36+ |
| Version mismatch | Update both Chrome extension and Claude Code to latest |
| Modal dialogs blocking | Dismiss modal manually in Chrome, then retry automation |
| Tab not responding | Switch to target tab manually, then run `/chrome` again |
| Connection lost | Run `/chrome` to reconnect |
| "Not available on free plan" | Requires Pro, Team, or Enterprise plan |

---

## Firefox MCP Issues

| Issue | Solution |
|-------|----------|
| Deno not installed | `brew install deno` |
| WebSocket connection fails | Check extension loaded in about:debugging, restart Firefox |
| Extension not loaded | about:debugging → This Firefox → Load Temporary Add-on |
| Permission errors | Run Deno with `--allow-all` flag |
| Extension lost after restart | Temporary add-ons don't persist — reload after Firefox restart |

---

## Chrome DevTools MCP Issues

| Issue | Solution |
|-------|----------|
| Chrome not found | Install Chrome or set `CHROME_PATH` env var |
| Port conflict | Kill other Chrome debug sessions: `pkill -f "chrome.*remote-debugging"` |
| Connection timeout | Increase timeout, check firewall |
| Headless rendering issues | Try `headless: false` for debugging |

---

## bdg CLI Issues

| Issue | Solution |
|-------|----------|
| Session won't start | Check Chrome installed, no conflicting debug sessions |
| Connection refused | `bdg stop` then retry, or `pkill -f "chrome.*remote-debugging"` |
| Command not found | Verify: `which bdg`, reinstall if needed |
| Invalid params | Use `bdg cdp <method> --describe` to check schema |
| Stale session | `bdg stop` and start new session |

---

## When to Switch Tools

| Issue | From | To | Reason |
|-------|------|-----|--------|
| Strict mode violations | pw-fast | pw-writer | Better element handling |
| External redirects | pw-fast | pw-writer | Multi-page support |
| Auth required | pw-fast | pw-writer or Claude Chrome | User session |
| Token budget | pw-writer snapshot | pw-writer getCleanHTML | 40x reduction |
| Need speed (simple site) | pw-writer | pw-fast batch | 10x faster |
| Need authenticated access | pw-fast | Claude Chrome | Shared login state |
| Performance profiling | Any | Chrome DevTools MCP | Built-in profiling tools |
| Quick one-off inspection | Any | bdg CLI | No MCP setup needed |
| Firefox-specific | Any | Firefox MCP | Only Firefox tool |
| E2E test suite | Scraping tools | Playwright test runner | Proper test framework |
