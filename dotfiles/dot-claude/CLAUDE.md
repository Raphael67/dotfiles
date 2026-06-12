Global Claude Configuration

## Personal Development Environment

- **Shell**: Zsh with oh-my-zsh
  - Source `~/.zshrc` at startup to load nvm and other shell configurations
- **Terminal**: Ghostty
- **Editor**: VSCode
- **Package Manager**: Homebrew
- **Timezone**: Europe/Paris (CET/CEST)

## Quick Reference

| Task | Approach |
|------|----------|
| New TypeScript project | bun init, bun add |
| New Python project | uv init, uv add |
| Browser debugging | bdg CLI |
| Library docs lookup | context7 MCP |
| Code change impact / what functions changed | `sem` (entity diff, blast radius) — see below |
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

- **Agents**: Always check if a subagent is more appropriate to do a task. Prefer `/pthread` (mprocs) over background subagents so the user can see agent activity in real time and interact directly
- **Skills**: Never update or alter a skill without explicit user request
- **Planning**: When in plan mode (or otherwise about to present a non-trivial implementation plan or design), invoke the `grill-me` skill first — interview me one question at a time to resolve open decisions before finalizing the plan. Skip for trivial, single-step, or unambiguous tasks.
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

## File Recovery (Emergency)

Two recovery methods are available when files are lost or corrupted by Claude Code.

### Method 1: claude-file-recovery (recommended)

Reconstructs files by replaying Write/Edit/Read operations from session transcripts.

```bash
# Interactive TUI — browse, search, diff, and extract files
claude-file-recovery tui

# List all recoverable files (filter with glob/regex/fuzzy)
claude-file-recovery list-files
claude-file-recovery list-files -f "*.tsx"
claude-file-recovery list-files -f "router" -m fuzzy

# Recover files at a specific point in time
claude-file-recovery list-files --before "2026-03-01 15:00"

# Extract files to disk
claude-file-recovery extract-files -f "src/components/*" -o /tmp/recovered
```

### Method 2: file-history-snapshot (raw backups)

Claude Code saves pre-edit file snapshots in `~/.claude/file-history/<session-id>/`. Each backup is a plain copy of the file before modification.

```bash
# 1. Find the session ID from the transcript that modified your file
grep -r "your-filename" ~/.claude/projects/*/sessions-index.json

# 2. List backups for that session
ls ~/.claude/file-history/<session-id>/

# 3. Map backup filenames to original paths — look in the transcript
cat ~/.claude/projects/<project>/<session-id>.jsonl | \
  python3 -c "
import json, sys
for line in sys.stdin:
    obj = json.loads(line)
    if obj.get('type') == 'file-history-snapshot':
        for path, info in obj['snapshot']['trackedFileBackups'].items():
            print(f\"{info['backupFileName']} -> {path} ({info['backupTime']})\")"

# 4. Copy the backup to restore it
cp ~/.claude/file-history/<session-id>/<hash>@v1 /path/to/restore
```

**Key difference**: `claude-file-recovery` replays tool operations from transcripts (Write/Edit/Read). `file-history-snapshot` stores actual file copies taken before each edit. Use snapshots when the tool call replay doesn't capture the file (e.g., Bash-based edits).

## Security & Best Practices

- Never commit secrets or API keys
- Use `bw-fetch` to retrieve credentials at runtime (see above)
- Always review changes before committing
- Prefer explicit imports over wildcards

### Security Hook System (damage-control)

All bash commands pass through a three-state security hook before execution:

| Decision | Meaning | Examples |
|----------|---------|---------|
| `allow` | Run silently, no friction | git status, npm install, stow |
| `confirm` | Ask user before running | rm -rf, git reset --hard, DROP TABLE |
| `block` | Blocked unconditionally | mkfs, dd to /dev/, kill -9 -1 |

Path-based rules (independent of bash patterns):
- **Zero-access paths**: SSH keys (`~/.ssh/`), GPG (`~/.gnupg/`), cloud creds (`~/.aws/`, `~/.kube/`), cert files (`*.pem`, `*.key`) — blocked for all access including reads
- **Read-only paths**: System dirs (`/etc/`, `/usr/`), lock files, build artifacts — writes blocked, reads allowed
- **No-delete paths**: `~/.claude/`, git dir, license/readme files — reads/writes allowed, deletion blocked

Config files: `~/.claude/hooks/damage-control/patterns.yaml` (patterns) and `bash-tool-damage-control.py` (logic).

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

## Asking the User Questions

**Applies to the main agent and every spawned subagent.** When you need information from the user:

1. **Always use the `AskUserQuestion` tool** — never ask in plain prose when the tool is available. It renders a proper interactive prompt with structured options.
2. **Ask exactly ONE question at a time.** Send the question, wait for the user's answer, then ask the next one based on the reply.
3. **Never batch questions** — no numbered lists ("1. ... 2. ... 3. ..."), no multi-part prompts, no "while we're at it, also..." follow-ups in the same turn.
4. **Sequential, not parallel.** Even if you have five things you want to clarify, ask the first, get the answer, then decide whether the next question is still needed (often the first answer makes later ones obsolete).
5. **If `AskUserQuestion` is not loaded** (e.g., a constrained subagent), fetch it via `ToolSearch` first, or fall back to a single plain-text question — still one at a time.

Rationale: batched questions force the user to context-switch across unrelated decisions, and earlier answers usually reshape later questions. Sequential asking is faster end-to-end and produces better answers.

## Available Tools

### context7 MCP (Library Documentation)

Fetch up-to-date documentation for libraries:
- Before implementing unfamiliar APIs
- When Stack Overflow answers seem outdated
- For framework-specific patterns (React, NestJS, etc.)

**Usage**: Use `resolve-library-id` to find the library, then `query-docs` to fetch relevant sections.

**Key features:**
- All 644 CDP protocol methods available
- Self-documenting via `--list`, `--describe`, `--search`
- JSON output by default (pipe to `jq` for processing)
- Semantic exit codes for error handling

### sem — Semantic Code Analysis (entity-level diff & blast radius)

`sem` parses code with tree-sitter and diffs at the **entity level** (functions, classes,
methods) instead of lines. Use it whenever you need to reason about *what code units changed*
or *what a change might break* — far more precise than `git diff` for impact reasoning.

**Prefer `sem` over `git diff` when** answering "what functions changed?", "what does this
change affect?", or building context about a specific entity before editing it.

```bash
sem diff --staged              # Entity-level diff of staged changes (the pre-commit hook)
sem diff                       # Working-tree changes
sem diff --commit <sha>        # Changes in a specific commit
sem impact <entity>            # Blast radius: everything depending on <entity>
sem impact <entity> --deps     # Direct dependencies only
sem impact <entity> --tests    # Affected tests
sem blame <file>               # Who last changed each function/class
sem log <entity>               # How a single entity evolved over time
sem entities <file>            # List all code units in a file
sem context <entity> --budget 4000   # Token-budgeted LLM context for an entity
```

- **For agents/automation, add `--format json`** (or `--json`) — e.g. `sem diff --staged --format json`.
- **MCP**: the `sem` server (`sem mcp`, registered in `~/.mcp.json`) exposes 6 tools —
  `sem_entities`, `sem_diff`, `sem_blame`, `sem_impact`, `sem_log`, `sem_context`. Use these
  directly when available.
- Installed via cargo on every platform (listed in `rust/packages.txt` in the dotfiles repo):
  `cargo install sem-cli` — provides the `sem` binary.

### GitNexus — Code Intelligence Platform

GitNexus indexes any codebase into a knowledge graph with 16 MCP tools for agents. Use it to understand unfamiliar code, analyze impact before changes, and trace execution flows.

**Installation & MCP:**
```bash
npm install -g gitnexus@latest
gitnexus setup          # Register MCP server with Claude Code (one-time)
```

**On new machines, auto-index key repos:**
```bash
bash ~/Projects/dotfiles/scripts/setup-gitnexus.sh
```

**Core Commands:**

| Command | Purpose |
|---------|---------|
| `gitnexus analyze /path` | Index a repository into `.gitnexus/` |
| `gitnexus list` | Show all indexed repos |
| `gitnexus status` | Check index staleness (vs. git HEAD) |
| `gitnexus context <symbol>` | View symbol callers/callees/types |
| `gitnexus query "term"` | Search codebase (BM25 + semantic) |
| `gitnexus impact <target>` | Blast radius analysis (what breaks if we change this?) |
| `gitnexus mcp` | Start MCP server (stdio) — called by Claude Code automatically |
| `gitnexus serve` | Start HTTP API + web UI on :4747 |
| `gitnexus wiki` | Generate LLM-powered codebase docs |
| `gitnexus clean --all` | Delete all indexes (cacheable, regenerate anytime) |

**Using MCP Tools in Claude Code:**

Once MCP is registered (`gitnexus setup`), agents can call these tools directly:

- **Find unfamiliar code**: Use `query` or `context` to understand symbol relationships
- **Before refactoring**: Use `impact` to understand blast radius
- **Analyzing diffs**: Use `detect_changes` to map Git changes to code units
- **Architecture docs**: Use `generate_map` prompt to generate Mermaid diagrams
- **Cross-repo safety**: Use group tools for multi-repo coordination

**Configuration:**

- **Global config:** `~/.config/gitnexus/config.json` (symlinked from dotfiles)
- **Per-repo overrides:** `.gitnexusrc` in repo root (optional, local, not stowed)
- **Environment variables:** `GITNEXUS_WORKER_POOL_SIZE`, `GITNEXUS_SKIP_OPTIONAL_GRAMMARS`, etc.

**Generated Skills:**

After indexing, GitNexus generates agent skills:
- `./.claude/skills/gitnexus/` — Built-in skills (exploring, debugging, impact analysis, refactoring, PR review)
- `./.claude/skills/generated/` — Auto-generated per functional area (one skill per Leiden cluster)

Use `gitnexus analyze --skills` to regenerate per-repo skills.

**Indexed Repositories:**

Auto-indexed on setup:
- `~/Projects/dotfiles` (cross-machine dev config)
- `~/Projects/keymaging/meta` (key project)

Manually index other repos:
```bash
cd /path/to/repo && gitnexus analyze
```

Index is stored in `.gitnexus/` (gitignored, cache-like, regenerable).

**Troubleshooting:**

- **Stale index?** → `gitnexus status` shows staleness; re-run `gitnexus analyze` to refresh
- **Missing symbol?** → May be below parse threshold (block-local); check symbol scope in `context`
- **Slow indexing?** → Check `GITNEXUS_SKIP_OPTIONAL_GRAMMARS=1` if C++ build is slow; embeddings add 20-50% time
- **MCP not appearing?** → Run `gitnexus setup` and restart Claude Code

@RTK.md
