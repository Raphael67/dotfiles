# Browser Tools Reference

Additional browser tools beyond Playwright test runner and scraping MCPs.

---

## Claude Chrome Integration (`claude --chrome`)

### Overview

Native Chrome integration for Claude Code. Shares your browser's login state — ideal for authenticated web apps, live debugging, and design verification.

### Setup

```bash
# Launch Claude Code with Chrome integration
claude --chrome

# Or inside an existing session
/chrome
```

**Requirements:**
- Chrome extension v1.0.36+
- Claude Code v2.0.73+
- Paid Claude plan (Pro, Team, or Enterprise)

### Architecture

- Uses Chrome Native Messaging API
- Connects to your running Chrome instance
- Shares your login state and cookies
- Visible browser (not headless) — you can watch actions happen
- Actions are performed in a real browser tab

### Capabilities

| Category | Actions |
|----------|---------|
| **Navigation** | Navigate to URLs, go back/forward, reload |
| **Interaction** | Click elements, type text, fill forms, select options |
| **Reading** | Read page content, extract text, get HTML |
| **Debugging** | Read console logs, monitor network requests |
| **Tabs** | List tabs, switch tabs, open/close tabs |
| **Visual** | Take screenshots, record GIFs of interactions |
| **Forms** | Fill complex multi-step forms with your session |

### Best For

- **Authenticated web apps** — Uses your logged-in sessions (GitHub, Jira, etc.)
- **Live debugging** — Inspect real app state with your data
- **Design verification** — Check UI matches specs with actual content
- **Data extraction** — Pull data from apps you're logged into
- **Form testing** — Test forms with real session state

### Limitations

- Requires visible Chrome window (not headless)
- Cannot run in CI/CD pipelines
- One tab at a time for interactions
- Modal dialogs may block automation
- Extension must be installed and enabled

### Troubleshooting

| Issue | Solution |
|-------|----------|
| Extension not detected | Reinstall extension, restart Chrome |
| Version mismatch | Update both Chrome extension and Claude Code |
| Modal blocking actions | Dismiss modal manually, then retry |
| Tab not responding | Switch to the target tab manually |
| Connection lost | Run `/chrome` again to reconnect |

---

## Claude Firefox MCP (`claude-firefox-mcp`)

### Overview

Firefox automation via Deno MCP server + Firefox extension + WebSocket. Also supports Thunderbird and SeaMonkey.

### Setup

```bash
# Clone and install
git clone https://github.com/hyperpolymath/claude-firefox-mcp
cd claude-firefox-mcp
./scripts/install.sh

# Load extension in Firefox
# Navigate to about:debugging → This Firefox → Load Temporary Add-on
# Select the extension manifest from the cloned repo
```

**MCP config:**
```json
{
  "mcpServers": {
    "firefox": {
      "command": "deno",
      "args": ["run", "--allow-all", "path/to/claude-firefox-mcp/src/index.ts"]
    }
  }
}
```

### Architecture

- **Deno MCP server** — Handles Claude ↔ Firefox communication
- **Firefox extension** — Injects into browser, exposes WebSocket
- **WebSocket** — localhost connection between MCP server and extension

### Capabilities (13 Core Tools)

| Tool | Description |
|------|-------------|
| `screenshot` | Capture current page |
| `navigate` | Go to URL |
| `read_content` | Extract page text/HTML |
| `click` | Click elements |
| `type` | Type into inputs |
| `fill_form` | Fill form fields |
| `get_tabs` | List open tabs |
| `switch_tab` | Switch to tab |
| `new_tab` | Open new tab |
| `close_tab` | Close tab |
| `execute_js` | Run JavaScript in page |
| `scroll` | Scroll page |
| `get_elements` | Query DOM elements |

### Best For

- Firefox-specific testing or debugging
- Cross-browser verification (complement Chromium tools)
- Thunderbird email automation
- When Chrome-based tools aren't suitable

### Troubleshooting

| Issue | Solution |
|-------|----------|
| Deno not installed | `brew install deno` |
| WebSocket connection fails | Check extension is loaded, restart Firefox |
| Extension not loaded | Use about:debugging to reload temporary add-on |
| Permission errors | Run with `--allow-all` flag |

**Source:** https://github.com/hyperpolymath/claude-firefox-mcp

---

## Chrome DevTools MCP (`chrome-devtools-mcp`)

### Overview

Full Chrome DevTools Protocol access via MCP. 26 tools across 6 categories for performance profiling, network inspection, and browser automation.

### Setup

```bash
# Add to Claude Code (user scope)
claude mcp add chrome-devtools --scope user npx chrome-devtools-mcp@latest
```

**Or in MCP config:**
```json
{
  "mcpServers": {
    "chrome-devtools": {
      "command": "npx",
      "args": ["chrome-devtools-mcp@latest"]
    }
  }
}
```

### Tool Categories (26 Tools)

**Automation (7):**
| Tool | Description |
|------|-------------|
| `navigate` | Go to URL |
| `click` | Click element |
| `type` | Type text |
| `select` | Select option |
| `screenshot` | Capture page |
| `evaluate` | Run JavaScript |
| `get_content` | Extract page content |

**Performance (5):**
| Tool | Description |
|------|-------------|
| `performance_profile` | CPU profiling |
| `performance_metrics` | Page metrics |
| `memory_snapshot` | Heap snapshot |
| `coverage` | Code coverage |
| `lighthouse` | Lighthouse audit |

**Network (4):**
| Tool | Description |
|------|-------------|
| `network_monitor` | Monitor requests |
| `network_intercept` | Intercept/modify requests |
| `network_throttle` | Simulate network conditions |
| `network_cache` | Cache management |

**Debugging (4):**
| Tool | Description |
|------|-------------|
| `console_read` | Read console output |
| `set_breakpoint` | Set breakpoints |
| `debug_evaluate` | Evaluate in debug context |
| `source_map` | Source map resolution |

**Emulation (3):**
| Tool | Description |
|------|-------------|
| `emulate_device` | Device emulation |
| `emulate_network` | Network conditions |
| `emulate_geolocation` | Geolocation spoofing |

**Input (3):**
| Tool | Description |
|------|-------------|
| `mouse` | Mouse events |
| `keyboard` | Keyboard events |
| `touch` | Touch events |

### Configuration Options

```json
{
  "headless": true,
  "isolatedProfile": true,
  "proxy": "http://proxy:8080",
  "viewport": { "width": 1280, "height": 720 }
}
```

### Best For

- **Performance profiling** — CPU, memory, coverage analysis
- **Network inspection** — Request monitoring, throttling, interception
- **Debugging** — Breakpoints, source maps, console access
- **Device testing** — Emulation of devices, networks, locations

### Troubleshooting

| Issue | Solution |
|-------|----------|
| Chrome not found | Install Chrome or set `CHROME_PATH` |
| Port conflict | Check no other Chrome debug session running |
| Connection timeout | Increase timeout in config |
| Headless issues | Try with `headless: false` for debugging |

**Source:** https://github.com/ChromeDevTools/chrome-devtools-mcp

---

## Playwright CLI (`@anthropic-ai/playwright-cli`)

### Overview

Token-efficient CLI for browser automation, optimized for AI agents. Complements MCP tools — use the CLI for context-constrained agents and scripted sequences, MCP for exploratory and long-running autonomous workflows.

### Setup

```bash
npm install -g @anthropic-ai/playwright-cli@latest
playwright-cli install              # Install browser binaries
```

### Core Commands

| Category | Commands |
|----------|----------|
| **Navigation** | `goto`, `go-back`, `go-forward`, `reload` |
| **Interaction** | `click`, `type`, `fill`, `drag`, `select`, `upload`, `check`, `press` |
| **Inspection** | `snapshot`, `screenshot` |
| **Session** | `-s=name`, `--persistent`, `close`, `close-all`, `list` |
| **Storage** | cookies, localStorage, sessionStorage (`list`, `get`, `set`, `delete`) |
| **Network** | Mock requests |
| **Monitoring** | `playwright-cli show` (visual dashboard) |
| **Recording** | Video/trace capture |

### Session Management

```bash
# Named sessions — isolate browser contexts by task
playwright-cli goto "https://example.com" -s=checkout-flow
playwright-cli click --text "Add to cart" -s=checkout-flow

# Persistent sessions — preserve cookies/storage across commands
playwright-cli goto "https://example.com" -s=my-session --persistent

# Environment variable for default session
export PLAYWRIGHT_CLI_SESSION=my-session

# Session lifecycle
playwright-cli list                  # List active sessions
playwright-cli close -s=checkout-flow  # Close specific session
playwright-cli close-all            # Close all sessions
```

### CLI vs MCP

| | CLI | MCP (pw-fast/pw-writer) |
|---|---|---|
| **Token cost** | Minimal — only command output | Higher — tool call overhead per action |
| **Context injection** | Explicit per command | Rich introspection, snapshots |
| **Best for** | Scripted sequences, CI pipelines | Exploratory work, complex SPAs |
| **Session model** | Named sessions, persistent | Per-connection |

### Best For

- **Token-constrained agents** — minimal context overhead per action
- **CI pipelines** — scriptable, deterministic sequences
- **Scripted automation** — chain commands in bash
- **Multi-agent workflows** — each agent gets an isolated named session
- When MCP tool-call overhead is undesirable

---

## bdg CLI (Browser Debugger)

### Overview

Terminal CLI for Chrome DevTools Protocol. Self-documenting with 53 CDP domains and 644 methods. Already installed — referenced in global CLAUDE.md.

### Quick Reference

```bash
# Session management
bdg example.com                    # Start session with URL
bdg https://localhost:5173 --chrome-flags="--ignore-certificate-errors"
bdg stop                           # End session

# Discovery (use these to learn available commands)
bdg cdp --list                     # List all 53 CDP domains
bdg cdp Network --list             # List methods in a domain
bdg cdp Network.getCookies --describe  # Full schema + examples
bdg cdp --search screenshot        # Search across all domains

# Common operations
bdg cdp Network.getCookies         # Get cookies
bdg cdp Page.captureScreenshot     # Take screenshot
bdg dom query "button"             # Query DOM elements
bdg cdp Runtime.evaluate --params '{"expression": "document.title"}'
```

### Key Features

- **All 644 CDP protocol methods** available via `bdg cdp <Domain.method>`
- **Self-documenting** via `--list`, `--describe`, `--search`
- **JSON output** by default (pipe to `jq` for processing)
- **Semantic exit codes** for error handling
- **Domain shortcuts**: `bdg dom`, `bdg net`, `bdg perf`

### Common Workflows

**Inspect page:**
```bash
bdg example.com
bdg cdp Runtime.evaluate --params '{"expression": "document.title"}'
bdg dom query ".main-content"
bdg cdp Page.captureScreenshot
bdg stop
```

**Debug network:**
```bash
bdg example.com
bdg cdp Network.enable
bdg cdp Network.getCookies
bdg cdp Network.getResponseBody --params '{"requestId": "..."}'
```

**Performance check:**
```bash
bdg example.com
bdg cdp Performance.enable
bdg cdp Performance.getMetrics
```

### Best For

- **Quick inspection** — One-off checks without full MCP setup
- **Low-level CDP access** — Direct protocol commands
- **Scripting** — Chain commands in bash scripts
- **Debugging** — Fast iteration with terminal workflow

### Troubleshooting

| Issue | Solution |
|-------|----------|
| Session won't start | Check Chrome is installed, no conflicting debug sessions |
| Connection refused | `bdg stop` then retry, or kill orphan Chrome processes |
| Command not found | Verify bdg is installed: `which bdg` |
| Invalid params | Use `--describe` to check parameter schema |

**Source:** https://github.com/szymdzum/browser-debugger-cli
