# Claude Code CLI Reference

Reference for the `claude` binary itself (flags, modes, subcommands) — as opposed to
[COMMANDS.md](COMMANDS.md), which covers `/slash-commands` typed *inside* a session.

Source: `claude --help`, each subcommand's `--help`, and binary strings inspection
(for flags that exist but aren't listed in `--help`). Version referenced: **2.1.241**.

## General Structure

```
claude [options] [command] [prompt]
```

- With no `command` and no `-p`: starts an **interactive** session (default).
- `prompt` (positional arg) seeds the first user message; can also come from stdin
  (`echo "..." | claude -p`) or be omitted entirely (prompt typed inside the TUI).
- `command` picks a CLI subcommand (`mcp`, `agents`, `auth`, …) instead of starting a
  session — see [Subcommands](#subcommands).
- `-h`/`--help` and `-v`/`--version` work at every level: `claude --help`,
  `claude mcp --help`, `claude mcp add --help`.

## Modes

| Mode | Trigger | Behavior |
|------|---------|----------|
| **Interactive** | default (no `-p`) | Full TUI, persists to session history, resumable |
| **Print** | `-p`/`--print` | Non-interactive: prints the response and exits. Required by most scripting-oriented flags (`--output-format`, `--input-format`, `--fallback-model`, `--max-budget-usd`, `--no-session-persistence`, `--replay-user-messages`, `--forward-subagent-text`, `--include-partial-messages`). Skips the workspace-trust dialog — only use in trusted directories. Settings files that fail validation are silently ignored (no error dialog). |
| **Background** | `--bg`/`--background` | Starts as a background agent and returns immediately; manage with `claude agents`. |
| **Cloud** | `--cloud [description\|session_id\|url]` | Creates or attaches to a cloud-hosted session instead of a local one. |
| **Worktree** | `-w`/`--worktree [name]` | Creates a new git worktree for the session; combine with `--tmux` to also open it in a tmux session (native iTerm2 panes when available, or `--tmux=classic`). |
| **Remote Control** | `--remote-control [name]` | Interactive session with Remote Control enabled, so another device can continue it (`--remote-control-session-name-prefix` sets the auto-name prefix, default: hostname). |
| **Bare** | `--bare` | Minimal mode: skips hooks, LSP, plugin sync, attribution, auto-memory, background prefetches, keychain reads, CLAUDE.md auto-discovery. Sets `CLAUDE_CODE_SIMPLE=1`. Auth is strictly `ANTHROPIC_API_KEY` or `apiKeyHelper` via `--settings` (no OAuth/keychain). Third-party providers (Bedrock/Vertex/Foundry) still use their own credentials. Skills still resolve via `/skill-name`. Provide context explicitly: `--system-prompt[-file]`, `--append-system-prompt[-file]`, `--add-dir` (for CLAUDE.md dirs), `--mcp-config`, `--settings`, `--agents`, `--plugin-dir`. |
| **Safe Mode** | `--safe-mode` | Disables all customizations (CLAUDE.md, skills, plugins, hooks, MCP servers, custom commands/agents, output styles, workflows, custom themes, keybindings). Admin-managed policy settings still apply; auth, model selection, built-in tools, and permissions work normally. Sets `CLAUDE_CODE_SAFE_MODE=1`. For troubleshooting a broken configuration. |

`--bare` and `--safe-mode` solve different problems: `--bare` strips overhead/telemetry for
scripted, ephemeral runs; `--safe-mode` strips *customizations* to isolate whether a broken
skill/hook/plugin is the cause of a problem.

## Options by Category

### Session & Continuity
| Flag | Purpose |
|------|---------|
| `-c, --continue` | Continue the most recent conversation in the current directory |
| `-r, --resume [value]` | Resume by session ID, or open an interactive picker with an optional search term |
| `--fork-session` | With `--resume`/`--continue`: create a new session ID instead of reusing the original |
| `--session-id <uuid>` | Use a specific session ID for the conversation (must be a valid UUID) |
| `--from-pr [value]` | Resume a session linked to a PR by PR number/URL, or open an interactive picker |
| `--teleport [session]` | Resume a teleport (pulled-in web) session, optionally by ID |
| `-n, --name <name>` | Display name for this session (shown in the prompt box, `/resume` picker, terminal title) |

### Directories & Context
| Flag | Purpose |
|------|---------|
| `--add-dir <directories...>` | Grant additional directories tool access (also used for extra CLAUDE.md discovery under `--bare`) |
| `--setting-sources <sources>` | Comma-separated: which of `user, project, local` settings to load |
| `--settings <file-or-json>` | Path to a settings JSON file, or a JSON string, to load additional settings from |
| `--exclude-dynamic-system-prompt-sections` | Moves per-machine sections (cwd, env info, memory paths, git status) from the system prompt into the first user message, to improve cross-user prompt-cache reuse. Only applies with the default system prompt (ignored with `--system-prompt`). Default: `false`. |

### System Prompt
| Flag | Purpose |
|------|---------|
| `--system-prompt <prompt>` | Replace the default system prompt entirely |
| `--system-prompt-file <file>` | Same, from a file. **Undocumented** (not shown in `--help`, confirmed via binary strings). Mutually exclusive with `--system-prompt` — passing both errors: `Cannot use both --system-prompt and --system-prompt-file`. |
| `--append-system-prompt <prompt>` | Append to the default system prompt instead of replacing it |
| `--append-system-prompt-file <file>` | Same, from a file. **Undocumented.** Mutually exclusive with `--append-system-prompt` — same error pattern. |

### Model & Effort
| Flag | Purpose |
|------|---------|
| `--model <model>` | Model for the session — an alias (`fable`, `opus`, `sonnet`, `haiku` → latest of that family) or a full model name (e.g. `claude-opus-5`) |
| `--effort <level>` | `low, medium, high, xhigh, max` |
| `--fallback-model <model>` | Automatic fallback when the primary is overloaded/unavailable. Comma-separated list tried in order; primary is retried at the start of each user turn. **Print mode only.** |
| `--autocompact <auto\|tokens>` | Auto-compact window size: `auto`, or an explicit `100k`–`1M` token count |
| `--max-budget-usd <amount>` | Maximum dollars to spend on API calls. **Print mode only.** |

### Tools & Permissions
| Flag | Purpose |
|------|---------|
| `--tools <tools...>` | Restrict the built-in tool set. `""` disables all tools, `"default"` uses all, or name specific tools (e.g. `"Bash,Edit,Read"`) |
| `--allowedTools, --allowed-tools <tools...>` | Allow-list, comma or space separated (e.g. `"Bash(git *) Edit"`) |
| `--disallowedTools, --disallowed-tools <tools...>` | Deny-list, same syntax |
| `--permission-mode <mode>` | `acceptEdits, auto, bypassPermissions, manual, dontAsk, plan` |
| `--dangerously-skip-permissions` | Bypass all permission checks outright. Sandboxes with no internet access only. |
| `--allow-dangerously-skip-permissions` | Make bypass-permissions *available as an option* for the session, without enabling it by default (weaker than `--dangerously-skip-permissions`) |
| `--disable-slash-commands` | Disable all skills (despite the flag name, this disables skills, not just `/commands`) |

### MCP & Plugins
| Flag | Purpose |
|------|---------|
| `--mcp-config <configs...>` | Load MCP servers from JSON files or JSON strings (space-separated) |
| `--strict-mcp-config` | Only use MCP servers from `--mcp-config`, ignoring every other MCP source |
| `--plugin-dir <path>` | Load a plugin from a directory or `.zip` for this session only (repeatable) |
| `--plugin-url <url>` | Fetch a plugin `.zip` from a URL for this session only (repeatable) |

### Agents
| Flag | Purpose |
|------|---------|
| `--agent <agent>` | Default agent for the session; overrides the `agent` setting |
| `--agents <json>` | Define custom agents inline, e.g. `'{"reviewer": {"description": "Reviews code", "prompt": "You are a code reviewer"}}'` |

### Print-Mode I/O (all require `-p`)
| Flag | Purpose |
|------|---------|
| `--output-format <format>` | `text` (default), `json` (single result), or `stream-json` (realtime streaming) |
| `--input-format <format>` | `text` (default) or `stream-json` (realtime streaming input) |
| `--include-partial-messages` | Stream partial message chunks as they arrive (needs `--output-format=stream-json`) |
| `--include-hook-events` | Include all hook lifecycle events in the output stream (needs `--output-format=stream-json`) |
| `--replay-user-messages` | Re-emit user messages from stdin back on stdout for acknowledgment (needs `--input-format=stream-json` **and** `--output-format=stream-json`) |
| `--forward-subagent-text` | Forward subagent text/thinking blocks as assistant/user messages with `parent_tool_use_id` set (needs `--output-format=stream-json`) |
| `--json-schema <schema>` | JSON Schema for structured output validation |
| `--no-session-persistence` | Don't save the session to disk (so it can't be resumed) |
| `--prompt-suggestions [value]` | Emit a `prompt_suggestion` message predicting the next user prompt, after each turn (`true/false/1/0/yes/no/on/off`, preset `true`) |

### Worktree, Remote & Cloud
| Flag | Purpose |
|------|---------|
| `-w, --worktree [name]` | Create a new git worktree for this session |
| `--tmux` | Create a tmux session for the worktree (requires `-w`). Native iTerm2 panes when available; `--tmux=classic` for a traditional tmux session. |
| `--remote-control [name]` | Interactive session with Remote Control enabled |
| `--remote-control-session-name-prefix <prefix>` | Prefix for auto-generated Remote Control session names (default: hostname) |
| `--cloud [description\|session_id\|url]` | Create/attach a cloud session |
| `--environment <environment_id>` | Run a new cloud session on a given self-hosted environment (`ccpool_...`) |
| `--chrome` / `--no-chrome` | Force-enable / disable the Claude in Chrome integration |
| `--ide` | Auto-connect to the IDE on startup if exactly one valid IDE is available |

### Diagnostics
| Flag | Purpose |
|------|---------|
| `-d, --debug [filter]` | Debug mode, optionally category-filtered (e.g. `"api,hooks"` or `"!1p,!file"`) |
| `--debug-file <path>` | Write debug logs to a specific path (implicitly enables debug mode) |
| `--verbose` | Override the verbose-mode config setting |
| `--ax-screen-reader` | Render screen-reader-friendly output: flat text, no borders/animations |

### Misc
| Flag | Purpose |
|------|---------|
| `--file <specs...>` | Download file resources at startup, `file_id:relative_path` pairs (e.g. `--file file_abc:doc.txt file_def:img.png`) |
| `--brief` | Enable the `SendUserMessage` tool for agent-to-user communication |
| `--betas <betas...>` | Beta headers to include in API requests (API key users only) |

## Subcommands

Each subcommand has its own `--help`; only the shape is summarized here.

| Subcommand | Purpose |
|------------|---------|
| `claude agents [options]` | Manage background agents. Has its own dispatch-time flags mirroring the top-level ones (`--model`, `--effort`, `--permission-mode`, `--mcp-config`, `--settings`, `--plugin-dir`, `--add-dir`, `--agent`, `--cwd`, `--strict-mcp-config`, `--setting-sources`) plus `--json` (machine-readable session list, no TTY needed) and `--all` (include completed sessions with `--json`) |
| `claude auth` | `login`, `logout`, `status` — manage Anthropic account authentication |
| `claude auto-mode` | `config`, `defaults`, `critique`, `reset` — inspect/reset the auto-mode classifier |
| `claude doctor` | Health-check the installation; reads current-directory settings without a trust prompt. Full checkup with fixes: run `/doctor` inside a session instead. |
| `claude gateway [options]` | Run the enterprise auth/telemetry gateway (`--config <path>` for a YAML config) |
| `claude import [options] [source]` | Import config from another agent (`codex`, `gemini`); `--dry-run`, `--yes[=<digest>]` |
| `claude install [options] [target]` | Install a Claude Code native build; `[target]` = `stable`, `latest`, or a specific version; `--force` to reinstall |
| `claude mcp` | `add`, `add-from-claude-desktop`, `add-json`, `get`, `list`, `login`, `logout`, `remove`, `reset-project-choices`, `serve` — configure MCP servers |
| `claude plugin` / `plugins` | `init\|new`, `install\|i`, `uninstall\|remove`, `update`, `enable`, `disable`, `list`, `details`, `validate`, `eval`, `tag`, `prune\|autoremove`, `marketplace` — manage plugins |
| `claude project` | `purge [path]` — delete all Claude Code state for a project (transcripts, tasks, file history, config entry); `--dry-run`, `-y`, `--interactive`, `--all` |
| `claude setup-token` | Set up a long-lived auth token (requires a Claude subscription) |
| `claude ultrareview [options] [target]` | Cloud-hosted multi-agent code review of the current branch (or a PR number/base branch); `--json`, `--post`/`--no-post` (default), `--timeout <minutes>` |
| `claude update` / `upgrade` | Check for updates and install if available |

## Examples

```bash
# Interactive session with an extra allowed directory
claude --add-dir ../shared-lib

# One-shot scripted call, JSON output, restricted tools
claude -p "summarize the diff" --output-format json --allowedTools "Bash(git diff) Read"

# Pipe a prompt in, get raw text back, no session saved
git diff | claude -p "review this diff" --no-session-persistence

# Resume the last conversation in this directory
claude -c

# Resume a specific session, but branch it into a new session ID
claude -r abc123 --fork-session

# Replace the system prompt from a file (undocumented flag)
claude --system-prompt-file ./prompts/reviewer.md -p "check this PR"

# Append extra guidance without touching the default system prompt
claude --append-system-prompt "Always answer in French"

# Minimal, fast, scripted run with explicit context (no CLAUDE.md, no hooks)
claude --bare --settings '{"apiKeyHelper": "echo $ANTHROPIC_API_KEY"}' -p "lint this file"

# Troubleshoot: rule out a broken skill/hook by disabling all customizations
claude --safe-mode

# Bypass permission prompts entirely (sandboxed/CI use only)
claude --dangerously-skip-permissions -p "run the migration script"

# Open a new worktree in its own tmux session
claude -w feature-branch --tmux

# Cap spend and add a fallback model for an unattended batch job
claude -p "generate the report" --max-budget-usd 2.00 --fallback-model claude-sonnet-5

# Structured output validated against a schema
claude -p "extract the fields" --output-format json \
  --json-schema '{"type":"object","properties":{"name":{"type":"string"}},"required":["name"]}'

# Inline custom agent for this session only
claude --agents '{"reviewer": {"description": "Reviews code", "prompt": "You are a strict code reviewer"}}' --agent reviewer

# Strict MCP: only the servers passed here, nothing from project/user config
claude --mcp-config ./ci-mcp.json --strict-mcp-config -p "list available tools"

# List background/interactive sessions as JSON, including completed ones
claude agents --json --all
```

## Interactions Between Options

- **`-p`/`--print` gates a whole family of flags** — `--output-format`, `--input-format`,
  `--fallback-model`, `--max-budget-usd`, `--no-session-persistence`,
  `--replay-user-messages`, `--forward-subagent-text`, `--include-partial-messages`,
  `--include-hook-events` all require it and are silently inert (or rejected) without it.
- **System prompt flags are pairwise exclusive**: `--system-prompt` XOR
  `--system-prompt-file`; `--append-system-prompt` XOR `--append-system-prompt-file`.
  Passing both sides of a pair errors out before the session starts. The plain and
  `-file` variants of *different* pairs (e.g. `--system-prompt` + `--append-system-prompt-file`)
  combine fine — replace, then append.
- **`--exclude-dynamic-system-prompt-sections` only applies with the default system
  prompt** — it's ignored the moment `--system-prompt` replaces it (nothing dynamic left
  to relocate).
- **`--tmux` requires `-w`/`--worktree`** — it has no effect (and isn't meaningful) without
  a worktree to attach to.
- **`--dangerously-skip-permissions` vs `--allow-dangerously-skip-permissions`**: the first
  *enables* bypass mode immediately for this run; the second only makes bypass mode
  *selectable* (e.g. from within `claude agents` dispatch) without turning it on by default.
  `claude agents --dangerously-skip-permissions` is documented as an alias for
  `--permission-mode bypassPermissions` in that subcommand specifically.
- **`--fork-session` only matters with `--resume`/`--continue`** — on a fresh session there
  is nothing to fork from.
- **`--bare` narrows how auth can work**: strictly `ANTHROPIC_API_KEY` or `apiKeyHelper` via
  `--settings`; OAuth and keychain reads are never consulted. Third-party providers
  (Bedrock/Vertex/Foundry) are unaffected since they use their own credential paths. Because
  CLAUDE.md auto-discovery is off, feed context back in explicitly with `--add-dir`,
  `--system-prompt[-file]`/`--append-system-prompt[-file]`, `--mcp-config`, `--settings`,
  `--agents`, `--plugin-dir`.
- **`--safe-mode` vs `--bare`**: safe mode keeps hooks/telemetry/auth behavior normal but
  turns off *customization sources* (CLAUDE.md, skills, plugins, hooks, MCP, custom
  commands/agents, output styles, workflows, themes, keybindings); admin-managed policy
  settings still apply. Bare mode keeps customizations reachable (skills still resolve via
  `/skill-name`) but strips runtime overhead and defaults auth down to API-key-only. They
  can be combined, but they solve different problems (see [Modes](#modes)).
  Both set a marker env var (`CLAUDE_CODE_SAFE_MODE=1` / `CLAUDE_CODE_SIMPLE=1`) other tools
  (hooks, MCP servers) can check for.
- **`--allowedTools`/`--disallowedTools` operate on top of `--tools`** — `--tools` decides
  which built-in tools *exist* for the session at all; the allow/deny lists then filter
  usage of whatever set that leaves (including fine-grained patterns like `Bash(git *)`).
- **`--strict-mcp-config` overrides every other MCP source** — project `.mcp.json`, user
  config, and managed config are all ignored once it's set; only `--mcp-config` counts.
- **`claude agents` mirrors top-level session flags** for the sessions it *dispatches*, not
  for itself — e.g. `claude agents --model X` sets the default model for sessions launched
  from the agent view, not a model for `claude agents` as a command.
