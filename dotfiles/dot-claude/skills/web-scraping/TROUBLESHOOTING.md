# Web Scraping Troubleshooting Guide

Common issues and solutions for pw-writer and pw-fast.

## Quick Diagnosis

| Symptom | Likely Cause | Solution |
|---------|--------------|----------|
| "strict mode violation" | Multiple elements match | More specific selector or switch to pw-writer |
| "Element reference no longer valid" | DOM changed | Re-capture snapshot before interaction |
| Navigation hangs | External redirect | Switch to pw-writer |
| Content not in snapshot | Not expanded/loaded | Click to expand, then extract |
| Response too large | Token budget | Use `getCleanHTML` or `expectation` filtering |
| Page blocked by modal | Cookie consent | Find and click accept button |

---

## Strict Mode Violations (pw-fast)

### Symptom
```
Error: strict mode violation: 3 elements matched selector
Candidates:
- ref=e42: button.submit "Submit"
- ref=e43: div.btn "Submit"
```

### Cause
Selector matches multiple elements. Playwright requires exact single match.

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

**Option 3: Switch to pw-writer**
pw-writer handles multiple matches gracefully with aria-ref system.

---

## Element Ref Invalidation

### Symptom
```
Error: Element reference e42 is no longer valid
```

### Cause
DOM was modified between getting the snapshot and using the ref (React re-render, SPA navigation).

### Solutions

**Option 1: Re-capture snapshot immediately before action**
```javascript
// pw-writer
const snapshot = await accessibilitySnapshot({ page, search: /submit/i });
// Use ref immediately
await page.locator('aria-ref=e42').click();
```

**Option 2: Use stable selectors instead of refs**
```javascript
// Instead of ref, use CSS or role
await page.getByRole('button', { name: 'Submit' }).click();
```

**Option 3: Chain snapshot and action in pw-fast batch**
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
- Navigation hangs indefinitely
- Page context closed unexpectedly
- URL changes to different domain

### Cause
Site redirects to external domain (common with menu systems, payment flows).

### Solution
**Switch to pw-writer** - handles multi-page flows natively:

```javascript
// pw-writer handles external redirects
await page.goto('https://main-site.com/menu');
// If it redirects to menu.external-site.com, pw-writer follows

// Access all pages including external
const pages = context.pages();
const menuPage = pages.find(p => p.url().includes('menu'));
```

---

## Cookie Consent Dialogs

### Symptom
Page blocked by modal overlay, elements not clickable.

### Solutions

**pw-fast: Find and click accept button**
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

**pw-writer: Use accessibility snapshot to find button**
```javascript
const snapshot = await accessibilitySnapshot({ page, search: /accept|agree|cookie/i });
console.log(snapshot);
// Find the accept button ref and click
await page.locator('aria-ref=e15').click();
```

**pw-writer: Hide overlay with CSS**
```javascript
await page.addStyleTag({
  content: '.cookie-banner, .consent-modal { display: none !important; }'
});
```

---

## Accordion/Tab Content Not Visible

### Symptom
Expected content missing from snapshot or HTML extraction.

### Cause
Content is collapsed/hidden until user interaction.

### Solutions

**Step 1: Find and click to expand**
```javascript
// pw-writer
const snapshot = await accessibilitySnapshot({ page, search: /menu|expand|show/i });
await page.locator('aria-ref=e10').click();  // Click accordion header
await waitForPageLoad({ page, timeout: 2000 });
```

**Step 2: Wait for content to load**
```javascript
// pw-writer
await page.waitForSelector('.accordion-content:visible');
// or
await waitForPageLoad({ page, timeout: 3000 });
```

**Step 3: Then extract**
```javascript
const content = await getCleanHTML({ locator: page.locator('.accordion-content') });
```

---

## Network Timeouts

### Symptom
- `waitForLoadState` hangs
- Page never reports "complete"
- Long-running analytics blocking load

### Cause
Analytics, ads, or tracking scripts that never complete.

### Solutions

**pw-writer: Use waitForPageLoad (ignores analytics)**
```javascript
// Instead of
await page.waitForLoadState('networkidle');  // May hang

// Use
await waitForPageLoad({ page, timeout: 5000 });  // Smart load detection
```

**pw-fast: Use domcontentloaded instead of networkidle**
```json
{
  "tool": "browser_navigate",
  "arguments": {
    "url": "https://example.com"
    // Don't wait for networkidle
  }
}
```

**Add explicit wait for expected content**
```json
{
  "tool": "browser_wait_for",
  "arguments": { "text": "Welcome" }
}
```

---

## Token Budget Exceeded

### Symptom
- Response truncated
- Very large response size
- Slow processing

### Solutions

**pw-writer: Use getCleanHTML instead of accessibilitySnapshot**
```javascript
// Instead of (5000+ tokens)
const snapshot = await accessibilitySnapshot({ page });

// Use (200-500 tokens)
const html = await getCleanHTML({
  locator: page.locator('.content'),
  search: /price|item/i  // Filter results
});
```

**pw-fast: Use expectation parameter**
```json
{
  "expectation": {
    "includeSnapshot": true,
    "snapshotOptions": {
      "selector": ".main-content",  // Scope to relevant area
      "maxLength": 1500             // Limit size
    }
  }
}
```

**pw-fast: Disable snapshot for intermediate steps**
```json
{
  "steps": [
    { "tool": "browser_navigate", "arguments": {...}, "expectation": { "includeSnapshot": false }},
    { "tool": "browser_click", "arguments": {...}, "expectation": { "includeSnapshot": false }},
    { "tool": "browser_snapshot", "arguments": {} }  // Only final step
  ]
}
```

---

## Page Context Closed

### Symptom
```
Error: Target page, context or browser has been closed
```

### Cause
- External navigation closed the page
- Browser crashed
- Connection lost

### Solutions

**pw-writer: Reset connection**
```javascript
const { page, context } = await resetPlaywright();
// Or use the reset MCP tool
```

**pw-fast: Navigate to fresh page**
```json
{
  "name": "browser_navigate",
  "arguments": { "url": "about:blank" }
}
// Then navigate to target
```

**pw-writer: Handle popups properly**
```javascript
// Capture popup before triggering
const [popup] = await Promise.all([
  page.waitForEvent('popup'),
  page.click('a[target=_blank]')
]);
state.newPage = popup;
```

---

## Dialog Not Handled

### Symptom
- Page hangs after alert/confirm/prompt
- "Dialog was dismissed" error

### Cause
Dialog handler not set up before triggering action.

### Solutions

**pw-writer: Set handler BEFORE action**
```javascript
// WRONG - will hang
page.on('dialog', dialog => console.log(dialog.message()));
await page.click('button');

// RIGHT - resolve the dialog
page.on('dialog', async dialog => {
  console.log('Dialog:', dialog.message());
  await dialog.accept();  // or dialog.dismiss()
});
await page.click('button');
```

**pw-fast: Use browser_handle_dialog**
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

### Symptom
- Download doesn't start
- Can't access downloaded file

### Solutions

**pw-writer: Capture download event**
```javascript
const [download] = await Promise.all([
  page.waitForEvent('download'),
  page.click('button.download')
]);
const path = await download.path();
await download.saveAs(`/tmp/${download.suggestedFilename()}`);
console.log('Downloaded to:', path);
```

---

## Empty Accessibility Snapshot

### Symptom
Snapshot returns minimal or empty content.

### Cause
- Page still loading
- Content in iframes
- Shadow DOM (closed)

### Solutions

**Wait for content**
```javascript
await waitForPageLoad({ page, timeout: 5000 });
const snapshot = await accessibilitySnapshot({ page });
```

**Check for iframes**
```javascript
// Content might be in iframe
const frame = page.frameLocator('#content-frame');
const frameContent = await frame.locator('body').innerHTML();
```

**Use HTML extraction instead**
```javascript
// If snapshot is empty, try HTML
const html = await getCleanHTML({ locator: page.locator('body') });
```

---

## Rate Limiting / Bot Detection

### Symptom
- 403/429 errors
- CAPTCHA challenges
- Empty responses

### Solutions

**pw-writer advantage**: Uses user's actual Chrome with cookies/session
- Pre-logged in
- Has normal browser fingerprint
- Cookies from previous visits

**Add delays between requests**
```javascript
await page.waitForTimeout(2000);  // 2 second delay
```

**Use network interception to find APIs**
```javascript
// Often APIs have less bot protection than frontend
state.responses = [];
page.on('response', async res => {
  if (res.url().includes('/api/')) {
    state.responses.push({ url: res.url(), body: await res.json() });
  }
});
```

---

## Quick Reference: When to Switch Tools

| Issue | From | To | Reason |
|-------|------|-----|--------|
| Strict mode violations | pw-fast | pw-writer | Better element handling |
| External redirects | pw-fast | pw-writer | Multi-page support |
| Auth required | pw-fast | pw-writer | User session |
| Token budget | pw-writer snapshot | pw-writer getCleanHTML | 40x reduction |
| Need speed (simple site) | pw-writer | pw-fast batch | 10x faster |
