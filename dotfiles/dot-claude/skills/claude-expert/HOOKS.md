# Claude Code Hooks Reference

## What Are Hooks?

Hooks are scripts or prompts that execute in response to Claude Code events. They can validate, block, modify, or log operations.

## Hook Events

| Hook | Trigger | Use Case |
|------|---------|----------|
| `PreToolUse` | Before tool execution | Security validation, blocking dangerous commands |
| `PostToolUse` | After tool execution | Logging, notifications |
| `PostToolUseFailure` | After tool fails | Error handling |
| `UserPromptSubmit` | When user sends a message | Logging, preprocessing |
| `Stop` | When Claude finishes responding | Notifications, cleanup |
| `SubagentStart` | When subagent spawns | Monitoring initialization |
| `SubagentStop` | When subagent finishes | Logging results |
| `SessionStart` | Session begins/resumes | Environment setup |
| `SessionEnd` | Session terminates | Cleanup, logging |
| `PreCompact` | Before context compaction | Pre-compaction actions |
| `Setup` | On --init or --maintenance | Initial setup |
| `PermissionRequest` | Permission dialog shown | Dynamic permission decisions |
| `Notification` | Claude sends notification | Desktop notifications |

## Configuration Location

Hooks are configured in `~/.claude/settings.json` under the `hooks` key:

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

### Fields

| Field | Description |
|-------|-------------|
| `matcher` | Tool name to match (e.g., `Bash`, `Edit`, `Write`) |
| `hooks` | Array of hook definitions |
| `type` | `command` (script) or `prompt` (LLM validation) |
| `command` | Script path to execute |
| `prompt` | Prompt for LLM validation |
| `timeout` | Timeout in seconds |

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

### Prompt Hook
Uses LLM for validation:

```json
{
  "type": "prompt",
  "prompt": "You are a security reviewer. Analyze this command: $ARGUMENTS\n\nRespond with JSON: {\"decision\": \"approve\" or \"block\", \"reason\": \"explanation\"}",
  "timeout": 10
}
```

## Exit Codes (Command Hooks)

| Code | Effect |
|------|--------|
| `0` | Allow (or check JSON output) |
| `2` | Block (stderr fed back to Claude) |

## JSON Output for Ask Decision

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

## Input Format

Hooks receive JSON on stdin:

```json
{
  "tool_name": "Bash",
  "tool_input": {
    "command": "rm -rf /tmp/test"
  }
}
```

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

## Best Practices

1. **Keep hooks fast**: Use `timeout` to prevent hangs
2. **Fail open**: Exit 0 on errors to avoid blocking legitimate work
3. **Log decisions**: Write to log file for debugging
4. **Use patterns file**: Separate configuration from code
5. **Test thoroughly**: Verify both block and allow cases
6. **Chain hooks**: Multiple hooks run in parallel, all must pass

## Environment Variables

| Variable | Description |
|----------|-------------|
| `CLAUDE_PROJECT_DIR` | Absolute path to project root |
| `CLAUDE_CODE_REMOTE` | `true` if running in remote/web environment |
| `CLAUDE_ENV_FILE` | Path to persist env vars (SessionStart only) |

## Advanced Hook Output

### PreToolUse Decision Control
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

### SessionStart Matchers
- `startup` - New session
- `resume` - Resumed session
- `clear` - After /clear
- `compact` - After compaction

### SessionEnd Reasons
- `clear` - Session cleared
- `logout` - User logged out
- `prompt_input_exit` - Exited at prompt
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
