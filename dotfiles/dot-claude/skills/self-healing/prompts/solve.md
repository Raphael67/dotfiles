# Solution Extraction Prompt

You are analyzing classified mistakes from Claude Code conversations to extract actionable learnings.

## Input

You will receive a list of mistakes in a specific category, along with their session context. Each mistake includes:
- `description`: what went wrong
- `session_file`: path to the session log
- `line_number`: where in the log this occurred
- `tool_name`: the tool involved
- `tool_input`: what was passed (truncated)
- `result`: the error or output (truncated)
- `next_user_message`: what the user said (truncated)
- `project_path`: which project this happened in

You may also receive relevant session context (surrounding messages) for each mistake.

## Task

For each mistake, determine:

1. **Was it resolved?** Did the conversation show a successful fix after the error?
2. **What's the root cause?** Why did Claude make this mistake?
3. **What's the learning?** A concrete, actionable rule to prevent recurrence.

## Output Format

Return a JSON object:

```json
{
  "learnings": [
    {
      "resolved": true,
      "rule": "When working in <project>, always use <path> for <purpose> instead of <wrong path>",
      "scope": "project",
      "project_path": "/Users/foo/project",
      "confidence": "high",
      "source_description": "Used wrong config path 3 times before correction"
    },
    {
      "resolved": false,
      "rule": "Never use tool X for Y; use tool Z instead",
      "scope": "global",
      "project_path": null,
      "confidence": "medium",
      "source_description": "User corrected tool choice but conversation ended"
    }
  ],
  "unresolved": [
    {
      "description": "Repeatedly failed to parse YAML config but never found root cause",
      "session_file": "/path/to/session.jsonl",
      "line_number": 42,
      "context": "Brief summary of what happened"
    }
  ]
}
```

## Rules for Learnings

- **Be specific**: "Use `bun test` not `npm test` in bun projects" > "Use the right test runner"
- **Be actionable**: Rules should be directly usable as memory entries
- **Format as**: "When X, do Y instead of Z" or "In <context>, always/never <action>"
- **Scope correctly**: Project-specific rules get `scope: "project"`, general rules get `scope: "global"`
- **Confidence levels**:
  - `high`: Clear error + clear fix, or user explicitly stated the rule
  - `medium`: Error is clear but fix is inferred
  - `low`: Pattern is suggestive but not conclusive
- **Deduplicate**: If multiple mistakes lead to the same learning, combine them into one rule
- **Skip trivials**: Don't create rules for one-off typos or transient errors
