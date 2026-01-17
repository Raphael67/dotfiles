# Hooks

Hooks allow you to execute custom scripts at specific points in the Gemini CLI lifecycle, enabling automation, logging, and security checks.

## Configuration
Hooks are defined in `.gemini/settings.json` (Project or User).

```json
{
  "hooks": {
    "my-pre-commit-hook": {
      "type": "command",
      "command": "python3 scripts/check-secrets.py",
      "description": "Checks for secrets before writing files",
      "matcher": "write_file|replace",
      "on": "BeforeTool"
    }
  }
}
```

## Events (`on`)
*   `SessionStart` / `SessionEnd`
*   `BeforeModel` / `AfterModel`: Before sending to/receiving from LLM.
*   `BeforeTool` / `AfterTool`: Before/after tool execution.
*   `BeforeAgent` / `AfterAgent`: Before/after sub-agent delegation.
*   `BeforeToolSelection`: Intercept/modify tool calls.

## Matchers
Used with Tool events to filter specific tools.
*   `*`: All tools.
*   `write_file`: Only `write_file`.
*   `read_*`: Wildcard matching.

## Writing Hooks
Scripts receive a JSON payload via `stdin` and must output a JSON payload to `stdout`.

### Input Payload (Example)
```json
{
  "event": "BeforeTool",
  "tool": "write_file",
  "input": { "file_path": "...", "content": "..." },
  "context": { ... }
}
```

### Output Payload
*   **Continue:** `{ "action": "continue" }`
*   **Reject:** `{ "action": "reject", "message": "Reason for rejection" }`
*   **Modify:** `{ "action": "modify", "input": { ... } }`

## Best Practices
*   **Speed:** Keep hooks fast; they block execution.
*   **Idempotency:** Ensure hooks can run multiple times safely.
*   **Security:** Verify scripts used in project-level hooks.
