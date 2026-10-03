# Claude Code Commands Reference

## What Are Commands?

Commands are user-invocable prompts stored in `.claude/commands/`. They provide:
- Quick access to common workflows
- Reusable prompt templates
- Project-specific operations
- Shorthand for complex tasks

## Directory Structure

```
.claude/commands/
├── prime.md           # Orient agent on codebase
├── install.md         # Setup/installation workflow
├── build.md           # Build from a plan
├── test.md            # Run tests
└── deploy.md          # Deployment workflow
```

### Locations
- **Project**: `.claude/commands/` (shared via git)
- **Global**: `~/.claude/commands/` (personal across all projects)

## Command Format

```yaml
---
description: Brief description shown in /help
allowed-tools: Bash, Read, Glob    # Optional: restrict tools
model: opus                         # Optional: specify model
argument-hint: [arg1] [arg2]        # Optional: show expected args
---

# Command content in markdown
```

## Invocation

```bash
# Basic invocation
/command-name

# With arguments
/command-name arg1 arg2

# Skill-specific command
/skill-name:command arg1
```

## Commands and Skills Merge

**This is the single most important correction as of v2.1.24x: custom commands have been
merged into skills.** From the official docs (`/docs/en/skills`):

> Custom commands have been merged into skills. A file at `.claude/commands/deploy.md` and a
> skill at `.claude/skills/deploy/SKILL.md` both create `/deploy` and work the same way. Your
> existing `.claude/commands/` files keep working. Skills add optional features: a directory
> for supporting files, frontmatter to control whether you or Claude invokes them, and the
> ability for Claude to load them automatically when relevant.

In practice:
- Files at `.claude/commands/review.md` and `.claude/skills/review/SKILL.md` both create `/review`
- Existing `.claude/commands/` files continue to work (backwards compatible) — there is no
  migration requirement
- Skills add optional features over a plain command file: a directory structure for
  supporting files/scripts, invocation-control frontmatter (who may invoke it — you, Claude,
  or both), and automatic loading when Claude judges the skill relevant to the task, even
  without an explicit `/name` invocation
- Built-in commands (`/help`, `/compact`, …) still execute fixed logic directly rather than
  loading a skill body; **bundled skills** (`/debug`, `/code-review`, `/doctor`, etc.) are
  shipped with Claude Code and invoked the same way as user-defined skills — see the
  categorized command list below for which built-ins are actually bundled skills

## Argument Syntax (v2.1.19+)

```yaml
# Shorthand (preferred)
USER_PROMPT: $0
OUTPUT_PATH: $1

# Bracket syntax
USER_PROMPT: $ARGUMENTS[0]
OUTPUT_PATH: $ARGUMENTS[1]

# All arguments
ALL_ARGS: $ARGUMENTS
```

## Common Command Patterns

### Prime Command
Orients the agent on a codebase:

```yaml
---
description: Prime agent on the codebase
allowed-tools: Bash, Read, Glob
---

# Purpose

Get oriented on the codebase. Read-only exploration.

## Instructions

- Do NOT modify any files
- Summarize what you learn
- Focus on key architecture decisions

## Workflow

- `git ls-files`
- Read `README.md`
- Read `CLAUDE.md` (if exists)
- Read `.claude/skills/*/SKILL.md`
- Read `ai_docs/*.md` (if exists, max 3 files)

## Report

Tell the user you're primed and summarize:
- Project structure
- Key technologies
- Important patterns
```

### Build Command
Implements from a plan file:

```yaml
---
description: Build the codebase based on a plan
argument-hint: [path-to-plan]
---

# Build

Follow the `Workflow` to implement the plan then `Report`.

## Variables

PATH_TO_PLAN: $ARGUMENTS

## Instructions

- Implement top to bottom, in order
- Do NOT stop between steps
- Make best-guess judgments based on the plan
- End with validation commands
- Fix issues before stopping

## Workflow

- If no `PATH_TO_PLAN` provided, STOP and ask user
- Read the plan at `PATH_TO_PLAN`
- Implement the entire plan before stopping

## Report

- Summarize work in bullet points
- Show files changed: `git diff --stat`
```

### Test Command
Runs test suite with analysis:

```yaml
---
description: Run tests and analyze failures
allowed-tools: Bash, Read, Grep
model: haiku
---

# Test

Run the test suite and provide analysis.

## Workflow

1. Detect test framework
2. Run tests
3. Parse failures
4. Suggest fixes

## Report

### Pass
```
All X tests passed in Y seconds.
Coverage: Z%
```

### Fail
```
## Failed Tests (X/Y)

### test_name (file:line)
- Expected: value
- Received: value
- Likely cause: [analysis]
- Fix: [suggestion]
```
```

### Install Command
Interactive installation workflow:

```yaml
---
description: Install skill/tool to the system
model: opus
---

# Install

Interactive installation with user prompts.

## Variables

GLOBAL_DIR: ~/.claude/
PROJECT_DIR: .claude/

## Workflow

### Step 1: Choose Location
Use AskUserQuestion:
```
Question: "Where to install?"
Options:
- Global (all projects)
- Project (this project)
- Cancel
```

### Step 2: Check Existing
- If exists: ask merge/overwrite/cancel
- If new: proceed to Step 3

### Step 3: Copy Files
- Create directories
- Copy files
- Update configuration

### Step 4: Verify
- Check files exist
- Show configuration

## Report

Installation summary with next steps.
```

### All-Skills Command
Lists available skills:

```yaml
---
description: List all available skills
---

# All Skills

List all available skills from your system prompt.
```

## Advanced Patterns

### Workflow Orchestration
Chain multiple commands:

```yaml
---
description: Full workflow - plan, build, test, deploy
argument-hint: [user_prompt]
---

# Full Workflow

## Variables

USER_PROMPT: $1
WORKFLOW_ID: workflow-<timestamp>

## Workflow

> Execute ALL steps. DO NOT STOP between steps.

1. **Plan**
   - Run `/skill:plan [USER_PROMPT]`
   - Capture: `PLAN_PATH`

2. **Build**
   - Run `/skill:build [PLAN_PATH]`
   - Validate before proceeding

3. **Test**
   - Run `/skill:test`
   - All tests must pass

4. **Deploy**
   - Run `/skill:deploy`
   - Report final URL

## Report

Complete workflow summary.
```

### Argument Handling
Handle optional arguments:

```yaml
---
description: Command with optional args
argument-hint: [required] [optional]
---

## Variables

REQUIRED_ARG: $1
OPTIONAL_ARG: $2 default "default_value" if not provided
```

### Conditional Routing
Route based on arguments:

```yaml
---
description: Multi-mode command
argument-hint: [mode] [options]
---

## Workflow

### Determine Mode

If `$1` is "install":
- Run installation workflow

If `$1` is "update":
- Run update workflow

If `$1` is "remove":
- Run removal workflow

If no mode specified:
- Use AskUserQuestion to determine mode
```

### Fork Terminal Pattern
Launch new terminal with command:

```yaml
---
description: Fork terminal with agentic tool
argument-hint: [tool] [prompt]
---

# Fork Terminal

## Variables

TOOL: $1 default "claude-code" if not provided
PROMPT: $2

## Instructions

- Run the fork tool to open new terminal
- Pass the prompt to the chosen agentic tool

## Workflow

1. Read `tools/fork_terminal.py`
2. Determine tool based on TOOL variable
3. Execute fork with PROMPT
```

## Commands vs Skills

| Aspect | Commands | Skills |
|--------|----------|--------|
| Location | `.claude/commands/` | `.claude/skills/name/` |
| Invocation | `/command-name` | Auto-discovered or `/skill name` |
| Structure | Single file | Directory with multiple files |
| Discovery | Explicit only | Auto or explicit |
| Use case | Quick actions | Complex domains |

## Built-in Commands (Current, v2.1.267) — 70+ Commands

`[Skill]` marks
a **bundled skill** (loaded/invoked like any skill, ships with Claude Code); `[Workflow]` marks
a bundled skill that only runs multi-step orchestration and is not auto-invoked; unmarked rows
execute fixed logic directly and are pure built-ins. `Hidden` means it does not appear in the
`/` command menu until typed in full.

### Project Setup & Initialization
| Command | Description | Version |
|---------|-------------|---------|
| `/init` | Initialize project with a `CLAUDE.md` guide. `CLAUDE_CODE_NEW_INIT=1` enables an interactive flow through skills, hooks, personal memory | — |
| `/memory` | Edit `CLAUDE.md` files; enable/disable and view auto-memory entries | — |
| `/mcp [reconnect\|enable\|disable]` | Manage MCP server connections and OAuth | Non-interactive mode v2.1.205+ |
| `/permissions` | Manage allow/ask/deny rules for tool permissions; runs immediately | Immediate opening v2.1.234+ |

### Session Management
| Command | Description | Version |
|---------|-------------|---------|
| `/clear [name]` | Start a new conversation with empty context; optional name labels the previous one | — |
| `/resume` | Return to an earlier conversation | — |
| `/branch [name]` | Fork the conversation into a new branch at the current point (was `/fork`) | Renamed v2.1.77+; `/fork` remains an alias historically |
| `/fork [prompt]` | Copy the current conversation into a new **background** session | v2.1.212+ |
| `/cd <path>` | Move the session to a new working directory, keeping the conversation | v2.1.169+ |
| `/add-dir <path>` | Add a working directory for file access during the session; runs immediately | Immediate confirmation v2.1.234+ |
| `/background [prompt]` | Detach the session to run as a background agent (alias `/bg`) | — |
| `/color [color\|default]` | Set/sync prompt-bar accent color; bare `/color` picks random | Non-interactive v2.1.205+ |
| `/export [filename]` | Export the current conversation as plain text | — |

### Model & Effort
| Command | Description | Version |
|---------|-------------|---------|
| `/model [model]` | Switch model; persists as default for new sessions; honors gateway model lists | Non-interactive v2.1.205+ |
| `/effort [low\|medium\|high\|xhigh\|max\|ultracode\|auto\|status]` | Set effort level (saved per model). `xhigh`, `max`, and `ultracode` are the newer top tiers above `high`; `max`/`ultracode` are session-only; works while Claude is mid-response. A level saved before `/effort` became per-model does not apply to newly released models such as Opus 5.5 (v2.1.280) | — |
| `/fast` | Toggle fast mode on/off | v2.1.205+; limited availability with `-p` non-interactive |
| `/advisor [model\|off]` | Enable/disable the advisor tool or pick its model | — |

### Code Review & Cleanup
| Command | Description | Version |
|---------|-------------|---------|
| `/code-review [level] [--fix] [--comment] [target]` | **[Skill]** Review a diff/PR for correctness bugs and cleanup opportunities at the given effort level; `--fix` applies findings, `--comment` posts inline PR comments; supports an ultra mode for cloud review | — |
| `/review` | **[Skill]** Alias for `/code-review` | — |
| `/simplify [low\|medium\|high\|xhigh\|max] [--fix] [path]` | **[Skill]** Simplify code for readability, performance, or bundle size at an effort level; `--fix` applies changes; quality-only, does not hunt bugs | — |
| `/security-review` | Check the current diff for security vulnerabilities | — |
| `/diff` | Interactive diff viewer for uncommitted changes and per-turn diffs; opens as a panel beside the conversation in fullscreen mode | Auto-refresh v2.1.198+; panel view v2.1.260+ |
| `/verify` | **[Skill]** Runs only when explicitly invoked (no longer auto-triggers) | Auto-invocation removed v2.1.215+ |

### Context & Workflow Management
| Command | Description | Version |
|---------|-------------|---------|
| `/context [all]` | Visualize context usage as a colored grid with optimization tips | — |
| `/compact [instructions]` | Free up context by summarizing the conversation | — |
| `/autocompact [auto\|<tokens>]` | Set the auto-compact window threshold | v2.1.221+ |
| `/plan [description]` | Enter plan mode; optional description starts planning immediately | v2.1.72+ |
| `/btw [question]` | Side question that sees full context but has no tools; discarded from history | Optional question v2.1.212+ |
| `/goal [condition\|clear\|stop\|off\|reset\|none\|cancel]` | Set a goal; Claude keeps working across turns until met. No argument shows current/last goal | — |

### Parallel Work & Agents
| Command | Description | Version |
|---------|-------------|---------|
| `/batch <instruction>` | **[Skill]** Orchestrate large-scale parallel changes across the codebase; decomposes into 5–30 units | — |
| `/loop [interval] [prompt]` | **[Skill]** Run a prompt (or slash command) repeatedly while the session stays open (alias `/proactive`); Esc cancels pending wakeups | — |
| `/subtask [prompt]` | Hand a side task to a subagent by **forking** the current conversation — the fork inherits full history, system prompt, model and prompt cache. Not listed on the commands docs page; sourced from [sub-agents docs](https://code.claude.com/docs/en/sub-agents) | Fork mode default since v2.1.232 |
| `/tasks` | List the session's background work, including completed subagents; runs immediately | — |
| `/agents` | Manage subagents | v2.1.198+: prints a reminder to ask Claude or edit `.claude/agents/` directly; no longer listed in the `/` menu or `/help` since v2.1.281, but typing it still explains |
| `/list-agents` | List subagents, agent-team teammates, and other Claude Code sessions Claude can message, with each one's name (alias `/peers`) | v2.1.224+ (earlier versions: "Unknown command"); teammate rows + own-session name line require v2.1.239+; needs cross-session messaging enabled |
| `/peers` | Alias for `/list-agents` | Same gating as `/list-agents` |

### Tools & Integrations
| Command | Description | Version |
|---------|-------------|---------|
| `/deep-research <question>` | **[Workflow]** Fan out web searches, fetch/cross-check sources, synthesize a cited report; explicit invocation only, not auto-triggered | v2.1.218+ |
| `/dataviz [request]` | **[Skill]** Design guidance for charts, graphs, dashboards with colorblind-safe palettes | v2.1.198+ |
| `/design [brief]` | **[Skill]** Draft UI mockups, screen flows, landing pages or posters as artboards on one canvas, published as a Design artifact | v2.1.265+; artifacts required (not on Bedrock/Vertex/Foundry) |
| `/design-sync [hint]` | **[Skill]** Convert a React design system and upload it to Claude Design | — |
| `/design-login` | Authorize design-system access for `/design-sync` | — |
| `/chrome` | Configure Claude in Chrome / select connected browser | — |
| `/workflow-authoring` | **[Skill]** Loads the dynamic-workflow script-writing reference; run before editing a saved `.claude/workflows/*.js` script | v2.1.248+ |

### Debugging & Troubleshooting
| Command | Description | Version |
|---------|-------------|---------|
| `/debug [description]` | **[Skill]** Enable debug logging and troubleshoot issues | — |
| `/doctor` | **[Skill]** Setup checkup: diagnoses/fixes installation issues, flags unused skills/servers/plugins | v2.1.205+/v2.1.206+ behavior changes (CLAUDE.md trim); stays typable when other skills are disabled |
| `/feedback [report]` | Send product feedback about Claude Code | — |
| `/bug [report]` | Report a bug or share the conversation (alias `/share`); opens immediately | Immediate opening v2.1.232+; query-string parsing removed v2.1.212+ |
| `/heapdump` | **Hidden.** Write a JS heap snapshot + memory breakdown to `~/Desktop` (or home dir on Linux without Desktop) for diagnosing high memory use. Attach only the `-diagnostics.json` file when reporting — the `.heapsnapshot` contains the full conversation and credentials | Hidden from menu; must type in full |

### Development Tools & References
| Command | Description | Version |
|---------|-------------|---------|
| `/claude-api [migrate\|upgrade\|managed-agents-onboard\|prompt-audit]` | **[Skill]** Loads Claude API/Managed Agents reference material; also auto-activates. `upgrade` migrates Python projects from `anthropic` SDK 0.x to 1.x | `prompt-audit` v2.1.221+; `upgrade` v2.1.239 |
| `/fewer-permission-prompts` | **[Skill]** Scan transcripts for common read-only calls, add a prioritized allowlist to `.claude/settings.json` | — |
| `/import [codex\|gemini\|cursor] [--dry-run] [--yes]` | Import configuration from OpenAI Codex, Google Gemini CLI or Cursor | v2.1.213+; Cursor v2.1.265+ |
| `/insights` | Generate an HTML report analyzing recent sessions/usage patterns on this machine; includes an estimate of how many permission prompts auto mode could have handled (v2.1.281) | Not available in cloud sessions |

### Settings & Configuration
| Command | Description | Version |
|---------|-------------|---------|
| `/config [key=value ...]` | Open the Settings interface; direct `key=value` set works in interactive, `-p`/print, and Remote Control sessions | Direct-set v2.1.181+ |
| `/settings` | Alias for `/config` | — |
| `/keybindings` | Open the keyboard-shortcuts file for customization | — |
| `/focus` | Toggle focus view (last prompt, tool-call summary, response only) | Fullscreen renderer only |
| `/theme [color]` | Create/switch/customize themes; plugins can ship themes; opens immediately | Immediate opening v2.1.234+ |
| `/auto-mode-setup` | Draft `autoMode.environment` entries from the project and past sessions | v2.1.228+; Pro/Max/Team |
| `/privacy-settings` | View and update privacy settings | Pro/Max plans only |

### GitHub & CI/CD
| Command | Description | Version |
|---------|-------------|---------|
| `/autofix-pr [prompt]` | Spawn a Claude Code web session watching a PR; pushes fixes on CI failure or new comments | — |
| `/install-github-app` | Install the Claude GitHub App, with optional GitHub Actions setup | — |

### Collaboration & Remote
| Command | Description | Version |
|---------|-------------|---------|
| `/install-slack-app` | Install the Claude Slack app via OAuth | — |
| `/remote-control` | Continue the local session from another device | — |
| `/desktop` / `/app` | Continue the session in the Claude Code Desktop app | macOS / x64 Windows only |
| `/teleport` | Pull a web session into the terminal | — |

### Status & Utilities
| Command | Description | Version |
|---------|-------------|---------|
| `/status` | Show session status; runs immediately | — |
| `/usage` / `/cost` | Token + cost breakdown (merged `/cost`/`/stats`); runs immediately | — |
| `/help` | Show help and available commands; opens immediately in fullscreen | Immediate opening v2.1.234+ |
| `/exit` / `/quit` | Exit the CLI; detaches a background session | — |
| `/copy [N]` | Copy the last (or Nth-latest) assistant response to the clipboard | v2.1.77+ |
| `/artifacts` | List artifacts you own or that are shared with you (this session's first), then attach one, open it, or copy its link. The `⧉` footer pill opens it (v2.1.281) | v2.1.208+ |
| `/output-style [style]` | List output styles or switch to one (e.g. `/output-style concise`); works headless and over Remote Control | v2.1.269+ |
| `/rewind` | Roll code/conversation back to a checkpoint, or summarize part of it | — |
| `/recap` | Generate a one-line session summary on demand | — |
| `/powerup` | Discover features via interactive lessons with animated demos | v2.1.90+ |
| `/release-notes` | View release notes with an interactive version picker | v2.1.92+ |
| `/login` / `/logout` | Sign in/out of the Anthropic account | — |
| `/mobile` / `/ios` / `/android` | Show a QR code to download the Claude mobile app | — |
| `/radio` | Open Claude FM lo-fi radio in the browser | — |
| `/upgrade` | Upgrade plan | Hidden on Enterprise plans |
| `/passes` | Share a free week of Claude Code with friends | Eligible accounts only |
| `/ide` | Manage IDE integrations and show status | — |
| `/hooks` | View hook configurations for tool events | — |
| `/plugin [subcommand]` | Manage Claude Code plugins | — |
| `/reload-plugins` | Reload active plugins | — |
| `/reload-skills` | Re-scan skill directories without restarting Claude Code | v2.1.152 |
| `/skills` | Browse and filter available skills, type-to-filter search box | v2.1.121+ |
| `/skill-doctor` | Show which loaded skills go unused and what they cost in context, so you can prune them; not available over Remote Control | v2.1.261+ |
| `/terminal-setup` | Enable iTerm2 clipboard access and other terminal integrations | v2.1.121+ |
| `/pr-comments [PR]` | **Removed** in v2.1.91 | Removed |

## Command Recognition Rules

- Commands are only recognized **at the start of a message** — typing `/foo` mid-sentence does
  nothing special
- Text following the command name becomes its **arguments**
- Typing `/` opens the command menu; typing `/` + letters filters it (typo-tolerant, with
  highlighting); some commands (e.g. `/heapdump`) stay hidden until typed in full
- **Queuing**: if you send a command while Claude is still responding, Claude Code **queues**
  it and runs it after the current turn finishes. Queued messages show in the conversation above
  the spinner (v2.1.281)
- **Send now** (`ctrl+enter`, or `ctrl+x ctrl+s`; v2.1.275+): sends all queued messages at once.
  Since v2.1.281 it moves running tools to the background instead of cancelling the turn
- **Immediate-execution exceptions** (do not wait for the turn to finish): `/status`,
  `/tasks`, `/usage` — and, as of **v2.1.234**, dialog commands (`/theme`, `/help`) and
  permission-related commands (`/permissions`, `/add-dir`). Before v2.1.234 those dialog
  commands were queued like everything else
- In fullscreen mode, dialog commands (`/theme`, `/help`) now open **immediately** (v2.1.234+)

## Skill Chaining

As of **v2.1.199**, skills are the one exception to "one command per message": a message can
chain **up to 6 skills**, e.g. `/skill-a /skill-b do XYZ` loads every named skill at the start
of the message and passes the trailing text (`do XYZ`) as arguments **to each of them**.

## Project Lifecycle

### `claude project purge [path]` (v2.1.126+)

Delete all Claude Code state for a project (transcripts, tasks, file history, config). Useful when a project's state is corrupted or you want a clean slate.

```bash
claude project purge --dry-run            # Show what would be deleted
claude project purge -y                   # Skip confirmation
claude project purge --interactive        # Pick which artifacts to delete
claude project purge --all                # Purge every tracked project
```

## Best Practices

1. **Keep commands focused**: One purpose per command
2. **Use allowed-tools**: Restrict to what's needed
3. **Provide argument hints**: Help users understand usage
4. **Include workflow**: Step-by-step for complex commands
5. **Report results**: Always summarize what was done
6. **Handle missing args**: Ask or fail gracefully
7. **Use models wisely**: haiku for simple, opus for complex

## Integration with Skills

Commands can invoke skill prompts:

```yaml
---
description: Invoke skill workflow
---

# Invoke Skill

## Workflow

1. Run `/skill-name:workflow-name [args]`
2. Process results
3. Report summary
```

Skills can define their own commands in `prompts/`:

```
.claude/skills/my-skill/
├── SKILL.md
└── prompts/
    ├── build.md      # \my-skill:build
    ├── test.md       # \my-skill:test
    └── deploy.md     # \my-skill:deploy
```
