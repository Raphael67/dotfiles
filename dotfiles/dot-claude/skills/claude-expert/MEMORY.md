# Claude Code Memory Reference

## Memory Types Hierarchy

Claude Code has a layered memory system, from broadest to most specific:

| Memory Type | Location | Purpose | Shared With |
|-------------|----------|---------|-------------|
| **Managed policy** | macOS: `/Library/Application Support/ClaudeCode/CLAUDE.md`<br>Linux/WSL: `/etc/claude-code/CLAUDE.md`<br>Windows: `C:\Program Files\ClaudeCode\CLAUDE.md` | Organization-wide instructions managed by IT/DevOps | All users in org |
| **User memory** | `~/.claude/CLAUDE.md` | Personal preferences for all projects | Just you (all projects) |
| **Project memory** | `./CLAUDE.md` or `./.claude/CLAUDE.md` | Team-shared instructions for the project | Team via source control |
| **Project rules** | `./.claude/rules/*.md` | Modular, topic-specific project instructions | Team via source control |
| **Project memory (local)** | `./CLAUDE.local.md` | Personal project-specific preferences | Just you (current project) |
| **Auto memory** | `~/.claude/projects/<project>/memory/` | Claude's automatic notes and learnings | Just you (per project) |

**Load order (broadest → most specific)**: managed policy → user (`~/.claude/CLAUDE.md`) → project → local. This is a *concatenation* order, not an override order — **CLAUDE.md files do not override each other; all discovered files are concatenated into context.** A file loaded later in the order simply appears later in context (i.e. is read last), which gives it more recency but not exclusivity. To hard-block an action regardless of what Claude decides, use a `PreToolUse` hook instead — CLAUDE.md is context, not enforced configuration.

**Directory-tree ordering**: within the working-directory hierarchy, content is ordered root-down — e.g. running Claude in `foo/bar/` loads `foo/CLAUDE.md` before `foo/bar/CLAUDE.md`, so instructions closer to the launch directory are read last (most recent). **Within each directory, `CLAUDE.local.md` is appended immediately after that directory's `CLAUDE.md`**, so personal local notes are the last thing read at that level.

CLAUDE.md/CLAUDE.local.md in the cwd and every ancestor directory load at launch. Files in **subdirectories below cwd load on demand** — only when Claude reads a file in that subtree, not at startup.

## CLAUDE.md Files

### Lookup Behavior

Claude Code recursively reads CLAUDE.md and CLAUDE.local.md files from CWD up to (but not including) root `/`. Files in subdirectories below CWD are loaded on-demand when Claude reads files in those subtrees. See the concatenation/ordering rules above.

### Import Syntax

CLAUDE.md files can import additional files using `@path/to/import`:

```markdown
See @README for project overview and @package.json for npm commands.

# Additional Instructions
- git workflow @docs/git-instructions.md
```

Rules:
- Relative paths resolve relative to the **containing file** (the file with the `@import`), not CWD
- Absolute paths and `@~/` home-directory paths supported
- Import parsing **skips Markdown code spans and fenced code blocks** — wrap a path in backticks (`` `@README` ``) to mention it literally without importing
- Recursive imports supported, **max depth: 4 hops**
- CLAUDE.local.md auto-added to .gitignore (with `CLAUDE_CODE_NEW_INIT=1`, `/init`'s personal option does this for you)

**External-import approval dialog**: an import in a **project-level** memory file counts as *external* when its path resolves **outside the current working directory** (e.g. importing `~/.claude/my-project-instructions.md` from a project CLAUDE.md to share personal notes across git worktrees). The first time Claude Code encounters external imports in a project it shows a one-time approval dialog listing the files; declining disables those imports permanently (the dialog does not reappear). This protects against imports smuggled in by files someone else commits to a shared project.

- **User-scope memory files** (`~/.claude/CLAUDE.md`, `~/.claude/rules/`) are files you wrote yourself — outside Cowork, their imports load with **no dialog**, trusted like the rest of your personal config.
- **Cowork-specific restrictions** (desktop Cowork sessions only): Claude Code **skips** any import in a user-scope file that resolves to a path **outside the session's working directory**, loading the rest of the file as normal. It also **skips** a `~/.claude/CLAUDE.md` that is itself a symlink/hard link, and a symlinked `~/.claude/rules/` directory or rule file that points outside the working directory.

### Additional Directories

```bash
# Load files from extra directories
claude --add-dir ../shared-config

# Also load CLAUDE.md from those directories
CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1 claude --add-dir ../shared-config
```

By default, `--add-dir` does **not** load CLAUDE.md from the added directory. Setting `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` loads `CLAUDE.md`, `.claude/CLAUDE.md`, `.claude/rules/*.md`, **and** `CLAUDE.local.md` from that directory (`CLAUDE.local.md` is skipped if `local` is excluded via `--setting-sources`).

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

Rules without `paths` are loaded unconditionally, at the same priority as `.claude/CLAUDE.md`. Path-scoped rules trigger when Claude *reads a matching file*, not on every tool use. As of **v2.1.198**, matching also works when Claude reaches a file through a **symlinked path** into the project directory (e.g. a symlinked checkout).

`.md` files are discovered **recursively** under `.claude/rules/` (subdirectories like `frontend/`, `backend/` are fine). Project rules are skipped entirely if `project` is excluded via `--setting-sources`; before **v2.1.211**, on-demand rules (path-scoped or in nested `.claude/rules/` dirs) loaded anyway despite that exclusion.

**Brace-expansion budget**: each brace group multiplies expanded patterns (`src/*.{ts,tsx}` → 2; `{a,b}/{c,d}/*.{ts,tsx}` → 8). A rule's whole `paths` list shares **one budget of 1,000 expanded patterns and 4 MiB**; patterns without braces don't count against it. A pattern that would exceed the budget is used **unexpanded**, so its literal braces match no files (**fixed in v2.1.217** — before that, a `paths` value with many brace groups could stall or crash the CLI at startup).

**Bracket patterns**: `[` starts a glob bracket expression (`[abc]`). A pattern with an unparseable `[` (e.g. `photos [2024/**`) is invalid — it **matches nothing**, and the rule's *other* patterns keep working; escape a literal `[` as `photos \[2024/**`. **Fixed in v2.1.207** — before that, one invalid pattern made the Read tool fail for every file the rule was evaluated against.

### Share Rules Across Projects with Symlinks

`.claude/rules/` supports symlinks — link a shared directory or an individual file into multiple projects:

```bash
ln -s ~/shared-claude-rules .claude/rules/shared
ln -s ~/company-standards/security.md .claude/rules/security.md
```

Symlinks resolve and load normally; **circular symlinks are detected and handled gracefully**.

### User-Level Rules

Personal rules at `~/.claude/rules/` apply to all projects — **loaded before project rules**, giving project rules higher priority.

## Auto Memory

Auto memory is Claude's persistent note-taking system. Claude automatically records learnings, patterns, and insights as it works, and skips anything derivable from the codebase or already stated in CLAUDE.md.

### Memory Types

Claude records each memory's kind as a `type` field in that file's frontmatter — exactly four values:

| `type` | Contents |
|--------|----------|
| `user` | Your role, expertise, and working preferences |
| `feedback` | Corrections you give Claude and approaches you confirm |
| `project` | Ongoing work, deadlines, and decisions Claude can't derive from code/git history |
| `reference` | Where to find information outside the project (issue tracker, dashboard, etc.) |

### How It Works

- **Enabled by default** — toggle with `/memory` command (writes `autoMemoryEnabled` to `~/.claude/settings.json`)
- Each project gets its own directory at `~/.claude/projects/<project>/memory/`
- `<project>` path derived from git repo root — **all worktrees and subdirs of the same repo share one memory dir**
- Outside git repos, the project root is used instead
- Auto memory is **machine-local**: not shared across machines or cloud environments
- Memory files are **excluded from the `cleanupPeriodDays` session-transcript retention sweep** — `MEMORY.md` and topic files persist until you or Claude edits/deletes them, independent of transcript cleanup

### Directory Structure

```
~/.claude/projects/<project>/memory/
├── MEMORY.md          # Concise index (first 200 lines OR 25KB, whichever is smaller, loaded at startup)
├── debugging.md       # Detailed notes on debugging patterns
├── api-conventions.md # API design decisions
└── ...                # Any topic files Claude creates
```

### Loading Behavior

- First **200 lines OR 25KB** of `MEMORY.md` (whichever comes first) loaded at the start of every conversation
- Content beyond that threshold is NOT loaded automatically — this limit applies only to `MEMORY.md`; CLAUDE.md files load in full up to **4 MiB** (larger files are skipped)
- After Claude writes `MEMORY.md`, Claude Code measures it against the limits: near a limit it reminds Claude to shorten the file (one line per entry, move detail to topic files, merge/drop stale entries); over a limit the write still succeeds but Claude Code returns an error telling Claude to rewrite the index, since content past the limit is dropped on next load
- Topic files (e.g., `debugging.md`) are NOT loaded at startup — Claude reads them on-demand via standard file tools
- Claude reads and writes memory files during sessions ("Saved N memories" / "Recalled N memories" in the UI)
- **`modified` frontmatter timestamp (v2.1.214+)**: when Claude writes a memory file that begins with YAML frontmatter, Claude Code records the write time as an ISO-8601 `modified` field, so both you and Claude can gauge freshness. Any frontmatter'd file gets the field on its next write (including files created pre-v2.1.214); Claude Code never adds frontmatter to a file that has none.

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

### Custom Memory Directory

Store auto memory in a custom location with `autoMemoryDirectory` (must be an absolute path or start with `~/`):
```json
// any settings scope
{ "autoMemoryDirectory": "~/my-custom-memory-dir" }
```

Read from **any settings scope**: user, project, local, policy, or `--settings`. When set in a project's `.claude/settings.json` or `.claude/settings.local.json`, it is honored under the same **workspace-trust rule as hooks** in settings files (i.e. it doesn't silently apply to an untrusted folder).

### Custom Project Directory Name — `CLAUDE_CODE_PROJECT_DIR_NAME` (v2.1.234+)

Set alongside `CLAUDE_CONFIG_DIR` to have Claude Code use a fixed name as the `<project>` directory under `<config dir>/projects/`, regardless of which repository you launch in — so every project launched with that config directory shares one auto memory directory.

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

### Inline Managed CLAUDE.md (claudeMd)

Instead of deploying a separate managed CLAUDE.md file, put its content directly inside `managed-settings.json` via the `claudeMd` key:

```json
// managed-settings.json (managed/policy scope only)
{
  "claudeMd": "Always run `make lint` before committing.\nNever push directly to main."
}
```

- **Precedence**: same as a managed CLAUDE.md file — loads before user and project CLAUDE.md.
- **Where it's honored**: managed/policy settings **only**. Setting `claudeMd` in user, project, or local settings has **no effect**.
- Use managed settings (`permissions.deny`, `sandbox.enabled`, `env`, `forceLoginMethod`, …) for hard technical enforcement; use managed CLAUDE.md/`claudeMd` for behavioral guidance — settings rules are enforced by the client regardless of what Claude decides, CLAUDE.md instructions are not.

### Excluding CLAUDE.md Files (claudeMdExcludes)

In large monorepos, skip irrelevant CLAUDE.md files:
```json
// .claude/settings.local.json
{
  "claudeMdExcludes": [
    "**/monorepo/CLAUDE.md",
    "/home/user/monorepo/other-team/.claude/rules/**"
  ]
}
```

Patterns match against absolute file paths using glob syntax. Configurable at **any settings layer** (user, project, local, or managed policy) — **arrays merge across layers** rather than one layer replacing another. Managed policy CLAUDE.md files **cannot** be excluded, so org-wide instructions always apply regardless of individual settings.

### CLAUDE.md HTML Comments (v2.1.72+)

Block-level HTML comments (`<!-- ... -->`) in CLAUDE.md are stripped before content is injected into Claude's context. Comments inside code blocks are preserved. Comments remain visible when read with the Read tool. Useful for maintainer notes that shouldn't consume context.

### AGENTS.md Bridge

Claude Code reads `CLAUDE.md`, **not** `AGENTS.md`. If your repository already uses `AGENTS.md` for other coding agents, create a `CLAUDE.md` that imports it so both tools share instructions:

```markdown
@AGENTS.md

## Claude Code

Claude-specific overrides go below the import.
```

A symlink also works if you don't need Claude-specific content (`ln -s AGENTS.md CLAUDE.md`; requires Administrator/Developer Mode on Windows, so use the `@AGENTS.md` import there instead).

**`/import`** brings another coding agent's configuration into Claude Code: it appends a one-time copy of instruction files such as `AGENTS.md` into the matching CLAUDE.md, and carries over MCP servers, commands, subagents, and skills. **Requires Claude Code v2.1.213+.**

### `/init` Command (Multi-Phase, v2.1.83+)

`/init` generates a starting `CLAUDE.md` from codebase analysis. It **always** reads Cursor rules (`.cursor/rules/` or `.cursorrules`) and Copilot rules (`.github/copilot-instructions.md`) and folds relevant parts in. Set `CLAUDE_CODE_NEW_INIT=1` to enable an interactive multi-phase flow: it asks which artifacts to set up (CLAUDE.md, skills, hooks), explores the codebase via subagent, asks follow-up questions, and shows a reviewable proposal before writing files. With this flag set, `/init` **additionally** reads `AGENTS.md`, `.devin/rules/`, `.windsurf/rules/` (or `.windsurfrules`), and `.clinerules`. If a CLAUDE.md already exists, `/init` suggests improvements rather than overwriting.

### Debug Loading with `InstructionsLoaded` Hook

Configure an `InstructionsLoaded` hook to log exactly which instruction files are loaded, when, and why. Matchers: `session_start`, `nested_traversal`, `path_glob_match`. Useful when path-scoped rules or lazy-loaded subdirectory CLAUDE.md files aren't behaving as expected.

### What Survives `/compact`

- **Project-root CLAUDE.md**: survives — Claude re-reads it from disk and re-injects it after `/compact`
- **Nested CLAUDE.md** in subdirectories, and rules with `paths:` frontmatter: NOT re-injected automatically — reload as Claude reads files they apply to
- **Auto memory**: not re-attached after compaction; `MEMORY.md` is read again on the next memory-relevant decision

If an instruction "vanishes" after `/compact`, it was either given only in conversation, lives in a nested CLAUDE.md that hasn't reloaded yet, or is a path-scoped rule that hasn't matched a file since. Add conversation-only instructions to CLAUDE.md to make them persist.

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
- First 200 lines (or 25KB, whichever is smaller) of `MEMORY.md` in system prompt each session

**Subagent memory scoping**: the *main conversation's* auto memory is a **separate directory** and is **NOT loaded into subagents** — the one exception is `subagent_type: "fork"`, which inherits the parent conversation and system prompt (and therefore its auto memory) wholesale. A subagent's own auto memory, enabled via its `memory` frontmatter field above, lives in its own directory independent of the parent's.

## Managed Settings Drop-In Directory (v2.1.83+)

`managed-settings.d/` directory supports independent policy fragments for modular organization-wide configuration. Each file in the directory is loaded as an independent policy fragment.

## Organization-Level Memory

Deploy centrally managed CLAUDE.md to the managed policy location via MDM, Group Policy, Ansible, etc.

## Memory Best Practices

- **Be specific**: "Use 2-space indentation" > "Format code properly"
- **Use structure**: Bullet points grouped under descriptive headings
- **Review periodically**: Update as project evolves
- **Don't duplicate**: Check existing memories before writing new ones
- **Stable patterns only**: Verify across multiple interactions before saving
- **Honor explicit requests**: When user says "always use X", save immediately
