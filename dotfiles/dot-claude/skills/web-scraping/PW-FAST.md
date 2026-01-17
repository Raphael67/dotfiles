# pw-fast (fast-playwright-mcp) Reference

Headless Chromium MCP optimized for batch execution and token efficiency.

## Architecture

- **Browser**: Headless Chromium (auto-launched)
- **Tools**: 30+ specialized tools (not a single execute tool)
- **Optimization**: `expectation` parameter controls response size
- **Batch**: `browser_batch_execute` for combining operations

## Tool Categories

### Core Automation
- `browser_navigate` - Navigate to URLs
- `browser_click` - Click elements
- `browser_type` - Type text into inputs
- `browser_hover` - Hover over elements
- `browser_press_key` - Press keyboard keys
- `browser_select_option` - Select dropdown options
- `browser_drag` - Drag and drop
- `browser_file_upload` - Upload files
- `browser_handle_dialog` - Handle alerts/confirms/prompts
- `browser_wait_for` - Wait for text/conditions

### Inspection
- `browser_snapshot` - Accessibility snapshot
- `browser_take_screenshot` - Screenshots with compression
- `browser_find_elements` - Discover elements by criteria
- `browser_inspect_html` - Extract HTML with depth control
- `browser_diagnose` - Page complexity analysis
- `browser_console_messages` - Console output
- `browser_network_requests` - Network activity

### Tabs
- `browser_tab_list` - List tabs
- `browser_tab_new` - Open new tab
- `browser_tab_select` - Switch tabs
- `browser_tab_close` - Close tabs

### Batch
- `browser_batch_execute` - Execute multiple operations in sequence

## Unified Selector System

All element-targeting tools use the same selector system with fallback support.

### Selector Types (Priority Order)

```typescript
// 1. REF - System-generated element ID (fastest)
{ "ref": "e42" }

// 2. ROLE - ARIA role with optional text
{ "role": "button", "text": "Submit" }
{ "role": "textbox" }

// 3. CSS - Standard CSS selectors
{ "css": "#submit-btn" }
{ "css": ".form-container button.primary" }

// 4. TEXT - Text content search
{ "text": "Click here" }
{ "text": "Email", "tag": "input" }
```

### Fallback Arrays

Provide multiple selectors; first match wins:

```json
{
  "selectors": [
    { "ref": "e42" },
    { "css": "#submit-btn" },
    { "role": "button", "text": "Submit" },
    { "text": "Submit" }
  ]
}
```

### Handling Multiple Matches (Strict Mode)

When multiple elements match, pw-fast returns an error with candidates:

```
Error: strict mode violation: 3 elements matched
Candidates:
- ref=e42 (0.95): button.submit-btn "Submit"
- ref=e43 (0.85): div.button "Submit"
- ref=e44 (0.72): span.label "Submit"
```

**Solutions:**
1. Use more specific selector: `{ "css": "form.login button[type='submit']" }`
2. Use `browser_find_elements` to discover the right ref
3. Switch to pw-writer if site is too complex

## Batch Execution

### Basic Structure

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

### Step Configuration

```typescript
interface BatchStep {
  tool: string;                    // Required: tool name
  arguments: Record<string, any>;  // Required: tool arguments
  expectation?: ExpectationOptions;// Optional: per-step override
  continueOnError?: boolean;       // Optional: continue on failure
}
```

### Error Handling

```json
{
  "steps": [
    {
      "tool": "browser_navigate",
      "arguments": { "url": "https://example.com" },
      "continueOnError": false  // Stop if navigation fails
    },
    {
      "tool": "browser_click",
      "arguments": { "selectors": [{ "css": ".optional-button" }] },
      "continueOnError": true   // Continue even if click fails
    },
    {
      "tool": "browser_snapshot",
      "arguments": {}
    }
  ],
  "stopOnFirstError": false
}
```

### Best Practices

- **Combine 3-7 operations** per batch for optimal efficiency
- **Use `globalExpectation`** to reduce token usage across all steps
- **Enable snapshot only on final step** for verification
- **Use `continueOnError: true`** for optional elements

## Expectation Parameter

Controls what gets returned in responses (70-80% token reduction).

### Core Options

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
      "levels": ["error", "warn"], // Filter by level
      "maxMessages": 10,
      "patterns": ["error"],       // Regex filters
      "removeDuplicates": true
    },

    "diffOptions": {
      "enabled": true,             // Show only changes (80% reduction)
      "format": "minimal",         // unified | split | minimal
      "maxDiffLines": 50,
      "context": 3
    },

    "imageOptions": {
      "format": "jpeg",            // jpeg | png | webp
      "quality": 60,               // 1-100 (JPEG only)
      "maxWidth": 800,
      "maxHeight": 600
    }
  }
}
```

### Token Optimization Examples

**Before (11,000 tokens):**
```
browser_navigate → 3,000 tokens
browser_type → 2,500 tokens
browser_type → 2,500 tokens
browser_click → 3,000 tokens
```

**After (2,000 tokens - 82% reduction):**
```json
{
  "steps": [...],
  "globalExpectation": {
    "includeSnapshot": false,
    "includeConsole": false,
    "includeTabs": false
  }
}
```

### Selective Snapshot

Only include relevant page sections:

```json
{
  "expectation": {
    "includeSnapshot": true,
    "snapshotOptions": {
      "selector": ".form-container, .error-message, .success-message",
      "maxLength": 1500,
      "format": "aria"
    }
  }
}
```

## Common Patterns

### Login Flow

```json
{
  "steps": [
    { "tool": "browser_navigate", "arguments": { "url": "/login" }},
    { "tool": "browser_type", "arguments": {
      "selectors": [{ "css": "#email" }], "text": "user@test.com"
    }},
    { "tool": "browser_type", "arguments": {
      "selectors": [{ "css": "#password" }], "text": "password123"
    }},
    { "tool": "browser_click", "arguments": {
      "selectors": [{ "role": "button", "text": "Sign In" }]
    }, "expectation": { "includeSnapshot": true }}
  ],
  "globalExpectation": { "includeSnapshot": false }
}
```

### Form Submission

```json
{
  "steps": [
    { "tool": "browser_type", "arguments": {
      "selectors": [{ "css": "input[name='name']" }], "text": "John Doe"
    }},
    { "tool": "browser_type", "arguments": {
      "selectors": [{ "css": "input[name='email']" }], "text": "john@example.com"
    }},
    { "tool": "browser_select_option", "arguments": {
      "selectors": [{ "css": "select[name='country']" }], "values": ["US"]
    }},
    { "tool": "browser_click", "arguments": {
      "selectors": [{ "role": "button", "text": "Submit" }]
    }, "expectation": {
      "includeSnapshot": true,
      "snapshotOptions": { "selector": ".form-status" }
    }}
  ],
  "globalExpectation": { "includeSnapshot": false }
}
```

### Table Scraping

```json
{
  "steps": [
    { "tool": "browser_navigate", "arguments": { "url": "/data-table" }},
    { "tool": "browser_wait_for", "arguments": { "text": "Loading..." }, "expectation": { "includeSnapshot": false }},
    { "tool": "browser_inspect_html", "arguments": {
      "selectors": [{ "css": "table.data" }],
      "depth": 5,
      "format": "html",
      "maxSize": 50000
    }}
  ]
}
```

### Element Discovery

When you don't know the exact selector:

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

Returns refs like `found_1`, `found_2` that can be used in subsequent calls.

## When pw-fast Fails

### Strict Mode Violations
**Symptom**: "strict mode violation: X elements matched"
**Cause**: Selector matches multiple elements
**Solutions**:
1. Use more specific CSS: `form.login button[type='submit']`
2. Use `browser_find_elements` to discover exact ref
3. **Switch to pw-writer** if site is complex

### External Redirects
**Symptom**: Navigation hangs or fails
**Cause**: Cross-origin redirect during navigation
**Solution**: **Switch to pw-writer** (handles via user Chrome)

### Cookie Consent Dialogs
**Symptom**: Page blocked by modal
**Solutions**:
1. Use `browser_find_elements` to find accept button
2. Click accept button with `browser_click`
3. **Switch to pw-writer** if user already accepted

### Dynamic Content Not Loading
**Symptom**: Elements missing from snapshot
**Solutions**:
1. Add `browser_wait_for` with expected text
2. Increase timeout in navigation
3. Use `browser_evaluate` to check load state

## Comparison with pw-writer

| Feature | pw-fast | pw-writer |
|---------|---------|-----------|
| **Speed** | Faster (batch) | Slower |
| **Reliability** | Lower on complex sites | Higher |
| **Token Control** | `expectation` param | `getCleanHTML` |
| **Auth Support** | Manual | Native (user session) |
| **Popups/Tabs** | Limited | Full support |
| **Error Recovery** | `continueOnError` | Full try/catch |
| **Best For** | Simple, predictable sites | Complex, dynamic sites |

## Defaults Reference

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
