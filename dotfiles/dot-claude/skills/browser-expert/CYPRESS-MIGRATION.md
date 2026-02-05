# Cypress to Playwright Migration Guide

## Key Differences

| Aspect | Cypress | Playwright |
|--------|---------|------------|
| Execution | Runs in browser | Runs in Node.js |
| Async model | Automatic chaining | Explicit async/await |
| Assertions | Implicit retry | Explicit `expect()` |
| Multi-tab | Not supported | Full support |
| iframes | Limited | Full support |
| Browsers | Chromium, Firefox, Electron | Chromium, Firefox, WebKit |

## Command Mapping

### Navigation

```typescript
// Cypress
cy.visit('https://example.com')
cy.visit('/path')
cy.reload()
cy.go('back')

// Playwright
await page.goto('https://example.com')
await page.goto('/path')
await page.reload()
await page.goBack()
```

### Selectors / Locators

```typescript
// Cypress
cy.get('.class')
cy.get('#id')
cy.get('[data-testid="submit"]')
cy.get('button').contains('Submit')
cy.contains('Welcome')
cy.get('input[name="email"]')

// Playwright
page.locator('.class')
page.locator('#id')
page.getByTestId('submit')
page.getByRole('button', { name: 'Submit' })
page.getByText('Welcome')
page.locator('input[name="email"]')
// Or better:
page.getByLabel('Email')
page.getByPlaceholder('Enter email')
```

### Finding Within Elements

```typescript
// Cypress
cy.get('.parent').find('.child')
cy.get('.parent').within(() => {
    cy.get('.child')
})

// Playwright
page.locator('.parent').locator('.child')
page.locator('.parent .child')
// Or with roles:
page.getByRole('article').getByRole('button')
```

### Actions

```typescript
// Cypress
cy.get('input').type('hello')
cy.get('input').clear()
cy.get('input').type('hello', { delay: 100 })
cy.get('button').click()
cy.get('button').dblclick()
cy.get('button').rightclick()
cy.get('input').focus()
cy.get('input').blur()
cy.get('checkbox').check()
cy.get('checkbox').uncheck()
cy.get('select').select('option1')

// Playwright
await page.locator('input').fill('hello')
await page.locator('input').clear()
await page.locator('input').type('hello', { delay: 100 })
await page.locator('button').click()
await page.locator('button').dblclick()
await page.locator('button').click({ button: 'right' })
await page.locator('input').focus()
await page.locator('input').blur()
await page.locator('checkbox').check()
await page.locator('checkbox').uncheck()
await page.locator('select').selectOption('option1')
```

### Assertions

```typescript
// Cypress
cy.get('.item').should('be.visible')
cy.get('.item').should('not.be.visible')
cy.get('.item').should('exist')
cy.get('.item').should('not.exist')
cy.get('.item').should('have.text', 'Hello')
cy.get('.item').should('contain', 'Hello')
cy.get('.item').should('have.value', 'test')
cy.get('.item').should('have.attr', 'href', '/home')
cy.get('.item').should('have.class', 'active')
cy.get('.item').should('be.disabled')
cy.get('.item').should('be.enabled')
cy.get('.item').should('be.checked')
cy.get('.items').should('have.length', 5)
cy.url().should('include', '/dashboard')
cy.title().should('eq', 'Dashboard')

// Playwright
await expect(page.locator('.item')).toBeVisible()
await expect(page.locator('.item')).toBeHidden()
await expect(page.locator('.item')).toBeAttached()
await expect(page.locator('.item')).not.toBeAttached()
await expect(page.locator('.item')).toHaveText('Hello')
await expect(page.locator('.item')).toContainText('Hello')
await expect(page.locator('.item')).toHaveValue('test')
await expect(page.locator('.item')).toHaveAttribute('href', '/home')
await expect(page.locator('.item')).toHaveClass(/active/)
await expect(page.locator('.item')).toBeDisabled()
await expect(page.locator('.item')).toBeEnabled()
await expect(page.locator('.item')).toBeChecked()
await expect(page.locator('.items')).toHaveCount(5)
await expect(page).toHaveURL(/dashboard/)
await expect(page).toHaveTitle('Dashboard')
```

### Waiting

```typescript
// Cypress
cy.wait(1000)
cy.wait('@apiCall')
cy.get('.item', { timeout: 10000 })

// Playwright
await page.waitForTimeout(1000)  // Avoid in tests
await page.waitForResponse(/api\/call/)
await expect(page.locator('.item')).toBeVisible({ timeout: 10000 })
```

### Network Interception

```typescript
// Cypress
cy.intercept('GET', '/api/users', { fixture: 'users.json' }).as('getUsers')
cy.intercept('POST', '/api/login', { statusCode: 200, body: { token: 'abc' } })
cy.intercept('GET', '/api/users', (req) => {
    req.reply({ users: [] })
})
cy.wait('@getUsers')

// Playwright
await page.route('**/api/users', route =>
    route.fulfill({ path: './fixtures/users.json' })
)
await page.route('**/api/login', route =>
    route.fulfill({ status: 200, json: { token: 'abc' } })
)
await page.route('**/api/users', route => {
    route.fulfill({ json: { users: [] } })
})
const response = await page.waitForResponse('**/api/users')
```

### Fixtures / Test Data

```typescript
// Cypress
cy.fixture('users.json').then((users) => {
    // use users
})
cy.intercept('GET', '/api/users', { fixture: 'users.json' })

// Playwright
import users from './fixtures/users.json'
// Direct import, no special API needed

await page.route('**/api/users', route =>
    route.fulfill({ path: './fixtures/users.json' })
)
```

### File Uploads

```typescript
// Cypress
cy.get('input[type="file"]').selectFile('path/to/file.pdf')
cy.get('input[type="file"]').selectFile(['file1.pdf', 'file2.pdf'])

// Playwright
await page.locator('input[type="file"]').setInputFiles('path/to/file.pdf')
await page.locator('input[type="file"]').setInputFiles(['file1.pdf', 'file2.pdf'])
await page.locator('input[type="file"]').setInputFiles([])  // Clear
```

### Screenshots

```typescript
// Cypress
cy.screenshot()
cy.screenshot('filename')
cy.get('.element').screenshot()

// Playwright
await page.screenshot({ path: 'screenshot.png' })
await page.locator('.element').screenshot({ path: 'element.png' })
await expect(page).toHaveScreenshot('filename.png')  // Visual comparison
```

### Test Structure

```typescript
// Cypress (cypress/e2e/login.cy.ts)
describe('Login', () => {
    beforeEach(() => {
        cy.visit('/login')
    })

    it('should login successfully', () => {
        cy.get('[data-testid="email"]').type('user@example.com')
        cy.get('[data-testid="password"]').type('password')
        cy.get('[data-testid="submit"]').click()
        cy.url().should('include', '/dashboard')
    })
})

// Playwright (tests/login.spec.ts)
import { test, expect } from '@playwright/test';

test.describe('Login', () => {
    test.beforeEach(async ({ page }) => {
        await page.goto('/login')
    })

    test('should login successfully', async ({ page }) => {
        await page.getByTestId('email').fill('user@example.com')
        await page.getByTestId('password').fill('password')
        await page.getByTestId('submit').click()
        await expect(page).toHaveURL(/dashboard/)
    })
})
```

### Custom Commands → Fixtures/Helpers

```typescript
// Cypress (support/commands.ts)
Cypress.Commands.add('login', (email, password) => {
    cy.visit('/login')
    cy.get('[data-testid="email"]').type(email)
    cy.get('[data-testid="password"]').type(password)
    cy.get('[data-testid="submit"]').click()
})

// Usage
cy.login('user@example.com', 'password')

// Playwright (fixtures/auth.ts)
import { test as base, Page } from '@playwright/test';

async function login(page: Page, email: string, password: string) {
    await page.goto('/login')
    await page.getByTestId('email').fill(email)
    await page.getByTestId('password').fill(password)
    await page.getByTestId('submit').click()
}

export const test = base.extend({
    authenticatedPage: async ({ page }, use) => {
        await login(page, 'user@example.com', 'password')
        await use(page)
    },
})

// Usage
test('dashboard', async ({ authenticatedPage }) => {
    await expect(authenticatedPage).toHaveURL(/dashboard/)
})
```

## Migration Steps

### 1. Project Setup

```bash
# Install Playwright
npm init playwright@latest

# Keep Cypress temporarily for parallel running
# Don't remove until migration complete
```

### 2. File Structure

```
# Cypress
cypress/
  e2e/
    login.cy.ts
  fixtures/
    users.json
  support/
    commands.ts

# Playwright
tests/
  login.spec.ts
fixtures/
  users.json
playwright.config.ts
```

### 3. Configuration

```typescript
// cypress.config.ts → playwright.config.ts
// baseUrl → use.baseURL
// defaultCommandTimeout → use.actionTimeout
// viewportWidth/Height → use.viewport
```

### 4. Convert Test by Test

1. Start with simple tests (no custom commands)
2. Convert assertions: `should()` → `expect().to*()`
3. Add `async/await` everywhere
4. Replace selectors with role-based locators
5. Convert intercepts to `page.route()`

### 5. Migrate Custom Commands

1. Identify all custom commands
2. Convert to helper functions or fixtures
3. Update test files to use new helpers

## Common Pitfalls

### Missing await

```typescript
// WRONG - will not wait
page.locator('button').click()
expect(page.locator('.result')).toBeVisible()

// CORRECT
await page.locator('button').click()
await expect(page.locator('.result')).toBeVisible()
```

### Cypress-style Chaining

```typescript
// WRONG - Playwright doesn't chain like Cypress
await page.locator('button').click().locator('.result')

// CORRECT
await page.locator('button').click()
await page.locator('.result')
```

### Implicit Waits

```typescript
// Cypress waits automatically
cy.get('.item').should('be.visible')  // Retries until visible

// Playwright - use expect for auto-retry
await expect(page.locator('.item')).toBeVisible()  // Retries

// NOT this (no retry)
const isVisible = await page.locator('.item').isVisible()
expect(isVisible).toBe(true)
```

### Environment Variables

```typescript
// Cypress
Cypress.env('API_URL')

// Playwright
process.env.API_URL
// Or in config:
use: { baseURL: process.env.API_URL }
```

## Tools

- **Official Converter**: https://demo.playwright.dev/cy2pw/
- **Ray's Converter**: https://ray.run/tools/cypress-to-playwright
- **cypress-to-playwright**: https://github.com/11joselu/cypress-to-playwright
