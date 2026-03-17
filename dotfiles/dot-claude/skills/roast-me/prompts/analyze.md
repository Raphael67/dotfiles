# Prompt Quality Analysis

You are analyzing user prompts from Claude Code conversation logs to identify prompt quality issues that **actually impacted the outcome**.

## Input

You will receive a JSON array of prompt records. Each has:
- `prompt_text`: the user's message (truncated)
- `prompt_length`: full length before truncation
- `prompt_position`: 1-based index in conversation (1 = opening prompt)
- `total_prompts_in_session`: how many prompts were in this session
- `has_xml_tags`: whether the prompt uses XML structure
- `has_file_paths`: whether file paths are included
- `has_code_blocks`: whether code blocks are included
- `followed_by_error`: whether a tool error occurred after this prompt
- `error_was_recovered`: whether the agent recovered from the error on its own
- `followed_by_correction`: whether the user corrected Claude next
- `correction_text`: what the correction said (truncated)
- `error_tool`: which tool errored
- `error_text`: the error message (truncated)
- `context_before`: what Claude said before this prompt (truncated)

## Critical: Focus on Real Impact

**Only flag issues that actually caused measurable harm.** The user is a productive senior developer — many "errors" are normal agent exploration that gets auto-recovered. Your job is to find the prompts where better prompting would have saved real time or prevented real problems.

### What is NOT an issue (be generous):
- Short follow-ups like "yes", "ok", "commit", "looks good" — normal conversation flow
- Prompts deep in a conversation (high `prompt_position`) that are brief — context is established
- Prompts where `followed_by_error=true` but `error_was_recovered=true` — the agent handled it
- Simple, direct requests that worked fine (no error, no correction)
- System/command messages (like skill invocations with `<command-message>` tags)
- First-time file-not-found while exploring — normal agent behavior
- Errors caused by the agent's own choices, not by the prompt being unclear

### What IS an issue (only flag these):
- Prompt was so vague that the agent went in a completely wrong direction
- Missing context that **directly caused** an unrecovered error or wasted significant work (>10 tool calls)
- User had to correct Claude immediately after — meaning the prompt was misleading
- Multiple unrelated tasks crammed together that caused one to fail
- Prompt led to a dangerous/destructive action (DROP TABLE, mass deletion, etc.)

## Issue Categories

| Code | Description |
|------|-------------|
| `VAGUE` | No specifics — "fix it", "make it work" with no context at all |
| `NO_CONTEXT` | Missing file paths, error messages, or expected behavior that would have helped |
| `NEGATIVE` | Only says "don't do X" instead of stating what to do |
| `NO_CRITERIA` | No way to know when the task is done correctly |
| `WALL_OF_TEXT` | Unstructured paragraph that should use formatting (lists, headers, code blocks) |
| `SCOPE_CREEP` | Multiple unrelated asks crammed into one prompt |
| `SELF_CONTRADICT` | User corrected the approach immediately after asking — prompt was misleading |
| `NO_STRUCTURE` | Complex multi-step request that would benefit from XML/markdown structure |
| `CAUSED_FAILURE` | Prompt directly led to a tool error or wrong direction due to bad/ambiguous instructions |

## Severity Guide
- **high**: Prompt directly caused wasted work (>20 tool calls), dangerous actions, or required significant correction
- **medium**: Prompt caused moderate inefficiency (5-20 wasted tool calls) or minor misdirection
- **low**: Minor improvement possible, prompt mostly worked but could be better

## Output Format

Return a JSON array with one object per prompt that has issues. **Skip prompts with no issues** — most prompts should be fine.

```json
[
  {
    "index": 0,
    "issues": ["VAGUE", "NO_CONTEXT"],
    "severity": "high",
    "impact": "Agent spent 35 tool calls exploring wrong directory before user corrected",
    "explanation": "Opening prompt says 'fix the auth' with no file, error message, or expected behavior",
    "technique": "The '3W Rule': always include What (the problem), Where (file/service), and Why (expected vs actual behavior)",
    "rewrite_suggestion": "Fix the auth middleware in src/middleware/auth.ts — it returns 401 for valid JWT tokens. Expected: valid tokens should pass through. Error: [paste error]",
    "original_prompt_snippet": "first 200 chars of prompt_text"
  }
]
```

**Key fields:**
- `impact`: What actually went wrong as a result — be specific about wasted tool calls, errors, or misdirection
- `technique`: A named, reusable prompting technique that would prevent this issue in the future
- `rewrite_suggestion`: A concrete rewrite of the prompt showing the technique in action

Be constructive and educational. The goal is to teach better prompting, not to find fault.
