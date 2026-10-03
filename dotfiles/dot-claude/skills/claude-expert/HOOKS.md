# Claude Code Hooks Reference

## What Are Hooks?

Hooks are scripts or prompts that execute in response to Claude Code events. They can validate, block, modify, or log operations.

## Hook Events

The docs now enumerate **31 hook events** (plus `Setup`, documented separately below). Grouped
by area:

**Per-turn / session lifecycle**

| Hook | Trigger | Use Case |
|------|---------|----------|
| `SessionStart` | Session begins/resumes | Environment setup (execution deferred at startup for performance). Can't block; supports `additionalContext`, `reloadSkills`, `sessionTitle`. On a resume, the input also carries session staleness and the estimated prompt-cache re-cache cost (v2.1.251+), so a hook can warn or act differently on a stale/expensive resume |
| `SessionEnd` | Session terminates | Cleanup, logging. Reasons: `clear`, `resume`, `logout`, `prompt_input_exit`, `bypass_permissions_disabled`, `other` |
| `UserPromptSubmit` | When user sends a message | Logging, preprocessing. Can block (erases the prompt); supports `additionalContext` |
| `UserPromptExpansion` | Before slash command expansion | Block or add context to command expansion. Matcher = command name |
| `Stop` | When Claude finishes responding | Notifications, cleanup. Input includes `last_assistant_message`. Can force continuation via `decision: "block"` |
| `StopFailure` | Turn ends due to API error (v2.1.78+) | Rate-limit/error recovery. **Output and exit code ignored** except `terminalSequence`. Matchers: `rate_limit`, `overloaded`, `authentication_failed`, `oauth_org_not_allowed`, `account_on_hold`, `billing_error`, `invalid_request`, `model_not_found`, `server_error`, `max_output_tokens`, `cloud_credential_error` (v2.1.267+), `unknown` |

**Tool execution**

| Hook | Trigger | Use Case |
|------|---------|----------|
| `PreToolUse` | Before tool execution | Security validation, blocking dangerous commands |
| `PostToolUse` | After tool execution | Logging, notifications |
| `PostToolUseFailure` | After tool fails | Error handling |
| `PostToolBatch` | After a full batch of parallel tool calls resolves | Stop the agentic loop before the next model call. No matcher support |
| `PermissionRequest` | Permission dialog shown | Dynamic permission decisions via `hookSpecificOutput.decision`. Supports `command`, `http`, `mcp_tool`, `prompt` — **not `agent`** (skipped with an error since v2.1.280). Fires in `--print` mode since v2.1.268 |
| `PermissionDenied` | Permission auto-denied by classifier (v2.1.89+) | React to denied operations, logging, recovery. Can set `retry: true` so the model may retry |

**Subagents & tasks**

| Hook | Trigger | Use Case |
|------|---------|----------|
| `SubagentStart` | When subagent spawns | Monitoring initialization. Matcher = agent type (`general-purpose`, `Explore`, `Plan`, custom names, plugin-scoped `my-plugin:reviewer`) |
| `SubagentStop` | When subagent finishes | Logging results. Input includes `last_assistant_message`, `agent_transcript_path`. Can block (`decision: "block"`) |
| `TeammateIdle` | Agent team teammate about to go idle | Quality gates, prevent idle. No matcher support |
| `TaskCreated` | Task created via TaskCreate (v2.1.84+) | Task validation, logging. Can block (rolls back the creation) |
| `TaskCompleted` | Task being marked as completed | Enforce completion criteria. Can block |

**Files & directories**

| Hook | Trigger | Use Case |
|------|---------|----------|
| `FileChanged` | File changes detected (v2.1.83+) | Auto-linting, file watchers. Matcher = literal filenames to watch, e.g. `.envrc\|.env` |
| `CwdChanged` | Working directory changes (v2.1.83+) | Reactive environment management. No matcher support |
| `DirectoryAdded` | A working directory is added mid-session | React to new directory scope. Matchers: `slash_command`, `register_repo_root` |
| `WorktreeCreate` | Git worktree created (via `--worktree` or `isolation: "worktree"`) | Worktree setup, replaces default git behavior (v2.1.69+). Supports `type: "http"` (v2.1.84+). Non-zero exit fails creation |
| `WorktreeRemove` | Git worktree removed (session exit or subagent finish) | Worktree cleanup (v2.1.69+). Failures logged in debug mode only |

**Configuration & context**

| Hook | Trigger | Use Case |
|------|---------|----------|
| `ConfigChange` | Configuration file changes during session | React to settings/skills changes. Matchers: `user_settings`, `project_settings`, `local_settings`, `policy_settings`, `skills` (v2.1.72+). Can block (except `policy_settings`) |
| `InstructionsLoaded` | After CLAUDE.md/rules/skills loaded | Post-instruction setup (v2.1.69+). Fires at session start and lazily during session. Matchers: `session_start`, `nested_traversal`, `path_glob_match`, `include`, `compact` |

**Model switching**

| Hook | Trigger | Use Case |
|------|---------|----------|
| `PreModelSwitch` | Before a model switch takes effect (v2.1.251+) | Block, confirm, or annotate a model switch. Matcher = model name (e.g. `claude-opus-5`, `.*opus.*`). Can block |
| `PostModelSwitch` | After a model switch completes (v2.1.251+) | React to the new model (e.g. re-check effort/tool assumptions). Matcher = model name. Feedback only |

**MCP & elicitation**

| Hook | Trigger | Use Case |
|------|---------|----------|
| `Elicitation` | When an MCP server requests user input (v2.1.76+) | MCP input decisions. Matcher = MCP server name. Can block (denies the elicitation) |
| `ElicitationResult` | After user responds to MCP elicitation (v2.1.76+) | MCP response filtering. Can block (forces the response to decline) |

**Notification & display**

| Hook | Trigger | Use Case |
|------|---------|----------|
| `Notification` | Claude sends notification | Desktop notifications. Matchers: `permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog`, `elicitation_url_dialog`, `elicitation_complete`, `elicitation_response`, `agent_needs_input`, `agent_completed`, `quota_auto_resume_fired`, `quota_auto_resume_stale`, `quota_auto_resume_disabled` (the three `quota_auto_resume_*` fire when a claude.ai usage-limit wait ends; v2.1.234+). **`permission_prompt` fires for permission dialogs as of v2.1.233+** — before that, permission prompts did not raise `Notification` |
| `MessageDisplay` | Assistant message about to be displayed (v2.1.152) | Transform or hide assistant message text during display. No matcher support |

**Compaction**

| Hook | Trigger | Use Case |
|------|---------|----------|
| `PreCompact` | Before context compaction | Pre-compaction actions. Matchers: `manual`, `auto`. Can block |
| `PostCompact` | After context compaction completes (v2.1.76+) | Post-compaction actions. Matchers: `manual`, `auto` |

## Setup Hook (claude --init)

The Setup hook fires when Claude enters a repository. It has two trigger modes:

| Trigger | When | Use Case |
|---------|------|----------|
| `init` | First time entering a repo (`claude --init`) | Install dependencies, set env vars, gather project info |
| `maintenance` | Periodically in existing repos | Log cleanup, git gc, health checks |

### CLI Flags

| Flag | Behavior |
|------|----------|
| `claude --init` | Enter repo and run Setup hook with `trigger: "init"` |
| `claude --init-only` | Run Setup hook and exit (no conversation) |
| `claude --maintenance` | Run Setup hook with `trigger: "maintenance"` |

### Setup Hook Input

```json
{
  "session_id": "abc123",
  "transcript_path": "/path/to/transcript.jsonl",
  "cwd": "/path/to/project",
  "permission_mode": "default",
  "hook_event_name": "Setup",
  "trigger": "init"
}
```

### Setup Hook Output (additionalContext)

Setup hooks can inject context into the session via `additionalContext`:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "Setup",
    "additionalContext": "Project: Node.js app\nGit branch: main\nDeps: node v20, uv 0.5"
  }
}
```

### Environment Persistence (CLAUDE_ENV_FILE)

During Setup hooks, `CLAUDE_ENV_FILE` is available to persist environment variables across the session:

```python
env_file = os.environ.get('CLAUDE_ENV_FILE')
if env_file:
    with open(env_file, 'a') as f:
        f.write(f'export PROJECT_ROOT="{cwd}"\n')
```

### Complete Setup Hook Example

```python
# /// script
# requires-python = ">=3.11"
# dependencies = ["python-dotenv"]
# ///
import json, sys, os, subprocess
from pathlib import Path

def main():
    input_data = json.loads(sys.stdin.read())
    trigger = input_data.get('trigger', 'init')
    cwd = input_data.get('cwd', os.getcwd())

    context_parts = [f"Setup: {trigger}", f"CWD: {cwd}"]

    if trigger == 'init':
        # Persist project root
        env_file = os.environ.get('CLAUDE_ENV_FILE')
        if env_file:
            with open(env_file, 'a') as f:
                f.write(f'export PROJECT_ROOT="{cwd}"\n')

        # Detect project type
        for name, desc in [('package.json', 'Node.js'), ('pyproject.toml', 'Python')]:
            if Path(cwd, name).exists():
                context_parts.append(f"Detected: {desc}")

        # Install deps if needed
        if Path(cwd, 'package.json').exists():
            subprocess.run(['npm', 'ci'], capture_output=True, timeout=300)

    elif trigger == 'maintenance':
        # Check log sizes, run git gc, etc.
        logs_dir = Path(cwd, 'logs')
        if logs_dir.exists():
            size_mb = sum(f.stat().st_size for f in logs_dir.rglob('*') if f.is_file()) / (1024*1024)
            context_parts.append(f"Logs: {size_mb:.1f}MB")

    output = {
        "hookSpecificOutput": {
            "hookEventName": "Setup",
            "additionalContext": "\n".join(context_parts)
        }
    }
    print(json.dumps(output))
    sys.exit(0)

if __name__ == '__main__':
    main()
```

## SessionStart Hook Details

SessionStart fires when a session begins or resumes. It supports context injection.

### SessionStart Input

```json
{
  "session_id": "abc123",
  "transcript_path": "/path/to/transcript.jsonl",
  "cwd": "/path/to/project",
  "hook_event_name": "SessionStart",
  "source": "startup"
}
```

### CLAUDE_ENV_FILE (SessionStart)

Like Setup, SessionStart provides `CLAUDE_ENV_FILE` for persisting environment variables:

```python
env_file = os.environ.get('CLAUDE_ENV_FILE')
if env_file:
    with open(env_file, 'a') as f:
        f.write('export MY_VAR="value"\n')
```

### SessionStart: reloadSkills and session title (v2.1.152)

SessionStart hooks can return `reloadSkills: true` to trigger a skills re-scan, and can set the session title:

```python
output = {
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "reloadSkills": True,
        "sessionTitle": "My Project — main branch"
    }
}
print(json.dumps(output))
```

### SessionStart Context Injection

Load development context at session start:

```python
def load_context(source):
    parts = [f"Session source: {source}"]

    # Git info
    branch = subprocess.run(['git', 'rev-parse', '--abbrev-ref', 'HEAD'],
                           capture_output=True, text=True).stdout.strip()
    parts.append(f"Git branch: {branch}")

    # Load context files
    for path in [".claude/CONTEXT.md", "TODO.md"]:
        if Path(path).exists():
            parts.append(Path(path).read_text()[:1000])

    return "\n".join(parts)

output = {
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": load_context(source)
    }
}
print(json.dumps(output))
```

## Configuration Location

| Location | Scope |
|----------|-------|
| `~/.claude/settings.json` | All your projects |
| `.claude/settings.json` | Single project (committable) |
| `.claude/settings.local.json` | Single project (gitignored) |
| Managed policy settings | Organization-wide |
| Plugin `hooks/hooks.json` | When plugin is enabled |
| Skill/agent frontmatter | While component is active |

Use `/hooks` in Claude Code to interactively view, add, and delete hooks.

Hooks are configured under the `hooks` key:

```json
{
  "hooks": {
    "PreToolUse": [...],
    "PostToolUse": [...],
    "UserPromptSubmit": [...],
    "Stop": [...],
    "Notification": [...]
  }
}
```

## Hook Structure

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "ToolName",
        "hooks": [
          {
            "type": "command",
            "command": "path/to/script.py",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

### Matcher Patterns

| Event | What matcher filters | Example values |
|-------|---------------------|----------------|
| PreToolUse, PostToolUse, PostToolUseFailure, PermissionRequest, PermissionDenied | Tool name | `Bash`, `Edit\|Write`, `mcp__.*` |
| SessionStart | How session started | `startup`, `resume`, `clear`, `compact`, `fork` |
| Setup | Which CLI flag triggered setup | `init`, `maintenance` |
| SessionEnd | Why session ended | `clear`, `resume`, `logout`, `prompt_input_exit`, `bypass_permissions_disabled`, `other` |
| Notification | Notification type | `permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog`, `elicitation_url_dialog`, `elicitation_complete`, `elicitation_response`, `agent_needs_input`, `agent_completed`, `quota_auto_resume_fired`, `quota_auto_resume_stale`, `quota_auto_resume_disabled` (the three `quota_auto_resume_*` fire when a claude.ai usage-limit wait ends; v2.1.234+) |
| SubagentStart, SubagentStop | Agent type | `general-purpose`, `Explore`, `Plan`, custom names, plugin-scoped `my-plugin:reviewer` |
| `PreModelSwitch`, `PostModelSwitch` | Model name (v2.1.251+) | `claude-opus-5`, `.*opus.*` |
| PreCompact, PostCompact | Trigger type | `manual`, `auto` |
| `ConfigChange` | Configuration source | `user_settings`, `project_settings`, `local_settings`, `policy_settings`, `skills` |
| `DirectoryAdded` | How the directory was added | `slash_command`, `register_repo_root` |
| `StopFailure` | Error type | `rate_limit`, `overloaded`, `authentication_failed`, `oauth_org_not_allowed`, `account_on_hold`, `billing_error`, `invalid_request`, `model_not_found`, `server_error`, `max_output_tokens`, `cloud_credential_error` (v2.1.267+), `unknown` |
| `InstructionsLoaded` | Load reason | `session_start`, `nested_traversal`, `path_glob_match`, `include`, `compact` |
| `Elicitation`, `ElicitationResult` | MCP server name | Your configured MCP server names |
| `FileChanged` | Literal filenames to watch | `.envrc\|.env` |
| `UserPromptExpansion` | Command name | Slash command being expanded |
| UserPromptSubmit, PostToolBatch, Stop, TeammateIdle, TaskCreated, TaskCompleted, WorktreeCreate, WorktreeRemove, CwdChanged, MessageDisplay | No matcher support | Always fires on every occurrence |

**Matcher evaluation rules**: a value containing only letters, digits, `_`, `-`, spaces, `,`, `|`
is an **exact match** (`"Edit|Write"` or, since v2.1.191+, `"Edit, Write"`); anything else is
evaluated as an **unanchored JavaScript regex** (`"^Notebook"`, `"mcp__memory__.*"`). Hyphens in
exact-match matchers require v2.1.195+ (earlier versions treated a hyphen as regex syntax).
`FileChanged` and `StopFailure` use a narrower exact-match character set (letters, digits, `_`,
`|` only).

### Conditional Hook Execution (`if` field, v2.1.85+)

Hooks can conditionally execute using permission rule syntax. This also fixes issues where hooks need compound commands or env-var prefixes:

```json
{
  "hooks": [
    {
      "type": "command",
      "if": "Bash(rm -rf *)",
      "command": "notify-rm-attempt.py",
      "timeout": 5
    },
    {
      "type": "command",
      "if": "Edit|Write",
      "command": "validate-edit.py",
      "timeout": 5
    },
    {
      "type": "command",
      "if": "Bash(DEBUG=1 npm install)",
      "command": "log-npm-install.sh",
      "timeout": 10
    }
  ]
}
```

**Supported patterns**:
- `ToolName` — Match any use of the tool
- `ToolName(pattern)` — Match tool with argument pattern (for Bash, matches the command string)
- `ToolName(param:value)` — Match a specific tool input parameter value; supports `*` wildcard (v2.1.178+). Example: `Edit(file_path:src/*)` matches Edit calls whose `file_path` starts with `src/`
- `Tool1|Tool2` — Match multiple tools
- `!ToolName` — Negate/exclude pattern
- Compound commands and env-var prefixes now supported (v2.1.85+)

> **Path pattern fix (v2.1.176)**: `if` conditions matching Read/Edit/Write tool paths (e.g. `Edit(src/*)`) now correctly match the file path argument. Previously these patterns silently failed to match.

There are **five hook handler types**: `command`, `http`, `mcp_tool`, `prompt`, `agent`.

### Common Fields

| Field | Description |
|-------|-------------|
| `type` | `command`, `http`, `mcp_tool`, `prompt`, or `agent` |
| `timeout` | Seconds. Defaults: 600 (command/http/mcp_tool), 30 (prompt), 60 (agent) — lowered to 30 for `UserPromptSubmit` and 10 for `MessageDisplay`; `SessionEnd` hooks share a combined 1.5s budget (configurable via `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS`) |
| `statusMessage` | Custom spinner message while hook runs |
| `once` | If `true`, runs only once per session then is removed (skill/agent frontmatter only) |
| `if` | Conditional execution using permission rule syntax (v2.1.85+). Only honored for tool-related events: `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest`, `PermissionDenied` |

### Command Hook Fields

| Field | Description |
|-------|-------------|
| `command` | Shell command to execute, or the executable name when `args` is present |
| `args` | Argument list. When present, `command` is spawned directly (exec form — each element is one argument, no shell tokenization/quoting). When absent, `command` runs in **shell form** (`sh -c` on macOS/Linux, Git Bash on Windows, or PowerShell), which supports pipes, `&&`, redirects, globs and variable expansion |
| `shell` | Which shell to use for shell-form execution: `"bash"` or `"powershell"`. Defaults to `"bash"`, or `"powershell"` on Windows when Git Bash isn't installed |
| `async` | If `true`, runs in background without blocking |
| `asyncRewake` | If `true`, runs in background and wakes Claude when it exits with code 2 (implies `async`) |

### HTTP Hook Fields (v2.1.63+)

| Field | Description |
|-------|-------------|
| `url` | URL to POST the hook's JSON input to (`Content-Type: application/json`) |
| `headers` | Additional HTTP headers (key/value); values support `$VAR_NAME` / `${VAR_NAME}` interpolation |
| `allowedEnvVars` | List of environment variable names permitted for interpolation into `headers` values |

Response handling: 2xx with empty body = success; 2xx with JSON body = parsed as hook output;
2xx with non-JSON body, non-2xx status, or a timeout = non-blocking error (execution continues).

### MCP Tool Hook Fields

| Field | Description |
|-------|-------------|
| `server` | Name of an already-configured MCP server (plugin-bundled servers: `plugin:<plugin-name>:<server-name>`) |
| `tool` | Name of the tool to call on that server |
| `input` | Optional arguments passed to the tool; string values support `${path}` substitution from the hook's JSON input |

If the server isn't connected or the tool returns `isError: true`, the hook produces a
non-blocking error and execution continues.

### Prompt/Agent Hook Fields

| Field | Description |
|-------|-------------|
| `prompt` | Prompt text. Use `$ARGUMENTS` for hook input JSON (escape literal `$` as `\$`, e.g. `\$1.00`) |
| `model` | Model to use. Defaults to fast model |

The `agent` type spawns a subagent with tool access (Read, Grep, Glob) for up to 50 turns; it is
still called out in the docs as **experimental and may change**.

## Hook Types

### Command Hook
Runs an external script:

```json
{
  "type": "command",
  "command": "uv run ~/.claude/hooks/validate.py",
  "timeout": 5
}
```

**Exec form** (`args` present) bypasses the shell entirely — safer when arguments contain
untrusted content, since there's no quoting/tokenization to exploit:

```json
{
  "type": "command",
  "command": "/usr/bin/python3",
  "args": ["~/.claude/hooks/validate.py", "--strict"],
  "shell": "bash",
  "timeout": 5
}
```

### Prompt Hook
Uses LLM for single-turn validation (returns `{ok: true/false, reason: "..."}`):

```json
{
  "type": "prompt",
  "prompt": "Evaluate if this action is safe: $ARGUMENTS. Check for destructive operations.",
  "timeout": 10
}
```

### Agent Hook
Spawns a subagent with tool access (Read, Grep, Glob) for up to 50 turns. Experimental. Supported on the same events as prompt hooks **except `PermissionRequest`** (its answer could never allow or deny; v2.1.280 skips it with an error pointing to command/http hooks):

```json
{
  "type": "agent",
  "prompt": "Verify all unit tests pass. Run the test suite and check results. $ARGUMENTS",
  "timeout": 120
}
```

### MCP Tool Hook

Call a tool on an already-connected MCP server:

```json
{
  "type": "mcp_tool",
  "server": "my-server",
  "tool": "security_scan",
  "input": { "file_path": "${tool_input.file_path}" }
}
```

Fields: `server` (configured MCP server name), `tool` (tool name), `input` (optional, with `${path}` substitution). If the server isn't connected or the tool returns `isError: true`, the hook fails non-blocking and execution continues. On blocking events (PreToolUse and similar), an `mcp_tool` hook whose server is still connecting now waits for it, up to the MCP connect timeout, instead of being skipped (v2.1.281).

### HTTP Hook (v2.1.63+)

POST JSON to a URL instead of running a shell command:

```json
{
  "type": "http",
  "url": "https://hooks.example.com/validate",
  "headers": { "Authorization": "Bearer ${MY_HOOK_TOKEN}" },
  "allowedEnvVars": ["MY_HOOK_TOKEN"],
  "timeout": 10
}
```

The hook input JSON is POSTed as the request body (`Content-Type: application/json`). The
response JSON is interpreted the same as command hook JSON output. `headers` values support
`$VAR` / `${VAR}` interpolation, but only for names listed in `allowedEnvVars`. Response
handling: 2xx + empty body = success; 2xx + JSON body = parsed; 2xx + other body, non-2xx
status, or a timeout = non-blocking error (execution continues).

### Async Hooks
Command hooks with `"async": true` run in background. Cannot block or return decisions. Output delivered on next conversation turn.

```json
{
  "type": "command",
  "command": "/path/to/run-tests.sh",
  "async": true,
  "timeout": 120
}
```

## Exit Codes (Command Hooks)

| Code | Effect |
|------|--------|
| `0` | Success. stdout is parsed as JSON if it starts with `{`, otherwise treated as plain text |
| `2` | Blocking error on events that can block: stderr becomes the blocking reason (JSON `permissionDecision` set in the same run cannot override this) |
| Other | Non-standard: parsed JSON is still honored for decision fields; plain text is a non-blocking error; parse failures fail open |

Timeout: the hook is canceled, no decision is rendered, and execution continues (fails open) —
except an Agent SDK callback timeout on `PreToolUse`, which blocks the tool call.

## Hook-Specific Flow Control

Each hook type has different blocking capabilities:

| Hook | Can Block? | Exit 2 Effect | JSON Decision Control |
|------|-----------|---------------|----------------------|
| UserPromptSubmit | Yes | Blocks prompt processing, erases the prompt | `decision`/`reason` (`approve`/`block`); `hookSpecificOutput.additionalContext` |
| UserPromptExpansion | Yes | Blocks the expansion | `decision`/`reason` |
| PreToolUse | Yes | Blocks tool, feeds stderr to Claude | `hookSpecificOutput.permissionDecision`: `allow`/`deny`/`ask`/`defer` (v2.1.89+) |
| PreModelSwitch | Yes | Blocks the switch, tells Claude why | `hookSpecificOutput.permissionDecision`: `allow`/`deny`; `blockReason` (v2.1.251+) |
| PostModelSwitch | Feedback only | stderr shown to user only | `additionalContext` (v2.1.251+) |
| PostToolUse | Feedback only | Shows error to Claude (tool already ran) | `decision: "block"` (prompts Claude); `additionalContext` |
| PostToolUseFailure | Feedback only | Shows error to Claude (tool already failed) | `additionalContext` |
| PostToolBatch | Yes | Stops the agentic loop before the next model call | `continue` |
| Stop | Yes | Blocks stoppage, forces continuation | `decision: "block"` (forces Claude to continue) |
| StopFailure | No | **Ignored** — output and exit code discarded except `terminalSequence` | N/A |
| SubagentStart | No | stderr shown to user only | N/A |
| SubagentStop | Yes | Blocks subagent stoppage | `decision: "block"` |
| TeammateIdle | Yes | Prevents the teammate from going idle | `continue` |
| TaskCreated | Yes | Rolls back the task creation | `continue` |
| TaskCompleted | Yes | Prevents the task from being marked complete | `continue` |
| Notification | No | Exit code and stderr ignored | N/A |
| MessageDisplay | No | Original text is displayed unchanged | N/A |
| PreCompact | Yes | Blocks compaction | `continue` |
| PostCompact | No | stderr shown to user only | N/A |
| SessionStart | No | stderr shown to user only | Context injection via `additionalContext`; `reloadSkills`; `sessionTitle` |
| SessionEnd | No | stderr shown to user only | N/A |
| Setup | No | stderr shown to user only | Context injection via `additionalContext` |
| FileChanged | No | stderr shown to user only | N/A |
| CwdChanged | No | stderr shown to user only | N/A |
| DirectoryAdded | No | stderr goes to debug log only (directory already added) | N/A |
| InstructionsLoaded | No | Exit code ignored | N/A |
| ConfigChange | Yes | Blocks the config change from taking effect (**except** `policy_settings`, which cannot be blocked) | `continue` |
| WorktreeCreate | Yes | Any non-zero exit fails worktree creation | `worktreePath` (HTTP hooks, v2.1.84+) |
| WorktreeRemove | No | Failures logged in debug mode only | N/A |
| PermissionRequest | Yes | Not honored — must use JSON `decision` object | `hookSpecificOutput.decision.behavior`: `allow`/`deny` (+ `updatedInput`, `message`, `interrupt`) |
| PermissionDenied | No | Exit code and stderr ignored | `hookSpecificOutput.retry: true` lets the model retry |
| Elicitation | Yes | Denies the elicitation | `hookSpecificOutput` decision fields |
| ElicitationResult | Yes | Blocks the response (becomes decline) | `hookSpecificOutput` nested decision |

### Common JSON Output Fields (All Hooks)

```json
{
  "continue": true,
  "stopReason": "message when continue=false",
  "suppressOutput": false,
  "systemMessage": "message added to the transcript (capped at 10,000 chars)",
  "terminalSequence": "ANSI escape sequence for notification/title/bell"
}
```

`continue: false` stops Claude Code processing entirely and takes precedence over every other
control, on any event. `systemMessage` and `terminalSequence` are honored by nearly every event
(some events discard `systemMessage` or show it elsewhere); most other fields are event-specific
— see the per-event table above and `hookSpecificOutput` below.

### `blockReason` — explaining a block

Several events accept a `blockReason` string inside `hookSpecificOutput`. It is the message
Claude receives explaining *why* it was blocked, so it can react rather than just stall.
Confirmed on the hooks docs page for these events:

| Event | Effect of `blockReason` |
|-------|------------------------|
| `Stop`, `SubagentStop` | Blocks stopping and tells Claude what still needs doing |
| `UserPromptSubmit` | Blocks the prompt and explains the rejection |
| `UserPromptExpansion` | Blocks the expansion and explains why |
| `PostToolBatch` | Stops the agentic loop after the batch, with a reason |
| `ElicitationResult` | Blocks the response (becomes a decline), with a reason |
| `PreModelSwitch` | Blocks the model switch and explains why (v2.1.251+) |

```json
{
  "hookSpecificOutput": {
    "hookEventName": "SubagentStop",
    "blockReason": "Tests were never run — re-run the suite before finishing."
  }
}
```

> **Practical consequence for any hook wired to `Stop` or `SubagentStop`**: stdout starting
> with `{` is parsed as JSON. A notification or logging hook on these events must print
> **nothing** on stdout and exit 0, or a stray JSON-looking line can block the agent.

### Flow Control Priority

1. `"continue": false` — Takes precedence over all other controls
2. `"decision": "block"` — Hook-specific blocking
3. Exit Code 2 — Simple blocking via stderr
4. Other exit codes — Non-blocking errors

### Stop Hook: Forcing Continuation

The Stop hook can force Claude to keep working:

```python
if not all_tests_passed():
    output = {
        "decision": "block",
        "reason": "Tests failing. Fix them before completing."
    }
    print(json.dumps(output))
    sys.exit(0)
```

**Caution**: Check `stop_hook_active` to prevent infinite loops.

## JSON Output for Ask/Defer Decision

To trigger a confirmation dialog:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask",
    "permissionDecisionReason": "This command requires confirmation"
  }
}
```

### Deferring Decisions in Headless Mode (v2.1.89+)

For headless sessions using `-p --resume`, PreToolUse hooks can defer decisions to pause the session and resume later:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "defer",
    "permissionDecisionReason": "Manual review required before deploying to production"
  }
}
```

This pauses the session at the tool. Resume with `claude --resume` when ready:

```bash
claude -p --model=claude-opus-4 --resume
```

**Use cases**:
- Human approval gates in CI/CD before destructive operations
- Code review gates before pushing to main branch
- Manual sign-off on sensitive database operations
- Integration with external approval workflows

PreToolUse hooks can satisfy AskUserQuestion requests via `updatedInput` and `permissionDecision: "allow"` (v2.1.85+):

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "updatedInput": {"command": "modified command"},
    "additionalContext": "Command was modified by validation hook"
  }
}
```

## Input Format

All hooks receive common fields via stdin JSON, plus event-specific fields:

```json
{
  "session_id": "abc123",
  "prompt_id": "uuid-of-the-current-user-prompt",
  "transcript_path": "/path/to/transcript.jsonl",
  "cwd": "/path/to/project",
  "permission_mode": "default",
  "effort": { "level": "high" },
  "hook_event_name": "PreToolUse",
  "agent_id": "abc123",
  "agent_type": "general-purpose",
  "tool_name": "Bash",
  "tool_input": {
    "command": "rm -rf /tmp/test"
  }
}
```

| Field | Notes |
|-------|-------|
| `prompt_id` | UUID correlating to OpenTelemetry events; absent until the first user input (v2.1.196+) |
| `transcript_path` | Written asynchronously — may lag behind the live conversation |
| `permission_mode` | One of `default`, `plan`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions` |
| `effort` | Object with `level`: `low`/`medium`/`high`/`xhigh`/`max`, when the model supports it |
| `agent_id`, `agent_type` | Only present for subagent-scoped hooks; `agent_type` can be a plugin-scoped name like `my-plugin:reviewer` |

## Disabling Hooks

Set `"disableAllHooks": true` in settings or use `/hooks` menu toggle. Hooks snapshot at startup - mid-session changes require review in `/hooks` menu. Project-level `false` overrides a user-level `true`; a CLI override via `--settings '{"disableAllHooks": true}'` takes precedence over everything. Managed-policy hooks can't be disabled by user/project/local settings — only a managed `disableAllHooks` can disable them, and `allowManagedHooksOnly` blocks non-managed hooks entirely (force-enabled plugin hooks are exempt).

Debug with `claude --debug` to see hook execution details.

**Execution model**: all matching hooks for an event run in parallel. If the same handler is
registered by multiple settings files it runs once (separate plugin copies still run
separately). User, project, and local settings hooks add up rather than replacing each other.

## Complete Example: Security Firewall

### settings.json

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "uv run ~/.claude/hooks/bash-validate.py",
            "timeout": 5
          }
        ]
      },
      {
        "matcher": "Edit",
        "hooks": [
          {
            "type": "command",
            "command": "uv run ~/.claude/hooks/edit-validate.py",
            "timeout": 5
          }
        ]
      },
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "uv run ~/.claude/hooks/write-validate.py",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

### Python Hook Script

```python
# /// script
# requires-python = ">=3.8"
# dependencies = ["pyyaml"]
# ///
"""
PreToolUse validation hook.
Exit 0 to allow, exit 2 to block.
"""

import json
import sys
import re

# Dangerous patterns to block
BLOCKED_PATTERNS = [
    (r'\brm\s+(-[^\s]*)*-[rRf]', 'rm with recursive/force flags'),
    (r'\bsudo\s+rm\b', 'sudo rm'),
    (r'\bgit\s+push\s+.*--force(?!-with-lease)', 'git push --force'),
]

# Patterns requiring confirmation
ASK_PATTERNS = [
    (r'\bgit\s+checkout\s+--\s*\.', 'Discards all uncommitted changes'),
    (r'\bgit\s+stash\s+drop\b', 'Permanently deletes a stash'),
]

def main():
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)  # Allow on parse error

    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})

    if tool_name != "Bash":
        sys.exit(0)

    command = tool_input.get("command", "")
    if not command:
        sys.exit(0)

    # Check blocked patterns
    for pattern, reason in BLOCKED_PATTERNS:
        if re.search(pattern, command, re.IGNORECASE):
            print(f"BLOCKED: {reason}", file=sys.stderr)
            sys.exit(2)

    # Check ask patterns
    for pattern, reason in ASK_PATTERNS:
        if re.search(pattern, command, re.IGNORECASE):
            output = {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "ask",
                    "permissionDecisionReason": reason
                }
            }
            print(json.dumps(output))
            sys.exit(0)

    sys.exit(0)  # Allow

if __name__ == "__main__":
    main()
```

## Notification Hook Example

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/notify.py UserPromptSubmit"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/notify.py Stop"
          }
        ]
      }
    ]
  }
}
```

## Permissions Configuration

Separate from hooks, permissions define tool access rules:

```json
{
  "permissions": {
    "deny": [
      "Bash(rm -rf /*:*)",
      "Bash(sudo rm -rf:*)",
      "Bash(mkfs:*)"
    ],
    "ask": [
      "Bash(git push --force:*)",
      "Bash(git reset --hard:*)"
    ]
  }
}
```

### Permission Format
```
ToolName(pattern:*)
```

- `deny`: Always block
- `ask`: Require user confirmation

## Pattern Configuration File

For complex patterns, use a separate YAML file:

```yaml
# patterns.yaml
bashToolPatterns:
  - pattern: '\brm\s+(-[^\s]*)*-[rRf]'
    reason: rm with recursive or force flags

  - pattern: '\bgit\s+checkout\s+--\s*\.'
    reason: Discards all uncommitted changes
    ask: true  # Confirmation instead of block

zeroAccessPaths:
  - "~/.ssh/"
  - "~/.aws/"
  - ".env"
  - "*.pem"

readOnlyPaths:
  - "package-lock.json"
  - "*.lock"
  - "/etc/"

noDeletePaths:
  - "~/.claude/"
  - "CLAUDE.md"
  - ".git/"
```

Load in hook script:
```python
import yaml
from pathlib import Path

config_path = Path(__file__).parent / "patterns.yaml"
with open(config_path) as f:
    config = yaml.safe_load(f)
```

### PostToolUse Tool Output Override (v2.1.121+)

PostToolUse hooks can replace the tool's output via `updatedToolOutput`:
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "updatedToolOutput": "Replacement output for the tool"
  }
}
```

This works for any tool, not just MCP tools.

## CLI Auth Commands (v2.1.41+)

New authentication management commands:
```bash
claude auth login     # Log in to Claude Code
claude auth status    # Check authentication status
claude auth logout    # Log out
```
## UV Single-File Scripts Architecture

Hooks work well as UV single-file scripts with embedded dependencies:

```python
#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pyyaml", "python-dotenv"]
# ///

import json, sys
# ... hook logic
```

Benefits:
- **Isolation** — Hook deps stay separate from project deps
- **Portability** — Each script declares its own requirements inline
- **No venv management** — UV handles everything automatically
- **Self-contained** — Each hook is independently understandable

## Plugin Hook System

Plugins bundle hooks, commands, agents, skills, and MCP servers together. Plugin hooks use `${CLAUDE_PLUGIN_ROOT}` for portable paths. Quote it in shell-form commands: an unquoted `${CLAUDE_PLUGIN_ROOT}` breaks on plugin paths with spaces, and `claude plugin validate` warns about it (v2.1.281). A top-level `$schema` key in `hooks/hooks.json` is accepted (v2.1.274).

### Plugin Structure
```
plugin-name/
├── .claude-plugin/
│   └── plugin.json          # Plugin metadata
├── commands/                # Slash commands (.md files)
├── agents/                  # Subagent definitions (.md files)
├── skills/                  # Skills (.md files with SKILL.md)
├── hooks/
│   └── hooks.json           # Event handlers
├── .mcp.json                # MCP server config (optional)
└── README.md
```

### Plugin hooks.json Format
```json
{
  "description": "Plugin description",
  "hooks": {
    "PreToolUse": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "python3 \"${CLAUDE_PLUGIN_ROOT}\"/hooks/pretooluse.py",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

### Prompt Hooks (LLM-Driven)

For nuanced, context-aware validation. Supported on: `Stop`, `SubagentStop`, `UserPromptSubmit`, `PreToolUse`.

```json
{
  "type": "prompt",
  "prompt": "Evaluate if this action is safe. $ARGUMENTS"
}
```

**Key difference**: SessionStart hooks ADD to the default system prompt. Subagent system prompts REPLACE it.

### Security Hook Pattern (Session-Scoped Deduplication)

Track warnings per session to avoid repeating:
```python
state_file = f"~/.claude/security_warnings_state_{session_id}.json"
# Show each warning only once per session per file
# Clean up state files older than 30 days (10% random chance per run)
```

### Enterprise Settings for Hook Control

```json
{
  "allowManagedHooksOnly": true,
  "allowManagedPermissionRulesOnly": true
}
```

### Auto Mode Classifier Rules (v2.1.136+)

The `settings.autoMode.hard_deny` setting adds classifier rules that block unconditionally in auto permission mode:

```json
{
  "autoMode": {
    "hard_deny": ["Bash(rm -rf *)"]
  }
}
```

Unlike standard deny rules, `hard_deny` rules apply even when Claude is operating in auto mode.

### Auto Mode Built-in Safety Blocks (v2.1.183)

Auto mode now blocks the following destructive operations **unless explicitly requested by the user** in the current turn:

- `git reset --hard`, `git checkout -- .`, `git clean -fd`, `git stash drop`
- `terraform destroy`, `pulumi destroy`, `cdk destroy`

These blocks are applied by the built-in auto-mode classifier independently of any `hard_deny` rules you configure.

### Subagent-Spawn Classifier (v2.1.178)

When operating in auto mode, Claude evaluates subagent spawns through a classifier before launch. The classifier can reject a subagent spawn if it determines the spawned agent would perform unsafe or out-of-scope actions. This fires before `SubagentStart`.

## Best Practices

1. **Keep hooks fast**: Use `timeout` to prevent hangs
2. **Fail open**: Exit 0 on errors to avoid blocking legitimate work
3. **Log decisions**: Write to log file for debugging
4. **Use patterns file**: Separate configuration from code
5. **Test thoroughly**: Verify both block and allow cases
6. **Chain hooks**: Multiple hooks run in parallel, all must pass
7. **Use `$CLAUDE_PROJECT_DIR`**: Prefix hook paths in settings.json for reliable resolution
8. **Use UV single-file scripts**: Embed dependencies inline for portable hooks

## Environment Variables

| Variable | Description |
|----------|-------------|
| `CLAUDE_PROJECT_DIR` | Absolute path to project root |
| `CLAUDE_CODE_REMOTE` | `true` if running in remote/web environment |
| `CLAUDE_ENV_FILE` | Path to persist env vars (Setup and SessionStart) |
| `CLAUDE_PLUGIN_ROOT` | Plugin script directory path (for plugin hooks) |
| `CLAUDE_PLUGIN_DATA` | Persistent data directory for plugin state (survives updates) (v2.1.78+) |
| `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS` | Configurable timeout for SessionEnd hooks (v2.1.74). Previously hardcoded at 1.5s |
| `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` | Set to `1` to strip credentials from subprocess environments (v2.1.83+) |
| `CLAUDE_EFFORT` | Current effort level (`low`/`medium`/`high`/`xhigh`/`max`), also available in hook JSON input as `effort.level` (v2.1.133+) |
| `CLAUDE_CLIENT_PRESENCE_FILE` | Path to a file whose presence suppresses mobile push notifications (v2.1.181+) |
| `CLAUDE_CODE_BRIDGE_SESSION_ID` | Set to the Remote Control session ID while the local session has an active Remote Control connection (v2.1.199+) |
| `CLAUDE_PLUGIN_OPTION_<KEY>` | Plugin user-configuration values, key upper-cased with underscores (e.g. `webhook_url` → `CLAUDE_PLUGIN_OPTION_WEBHOOK_URL`) |
| `CLAUDE_CODE_TOOL_MEMORY_LIMIT` | Memory cgroup limit for Bash-tool subprocesses on Linux (v2.1.233+) |
| `CLAUDE_CODE_WEBFETCH_CACHE_TTL_MS` | Overrides WebFetch's cache TTL in milliseconds (v2.1.233+) |
| `CLAUDE_CODE_PROJECT_DIR_NAME` | Custom name for the per-project transcript directory (v2.1.234+) |
| `ANTHROPIC_DEFAULT_MODEL` | Default model for new sessions, overridable via `/model` (v2.1.236+) |
| `CLAUDE_CODE_ENABLE_TODO_TOOLS` | Set to `1` to re-enable TaskCreate/Get/Update/List and TodoWrite, which are otherwise unavailable by default on Opus 4.8, Sonnet 5, Fable 5, Mythos 5+ (v2.1.233+) |

Note: `OTEL_*` exporter variables are stripped from every subprocess Claude Code spawns,
including hooks.

## Advanced Hook Output

### PreToolUse Decision Control

> **Note**: Top-level `decision` and `reason` fields are **deprecated** for PreToolUse. Use `hookSpecificOutput.permissionDecision` and `hookSpecificOutput.permissionDecisionReason` instead. The deprecated values `"approve"` and `"block"` map to `"allow"` and `"deny"` respectively. Other events (PostToolUse, Stop, etc.) continue to use top-level `decision`/`reason`.

> **Bug Fixes (v2.1.90)**: Fixed `PreToolUse` hooks with JSON stdout and exit code 2 not blocking tool call. Fixed `Edit`/`Write` failure when PostToolUse hook rewrites file between edits. Fixed `file_path` not absolute for Write/Edit/Read hooks (v2.1.89).

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow|deny|ask",
    "permissionDecisionReason": "explanation",
    "updatedInput": {"command": "modified command"},
    "additionalContext": "Extra context for Claude"
  }
}
```

`permissionDecision` values for `PreToolUse`:
- `"allow"` — skip the interactive permission prompt. Deny/ask rules (including enterprise managed deny lists) still apply, as do prompts for connector tools an org marked `ask`, or MCP tools marked `requiresUserInteraction`
- `"deny"` — cancel the tool call, feed `permissionDecisionReason` back to Claude
- `"ask"` — show the permission prompt to the user as normal
- `"defer"` — headless mode (`-p`) only: exits the process with the tool call preserved for an Agent SDK wrapper to collect input and resume (see below)

### PermissionRequest Control
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PermissionRequest",
    "decision": {
      "behavior": "allow|deny",
      "updatedInput": {...},
      "message": "reason",
      "interrupt": false
    }
  }
}
```

### PermissionDenied Hook (v2.1.89+)

Fires after auto-deny classifier rejection. Use for logging or recovery:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PermissionDenied",
    "additionalContext": "Operation denied by classifier. Reason: destructive pattern detected",
    "retry": true
  }
}
```

`retry: true` tells the model it may retry the denied call; it's ignored for no-verdict
denials. Exit code and stderr are otherwise ignored for this event.

### TaskCreated Hook (v2.1.84+)

Fires when a task is created via TaskCreate. Use for logging or validation:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "TaskCreated",
    "additionalContext": "Task created: Fix authentication bug"
  }
}
```

### WorktreeCreate Hook with HTTP Support (v2.1.84+)

When a worktree is created via `--worktree` or `isolation: "worktree"`, a `WorktreeCreate` hook fires. Replaces the default git behavior.

Hook input includes:
```json
{
  "worktree_path": "/path/to/worktree",
  "branch_name": "feature/abc"
}
```

For HTTP hooks (v2.1.84+), the hook output can provide a custom worktree path:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "WorktreeCreate",
    "worktreePath": "/custom/worktree/path"
  }
}
```

### SessionStart Matchers
- `startup` - New session
- `resume` - Resumed session
- `clear` - After /clear
- `compact` - After compaction
- `fork` - Forked subagent session (`subagent_type: "fork"`)

### SessionEnd Reasons
- `clear` - Session cleared
- `resume` - Session resumed elsewhere
- `logout` - User logged out
- `prompt_input_exit` - Exited at prompt
- `bypass_permissions_disabled` - Bypass permissions were disabled
- `other` - Other reasons

## Plugin and Skill Hooks

### Plugin Hooks
Define in `plugins/your-plugin/hooks/hooks.json`

### Skill/Agent Hooks
```yaml
---
name: my-skill
hooks:
  PreToolUse:
    - matcher: Bash
      hooks:
        - type: command
          command: validate.py
          once: true  # Run once per session
---
```
