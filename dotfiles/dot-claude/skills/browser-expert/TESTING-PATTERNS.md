# Playwright Testing Patterns

## Page Object Model (POM)

### Basic Page Object

```typescript
// pages/login-page.ts
import { Page, Locator } from '@playwright/test';

export class LoginPage {
    readonly page: Page;
    readonly emailInput: Locator;
    readonly passwordInput: Locator;
    readonly submitButton: Locator;
    readonly errorMessage: Locator;

    constructor(page: Page) {
        this.page = page;
        this.emailInput = page.getByLabel('Email');
        this.passwordInput = page.getByLabel('Password');
        this.submitButton = page.getByRole('button', { name: 'Sign in' });
        this.errorMessage = page.getByRole('alert');
    }

    async goto() {
        await this.page.goto('/login');
    }

    async login(email: string, password: string) {
        await this.emailInput.fill(email);
        await this.passwordInput.fill(password);
        await this.submitButton.click();
    }
}
```

### POM with Fixtures

```typescript
// fixtures/pages.ts
import { test as base } from '@playwright/test';
import { LoginPage } from '../pages/login-page';
import { DashboardPage } from '../pages/dashboard-page';

type Pages = {
    loginPage: LoginPage;
    dashboardPage: DashboardPage;
};

export const test = base.extend<Pages>({
    loginPage: async ({ page }, use) => {
        const loginPage = new LoginPage(page);
        await use(loginPage);
    },
    dashboardPage: async ({ page }, use) => {
        const dashboardPage = new DashboardPage(page);
        await use(dashboardPage);
    },
});

export { expect } from '@playwright/test';
```

### Usage

```typescript
import { test, expect } from '../fixtures/pages';

test('successful login', async ({ loginPage, dashboardPage }) => {
    await loginPage.goto();
    await loginPage.login('user@example.com', 'password');
    await expect(dashboardPage.welcomeMessage).toBeVisible();
});
```

---

## Authentication Patterns

### Storage State (Session Reuse)

```typescript
// playwright.config.ts
export default defineConfig({
    projects: [
        // Setup project — runs first, saves auth state
        { name: 'setup', testMatch: /.*\.setup\.ts/ },

        // Main tests — depend on setup
        {
            name: 'chromium',
            use: {
                ...devices['Desktop Chrome'],
                storageState: '.auth/user.json',
            },
            dependencies: ['setup'],
        },
    ],
});
```

```typescript
// tests/auth.setup.ts
import { test as setup, expect } from '@playwright/test';

const authFile = '.auth/user.json';

setup('authenticate', async ({ page }) => {
    await page.goto('/login');
    await page.getByLabel('Email').fill('user@example.com');
    await page.getByLabel('Password').fill('password');
    await page.getByRole('button', { name: 'Sign in' }).click();

    await expect(page.getByText('Welcome')).toBeVisible();

    await page.context().storageState({ path: authFile });
});
```

### Multiple Users

```typescript
export default defineConfig({
    projects: [
        { name: 'setup-admin', testMatch: /admin\.setup\.ts/ },
        { name: 'setup-user', testMatch: /user\.setup\.ts/ },

        {
            name: 'admin-tests',
            use: { storageState: '.auth/admin.json' },
            dependencies: ['setup-admin'],
        },
        {
            name: 'user-tests',
            use: { storageState: '.auth/user.json' },
            dependencies: ['setup-user'],
        },
    ],
});
```

### API Login (Faster)

```typescript
setup('authenticate via API', async ({ request }) => {
    const response = await request.post('/api/login', {
        data: { email: 'user@example.com', password: 'password' }
    });

    expect(response.ok()).toBeTruthy();

    const { token } = await response.json();
    await fs.writeFile('.auth/token.txt', token);
});
```

---

## API Mocking

### Basic Mocking

```typescript
test('mock API response', async ({ page }) => {
    await page.route('**/api/users', route =>
        route.fulfill({
            status: 200,
            json: [
                { id: 1, name: 'Alice' },
                { id: 2, name: 'Bob' },
            ],
        })
    );

    await page.goto('/users');
    await expect(page.getByRole('listitem')).toHaveCount(2);
});
```

### Mock from File

```typescript
test('mock from fixture', async ({ page }) => {
    await page.route('**/api/products', route =>
        route.fulfill({ path: './fixtures/products.json' })
    );
});
```

### Modify Response

```typescript
test('modify response', async ({ page }) => {
    await page.route('**/api/user', async route => {
        const response = await route.fetch();
        const json = await response.json();
        json.name = 'Modified Name';
        await route.fulfill({ json });
    });
});
```

### Error Simulation

```typescript
test('handle API error', async ({ page }) => {
    await page.route('**/api/data', route =>
        route.fulfill({
            status: 500,
            json: { error: 'Internal Server Error' },
        })
    );

    await page.goto('/dashboard');
    await expect(page.getByText('Something went wrong')).toBeVisible();
});
```

### Abort Requests

```typescript
test('block analytics', async ({ page }) => {
    await page.route('**/*google-analytics*/**', route => route.abort());
    await page.route('**/*.{png,jpg,jpeg}', route => route.abort());
});
```

### Wait for Response

```typescript
test('wait for API', async ({ page }) => {
    const responsePromise = page.waitForResponse('**/api/users');
    await page.getByRole('button', { name: 'Load' }).click();
    const response = await responsePromise;

    expect(response.status()).toBe(200);
    const data = await response.json();
    expect(data.users).toHaveLength(5);
});
```

---

## Visual Testing

### Screenshot Comparison

```typescript
test('visual regression', async ({ page }) => {
    await page.goto('/dashboard');
    await expect(page).toHaveScreenshot('dashboard.png');
});

test('element screenshot', async ({ page }) => {
    await page.goto('/dashboard');
    await expect(page.locator('.chart')).toHaveScreenshot('chart.png');
});
```

### Configuration

```typescript
// playwright.config.ts
export default defineConfig({
    expect: {
        toHaveScreenshot: {
            maxDiffPixels: 100,
            threshold: 0.2,
        },
    },
});
```

### Update Snapshots

```bash
npx playwright test --update-snapshots
```

### Full Page & Masked Screenshots

```typescript
test('full page', async ({ page }) => {
    await page.goto('/long-page');
    await expect(page).toHaveScreenshot('full-page.png', { fullPage: true });
});

test('masked screenshot', async ({ page }) => {
    await page.goto('/dashboard');
    await expect(page).toHaveScreenshot('dashboard.png', {
        mask: [
            page.locator('.timestamp'),
            page.locator('.random-ad'),
        ],
    });
});
```

---

## Accessibility Testing

### Built-in Assertions

```typescript
test('accessibility attributes', async ({ page }) => {
    await page.goto('/form');

    await expect(page.locator('#submit')).toHaveRole('button');
    await expect(page.locator('#email')).toHaveAccessibleName('Email address');
    await expect(page.locator('#password'))
        .toHaveAccessibleDescription('Must be at least 8 characters');
});
```

### Axe Integration

```typescript
// Install: npm install @axe-core/playwright
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test('accessibility scan', async ({ page }) => {
    await page.goto('/');
    const results = await new AxeBuilder({ page }).analyze();
    expect(results.violations).toEqual([]);
});

test('scan specific area', async ({ page }) => {
    await page.goto('/');
    const results = await new AxeBuilder({ page })
        .include('.main-content')
        .exclude('.third-party-widget')
        .withTags(['wcag2a', 'wcag2aa'])
        .analyze();

    expect(results.violations).toEqual([]);
});
```

---

## Mobile Testing

### Device Emulation

```typescript
// playwright.config.ts
import { devices } from '@playwright/test';

export default defineConfig({
    projects: [
        { name: 'Desktop Chrome', use: { ...devices['Desktop Chrome'] } },
        { name: 'Mobile Chrome', use: { ...devices['Pixel 5'] } },
        { name: 'Mobile Safari', use: { ...devices['iPhone 12'] } },
        { name: 'Tablet', use: { ...devices['iPad Pro 11'] } },
    ],
});
```

### Custom Viewport & Touch

```typescript
test('custom mobile', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/');
});

test('swipe gesture', async ({ page }) => {
    await page.goto('/carousel');
    await page.locator('.carousel').dragTo(page.locator('.carousel'), {
        sourcePosition: { x: 300, y: 100 },
        targetPosition: { x: 50, y: 100 },
    });
});
```

### Geolocation

```typescript
test('location-based', async ({ context }) => {
    await context.setGeolocation({ latitude: 37.7749, longitude: -122.4194 });
    const page = await context.newPage();
    await page.goto('/stores');
    await expect(page.getByText('San Francisco')).toBeVisible();
});
```

---

## Parallel Execution & Sharding

### Configuration

```typescript
export default defineConfig({
    fullyParallel: true,
    workers: process.env.CI ? 2 : undefined,
});
```

### Serial Tests

```typescript
test.describe.configure({ mode: 'serial' });

test.describe('ordered tests', () => {
    test('step 1', async ({ page }) => {});
    test('step 2', async ({ page }) => {});
});
```

### Sharding (CI)

```bash
npx playwright test --shard=1/3  # Machine 1
npx playwright test --shard=2/3  # Machine 2
npx playwright test --shard=3/3  # Machine 3
```

---

## Network Handling

### Request Interception

```typescript
test('log requests', async ({ page }) => {
    page.on('request', request => {
        console.log('>>', request.method(), request.url());
    });
    page.on('response', response => {
        console.log('<<', response.status(), response.url());
    });
    await page.goto('/');
});
```

### Modify Headers

```typescript
test('add auth header', async ({ page }) => {
    await page.route('**/api/**', route => {
        route.continue({
            headers: {
                ...route.request().headers(),
                'Authorization': 'Bearer token123',
            },
        });
    });
});
```

### Offline Mode

```typescript
test('offline behavior', async ({ context }) => {
    const page = await context.newPage();
    await page.goto('/');

    await context.setOffline(true);
    await page.getByRole('button', { name: 'Save' }).click();
    await expect(page.getByText('You are offline')).toBeVisible();

    await context.setOffline(false);
});
```

---

## File Uploads & Downloads

### Upload

```typescript
test('file upload', async ({ page }) => {
    await page.goto('/upload');

    // Single file
    await page.locator('input[type="file"]').setInputFiles('path/to/file.pdf');

    // Multiple files
    await page.locator('input[type="file"]').setInputFiles(['file1.pdf', 'file2.pdf']);

    // Clear
    await page.locator('input[type="file"]').setInputFiles([]);
});

// Drag and drop upload
test('drag upload', async ({ page }) => {
    await page.goto('/upload');
    const dataTransfer = await page.evaluateHandle(() => new DataTransfer());
    await page.dispatchEvent('.dropzone', 'drop', { dataTransfer });
});
```

### Download

```typescript
test('file download', async ({ page }) => {
    const downloadPromise = page.waitForEvent('download');
    await page.getByRole('link', { name: 'Download' }).click();
    const download = await downloadPromise;

    await download.saveAs('./downloads/' + download.suggestedFilename());
    const path = await download.path();
});
```

---

## iframes & Shadow DOM

### iframes

```typescript
test('iframe interaction', async ({ page }) => {
    await page.goto('/page-with-iframe');

    const frame = page.frameLocator('#my-iframe');
    await frame.getByRole('button', { name: 'Submit' }).click();
    await expect(frame.getByText('Success')).toBeVisible();
});

// Nested iframes
test('nested frames', async ({ page }) => {
    const outer = page.frameLocator('#outer');
    const inner = outer.frameLocator('#inner');
    await inner.getByRole('button').click();
});
```

### Shadow DOM

```typescript
test('shadow DOM', async ({ page }) => {
    await page.goto('/web-components');

    // Locators pierce shadow DOM by default
    await page.getByRole('button', { name: 'Shadow Button' }).click();

    // Or be explicit
    await page.locator('my-component').locator('button').click();
});
```

---

## Debugging

### Debug Mode

```bash
npx playwright test --debug
```

### Pause in Test

```typescript
test('debug test', async ({ page }) => {
    await page.goto('/');
    await page.pause();  // Opens inspector
    await page.getByRole('button').click();
});
```

### Trace Viewer

```typescript
// playwright.config.ts
export default defineConfig({
    use: {
        trace: 'on-first-retry',  // or 'on', 'retain-on-failure'
    },
});
```

```bash
npx playwright show-trace trace.zip
```

### Console Logs

```typescript
test('capture logs', async ({ page }) => {
    page.on('console', msg => console.log('PAGE:', msg.text()));
    page.on('pageerror', err => console.log('ERROR:', err.message));
    await page.goto('/');
});
```
