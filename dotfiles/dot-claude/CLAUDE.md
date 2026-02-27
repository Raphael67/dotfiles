# Global Claude Configuration

## Personal Development Environment

- **Shell**: Zsh with oh-my-zsh
  - Source `~/.zshrc` at startup to load nvm and other shell configurations
- **Terminal**: Ghostty
- **Editor**: VSCode
- **Package Manager**: Homebrew

## Quick Reference

| Task | Approach |
|------|----------|
| New TypeScript project | bun init, bun add |
| New Python project | uv init, uv add |
| Browser debugging | bdg CLI |
| Library docs lookup | context7 MCP |
| Run tests | Project-specific (check CLAUDE.md) |
| Fetch secrets/passwords | `bw-fetch` (Touch ID per request) |

## Code Style Preferences

- **Indentation**: 4 spaces for JS/TS/JSON, 2 spaces for YAML
- **JavaScript/TypeScript**:
  - Prefer `const` over `let` when possible
  - Use semicolons
  - Prefer arrow functions for inline callbacks
  - Use TypeScript strict mode
  - Use bun as package manager (unless project CLAUDE.md specifies otherwise)
- **Python**:
  - Follow PEP 8
  - always use uv as package manager
- **Markdown**:
  - Use ATX-style headers (#)

## Workflow Preferences

- **Agents**: Always check if a subagent is more appropriate to do a task
- **Skills**: Never update or alter a skill without explicit user request
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

## File Safety

- **Backup before modification**: ALWAYS create a backup copy of `.xlsx`, `.docx`, and `.pdf` files BEFORE any modification. Copy the original to `<filename>.backup.<YYYYMMDD-HHMMSS>.<ext>` (e.g., `report.backup.20260218-143052.xlsx`) in the same directory. Do this even for minor edits — these formats are binary and changes are hard to reverse.

## Secrets & Credentials

When you need an API key, password, token, or any secret:
1. **Never hardcode** — always fetch at runtime via `bw-fetch`
2. **Search first** if you don't know the exact item name: `bw-fetch search "<query>"`
3. **Fetch by ID** if multiple items share a name: `bw-fetch password "<item-id>"`
4. **Fetch by name** if unique: `bw-fetch password "<item-name>"`

Each `bw-fetch` call triggers Touch ID — the user must approve with their fingerprint.

```bash
bw-fetch search "aws"                          # Find items → Touch ID
bw-fetch password "AWS IAM"                    # Get password → Touch ID
bw-fetch totp "AWS IAM"                        # Get TOTP code → Touch ID
bw-fetch item "698ba95d-..."                   # Full item JSON by ID → Touch ID
```

**Rules:**
- Never store fetched secrets in files, env vars, or shell history
- Pipe secrets directly where needed (e.g., `bw-fetch password "X" | some-command`)
- Never log or echo secrets — use `--raw` output silently
- If a secret is needed in a `.env` file, ask the user to confirm before writing it

## Security & Best Practices

- Never commit secrets or API keys
- Use `bw-fetch` to retrieve credentials at runtime (see above)
- Always review changes before committing
- Prefer explicit imports over wildcards

## Error Handling

- **Build/Test failures**: Fix the issue, don't skip or ignore
- **Missing dependencies**: Ask before installing new packages
- **Ambiguous requirements**: Ask clarifying questions early
- **Permission errors**: Report and suggest solutions, don't force

## File Organization

- **New source files**: Follow existing project structure
- **Test files**: Colocate with source or in `tests/` (project-dependent)
- **Config files**: Root directory unless project has specific convention
- **Generated files**: Never commit (add to .gitignore)
- **Temporary files**: Use OS temp folder (`/tmp` or `$TMPDIR`)
- **One-shot scripts**: OS temp folder, delete after use
- **Persistent scripts**: Store in the skill/project that requires them (self-contained)

### Script Languages

| Script Type | Language Priority |
|-------------|-------------------|
| Inline/temporary | Best for task (bash, python, ts, rust) |
| Persistent (user-facing) | TypeScript > Python |
| Skill scripts | Best for task (self-contained in skill) |

Allowed languages: Python, Bash, TypeScript, Rust

## Communication Style

- Concise: bullet points over prose
- Direct: state facts, skip preamble
- Structured: use markdown (headers, tables, lists)
- No filler: avoid gratitude, apologies, paraphrasing
- No repetition: don't echo the question back
- Examples when useful, not for padding

## Available Tools

### context7 MCP (Library Documentation)

Fetch up-to-date documentation for libraries:
- Before implementing unfamiliar APIs
- When Stack Overflow answers seem outdated
- For framework-specific patterns (React, NestJS, etc.)

**Usage**: Use `resolve-library-id` to find the library, then `query-docs` to fetch relevant sections.

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
