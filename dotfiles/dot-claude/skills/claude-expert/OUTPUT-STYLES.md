# Claude Code Output Styles Reference

## What Are Output Styles?

Output styles are markdown files that modify Claude's system prompt to change how Claude responds — role, tone, and output format — not what Claude knows or its core functionality. They apply to the **main conversation only**. Use CLAUDE.md instead for project/codebase instructions.

## Configuration

Activate a style:
```bash
/output-style concise   # switch by name (case-insensitive); no argument lists styles and marks the current one
/config                 # or select "Output style" from the menu (writes to .claude/settings.local.json)
```

`/output-style [name]` was removed in v2.1.91 and **re-added in v2.1.269**. It also works in non-interactive mode, Agent SDK sessions, and over Remote Control (mobile/web), where only built-in styles can be listed and selected. In the VS Code extension, pick **Output styles** from the `/` command menu (v2.1.257+).

Or set it directly in a settings file:
```json
{
  "outputStyle": "Explanatory"
}
```

When you switch styles mid-session, Claude uses the new style starting with your next message (v2.1.251+; before that it applied only after `/clear` or a new session). That first message pays a prompt-cache cost, since the style is part of the system prompt. Style **files** are read at startup: create or edit one mid-session and restart Claude Code to pick it up. The `outputStyle` settings value is case-sensitive (`Proactive`, `Concise`, `Explanatory`, `Learning`); a non-matching value such as `explanatory` falls back to Default.

In the Desktop app, running `/config` opens **Settings > Claude Code** instead of a terminal menu; set `outputStyle` in a settings file there too.

### Locations
- **User**: `~/.claude/output-styles/*.md` (personal, all projects)
- **Project**: `.claude/output-styles/*.md` (shared via git). Loads from *every* `.claude/output-styles/` directory between the working directory and the repo root — when the same style name exists in more than one, the one closest to the working directory wins.
- **Managed policy**: `.claude/output-styles/` inside the [managed settings directory](https://code.claude.com/docs/en/managed-settings#delivery-mechanisms)
- **Plugins**: can ship styles in an `output-styles/` directory

The file name becomes the style name unless overridden by `name` in the frontmatter.

## Output Style Format

```yaml
---
name: my-style
description: Brief description of the formatting approach
keep-coding-instructions: false
---

# Formatting Instructions

When responding, always format your output as [specific format].

## Rules
- Rule 1
- Rule 2

## Example

[Show an example of the expected output format]
```

### Frontmatter fields

| Field | Purpose | Default |
|---|---|---|
| `name` | Style name, if not the file name | Inherits from file name |
| `description` | Shown in the `/config` picker | None |
| `keep-coding-instructions` | Keep Claude Code's built-in software-engineering instructions (how to scope changes, write comments, verify work) alongside your custom instructions. Set `true` when changing *how* Claude communicates but it's still coding; leave `false`/omitted when Claude isn't doing software engineering at all (e.g. a writing assistant) | `false` |
| `force-for-plugin` | Plugin styles only: auto-apply this style whenever the plugin is enabled, overriding the user's `outputStyle` setting. If multiple enabled plugins set this, the first one loaded wins | `false` |

## Built-In Styles

Claude Code ships five built-in styles, selectable via `/config`:

| Style | Description |
|-------|-------------|
| **Default** | The existing system prompt — standard software-engineering assistant behavior |
| **Proactive** | Executes immediately, makes reasonable assumptions instead of pausing for routine decisions, prefers action over planning. Stronger autonomous-execution guidance than auto permission mode; works independent of permission mode, which still governs what runs without asking |
| **Concise** | Leads with the result, skips preamble and narration, keeps responses short by default — while doing the engineering work as thoroughly as Default. Answers in full when asked for detail; always keeps complete content of error reports, security warnings, and destructive-action confirmations. **Requires Claude Code v2.1.237+** |
| **Explanatory** | Adds educational "Insights" between coding steps to explain implementation choices and codebase patterns |
| **Learning** | Collaborative learn-by-doing mode: shares "Insights" while coding *and* asks you to contribute small pieces of code yourself via `TODO(human)` markers |

> **Bug fix (v2.1.238)**: custom output styles could drift (lose their configured instructions) during long sessions — fixed in this release, alongside an unrelated unbounded-memory-growth fix.

Token usage varies by style: adding instructions to the system prompt increases input tokens (mitigated by prompt caching after the first request). Explanatory and Learning produce longer responses by design (more output tokens); Concise does the opposite. Custom styles' output-token cost depends entirely on what you instruct.

## How Output Styles Work

- Claude Code appends each output style's custom instructions to the **end of the system prompt**.
- All output styles trigger periodic reminders for Claude to keep adhering to the style during the conversation.
- Custom output styles **omit** Claude Code's built-in software-engineering instructions unless `keep-coding-instructions: true` is set.
- **Subagents do NOT inherit the parent's output style** — a subagent runs its own system prompt, so the style change doesn't propagate. The one exception is a **fork** (`subagent_type: "fork"`), which inherits the parent's full system prompt, output style included.

### Comparison to related features

| Feature | How it works | Use when |
|---|---|---|
| Output styles | Modifies the system prompt | Different role/tone/format on every turn |
| CLAUDE.md | Adds a user message after the system prompt | Claude should always know project conventions |
| `--append-system-prompt` | Appends without removing anything | One-off addition for a single invocation |
| Agents (sub-agents) | Runs with its own system prompt, model, tools | A separately scoped helper for a focused task |
| Skills | Loads task-specific instructions on invocation | A reusable workflow |

## Example Custom Style Templates

These are patterns you build yourself with `output-styles/*.md` — not built-in styles.

| Template | Description | Best For |
|-------|-------------|----------|
| **genui** | Generates beautiful HTML with embedded CSS/JS | Interactive visual outputs, browser preview |
| **table-based** | Organizes information in markdown tables | Comparisons, structured data, status reports |
| **yaml-structured** | Formats responses as YAML | Settings, hierarchical data, API responses |
| **bullet-points** | Clean nested lists with dashes | Action items, documentation, task tracking |
| **ultra-concise** | Minimal words, maximum speed | Experienced devs, rapid prototyping (superseded for most cases by the built-in **Concise** style above) |
| **html-structured** | Semantic HTML5 with data attributes | Web documentation, rich formatting |
| **markdown-focused** | Leverages all markdown features | Complex documentation, mixed content |
| **tts-summary** | Announces completion via TTS | Audio feedback, accessibility |

### GenUI Style Example

The `genui` style generates complete HTML pages with embedded styling that can be opened directly in a browser:

```markdown
---
name: genui
description: Generate beautiful HTML interfaces with embedded styling
---

When the user asks for visual output, generate a complete HTML file:

1. Include all CSS inline (no external dependencies)
2. Add interactive JavaScript where appropriate
3. Use modern design patterns (gradients, shadows, animations)
4. Make it responsive
5. Save to a .html file the user can open

## Example Output
A single self-contained HTML file with:
- Embedded <style> tag
- Semantic HTML structure
- Interactive <script> if needed
- No external dependencies
```

## Creating Custom Styles

### 1. Simple Style
```yaml
---
name: concise-json
description: All responses as JSON objects
---

Format every response as valid JSON:
- Use descriptive keys
- Include a "summary" field
- Add "details" array for complex responses

Example:
{
  "summary": "Created 3 files",
  "details": ["src/app.ts", "src/utils.ts", "tests/app.test.ts"],
  "status": "success"
}
```

### 2. Domain-Specific Style
```yaml
---
name: code-review
description: Format responses as structured code reviews
---

Format all code-related responses as:

## Review Summary
- Overall assessment (1-5 stars)

## Issues Found
| Severity | File | Line | Description |
|----------|------|------|-------------|
| ... | ... | ... | ... |

## Recommendations
1. Prioritized list of improvements
```

## Best Practices

1. **Keep instructions clear**: The style must unambiguously describe the format
2. **Include examples**: Show Claude exactly what output looks like
3. **Be specific about structure**: Define headers, separators, formatting rules
4. **Test with various prompts**: Ensure the style works across different task types
5. **Don't override functionality**: Styles change format, not behavior
