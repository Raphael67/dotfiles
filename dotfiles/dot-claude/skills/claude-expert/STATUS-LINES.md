# Claude Code Status Lines Reference

## What Are Status Lines?

The status line is a customizable bar at the bottom of Claude Code that runs **any shell command** you configure (not just Python) — it receives JSON session data on stdin and displays whatever the script prints to stdout. It renders in its own row **above** the built-in footer badges (PR/MR badge, permission-mode indicator, keyboard hints) and does **not replace them** — those badges keep rendering below a custom status line. Configuring a custom status line does suppress most of the footer's keyboard hints (`esc to interrupt`, `? for shortcuts`, the voice-dictation hint).

For clickable link badges (e.g. turning issue/review IDs mentioned in the conversation into links) without writing a script at all, use `footerLinksRegexes` instead (see below).

## Configuration

Set in `settings.json` (user, project, local, or managed):

```json
{
  "statusLine": {
    "type": "command",
    "command": "uv run $CLAUDE_PROJECT_DIR/.claude/status_lines/status_line.py",
    "padding": 2,
    "refreshInterval": 5,
    "hideVimModeIndicator": false
  }
}
```

Or use `/statusline` command in Claude Code for interactive setup — describe what you want in natural language (e.g. `/statusline show model name and context percentage with a progress bar`) and it generates the script and settings for you.

### Config fields

| Field | Description |
|---|---|
| `type` | Must be `"command"` |
| `command` | Script path or inline shell command. Runs in a shell, so `jq`-based one-liners work directly, e.g. `"jq -r '\"[\\(.model.display_name)] \\(.context_window.used_percentage // 0)% context\"'"` |
| `padding` | Extra horizontal spacing (characters) added to the status line content, on top of the interface's built-in spacing. Default `0` |
| `refreshInterval` | Re-runs the command every N seconds *in addition to* event-driven updates. Minimum `1`. Use for time-based data (clocks) or when background subagents change git state while the main session is idle — event-driven triggers go quiet during idle periods |
| `hideVimModeIndicator` | Suppresses the built-in `-- INSERT --` text below the prompt. Set `true` when your script renders `vim.mode` itself, to avoid showing the mode twice |

There's also a separate `subagentStatusLine` setting (same `type`/`command` shape) that overrides the per-row rendering of subagents in the agent panel — it receives a `tasks` array (id, name, type, status, model, effort, contextWindowSize, tokenCount, ...) instead of the main schema below.

### Disable the status line

Run `/statusline` and ask it to clear/remove the status line, or delete the `statusLine` field from settings.json manually.

## Update Triggers & Debouncing

The script runs once when a session starts (including on resume), then again when:
- A new assistant message arrives
- `/compact` finishes
- The permission mode changes
- Vim mode toggles
- A `refreshInterval` timer elapses, if set

Updates are **debounced at 300ms**: rapid changes batch together and the script runs once after they stop. If a new update triggers while the script is still running, Claude Code **cancels the in-flight script**. Editing the script file itself takes effect on the next trigger — no restart needed.

## Terminal Size: COLUMNS / LINES (v2.1.153+)

Claude Code captures the script's stdout instead of attaching it to a tty, so `tput cols` and language-level terminal-size detection **cannot** read the real terminal width from inside the script. As of **v2.1.153**, Claude Code sets the `COLUMNS` and `LINES` environment variables to the current terminal dimensions before invoking the script — read those instead.

## Workspace Trust Gate

Because `statusLine` executes a shell command, it runs under the same **workspace trust** rule as hooks in settings files. Until the folder (or a parent whose trust extends to it) is accepted in the trust dialog, **the status line stays blank** — `claude --debug` logs `Status line command skipped: workspace trust not accepted`. Restart Claude Code and accept the trust dialog to enable it.

## Status Line Input Schema

Status lines receive JSON via stdin. Key fields (see the [full accordion schema in the docs](https://code.claude.com/docs/en/statusline#available-data) for the complete nested shape):

| Field | Description |
|-------|-------------|
| `model.id`, `model.display_name` | Current model identifier and display name |
| `cwd`, `workspace.current_dir` | Current working directory (same value; prefer `workspace.current_dir`) |
| `workspace.project_dir` | Directory Claude Code was launched from (may differ from `cwd`) |
| `workspace.added_dirs` | Dirs added via `/add-dir` / `--add-dir` |
| `workspace.git_worktree` | Worktree name when inside a linked `git worktree add` checkout |
| `workspace.repo.host/owner/name` | Repo identity parsed from the `origin` remote |
| `cost.total_cost_usd` | Estimated session cost in USD (client-computed at list rates; may not match your actual bill). Resets to $0 on `/clear` |
| `cost.total_duration_ms` | Wall-clock time since session start |
| `cost.total_api_duration_ms` | Time spent waiting on API responses |
| `cost.total_lines_added`, `cost.total_lines_removed` | Lines of code changed |
| `context_window.total_input_tokens`, `.total_output_tokens` | Tokens currently in context window |
| `context_window.context_window_size` | Max context size — 200000 by default, 1000000 for extended-context models |
| `context_window.used_percentage`, `.remaining_percentage` | Pre-calculated percentages |
| `context_window.current_usage` | `{input_tokens, output_tokens, cache_creation_input_tokens, cache_read_input_tokens}` from the last API call. `null` before the first call and again right after `/compact` |
| `exceeds_200k_tokens` | Whether total tokens from the last response exceed 200k (fixed threshold regardless of actual window size) |
| `fast_mode` | Whether fast mode is enabled |
| `effort.level` | Current reasoning effort (`low`/`medium`/`high`/`xhigh`/`max`); absent if the model doesn't support it |
| `thinking.enabled` | Whether extended thinking is on |
| `rate_limits.five_hour.used_percentage`, `.resets_at` | 5-hour rolling rate-limit window (Claude.ai Pro/Max subscribers only, after first API response) |
| `rate_limits.seven_day.used_percentage`, `.resets_at` | 7-day rate-limit window |
| `session_id` | Unique session identifier |
| `session_name` | Custom (`--name`/`/rename`) or AI-generated session title. Absent for the default display name |
| `prompt_id` | UUID of the current user prompt. Absent until first input. Requires v2.1.196+ |
| `transcript_path` | Path to the conversation transcript file |
| `version` | Claude Code version |
| `output_style.name` | Current output style name |
| `vim.mode` | `NORMAL`/`INSERT`/`VISUAL`/`VISUAL LINE`, present only when vim mode is enabled |
| `agent.name` | Present when running with `--agent` or agent settings configured |
| `pr.number`, `pr.url` | Open PR for the branch, mirroring the footer PR badge. In a repo with a GitLab remote, populated from the open merge request instead — see GitLab section below |
| `pr.review_state` | `approved`, `pending`, `changes_requested`, or `draft` |
| `worktree.name/path/branch/original_cwd/original_branch` | Present only during `--worktree` sessions |

**Fields that may be absent entirely**: `session_name`, `prompt_id`, `workspace.git_worktree`, `workspace.repo`, `effort`, `vim`, `agent`, `pr` (and its sub-fields), `worktree`, `rate_limits`. Always guard with `// 0` / `// empty` (jq) or `?.` (JS) / `.get()` (Python).

**Fields that may be `null`**: `context_window.current_usage`, `context_window.used_percentage`, `context_window.remaining_percentage` — before the first API response, or right after `/compact` until the next call repopulates them.

## GitLab Merge Request Badge (v2.1.234+)

Added in **v2.1.234**: in a repo with a GitLab remote, the footer's PR badge becomes an **MR badge** (`MR !N`) reflecting the branch's open merge request, with draft/pending/approved(green) states. The same data populates the stdin schema:

- `pr.kind` is set to `"mr"` for a GitLab merge request (absent for GitHub PRs, so older scripts keep working unmodified).
- `pr.number` becomes the merge-request number; `pr.url` its URL.
- `pr.review_state` is set to `approved` when GitLab reports it mergeable, `pending` for any other open state, and `draft` for a draft MR.
- Merge-request data requires Claude Code **v2.1.234+**.

As noted above, this badge (like the GitHub PR badge and the permission-mode badge) renders in the **footer row below** a custom status line — configuring `statusLine` does not remove or replace it.

## Cost Estimate Premium for Data-Residency Workspaces (v2.1.239+)

As of **v2.1.239**, cost estimates — including the status line's `cost.total_cost_usd`, `/cost`, and `--max-budget-usd` — include a **1.1x US-only-inference premium** for data-residency workspaces. If your org uses a data-residency workspace, expect the status line's cost figure to run about 10% higher than the equivalent non-data-residency estimate for the same usage.

## `footerLinksRegexes`: No-Script Link Badges

`footerLinksRegexes` (user or managed settings scope) is the no-script alternative to a custom status line for **clickable link badges**: it matches regex patterns against Claude Code's output (e.g. issue or review IDs like `JIRA-123`) and turns matches into clickable footer badges below the input box, without writing a `statusLine` command at all.

## Output Format

Print a single line to stdout. Supports ANSI color codes:

```python
# ANSI color helpers
BOLD = "\033[1m"
CYAN = "\033[36m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
RED = "\033[31m"
DIM = "\033[2m"
RESET = "\033[0m"

print(f"{CYAN}main{RESET} | {GREEN}opus{RESET} | 42 msgs | $0.15")
```

## Progressive Examples

### v1: Basic MVP
Shows git branch, directory, and model info. `model` is an object (`model.display_name`), not a flat string:
```python
branch = subprocess.run(['git', 'rev-parse', '--abbrev-ref', 'HEAD'],
                       capture_output=True, text=True).stdout.strip()
model_short = data.get('model', {}).get('display_name', '')
print(f"⎇ {branch} | 📁 {os.path.basename(cwd)} | 🤖 {model_short}")
```

### v5: Cost Tracking
Adds cost and line-change tracking. Real field names are `cost.total_cost_usd` and `cost.total_lines_added`/`total_lines_removed`:
```python
cost = data.get('cost', {}).get('total_cost_usd', 0)
adds = data.get('cost', {}).get('total_lines_added', 0)
dels = data.get('cost', {}).get('total_lines_removed', 0)
print(f"💰 ${cost:.2f} | +{adds}/-{dels} lines | ⏱ {elapsed}")
```

### v6: Context Window Usage
Visual bar showing context consumption. The pre-calculated field is `used_percentage` (not `percentage`):
```python
ctx = data.get('context_window', {})
pct = int(ctx.get('used_percentage', 0) or 0)
bar_len = 20
filled = int(bar_len * pct / 100)
bar = "█" * filled + "░" * (bar_len - filled)
color = GREEN if pct < 60 else YELLOW if pct < 80 else RED
print(f"Context: {color}[{bar}] {pct}%{RESET}")
```

### v8: Token/Cache Stats
Shows detailed token usage with cache efficiency. Per-component counts live under `context_window.current_usage`, not `cost`:
```python
usage = (data.get('context_window', {}) or {}).get('current_usage') or {}
input_t = usage.get('input_tokens', 0)
output_t = usage.get('output_tokens', 0)
cache_r = usage.get('cache_read_input_tokens', 0)
cache_w = usage.get('cache_creation_input_tokens', 0)
print(f"In:{input_t//1000}k Out:{output_t//1000}k Cache R:{cache_r//1000}k W:{cache_w//1000}k")
```

### v9: Powerline Minimal
Stylized segments with powerline separators:
```python
SEP = "\ue0b0"  # Powerline separator
print(f" {branch} {SEP} {model} {SEP} {pct}% {SEP} ${cost:.2f} ")
```

## Session Data Integration

Status lines can read session data from files managed by hooks:

```python
session_file = Path(f".claude/data/sessions/{session_id}.json")
if session_file.exists():
    session = json.loads(session_file.read_text())
    agent_name = session.get('agent_name', 'Unknown')
    prompts = session.get('prompts', [])
    extras = session.get('extras', {})
```

### Agent Naming
Hooks can auto-generate unique agent names (via LLM) stored in session data:
- Priority: Ollama (local) → Anthropic → OpenAI → Fallback names
- Names are single-word identifiers (e.g., Phoenix, Sage, Nova)
- Displayed in status line for session identification

### Custom Metadata (v4+)
Add key-value pairs to session data for display:
```json
{
  "extras": {
    "project": "myapp",
    "status": "debugging",
    "environment": "prod"
  }
}
```

## Task Type Color Coding

Status lines can color-code based on prompt analysis:

| Indicator | Color | Task Type |
|-----------|-------|-----------|
| 🔍 | Purple | Analysis/search |
| 💡 | Green | Creation/implementation |
| 🔧 | Yellow | Fix/debug |
| 🗑️ | Red | Deletion |
| ❓ | Blue | Questions |
| 💬 | Default | General |

## Best Practices

1. **Keep it fast**: updates are debounced at 300ms and an in-flight script gets cancelled by the next trigger, so keep execution well under that
2. **Handle errors gracefully**: a non-zero exit or empty stdout blanks the status line; print something even on failure, never crash
3. **Truncate long text**: Use ellipsis for prompts > 50 chars
4. **Use colors sparingly**: Aid readability without visual noise
5. **Cache expensive calls**: Don't run git commands every refresh — key any cache file by `session_id` (stable per session, unique across concurrent sessions), not a process PID
6. **Test with**: `echo '{"session_id":"test","model":{"display_name":"Opus"},"workspace":{"current_dir":"/tmp"},"context_window":{"used_percentage":25}}' | python status_line.py`
