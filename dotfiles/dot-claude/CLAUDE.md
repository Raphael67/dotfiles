# Global Claude Configuration

## Personal Development Environment

- **Shell**: Zsh with oh-my-zsh
  - Source `~/.zshrc` at startup to load nvm and other shell configurations
- **Terminal**: Ghostty
- **Editor**: VSCode
- **Package Manager**: Homebrew

## Code Style Preferences

- **Indentation**: 4 spaces for JS/TS/JSON, 2 spaces for YAML
- **JavaScript/TypeScript**:
  - Prefer `const` over `let` when possible
  - Use semicolons
  - Prefer arrow functions for inline callbacks
  - Use TypeScript strict mode
  - Use bun as package manager for every command
- **Python**:
  - Follow PEP 8
  - always use uv as package manager
- **Markdown**:
  - Use ATX-style headers (#)

## Workflow Preferences

- **Agents**: Always check if a subagent is more appropriate to do a task
- **Git**: Use conventional commits format
- **Documentation**: Keep README files concise and practical

## Role-Based Responsibilities

### For Development Work (coding tasks):
- **Testing**: Run tests before commits
- **Linting**: Always run linters/formatters before commits
- **Code Quality**: Follow established patterns and conventions

### For Specification/Documentation Work:
- **No Testing Required**: Specs and docs don't need code testing
- **No Linting Required**: Focus on content quality, not code style
- **Commit Immediately**: Push specifications and documentation when complete
- **Quality Focus**: Ensure completeness, clarity, and alignment with requirements

## Security & Best Practices

- Never commit secrets or API keys
- Use environment variables for sensitive data
- Always review changes before committing
- Prefer explicit imports over wildcards

## Communication Style

- Be concise and direct
- Focus on practical solutions
- Minimize unnecessary explanations
- Use examples when helpful
- Do not repeat information unnecessarily
- Do not repeat the question or prompt
- Do not gratitude or apologies unless specifically requested

## Available Tools

### Browser Debugger CLI (bdg)

Terminal access to Chrome DevTools Protocol for browser automation and debugging. Optimized for AI agents with self-discovery and token-efficient output.

**Quick Reference:**
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

**When to use bdg:**
- Debugging web applications in browser
- Inspecting network requests/responses
- Capturing screenshots
- Executing JavaScript in page context
- DOM manipulation and inspection
- Performance profiling

**Key features:**
- All 644 CDP protocol methods available
- Self-documenting via `--list`, `--describe`, `--search`
- JSON output by default (pipe to `jq` for processing)
- Semantic exit codes for error handling
