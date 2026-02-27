# Claude Code Memory Reference

## Memory Types Hierarchy

Claude Code has a layered memory system, from broadest to most specific:

| Memory Type | Location | Purpose | Shared With |
|-------------|----------|---------|-------------|
| **Managed policy** | macOS: `/Library/Application Support/ClaudeCode/CLAUDE.md`<br>Linux: `/etc/claude-code/CLAUDE.md`<br>Windows: `C:\Program Files\ClaudeCode\CLAUDE.md` | Organization-wide instructions managed by IT/DevOps | All users in org |
| **Project memory** | `./CLAUDE.md` or `./.claude/CLAUDE.md` | Team-shared instructions for the project | Team via source control |
| **Project rules** | `./.claude/rules/*.md` | Modular, topic-specific project instructions | Team via source control |
| **User memory** | `~/.claude/CLAUDE.md` | Personal preferences for all projects | Just you (all projects) |
| **Project memory (local)** | `./CLAUDE.local.md` | Personal project-specific preferences | Just you (current project) |
| **Auto memory** | `~/.claude/projects/<project>/memory/` | Claude's automatic notes and learnings | Just you (per project) |

**Precedence**: More specific instructions override broader ones. CLAUDE.local.md > CLAUDE.md > ~/.claude/CLAUDE.md > managed policy.

## CLAUDE.md Files

### Lookup Behavior

Claude Code recursively reads CLAUDE.md and CLAUDE.local.md files from CWD up to (but not including) root `/`. Files in subdirectories below CWD are loaded on-demand when Claude reads files in those subtrees.

### Import Syntax

CLAUDE.md files can import additional files using `@path/to/import`:

```markdown
See @README for project overview and @package.json for npm commands.

# Additional Instructions
- git workflow @docs/git-instructions.md
```

Rules:
- Relative paths resolve relative to the importing file, not CWD
- Absolute paths and `@~/` home-directory paths supported
- First encounter triggers approval dialog (one-time per project)
- Not evaluated inside code spans/blocks
- Recursive imports supported (max depth: 5)
- CLAUDE.local.md auto-added to .gitignore

### Additional Directories

```bash
# Load files from extra directories
claude --add-dir ../shared-config

# Also load CLAUDE.md from those directories
CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1 claude --add-dir ../shared-config
```

## Modular Rules (.claude/rules/)

Organize instructions into focused topic files:

```
.claude/rules/
├── frontend/
│   ├── react.md
│   └── styles.md
├── backend/
│   ├── api.md
│   └── database.md
└── general.md
```

### Path-Specific Rules (Conditional Loading)

Use YAML frontmatter to scope rules to specific files:

```markdown
---
paths:
  - "src/api/**/*.ts"
  - "lib/**/*.ts"
---

# API Development Rules
- All API endpoints must include input validation
```

Glob patterns supported: `**/*.ts`, `src/**/*`, `*.md`, brace expansion `*.{ts,tsx}`.

Rules without `paths` are loaded unconditionally.

### User-Level Rules

Personal rules at `~/.claude/rules/` apply to all projects (loaded before project rules, lower priority).

## Auto Memory

Auto memory is Claude's persistent note-taking system. Claude automatically records learnings, patterns, and insights as it works.

### How It Works

- **Enabled by default** — toggle with `/memory` command
- Each project gets its own directory at `~/.claude/projects/<project>/memory/`
- `<project>` path derived from git repo root (all subdirs share one memory dir)
- Git worktrees get separate memory directories
- Outside git repos, working directory path is used

### Directory Structure

```
~/.claude/projects/<project>/memory/
├── MEMORY.md          # Concise index (first 200 lines loaded at startup)
├── debugging.md       # Detailed notes on debugging patterns
├── api-conventions.md # API design decisions
└── ...                # Any topic files Claude creates
```

### Loading Behavior

- First **200 lines** of `MEMORY.md` loaded into system prompt at session start
- Content beyond 200 lines is NOT loaded automatically
- Topic files (e.g., `debugging.md`) loaded on-demand via file tools
- Claude reads and writes memory files during sessions

### What Claude Remembers

- Project patterns: build commands, test conventions, code style
- Debugging insights: solutions to tricky problems, common errors
- Architecture notes: key files, module relationships, abstractions
- User preferences: communication style, workflow habits, tool choices

### Best Practices for MEMORY.md

- Keep it concise — stays under 200 lines
- Use bullet points under descriptive markdown headings
- Move detailed notes into separate topic files
- Link to topic files from MEMORY.md for discoverability
- Organize semantically by topic, not chronologically

### User Commands

- `/memory` — Open file selector (includes auto memory + CLAUDE.md files) and toggle auto-memory on/off
- Direct request: "remember that we use pnpm, not npm"
- Direct request: "save to memory that API tests require local Redis"

### Configuration

Disable auto memory globally:
```json
// ~/.claude/settings.json
{ "autoMemoryEnabled": false }
```

Disable per-project:
```json
// .claude/settings.json
{ "autoMemoryEnabled": false }
```

Environment variable override (takes precedence over all settings):
```bash
export CLAUDE_CODE_DISABLE_AUTO_MEMORY=1  # Force off
export CLAUDE_CODE_DISABLE_AUTO_MEMORY=0  # Force on
```

## Agent Memory

Custom agents can have persistent memory via the `memory` frontmatter field:

```yaml
---
name: code-reviewer
memory: user    # Scope: user, project, or local
---
```

| Scope | Location | Use Case |
|-------|----------|----------|
| `user` | `~/.claude/agent-memory/<name>/` | Learnings across all projects |
| `project` | `.claude/agent-memory/<name>/` | Project-specific, shareable via git |
| `local` | `.claude/agent-memory-local/<name>/` | Project-specific, not committed |

When memory is enabled:
- Read, Write, Edit tools auto-enabled for memory access
- Agent maintains `MEMORY.md` automatically
- First 200 lines of `MEMORY.md` in system prompt each session

## Organization-Level Memory

Deploy centrally managed CLAUDE.md to the managed policy location via MDM, Group Policy, Ansible, etc.

## Memory Best Practices

- **Be specific**: "Use 2-space indentation" > "Format code properly"
- **Use structure**: Bullet points grouped under descriptive headings
- **Review periodically**: Update as project evolves
- **Don't duplicate**: Check existing memories before writing new ones
- **Stable patterns only**: Verify across multiple interactions before saving
- **Honor explicit requests**: When user says "always use X", save immediately
