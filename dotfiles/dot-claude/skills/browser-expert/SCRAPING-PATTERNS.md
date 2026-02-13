# Web Scraping Patterns

Reusable patterns for common scraping tasks with pw-writer, pw-fast, and Tadpole.

---

## Table Extraction

### pw-writer (Recommended)

```javascript
// Navigate to page with table
await page.goto('https://example.com/data', { waitUntil: 'domcontentloaded' });
await waitForPageLoad({ page, timeout: 5000 });

// Extract table HTML (token-efficient)
const tableHtml = await getCleanHTML({ locator: page.locator('table.data') });
console.log(tableHtml);

// Or extract as structured data
const data = await page.$$eval('table.data tr', rows => {
  return rows.map(row => {
    const cells = row.querySelectorAll('td, th');
    return Array.from(cells).map(cell => cell.textContent.trim());
  });
});
console.log(JSON.stringify(data, null, 2));
```

### pw-fast

```json
{
  "steps": [
    { "tool": "browser_navigate", "arguments": { "url": "https://example.com/data" }},
    { "tool": "browser_wait_for", "arguments": { "text": "Loading...", "textGone": true }},
    { "tool": "browser_inspect_html", "arguments": {
      "selectors": [{ "css": "table.data" }],
      "depth": 5,
      "format": "html",
      "maxSize": 50000
    }}
  ],
  "globalExpectation": { "includeSnapshot": false }
}
```

### Tadpole

```kdl
main {
  new_page {
    goto "https://example.com/data"
    wait_until
    $$ "table.data tr" {
      extract "rows[]" {
        cells { func "(el) => Array.from(el.querySelectorAll('td, th')).map(c => c.textContent.trim())" }
      }
    }
  }
}
```
```bash
tadpole run table-extract.kdl --auto --headless --output table.json
```

---

## Paginated List Scraping

### pw-writer with State Persistence

```javascript
// Initialize state
state.allItems = [];
state.pageNum = 1;

// Scrape current page
const items = await page.$$eval('.item', els => els.map(e => ({
  title: e.querySelector('.title')?.textContent,
  price: e.querySelector('.price')?.textContent,
  link: e.querySelector('a')?.href
})));
state.allItems.push(...items);
console.log(`Page ${state.pageNum}: ${items.length} items`);

// Check for next page
const hasNext = await page.$('a.next-page:not(.disabled)');
if (hasNext) {
  state.pageNum++;
  await page.click('a.next-page');
  await waitForPageLoad({ page, timeout: 5000 });
  // Call this execute block again
}

console.log(`Total: ${state.allItems.length} items`);
```

### Continue Pagination

```javascript
// Continue from previous state
const items = await page.$$eval('.item', els => els.map(e => ({
  title: e.querySelector('.title')?.textContent,
  price: e.querySelector('.price')?.textContent
})));
state.allItems.push(...items);

const hasNext = await page.$('a.next-page:not(.disabled)');
if (hasNext) {
  state.pageNum++;
  await page.click('a.next-page');
  await waitForPageLoad({ page });
}

console.log(`Page ${state.pageNum}: Total ${state.allItems.length} items`);
```

---

## Form Fill and Submit

### pw-fast Batch (Simple Forms)

```json
{
  "steps": [
    { "tool": "browser_navigate", "arguments": { "url": "/contact" }},
    { "tool": "browser_type", "arguments": {
      "selectors": [{ "css": "input[name='name']" }], "text": "John Doe"
    }},
    { "tool": "browser_type", "arguments": {
      "selectors": [{ "css": "input[name='email']" }], "text": "john@example.com"
    }},
    { "tool": "browser_type", "arguments": {
      "selectors": [{ "css": "textarea[name='message']" }], "text": "Hello, I have a question..."
    }},
    { "tool": "browser_select_option", "arguments": {
      "selectors": [{ "css": "select[name='subject']" }], "values": ["support"]
    }},
    { "tool": "browser_click", "arguments": {
      "selectors": [{ "role": "button", "text": "Submit" }]
    }, "expectation": {
      "includeSnapshot": true,
      "snapshotOptions": { "selector": ".form-result" }
    }}
  ],
  "globalExpectation": { "includeSnapshot": false }
}
```

### Tadpole

```kdl
main {
  new_page {
    goto "https://example.com/contact"
    wait_until
    $ "input[name='name']" { type "John Doe" }
    $ "input[name='email']" { type "john@example.com" }
    $ "textarea[name='message']" { type "Hello, I have a question..." }
    $ "button[type='submit']" {
      click delay="=gauss(300, 50)"
    }
    wait_until
    extract "result" {
      confirmation { $ ".form-result" ; text }
    }
  }
}
```

### pw-writer (Complex Forms)

```javascript
await page.goto('https://example.com/apply', { waitUntil: 'domcontentloaded' });
await waitForPageLoad({ page });

await page.getByLabel('Full Name').fill('John Doe');
await page.getByLabel('Email').fill('john@example.com');
await page.getByLabel('Phone').fill('+1-555-123-4567');
await page.getByLabel('Country').selectOption('US');
await page.getByLabel('Birth Date').fill('1990-01-15');
await page.getByLabel('Resume').setInputFiles('/path/to/resume.pdf');
await page.getByLabel('I agree to terms').check();

await page.getByRole('button', { name: 'Submit Application' }).click();
await waitForPageLoad({ page });

const result = await getCleanHTML({ locator: page.locator('.confirmation') });
console.log(result);
```

---

## API Discovery (Network Interception)

### Setup and Capture

```javascript
state.apiCalls = [];

page.on('request', req => {
  const url = req.url();
  if (url.includes('/api/') || url.includes('/graphql')) {
    state.apiCalls.push({
      url,
      method: req.method(),
      headers: req.headers(),
      postData: req.postData()
    });
  }
});

page.on('response', async res => {
  const url = res.url();
  if (url.includes('/api/') || url.includes('/graphql')) {
    const existing = state.apiCalls.find(c => c.url === url);
    if (existing) {
      try {
        existing.status = res.status();
        existing.response = await res.json();
      } catch {
        existing.response = await res.text().catch(() => null);
      }
    }
  }
});

console.log('Network capture started. Now trigger actions...');
```

### Trigger Actions and Analyze

```javascript
await page.click('button.load-data');
await waitForPageLoad({ page, timeout: 5000 });

console.log(`Captured ${state.apiCalls.length} API calls:`);
state.apiCalls.forEach(call => {
  console.log(`${call.method} ${call.url.slice(0, 80)}`);
  if (call.response) {
    console.log(`  Status: ${call.status}`);
    console.log(`  Response: ${JSON.stringify(call.response).slice(0, 200)}...`);
  }
});
```

### Replay API Directly

```javascript
const productApi = state.apiCalls.find(c => c.url.includes('/products'));

const nextPage = await page.evaluate(async ({ url, headers }) => {
  const newUrl = url.replace('page=1', 'page=2');
  const res = await fetch(newUrl, { headers });
  return res.json();
}, { url: productApi.url, headers: productApi.headers });

console.log('Next page data:', JSON.stringify(nextPage).slice(0, 500));
```

### Cleanup

```javascript
page.removeAllListeners('request');
page.removeAllListeners('response');
```

---

## Infinite Scroll Scraping

### pw-writer

```javascript
state.items = [];
state.scrollCount = 0;
const maxScrolls = 10;

const getItems = async () => {
  return page.$$eval('.item', els => els.map(e => e.textContent.trim()));
};

while (state.scrollCount < maxScrolls) {
  const before = (await getItems()).length;

  await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
  await waitForPageLoad({ page, timeout: 3000 });

  const after = (await getItems()).length;
  state.scrollCount++;

  console.log(`Scroll ${state.scrollCount}: ${before} → ${after} items`);

  if (after === before) break;
}

state.items = await getItems();
console.log(`Total: ${state.items.length} items`);
```

---

## Multi-Page Crawl

### pw-writer with Tab Management

```javascript
const links = await page.$$eval('a.product-link', els =>
  els.map(e => e.href).slice(0, 10)
);
state.results = [];

for (const link of links) {
  const newPage = await context.newPage();
  await newPage.goto(link, { waitUntil: 'domcontentloaded' });
  await waitForPageLoad({ page: newPage, timeout: 5000 });

  const data = await newPage.evaluate(() => ({
    title: document.querySelector('h1')?.textContent,
    price: document.querySelector('.price')?.textContent,
    description: document.querySelector('.description')?.textContent?.slice(0, 200)
  }));

  state.results.push({ url: link, ...data });
  await newPage.close();
}

console.log(`Crawled ${state.results.length} pages`);
console.log(JSON.stringify(state.results, null, 2));
```

### Tadpole (Parallel Pages)

```kdl
main {
  new_page {
    goto "https://example.com"
    wait_until
    // Extract links first, then crawl in parallel
    $$ "a.product-link" {
      extract "links[]" {
        url { attr "href" }
      }
    }
  }
  // Tadpole parallel crawl (each page in own tab)
  parallel {
    new_page {
      goto "=links[0].url"
      wait_until
      extract "products[]" {
        title { $ "h1" ; text }
        price { $ ".price" ; text }
        description { $ ".description" ; text }
      }
    }
    new_page {
      goto "=links[1].url"
      wait_until
      extract "products[]" {
        title { $ "h1" ; text }
        price { $ ".price" ; text }
        description { $ ".description" ; text }
      }
    }
  }
}
```
```bash
tadpole run crawl.kdl --auto --headless --output products.json
```

---

## Screenshot Comparison

### Before/After Visual Diff

```javascript
await page.screenshot({ path: '/tmp/before.png', scale: 'css' });

await page.click('button.apply-changes');
await waitForPageLoad({ page });

await page.screenshot({ path: '/tmp/after.png', scale: 'css' });
```

### Element Screenshot

```javascript
const element = page.locator('.product-card').first();
await element.screenshot({ path: '/tmp/product.png' });
```

---

## Authentication Flow

### pw-writer (Reuses Session)

```javascript
const isLoggedIn = await page.$('.user-menu');
if (isLoggedIn) {
  console.log('Already logged in (using existing session)');
} else {
  await page.goto('https://example.com/login');
  await page.getByLabel('Email').fill('user@example.com');
  await page.getByLabel('Password').fill('password123');
  await page.getByRole('button', { name: 'Sign In' }).click();
  await waitForPageLoad({ page });
}

const data = await getCleanHTML({ locator: page.locator('.dashboard') });
console.log(data);
```

### pw-fast (Manual Login)

```json
{
  "steps": [
    { "tool": "browser_navigate", "arguments": { "url": "/login" }},
    { "tool": "browser_type", "arguments": {
      "selectors": [{ "css": "#email" }], "text": "user@example.com"
    }},
    { "tool": "browser_type", "arguments": {
      "selectors": [{ "css": "#password" }], "text": "password123"
    }},
    { "tool": "browser_click", "arguments": {
      "selectors": [{ "role": "button", "text": "Sign In" }]
    }},
    { "tool": "browser_wait_for", "arguments": { "text": "Dashboard" }},
    { "tool": "browser_navigate", "arguments": { "url": "/data" }},
    { "tool": "browser_snapshot", "arguments": {} }
  ],
  "globalExpectation": { "includeSnapshot": false }
}
```

---

## Handling Dynamic Dropdowns

### Autocomplete / Typeahead

```javascript
await page.getByLabel('City').fill('New Y');
await page.waitForSelector('.autocomplete-dropdown');
await page.getByRole('option', { name: 'New York, NY' }).click();

const value = await page.getByLabel('City').inputValue();
console.log('Selected:', value);
```

### Select2 / Custom Dropdowns

```javascript
await page.click('.select2-container');
await page.waitForSelector('.select2-results');
await page.locator('.select2-search input').fill('United States');
await page.waitForSelector('.select2-results__option--highlighted');
await page.click('.select2-results__option--highlighted');
```

---

## Error-Resilient Scraping

### With Retry Logic

```javascript
state.maxRetries = 3;
state.currentRetry = 0;

const scrapeWithRetry = async () => {
  try {
    await page.goto('https://example.com/data', { timeout: 10000 });
    await waitForPageLoad({ page, timeout: 5000 });

    const data = await getCleanHTML({ locator: page.locator('.content') });
    state.currentRetry = 0;
    return data;
  } catch (error) {
    state.currentRetry++;
    console.log(`Attempt ${state.currentRetry} failed: ${error.message}`);

    if (state.currentRetry < state.maxRetries) {
      await page.waitForTimeout(2000);
      return scrapeWithRetry();
    }
    throw error;
  }
};

const result = await scrapeWithRetry();
console.log(result);
```

---

## Data Export

### Tadpole (Built-in JSON Output)

```bash
# Tadpole natively outputs JSON via --output flag
tadpole run scrape.kdl --auto --headless --output /tmp/scraped-data.json

# Or pipe stdout to jq for processing
tadpole run scrape.kdl --auto --headless | jq '.products[] | {name, price}'
```

### Save to JSON

```javascript
const fs = require('node:fs');
const data = state.allItems;
fs.writeFileSync('/tmp/scraped-data.json', JSON.stringify(data, null, 2));
console.log(`Saved ${data.length} items to /tmp/scraped-data.json`);
```

### Save to CSV

```javascript
const fs = require('node:fs');
const headers = Object.keys(state.allItems[0]).join(',');
const rows = state.allItems.map(item =>
  Object.values(item).map(v => `"${String(v).replace(/"/g, '""')}"`).join(',')
);
const csv = [headers, ...rows].join('\n');

fs.writeFileSync('/tmp/scraped-data.csv', csv);
console.log(`Saved ${state.allItems.length} rows to /tmp/scraped-data.csv`);
```
