# Claude Code Output Styles Reference

## What Are Output Styles?

Output styles are markdown files that modify Claude's system prompt to change response formatting. They transform how Claude communicates without affecting core functionality.

## Configuration

Activate a style:
```bash
/output-style [name]
```

### Locations
- **Project**: `.claude/output-styles/*.md` (shared via git)
- **User**: `~/.claude/output-styles/*.md` (personal, all projects)

## Output Style Format

```yaml
---
name: my-style
description: Brief description of the formatting approach
---

# Formatting Instructions

When responding, always format your output as [specific format].

## Rules
- Rule 1
- Rule 2

## Example

[Show an example of the expected output format]
```

## Available Styles

| Style | Description | Best For |
|-------|-------------|----------|
| **genui** | Generates beautiful HTML with embedded CSS/JS | Interactive visual outputs, browser preview |
| **table-based** | Organizes information in markdown tables | Comparisons, structured data, status reports |
| **yaml-structured** | Formats responses as YAML | Settings, hierarchical data, API responses |
| **bullet-points** | Clean nested lists with dashes | Action items, documentation, task tracking |
| **ultra-concise** | Minimal words, maximum speed | Experienced devs, rapid prototyping |
| **html-structured** | Semantic HTML5 with data attributes | Web documentation, rich formatting |
| **markdown-focused** | Leverages all markdown features | Complex documentation, mixed content |
| **tts-summary** | Announces completion via TTS | Audio feedback, accessibility |

## GenUI Style (Recommended)

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
