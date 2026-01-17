# Custom Slash Commands

Custom slash commands allow users to define reusable prompts as personal shortcuts within the Gemini CLI. They are defined in TOML files.

## Locations & Precedence
1.  **Project-scoped:** `<project-root>/.gemini/commands/` (Overrides user commands).
2.  **User-scoped:** `~/.gemini/commands/` (Available everywhere).

## File Naming
The command name is derived from the file path relative to the `commands` directory.
*   `commands/plan.toml` -> `/plan`
*   `commands/git/commit.toml` -> `/git:commit` (Directories become namespaces).

## TOML Format
Files must have a `.toml` extension.

```toml
# commands/example.toml
prompt = "Your prompt goes here..."
description = "Description displayed in /help"
```

## Dynamic Content

### Arguments `{{args}}`
Injects text typed by the user after the command.
*   Command: `/jira PROJ-123`
*   TOML: `prompt = "Summarize ticket {{args}}"`
*   Result: "Summarize ticket PROJ-123"

*Note: If `{{args}}` is omitted, the user's input is appended to the end of the prompt.*

### Shell Injection `!{...}`
Executes a shell command and injects the stdout.
*   `prompt = "Summarize these changes:\n\n!{git diff HEAD}"`

*Security: Gemini prompts for confirmation before executing shell commands.*

### File Embedding `@{...}`
Embeds file or directory content.
*   `prompt = "Review this file: @{src/main.rs}"`
*   `prompt = "Review this folder: @{src/}"` (Respects `.gitignore`).

## Best Practices
*   Use project-scoped commands for team workflows (commit messages, PR reviews).
*   Use user-scoped commands for personal utilities.
*   Combine `!{}` and `{{args}}` for powerful dynamic prompts.

```