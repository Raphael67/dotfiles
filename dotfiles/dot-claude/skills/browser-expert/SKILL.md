---
name: browser-expert
description: >
  Browser automation expert covering Playwright testing, Playwright CLI, web scraping (pw-writer/pw-fast/tadpole),
  Claude Chrome integration, Firefox MCP, Chrome DevTools MCP, and bdg CLI.
  Use for e2e tests, browser automation, scraping, data extraction, crawling,
  browser debugging, Chrome DevTools, agentic browser orchestration, or when user mentions
  Playwright, Playwright CLI, scrape, crawl, automate browser, bdg, chrome, firefox, tadpole, KDL.
user-invocable: true
argument-hint: [self-update]
version: 1.0.0
---

# Browser Expert Skill

## Quick Reference

| Topic | File | Use When |
|-------|------|----------|
| E2E testing | [TESTING.md](TESTING.md) | Writing Playwright tests, locators, assertions, config |
| Scraping tools | [SCRAPING.md](SCRAPING.md) | pw-writer, pw-fast, or Tadpole tool APIs |
| Browser tools | [TOOLS.md](TOOLS.md) | Claude Chrome, Firefox MCP, Chrome DevTools MCP, Playwright CLI, bdg CLI |
| Test patterns | [TESTING-PATTERNS.md](TESTING-PATTERNS.md) | POM, auth, mocking, visual, a11y, mobile |
| Scraping patterns | [SCRAPING-PATTERNS.md](SCRAPING-PATTERNS.md) | Tables, pagination, forms, API discovery, agentic orchestration |
| Troubleshooting | [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Errors, tool switching, debugging |

## Argument Routing

If argument is `self-update`, execute [cookbook/self-update.md](cookbook/self-update.md).

## 8-Tool Decision Tree

```
What are you trying to do?
│
├── Write e2e tests?
│   └── Playwright test runner → TESTING.md
│
├── Scrape/extract data from websites?
│   ├── Declarative/repeatable workflow? (KDL scripts, anti-detection, modules)
│   │   └── Tadpole → SCRAPING.md
│   ├── Complex site? (SPAs, auth, cookie dialogs, redirects)
│   │   └── pw-writer MCP → SCRAPING.md
│   └── Simple site with known selectors?
│       └── pw-fast MCP → SCRAPING.md
│
├── Token-efficient CLI browser control for agents? (no MCP overhead)
│   └── Playwright CLI → TOOLS.md
│
├── Debug/inspect a web app interactively?
│   ├── Need authenticated access to web app?
│   │   └── Claude Chrome (`claude --chrome`) → TOOLS.md
│   ├── Need performance profiling or network inspection?
│   │   └── Chrome DevTools MCP → TOOLS.md
│   └── Quick low-level CDP inspection?
│       └── bdg CLI → TOOLS.md
│
└── Automate Firefox specifically?
    └── Claude Firefox MCP → TOOLS.md
```

## Tool Comparison

| Tool | Type | Browser | Auth | Speed | Best For |
|------|------|---------|------|-------|----------|
| **Playwright** | Test runner | Chromium/FF/WebKit | Storage state | Medium | E2E testing |
| **pw-writer** | MCP (extension) | User's Chrome | Native session | ~22s | Complex scraping, SPAs |
| **pw-fast** | MCP (headless) | Headless Chromium | Manual | ~2s batch | Simple scraping, batch ops |
| **Claude Chrome** | Built-in | User's Chrome | Shared login | Fast | Authenticated apps, live debug |
| **Firefox MCP** | MCP (extension) | Firefox | Extension | Medium | Firefox automation |
| **DevTools MCP** | MCP (npx) | Headless Chrome | None | Fast | Perf profiling, network |
| **Tadpole** | CLI (KDL DSL) | Headless Chrome | None | Medium | Declarative scraping, anti-detection, reusable modules |
| **Playwright CLI** | CLI | Chromium | Storage state | Fast | Token-efficient agent automation, CI pipelines |
| **bdg CLI** | CLI | Chrome | None | Fast | Low-level CDP, quick inspect |

## Quick Starts

### Playwright Test
```typescript
import { test, expect } from '@playwright/test';

test('example', async ({ page }) => {
    await page.goto('https://example.com');
    await expect(page).toHaveTitle(/Example/);
    await page.getByRole('button', { name: 'Submit' }).click();
    await expect(page.getByText('Success')).toBeVisible();
});
```

### pw-writer (Complex Scraping)
```javascript
await page.goto('https://example.com', { waitUntil: 'domcontentloaded' });
await waitForPageLoad({ page, timeout: 5000 });
const html = await getCleanHTML({
  locator: page.locator('table.data'),
  search: /price|item/i
});
console.log(html);
```

### pw-fast (Simple Scraping)
```json
{
  "name": "browser_batch_execute",
  "arguments": {
    "steps": [
      { "tool": "browser_navigate", "arguments": { "url": "https://example.com" }},
      { "tool": "browser_snapshot", "arguments": {} }
    ],
    "globalExpectation": { "includeSnapshot": false }
  }
}
```

### Tadpole (Declarative Scraping)
```kdl
main {
  new_page {
    goto "https://example.com"
    $$ ".product" {
      extract "products[]" {
        name { $ "h2" ; text }
        price { $ ".price" ; attr "data-value" }
      }
    }
  }
}
```
```bash
tadpole run scrape.kdl --auto --headless --output results.json
```

### Playwright CLI
```bash
npm install -g @anthropic-ai/playwright-cli@latest && playwright-cli install
playwright-cli goto "https://example.com"   # Navigate
playwright-cli snapshot                      # Get page state
playwright-cli click --text "Submit"         # Interact
playwright-cli close                         # End session
```

### Claude Chrome
```bash
claude --chrome           # Launch with Chrome integration
# Or inside session:
/chrome                   # Connect to Chrome
```

### bdg CLI
```bash
bdg example.com                    # Start session
bdg cdp Page.captureScreenshot     # Screenshot
bdg dom query "button"             # Query DOM
bdg stop                           # End session
```

### Chrome DevTools MCP
```bash
claude mcp add chrome-devtools --scope user npx chrome-devtools-mcp@latest
```

### Firefox MCP
```bash
git clone https://github.com/hyperpolymath/claude-firefox-mcp
cd claude-firefox-mcp && ./scripts/install.sh
```

## Unified Selector Priority

For all Playwright-based tools (test runner, pw-writer, pw-fast), prefer selectors in this order:

1. **Best**: `getByRole('button', { name: 'Submit' })` — Semantic ARIA, resilient to DOM changes
2. **Good**: `getByLabel('Email')`, `getByText('Sign in')` — User-facing text
3. **Good**: `getByTestId('submit-btn')` — Explicit test attributes
4. **Good**: `getByPlaceholder('Enter email')` — Placeholder text
5. **OK**: `getByAltText('Logo')`, `getByTitle('Close')` — Alt/title attributes
6. **Fallback**: `locator('input[name="email"]')` — Semantic HTML attributes
7. **Avoid**: `locator('.btn-primary')`, `locator('#submit')` — Classes/IDs change
8. **Last resort**: `locator('div > form > button')` — Fragile path selectors

**pw-writer specific**: Use `aria-ref=eN` from `accessibilitySnapshot` for precise targeting.
**pw-fast specific**: Use selector arrays with fallback: `[{ "ref": "e42" }, { "css": "#btn" }, { "role": "button" }]`

## External Resources

| Resource | URL |
|----------|-----|
| Playwright docs | https://playwright.dev/docs/intro |
| Playwright API | https://playwright.dev/docs/api/class-page |
| pw-fast (fast-playwright-mcp) | https://github.com/tontoko/fast-playwright-mcp |
| pw-writer (playwriter) | https://github.com/remorses/playwriter |
| Claude Chrome docs | https://code.claude.com/docs/en/chrome |
| Chrome DevTools MCP | https://github.com/ChromeDevTools/chrome-devtools-mcp |
| Firefox MCP | https://github.com/hyperpolymath/claude-firefox-mcp |
| Tadpole | https://github.com/tadpolehq/tadpole |
| Tadpole community modules | https://github.com/tadpolehq/community |
| Playwright CLI | https://www.npmjs.com/package/@anthropic-ai/playwright-cli |
| Bowser (agentic patterns reference) | https://github.com/disler/bowser |
| bdg CLI | https://github.com/szymdzum/browser-debugger-cli |

## When to Read Each File

- **Starting a new e2e test suite** → TESTING.md for setup, then TESTING-PATTERNS.md for patterns
- **Scraping a website** → Check decision tree above, then SCRAPING.md for tool API (pw-writer, pw-fast, or Tadpole)
- **Complex scraping scenario** → SCRAPING-PATTERNS.md for reusable patterns
- **Using Claude Chrome or other browser tools** → TOOLS.md
- **Token-efficient browser automation** → TOOLS.md (Playwright CLI section)
- **Agentic browser orchestration patterns** → SCRAPING-PATTERNS.md
- **Something not working** → TROUBLESHOOTING.md
- **Updating this skill's docs** → `/browser-expert self-update`
