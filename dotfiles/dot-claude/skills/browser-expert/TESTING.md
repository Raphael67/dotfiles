# Playwright Testing Reference

## Project Setup

```bash
# Initialize new project
npm init playwright@latest

# Install in existing project
npm install -D @playwright/test
npx playwright install
```

## TypeScript Configuration

```json
// tsconfig.json — Enables type safety, path aliases, and modern JS features
{
    "compilerOptions": {
        "target": "ESNext",
        "module": "CommonJS",
        "moduleResolution": "Node",
        "types": ["@playwright/test"],
        "esModuleInterop": true,
        "strict": true,
        "skipLibCheck": true,
        "baseUrl": ".",
        "paths": {
            "@pages/*": ["src/pageObject/pages/*"],
            "@tests/*": ["src/tests/*"]
        }
    },
    "include": ["src/**/*.ts", "tests/**/*.ts", "playwright.config.ts"]
}
```

## Core Concepts

### Quick Start

```typescript
import { test, expect } from '@playwright/test';

test('example test', async ({ page }) => {
    await page.goto('https://example.com');
    await expect(page).toHaveTitle(/Example/);
    await page.getByRole('button', { name: 'Submit' }).click();
    await expect(page.getByText('Success')).toBeVisible();
});
```

## Locators

### Recommended Locators (Priority Order)

```typescript
// 1. By Role (best - reflects accessibility tree)
page.getByRole('button', { name: 'Submit' })
page.getByRole('heading', { name: 'Welcome', level: 1 })
page.getByRole('link', { name: /learn more/i })
page.getByRole('textbox', { name: 'Email' })
page.getByRole('checkbox', { name: 'Accept terms' })

// 2. By Label (form controls)
page.getByLabel('Username')
page.getByLabel('Password')

// 3. By Placeholder
page.getByPlaceholder('Enter email')

// 4. By Text
page.getByText('Welcome back')
page.getByText(/welcome/i)  // regex, case-insensitive

// 5. By Alt Text (images)
page.getByAltText('Company logo')

// 6. By Title
page.getByTitle('Close dialog')

// 7. By Test ID (fallback)
page.getByTestId('submit-button')

// 8. CSS/XPath (last resort)
page.locator('.submit-btn')
page.locator('xpath=//button[@type="submit"]')
```

### Locator Chaining & Filtering

```typescript
// Chain to narrow scope
page.getByRole('list').getByRole('listitem')
page.locator('article').getByRole('button')

// Filter by text
page.getByRole('listitem').filter({ hasText: 'Product 2' })
page.getByRole('listitem').filter({ hasNotText: 'Out of stock' })

// Filter by child element
page.getByRole('listitem').filter({
    has: page.getByRole('heading', { name: 'Product' })
})

// Combine with .and() / .or()
const button = page.getByRole('button').and(page.getByText('Submit'))
const saveBtn = page.getByRole('button', { name: 'Save' })
    .or(page.getByRole('button', { name: 'Update' }))

// Select from multiple matches
locator.first()
locator.last()
locator.nth(2)  // 0-indexed
```

### Locator Actions

```typescript
await locator.click()
await locator.dblclick()
await locator.fill('text')           // Clear + type (inputs)
await locator.type('text')           // Type character by character
await locator.press('Enter')
await locator.check()                // Checkbox
await locator.uncheck()
await locator.selectOption('value')  // Dropdown
await locator.hover()
await locator.focus()
await locator.blur()
await locator.clear()
await locator.setInputFiles('file.pdf')  // File upload
```

## Assertions

### Auto-Retrying (Async) - Preferred

```typescript
// Visibility
await expect(locator).toBeVisible()
await expect(locator).toBeHidden()
await expect(locator).toBeAttached()

// State
await expect(locator).toBeEnabled()
await expect(locator).toBeDisabled()
await expect(locator).toBeEditable()
await expect(locator).toBeChecked()
await expect(locator).toBeFocused()

// Content
await expect(locator).toHaveText('Hello')
await expect(locator).toHaveText(/hello/i)
await expect(locator).toContainText('Hello')
await expect(locator).toHaveValue('input value')
await expect(locator).toHaveAttribute('href', '/home')
await expect(locator).toHaveClass(/active/)
await expect(locator).toHaveCSS('color', 'rgb(0, 0, 0)')
await expect(locator).toHaveCount(5)

// Page
await expect(page).toHaveTitle('Dashboard')
await expect(page).toHaveURL(/dashboard/)
await expect(page).toHaveScreenshot()

// Accessibility
await expect(locator).toHaveRole('button')
await expect(locator).toHaveAccessibleName('Submit form')

// Negation
await expect(locator).not.toBeVisible()
```

### Non-Retrying (Sync)

```typescript
// Use for values already retrieved
const text = await locator.textContent()
expect(text).toBe('Hello')
expect(text).toContain('ell')
expect(text).toMatch(/hello/i)

// Numbers
expect(count).toBe(5)
expect(count).toBeGreaterThan(3)
expect(count).toBeLessThanOrEqual(10)

// Truthiness
expect(value).toBeTruthy()
expect(value).toBeFalsy()
expect(value).toBeDefined()
expect(value).toBeNull()
```

### Soft Assertions

```typescript
// Don't stop test on failure
await expect.soft(locator).toHaveText('Expected')
await expect.soft(page).toHaveTitle('Title')
// Test continues even if above fails
```

## Test Structure

### Basic Test

```typescript
import { test, expect } from '@playwright/test';

test('has title', async ({ page }) => {
    await page.goto('https://example.com');
    await expect(page).toHaveTitle(/Example/);
});
```

### Test Groups

```typescript
test.describe('Feature', () => {
    test('scenario 1', async ({ page }) => {});
    test('scenario 2', async ({ page }) => {});
});

// Serial execution (tests depend on each other)
test.describe.serial('Sequential', () => {
    test('step 1', async ({ page }) => {});
    test('step 2', async ({ page }) => {});
});

// Parallel (default)
test.describe.parallel('Parallel', () => {});

// Configure mode
test.describe.configure({ mode: 'serial' });
```

### Hooks

```typescript
test.beforeAll(async () => {
    // Once before all tests in file/describe
});

test.beforeEach(async ({ page }) => {
    // Before each test
    await page.goto('/');
});

test.afterEach(async ({ page }) => {
    // After each test
});

test.afterAll(async () => {
    // Once after all tests
});
```

### Test Modifiers

```typescript
test.only('focused test', async () => {});     // Run only this
test.skip('skipped test', async () => {});     // Skip always
test.fixme('broken test', async () => {});     // Skip, marks as fixme
test.slow('slow test', async () => {});        // 3x timeout

// Conditional
test.skip(browserName === 'webkit', 'Safari issue');
test.fail(process.env.CI, 'Known CI issue');
```

### Test Steps

```typescript
test('checkout flow', async ({ page }) => {
    await test.step('Add to cart', async () => {
        await page.getByRole('button', { name: 'Add' }).click();
    });

    await test.step('Proceed to checkout', async () => {
        await page.getByRole('link', { name: 'Checkout' }).click();
    });
});
```

## Fixtures

### Built-in Fixtures

```typescript
test('example', async ({
    page,       // Isolated page instance
    context,    // Browser context
    browser,    // Browser instance
    request,    // API request context
}) => {});
```

### Custom Fixtures

```typescript
// fixtures.ts
import { test as base } from '@playwright/test';
import { TodoPage } from './pages/todo-page';

export const test = base.extend<{ todoPage: TodoPage }>({
    todoPage: async ({ page }, use) => {
        const todoPage = new TodoPage(page);
        await todoPage.goto();
        await use(todoPage);
        // Cleanup after test
    },
});

// Usage
test('add todo', async ({ todoPage }) => {
    await todoPage.addTodo('Buy milk');
});
```

## Configuration (playwright.config.ts)

```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
    testDir: './tests',
    fullyParallel: true,
    forbidOnly: !!process.env.CI,
    retries: process.env.CI ? 2 : 0,
    workers: process.env.CI ? 1 : undefined,
    reporter: 'html',

    use: {
        baseURL: 'http://localhost:3000',
        trace: 'on-first-retry',
        screenshot: 'only-on-failure',
        video: 'retain-on-failure',
    },

    projects: [
        { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
        { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
        { name: 'webkit', use: { ...devices['Desktop Safari'] } },
        { name: 'Mobile Chrome', use: { ...devices['Pixel 5'] } },
        { name: 'Mobile Safari', use: { ...devices['iPhone 12'] } },
    ],

    webServer: {
        command: 'npm run start',
        url: 'http://localhost:3000',
        reuseExistingServer: !process.env.CI,
    },
});
```

## CLI Commands

```bash
# Run tests
npx playwright test                      # All tests
npx playwright test tests/login.spec.ts  # Specific file
npx playwright test -g "login"           # Match title
npx playwright test --grep "@smoke"      # Run tagged tests
npx playwright test --project=chromium   # Specific browser

# Debug
npx playwright test --headed             # See browser
npx playwright test --debug              # Inspector: step through, inspect DOM
npx playwright test --ui                 # Interactive UI with visual runner

# Utilities
npx playwright codegen example.com       # Record test
npx playwright show-report               # View report
npx playwright show-trace trace.zip      # View trace

# Install
npx playwright install                   # All browsers
npx playwright install chromium          # Specific browser
```

## Navigation & Waiting

```typescript
// Navigation
await page.goto('https://example.com')
await page.goto('/path', { waitUntil: 'networkidle' })
await page.goBack()
await page.goForward()
await page.reload()

// Wait for
await page.waitForURL(/dashboard/)
await page.waitForLoadState('networkidle')
await page.waitForSelector('.loaded')
await page.waitForResponse(/api\/users/)
await page.waitForTimeout(1000)  // Avoid in tests
```

## Keyboard & Mouse

```typescript
// Keyboard
await page.keyboard.press('Enter')
await page.keyboard.press('Control+A')
await page.keyboard.type('Hello')

// Mouse
await page.mouse.click(100, 200)
await page.mouse.dblclick(100, 200)
await page.mouse.move(100, 200)
await page.mouse.down()
await page.mouse.up()
```

## Debugging

### Interactive Debug Mode (Playwright Inspector)

```bash
npx playwright test --debug
```

Launches the **Playwright Inspector** — pauses at each step for interactive control over browser state, DOM elements, and network activity. Step through flaky or failing tests to diagnose timing or selector issues.

### Trace Viewer

Enable tracing in `playwright.config.ts`:

```typescript
use: {
    trace: 'retain-on-failure',  // or 'on-first-retry'
}
```

When a test fails, open the trace file:

```bash
npx playwright show-trace trace.zip
```

Displays a detailed timeline of actions, DOM snapshots, network requests, and screenshots.

### Screenshots & Video

```typescript
use: {
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
}
```

Artifacts are saved per-test and attached to reports — diagnose UI regressions without rerunning.

### Console Log Capture

```typescript
page.on('console', msg => console.log(msg.text()));
```

Captures browser console warnings and errors that may not cause test failures but affect stability.

### VS Code Integration

The official **Playwright VS Code extension** provides:
- Tests in the Test Explorer panel, grouped by file and project
- Run/debug a single test, file, or suite with one click
- Breakpoints in TypeScript files to inspect application state
- Live logs, step-by-step execution, and screenshots in the debug console

## Reporting & Analysis

### HTML Report

```typescript
// playwright.config.ts
reporter: [['html', { outputFolder: 'playwright-report' }]],
```

```bash
npx playwright show-report           # Open HTML report
```

Includes pass/fail counts, execution time, stack traces, console logs, screenshots, videos, and trace links.

### Allure Reporter

```bash
npm install -D allure-playwright
```

```typescript
// playwright.config.ts
reporter: [['allure-playwright']],
```

```bash
npx allure serve allure-results      # Generate and open Allure report
```

Integrates in CI/CD pipelines for trend analysis and flaky test detection.

### Retry Logic

```typescript
// playwright.config.ts
retries: process.env.CI ? 2 : 0,
```

Reports track retry attempts, helping identify unstable tests that need fixes.

## Best Practices

1. **Use role-based locators** — Most resilient to DOM changes
2. **Avoid CSS/XPath** — Brittle, break with refactoring
3. **Use auto-waiting assertions** — `expect(locator).toBeVisible()` retries
4. **Isolate tests** — Each test starts fresh, no shared state
5. **Mock external APIs** — Use `page.route()` for reliability
6. **Headed for local dev, headless for CI** — Toggle with `--headed` flag or config
7. **Enable traces on failure** — `trace: 'retain-on-failure'` for post-mortem debugging
8. **Tag tests with grep markers** — `test('@smoke: login', ...)` then `--grep "@smoke"`
