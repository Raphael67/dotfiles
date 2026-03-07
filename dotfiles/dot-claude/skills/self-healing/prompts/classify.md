# Classification Prompt

You are classifying extractions from Claude Code conversation logs to identify genuine mistakes.

## Input

You will receive a JSON array of extractions. Each has:
- `tool_name`: the tool that was used
- `tool_input`: what was passed to the tool (truncated)
- `result`: the tool result or error message (truncated)
- `is_error`: whether the tool returned an error
- `next_user_message`: what the user said next (truncated)
- `type`: `tool_error` or `user_correction`

## Task

For each extraction, classify it as either `mistake` or `not_mistake`.

**`mistake`** = Claude made an avoidable error that could be prevented by a memory rule. Examples:
- Used wrong file path repeatedly
- Used wrong tool for the task
- Misunderstood what the user wanted
- Made a syntax or config error
- Ignored a permission or access constraint
- Repeated the same failing approach multiple times

**`not_mistake`** = Normal operation, exploratory behavior, or unavoidable error. Examples:
- First-time file-not-found while exploring a codebase
- User changed their mind (not a correction)
- Tool timeout or transient network error
- User said "no" to a confirmation prompt (normal flow)
- Correction patterns in unrelated user text

## Categories (for mistakes only)

- `FILE_PATH_ERROR` - Wrong file path, missing file, wrong directory
- `WRONG_TOOL` - Used incorrect tool for the task
- `MISUNDERSTOOD_INTENT` - Did something different from what user asked
- `CONFIG_ERROR` - Wrong configuration, settings, or environment assumption
- `SYNTAX_ERROR` - Code syntax, JSON, YAML, or format errors
- `PERMISSION_ERROR` - Ignored access constraints or permissions
- `REPEATED_FAILURE` - Tried the same failing approach multiple times
- `OTHER` - Mistake that doesn't fit above categories

## Output Format

Return a JSON array with one object per extraction:

```json
[
  {
    "index": 0,
    "classification": "mistake",
    "category": "FILE_PATH_ERROR",
    "description": "Used /src/app.ts instead of /src/main.ts for the entry point"
  },
  {
    "index": 1,
    "classification": "not_mistake",
    "category": null,
    "description": "Normal exploratory file read"
  }
]
```

Be conservative: only classify as `mistake` if there's clear evidence of an avoidable error. When in doubt, classify as `not_mistake`.
