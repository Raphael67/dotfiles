# Self-Update Procedure

Updates the agent-expert skill from web sources and local repositories.

## Sources

| Source | Type | URL / Path | Updates |
|--------|------|------------|---------|
| Pi docs | Web | https://shittycodingagent.ai/ | PI.md |
| OpenRouter docs | Web | https://openrouter.ai/docs/quickstart | OPENROUTER.md |
| OpenCode docs | Web | https://opencode.ai/docs | OPENCODE.md |
| Pi mono repo | Local | ~/Projects/pi-mono | PI.md (deep) |
| OpenCode repo | Local | ~/Projects/opencode | OPENCODE.md (deep) |
| Claude leaked files | Local | ~/Projects/claude-leaked-files | CLAUDE-CODE.md |
| Pi vs CC comparison | Local | ~/Projects/pi-vs-claude-code | COMPARISON.md |

## Procedure

### Step 1: Check last update
```bash
cat ~/.claude/skills/agent-expert/.self-update-state.json
```

### Step 2: Fetch web sources
Use WebFetch to retrieve current documentation from each web URL listed above. Extract key changes (new features, API changes, new models/providers).

### Step 3: Check local repos (if present)
For each local repo path:
1. Check if directory exists: `ls <path>/`
2. If exists, check recent changes: `git -C <path> log --oneline -10`
3. Read key files for updates:
   - Pi: `packages/coding-agent/docs/*.md`, `AGENTS.md`
   - OpenCode: `packages/opencode/src/agent/`, `packages/opencode/src/provider/`, `AGENTS.md`
   - Claude leaked: `README.md`, `tools.ts`, `tasks.ts`
   - Pi vs CC: `COMPARISON.md`, `PI_VS_OPEN_CODE.md`, `TOOLS.md`

### Step 4: Update reference files
For each skill file that has new information:
1. Read the current file
2. Identify sections that need updates
3. Apply edits (preserve structure, update content)

### Step 5: Update state file
Write updated timestamp to `.self-update-state.json`:
```json
{
  "lastUpdate": "2026-04-15T12:00:00Z",
  "sources": {
    "shittycodingagent.ai": "2026-04-15",
    "openrouter.ai": "2026-04-15",
    "opencode.ai": "2026-04-15",
    "pi-mono": "2026-04-15",
    "opencode-repo": "2026-04-15",
    "claude-leaked": "2026-04-15",
    "pi-vs-cc": "2026-04-15"
  }
}
```

### Step 6: Report changes
Summarize what was updated in each file.
