# Self-Update Workflow

Fetch Claude Code changelog and documentation, review all reference files with parallel subagents, and auto-apply updates.

## Variables

```
SKILL_DIR = ~/.claude/skills/claude-expert
STATE_FILE = $SKILL_DIR/.self-update-state.json
CHANGELOG_URL = https://github.com/anthropics/claude-code/releases
```

### Documentation URLs

| Source | URL | Maps To |
|--------|-----|---------|
| GitHub Releases | https://github.com/anthropics/claude-code/releases | All files |
| Skills Docs | https://code.claude.com/docs/en/skills | SKILLS.md |
| Hooks Docs | https://code.claude.com/docs/en/hooks | HOOKS.md |
| MCP Docs | https://code.claude.com/docs/en/mcp | MCP.md |
| Agent SDK | https://code.claude.com/docs/en/sub-agents | SUBAGENTS.md |
| Anthropic News | https://www.anthropic.com/news | PROMPTING.md (model updates) |

### Model-Specific Sources

For model updates and capabilities, also check:
- https://www.anthropic.com/news/claude-opus-4-6 (or latest model announcement)
- Look for new model announcements on https://www.anthropic.com/news

## Workflow

### Step 0: Read State File

Read `$STATE_FILE` to get last update timestamp and version.

- If file doesn't exist or is corrupt, treat as first run
- Extract `lastUpdateTimestamp` and `lastVersion` for comparison

### Step 1: Fetch Changelog

Use WebFetch to retrieve GitHub releases:

```
URL: https://github.com/anthropics/claude-code/releases
Prompt: Extract release notes since {lastVersion}. For each release, list: version number, release date, new features, breaking changes, and deprecations. Format as structured data.
```

### Step 2: Fetch Documentation (Parallel)

Launch 5 parallel WebFetch calls:

| URL | Prompt |
|-----|--------|
| Skills Docs | Extract all information about Claude Code skills: file structure, YAML frontmatter options, cookbook patterns, auto-discovery behavior, and best practices. |
| Hooks Docs | Extract all information about Claude Code hooks: PreToolUse, PostToolUse, event types, exit codes, JSON output format, and configuration options. |
| MCP Docs | Extract all information about MCP in Claude Code: server configuration, transport types, tool definitions, resource handling, and troubleshooting. |
| Agent SDK Docs | Extract all information about sub-agents in Claude Code: agent definition files, YAML options, tool restrictions, Task tool usage, and parallel execution. |
| Anthropic News | Extract recent announcements about Claude models: new model releases, capabilities, pricing, API changes, and features. Focus on model IDs, performance benchmarks, and technical details. |

### Step 3: Launch Parallel Subagents

Launch **7 parallel Task agents** (subagent_type: general-purpose, model: haiku) to review each reference file.

Each agent receives:
- Combined changelog + relevant documentation as context
- One assigned reference file to review
- Instructions to return structured findings

<parallel-agents>
| Agent | File | Instructions |
|-------|------|--------------|
| 1 | SKILLS.md | Review against skills docs. Return: outdated_sections[], new_content[], corrections[]. |
| 2 | COMMANDS.md | Review against changelog for command changes. Return: outdated_sections[], new_content[], corrections[]. |
| 3 | SUBAGENTS.md | Review against agent SDK docs. Return: outdated_sections[], new_content[], corrections[]. |
| 4 | WORKFLOWS.md | Review against changelog for workflow features. Return: outdated_sections[], new_content[], corrections[]. |
| 5 | PROMPTING.md | Review against changelog for prompting changes. Return: outdated_sections[], new_content[], corrections[]. |
| 6 | HOOKS.md | Review against hooks docs. Return: outdated_sections[], new_content[], corrections[]. |
| 7 | MCP.md | Review against MCP docs. Return: outdated_sections[], new_content[], corrections[]. |
</parallel-agents>

**Agent Prompt Template:**

```
You are reviewing a Claude Code reference file for updates.

<context>
<changelog>
{CHANGELOG_CONTENT}
</changelog>

<documentation>
{RELEVANT_DOCS}
</documentation>
</context>

<file-to-review>
{FILE_CONTENT}
</file-to-review>

<instructions>
1. Compare the file content against the changelog and documentation
2. Identify sections that are outdated or incorrect
3. Identify new features/content that should be added
4. Identify corrections needed

Return your findings in this exact format:
</instructions>

<output-format>
OUTDATED_SECTIONS:
- section_name: "Section Title"
  issue: "Description of what's outdated"
  suggested_fix: "How to fix it"

NEW_CONTENT:
- location: "Where to add (after section X)"
  content: "Content to add"
  reason: "Why this should be added"

CORRECTIONS:
- line_or_section: "Location"
  current: "Current text"
  corrected: "Corrected text"
  reason: "Why this correction is needed"

NO_CHANGES_NEEDED: true/false
SUMMARY: "One-line summary of findings"
</output-format>
```

### Step 4: Collect and Consolidate Results

Wait for all 7 agents to complete. Consolidate findings:

- Group changes by file
- Deduplicate overlapping suggestions
- Prioritize corrections over additions
- Flag any conflicting recommendations

### Step 5: Apply Updates

For each file with changes:

1. Read current file content
2. Apply corrections first (highest priority)
3. Apply content updates
4. Add new content sections
5. Verify file still parses correctly

**Error Handling:**
- If Edit fails, log error and continue with next file
- Track which edits succeeded/failed for report

### Step 6: Update State File

Write updated state to `$STATE_FILE`:

```json
{
  "lastUpdateTimestamp": "{CURRENT_ISO_TIMESTAMP}",
  "lastVersion": "{LATEST_VERSION_FROM_CHANGELOG}",
  "updateHistory": [
    {
      "timestamp": "{CURRENT_ISO_TIMESTAMP}",
      "version": "{LATEST_VERSION}",
      "filesUpdated": ["{LIST_OF_FILES}"],
      "changesApplied": {COUNT},
      "newFeatures": ["{LIST_OF_NEW_FEATURES}"]
    },
    ...previous_history
  ]
}
```

### Step 7: Generate Report

Output a human-readable summary:

```
## Self-Update Complete

**Version:** {PREVIOUS_VERSION} → {NEW_VERSION}
**Date:** {CURRENT_DATE}

### New Features Detected

| Feature | Version | Affects |
|---------|---------|---------|
| ... | ... | ... |

### Files Updated

| File | Changes | Status |
|------|---------|--------|
| SKILLS.md | +3 sections, ~2 corrections | ✓ Updated |
| HOOKS.md | No changes needed | - Skipped |
| ... | ... | ... |

### Change Details

#### SKILLS.md
- Added: New cookbook patterns section
- Corrected: YAML frontmatter options list
- Updated: Auto-discovery behavior description

#### ...

### Summary

- **Files reviewed:** 7
- **Files updated:** X
- **Changes applied:** Y
- **New features documented:** Z
```

## Error Handling

| Error | Action |
|-------|--------|
| WebFetch failure | Continue with available sources, note in report |
| Subagent timeout | Mark file as "review skipped", continue |
| State file missing | Create new, treat as first run |
| State file corrupt | Backup and create new |
| Edit failure | Log error, continue with next file, report at end |

## Up-to-Date Detection

If changelog shows no new versions since `lastVersion`:

```
## Self-Update Check

Already up to date!

**Current Version:** {VERSION}
**Last Updated:** {TIMESTAMP}
**Files Tracked:** 7
```

Skip steps 3-6, exit early.
