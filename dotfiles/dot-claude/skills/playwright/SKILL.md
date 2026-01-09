---
name: playwright
description: Write Playwright tests, migrate from Cypress, and answer Playwright questions. Use when working with e2e tests, browser automation, Playwright, or migrating from Cypress.
user-invocable: false
---

# Playwright Testing Skill

## Quick Start

```typescript
import { test, expect } from '@playwright/test';

test('example test', async ({ page }) => {
    await page.goto('https://example.com');
    await expect(page).toHaveTitle(/Example/);
    await page.getByRole('button', { name: 'Submit' }).click();
    await expect(page.getByText('Success')).toBeVisible();
});
```

## Project Setup

```bash
# Initialize new project
npm init playwright@latest

# Install in existing project
npm install -D @playwright/test
npx playwright install
```

## Core Concepts

### Locators (Prefer User-Facing)
```typescript
page.getByRole('button', { name: 'Submit' })  // Best: accessibility
page.getByText('Welcome')                      // By visible text
page.getByLabel('Email')                       // Form fields
page.getByTestId('submit-btn')                 // data-testid fallback
page.locator('css-selector')                   // Last resort
```

### Assertions (Auto-Retry)
```typescript
await expect(locator).toBeVisible();
await expect(locator).toHaveText('Hello');
await expect(page).toHaveURL(/dashboard/);
```

### Test Structure
```typescript
test.describe('Feature', () => {
    test.beforeEach(async ({ page }) => {
        await page.goto('/');
    });

    test('scenario', async ({ page }) => {
        // test code
    });
});
```

## Reference Files

| File | Use When |
|------|----------|
| [REFERENCE.md](REFERENCE.md) | Need API details for locators, assertions, config |
| [CYPRESS-MIGRATION.md](CYPRESS-MIGRATION.md) | Converting Cypress tests to Playwright |
| [PATTERNS.md](PATTERNS.md) | Implementing POM, auth, mocking, visual tests |

## Common Commands

```bash
npx playwright test                    # Run all tests
npx playwright test --headed           # Run with browser visible
npx playwright test --ui               # Interactive UI mode
npx playwright test --debug            # Debug mode with inspector
npx playwright test -g "login"         # Run tests matching pattern
npx playwright codegen example.com     # Generate tests by recording
npx playwright show-report             # View HTML report
```

## Best Practices

1. **Use role-based locators** - Most resilient to DOM changes
2. **Avoid CSS/XPath** - Brittle, break with refactoring
3. **Use auto-waiting assertions** - `expect(locator).toBeVisible()` retries
4. **Isolate tests** - Each test starts fresh, no shared state
5. **Mock external APIs** - Use `page.route()` for reliability
