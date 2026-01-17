---
name: web-scraping
description: Web scraping with Playwright MCP tools. Choose pw-writer (user Chrome, complex sites, 100% reliable) or pw-fast (headless, batch mode, simple sites). Use for scraping, data extraction, browser automation, crawling, or when user mentions extract, scrape, crawl, automate browser.
user-invocable: true
version: 1.0.0
---

# Web Scraping Skill

Expert guidance for choosing between **pw-writer** and **pw-fast** MCP tools for web scraping.

## Quick Decision Tree

```
Is site complex? (SPAs, accordions, cookie dialogs, external redirects, auth)
├── YES → Use pw-writer
│   ├── Token-constrained? → getCleanHTML (40x fewer tokens)
│   ├── Need navigation? → accessibilitySnapshot + aria-ref
│   └── Visual layout complex? → screenshotWithAccessibilityLabels
│
└── NO → Selectors unambiguous? (unique IDs, test-ids)
    ├── YES → Use pw-fast batch_execute (fastest: ~2s)
    └── NO → Use pw-writer (more reliable)

Need to discover hidden APIs?
├── YES → pw-writer network interception
└── NO → DOM-based extraction
```

## Tool Comparison

| Aspect | pw-writer | pw-fast |
|--------|-----------|---------|
| **Browser** | User's Chrome (extension) | Headless Chromium |
| **Mean Time** | 22s (getCleanHTML) | 2s (batch) |
| **Success Rate** | **100%** (complex sites) | 0-33% (complex sites) |
| **Token Usage** | **~239** (getCleanHTML) | ~2,138 |
| **Strict Mode** | Handles gracefully | Fails on multiple matches |
| **Cookies/Auth** | Native (user session) | Manual handling |
| **New Tabs/Popups** | Full support | Limited |
| **Best For** | Complex sites, reliability | Simple sites, speed |

## When to Use Each Tool

### Use pw-writer when:
- Site requires login/authentication (reuses user session)
- Complex SPAs with dynamic content
- Sites with cookie consent dialogs
- Pages with accordions, tabs, or lazy-loaded content
- External redirects during navigation
- Multiple elements match selectors (would fail strict mode)
- Token budget is constrained (use `getCleanHTML`)
- Need to discover APIs via network interception

### Use pw-fast when:
- Simple, static pages with unique selectors
- Batch operations on predictable pages (forms, lists)
- No authentication required
- Speed is critical and site structure is known
- Running automated pipelines (headless)

## Quick Start Patterns

### pw-writer: Token-Efficient Extraction (RECOMMENDED)
```javascript
// Navigate and wait
await page.goto('https://example.com', { waitUntil: 'domcontentloaded' });
await waitForPageLoad({ page, timeout: 5000 });

// Extract with getCleanHTML (40x fewer tokens than snapshot)
const html = await getCleanHTML({
  locator: page.locator('table.data'),
  search: /price|item/i  // Optional: filter results
});
console.log(html);
```

### pw-writer: Navigation with aria-ref
```javascript
// Get accessibility snapshot for navigation
console.log(await accessibilitySnapshot({ page, search: /menu|button/i }));

// Click using aria-ref from snapshot (no quotes on ref value!)
await page.locator('aria-ref=e14').click();
await waitForPageLoad({ page });
```

### pw-fast: Batch Execution (Simple Sites)
```json
{
  "name": "browser_batch_execute",
  "arguments": {
    "steps": [
      { "tool": "browser_navigate", "arguments": { "url": "https://example.com" }},
      { "tool": "browser_type", "arguments": {
        "selectors": [{ "css": "#search" }], "text": "query"
      }},
      { "tool": "browser_click", "arguments": {
        "selectors": [{ "role": "button", "text": "Search" }]
      }}
    ],
    "globalExpectation": { "includeSnapshot": false }
  }
}
```

### pw-writer: API Discovery (Network Interception)
```javascript
// Setup listener
state.responses = [];
page.on('response', async res => {
  if (res.url().includes('/api/')) {
    try {
      state.responses.push({ url: res.url(), body: await res.json() });
    } catch {}
  }
});

// Trigger actions (scroll, click, navigate)
await page.click('button.load-more');

// Analyze captured API responses
console.log(`Captured ${state.responses.length} API calls`);
state.responses.forEach(r => console.log(r.url));

// Cleanup
page.removeAllListeners('response');
```

## Reference Files

| File | Use When |
|------|----------|
| [PW-WRITER.md](PW-WRITER.md) | Using pw-writer for complex scraping, need full API docs |
| [PW-FAST.md](PW-FAST.md) | Using pw-fast batch execution, selector system details |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Encountering errors (strict mode, redirects, timeouts) |
| [PATTERNS.md](PATTERNS.md) | Looking for reusable patterns (tables, forms, pagination) |

## Playwright Selector Priority

For both tools, prefer selectors in this order:

1. **Best**: `[data-testid="submit"]` - Explicit test attributes
2. **Good**: `getByRole('button', { name: 'Save' })` - Semantic ARIA
3. **Good**: `getByText('Sign in')`, `getByLabel('Email')` - User-facing
4. **OK**: `input[name="email"]` - Semantic HTML attributes
5. **Avoid**: `.btn-primary`, `#submit` - Classes/IDs change frequently
6. **Last resort**: `div > form > button` - Fragile path selectors

## Key Differences Summary

| Feature | pw-writer | pw-fast |
|---------|-----------|---------|
| **Primary Tool** | `execute` (single tool, full API) | 30+ specialized tools |
| **Token Optimization** | `getCleanHTML` (best) | `expectation` parameter |
| **Element Selection** | `aria-ref=eN` from snapshot | Selector arrays with fallback |
| **State Persistence** | `state` object | None between calls |
| **Multiple Pages** | `context.pages()` | `browser_tab_*` tools |
| **Error Recovery** | Full Playwright try/catch | `continueOnError` in batch |
