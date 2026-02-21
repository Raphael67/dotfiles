# Claude Code Status Lines Reference

## What Are Status Lines?

Status lines are dynamic terminal displays that show real-time conversation context at the bottom of your terminal during Claude Code sessions. They are Python scripts that receive JSON input and output formatted text.

## Configuration

Set in `settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "uv run $CLAUDE_PROJECT_DIR/.claude/status_lines/status_line.py"
  }
}
```

Or use `/statusline` command in Claude Code for interactive setup.

## Status Line Input Schema

Status lines receive JSON via stdin with these fields:

| Field | Type | Description |
|-------|------|-------------|
| `cwd` | string | Current working directory |
| `session_id` | string | Unique session identifier |
| `model` | string | Current model (e.g., "claude-opus-4-6") |
| `permission_mode` | string | Current permission mode |
| `message_count` | number | Total messages in conversation |
| `turns` | number | Number of conversation turns |
| `conversation` | object | Last few messages with role/content |
| `context_window` | object | `used`, `total`, `percentage` |
| `cost` | object | `total_cost`, `input_tokens`, `output_tokens`, `cache_creation_tokens`, `cache_read_tokens` |
| `duration` | object | `start_time`, `elapsed_seconds` |
| `line_changes` | object | `additions`, `deletions` |

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
Shows git branch, directory, and model info:
```python
branch = subprocess.run(['git', 'rev-parse', '--abbrev-ref', 'HEAD'],
                       capture_output=True, text=True).stdout.strip()
model_short = data.get('model', '').split('-')[-1][:6]
print(f"⎇ {branch} | 📁 {os.path.basename(cwd)} | 🤖 {model_short}")
```

### v5: Cost Tracking
Adds cost and line change tracking:
```python
cost = data.get('cost', {}).get('total_cost', 0)
adds = data.get('line_changes', {}).get('additions', 0)
dels = data.get('line_changes', {}).get('deletions', 0)
print(f"💰 ${cost:.2f} | +{adds}/-{dels} lines | ⏱ {elapsed}")
```

### v6: Context Window Usage
Visual bar showing context consumption:
```python
ctx = data.get('context_window', {})
pct = ctx.get('percentage', 0)
bar_len = 20
filled = int(bar_len * pct / 100)
bar = "█" * filled + "░" * (bar_len - filled)
color = GREEN if pct < 60 else YELLOW if pct < 80 else RED
print(f"Context: {color}[{bar}] {pct}%{RESET}")
```

### v8: Token/Cache Stats
Shows detailed token usage with cache efficiency:
```python
cost_data = data.get('cost', {})
input_t = cost_data.get('input_tokens', 0)
output_t = cost_data.get('output_tokens', 0)
cache_r = cost_data.get('cache_read_tokens', 0)
cache_w = cost_data.get('cache_creation_tokens', 0)
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

1. **Keep it fast**: Status lines run frequently (300ms throttle), keep execution < 100ms
2. **Handle errors gracefully**: Print empty string on failure, never crash
3. **Truncate long text**: Use ellipsis for prompts > 50 chars
4. **Use colors sparingly**: Aid readability without visual noise
5. **Cache expensive calls**: Don't run git commands every refresh
6. **Test with**: `echo '{"session_id":"test","model":"claude-opus-4-6"}' | python status_line.py`
