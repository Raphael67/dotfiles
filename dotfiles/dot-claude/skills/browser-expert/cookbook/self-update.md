# Self-Update Workflow

Fetch Playwright, MCP tool, and browser tool documentation, review all reference files with parallel subagents, and auto-apply updates.

## Variables

```
SKILL_DIR = ~/.claude/skills/browser-expert
STATE_FILE = $SKILL_DIR/.self-update-state.json
```

### Documentation URLs

| Source | URL | Maps To |
|--------|-----|---------|
| Playwright docs | https://playwright.dev/docs/intro | TESTING.md |
| Playwright API | https://playwright.dev/docs/api/class-page | TESTING.md |
| Playwright releases | https://github.com/microsoft/playwright/releases | All files |
| pw-fast repo | https://github.com/tontoko/fast-playwright-mcp | SCRAPING.md |
| pw-writer repo | https://github.com/remorses/playwriter | SCRAPING.md |
| Claude Chrome docs | https://code.claude.com/docs/en/chrome | TOOLS.md |
| Chrome DevTools MCP | https://github.com/ChromeDevTools/chrome-devtools-mcp | TOOLS.md |
| Firefox MCP | https://github.com/hyperpolymath/claude-firefox-mcp | TOOLS.md |
| Tadpole | https://github.com/tadpolehq/tadpole | SCRAPING.md |
| Tadpole community | https://github.com/tadpolehq/community | SCRAPING.md |
| bdg CLI | https://github.com/szymdzum/browser-debugger-cli | TOOLS.md |

## Workflow

### Step 0: Read State File

Read `$STATE_FILE` to get last update timestamp and Playwright version.

- If file doesn't exist or is corrupt, treat as first run
- Extract `lastUpdateTimestamp` and `playwrightVersion` for comparison

### Step 1: Check Playwright Version

Run `npx playwright --version` to get current installed version.

- Compare with `playwrightVersion` in state file
- If same version and updated within last 7 days, report "up to date" and stop
- Otherwise continue with update

### Step 2: Fetch Documentation (Parallel)

Launch **11 parallel WebFetch calls** for all documentation URLs listed above.

| URL | Prompt |
|-----|--------|
| Playwright docs | Extract core concepts, setup, configuration, locators, assertions, test structure, fixtures, hooks. Focus on what changed recently. |
| Playwright API | Extract Page API methods, locator methods, assertion methods. Note any new or deprecated APIs. |
| Playwright releases | Extract release notes for recent versions. Focus on breaking changes, new features, deprecations. |
| pw-fast repo | Extract README: tool list, selector system, batch execution, expectation parameter, configuration options. |
| pw-writer repo | Extract README: utilities (getCleanHTML, accessibilitySnapshot, etc.), setup, architecture, API changes. |
| Claude Chrome docs | Extract setup requirements, capabilities, limitations, troubleshooting. Note version requirements. |
| Chrome DevTools MCP | Extract README: tool list, categories, setup, configuration options. |
| Firefox MCP | Extract README: setup, capabilities, architecture, supported applications. |
| Tadpole | Extract README: KDL syntax, CLI flags, actions, evaluators, module system, expression system. |
| Tadpole community | Extract available community modules, usage patterns. |
| bdg CLI | Extract README: commands, domains, usage patterns, configuration. |

### Step 3: Launch Parallel Subagents

Launch **8 parallel Task agents** (subagent_type: general-purpose, model: haiku) to review each reference file.

Each agent receives:
- Combined documentation from relevant URLs as context
- One assigned reference file to review
- Instructions to return structured findings

**Do NOT update CYPRESS-MIGRATION.md** — it's a standalone guide that doesn't need automated updates.

<parallel-agents>
| Agent | File | Documentation Sources |
|-------|------|----------------------|
| 1 | SKILL.md | All sources (overview, tool comparison) |
| 2 | TESTING.md | Playwright docs + API + releases |
| 3 | SCRAPING.md | pw-fast + pw-writer repos + Tadpole + Tadpole community |
| 4 | TOOLS.md | Claude Chrome + DevTools MCP + Firefox MCP + bdg CLI |
| 5 | TESTING-PATTERNS.md | Playwright docs + API + releases |
| 6 | SCRAPING-PATTERNS.md | pw-fast + pw-writer repos + Tadpole + Tadpole community |
| 7 | TROUBLESHOOTING.md | All sources (cross-cutting) |
| 8 | cookbook/self-update.md | All sources (URL validation) |
</parallel-agents>

**Agent Prompt Template:**

```
You are reviewing a browser automation reference file for updates.

<context>
<documentation>
{RELEVANT_DOCS}
</documentation>
</context>

<current-playwright-version>
{PLAYWRIGHT_VERSION}
</current-playwright-version>

<file-to-review>
{FILE_CONTENT}
</file-to-review>

<instructions>
1. Compare the file content against the fetched documentation
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

Wait for all 8 agents to complete. Consolidate findings:

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
  "playwrightVersion": "{CURRENT_PLAYWRIGHT_VERSION}",
  "updateHistory": [
    {
      "timestamp": "{CURRENT_ISO_TIMESTAMP}",
      "playwrightVersion": "{PLAYWRIGHT_VERSION}",
      "filesUpdated": ["{LIST_OF_FILES}"],
      "changesApplied": "{COUNT}"
    },
    ...previous_history
  ]
}
```

### Step 7: Generate Report

Output a human-readable summary:

```
## Self-Update Complete

**Playwright Version:** {PREVIOUS_VERSION} → {NEW_VERSION}
**Date:** {CURRENT_DATE}

### Files Updated

| File | Changes | Status |
|------|---------|--------|
| TESTING.md | +3 sections, ~2 corrections | Updated |
| TOOLS.md | No changes needed | Skipped |
| ... | ... | ... |

### Change Details

#### TESTING.md
- Added: New assertion methods
- Corrected: Config example
- Updated: CLI commands

#### ...

### Summary

- **Files reviewed:** 8
- **Files updated:** X
- **Changes applied:** Y
```

## Error Handling

| Error | Action |
|-------|--------|
| WebFetch failure | Continue with available sources, note in report |
| Subagent timeout | Mark file as "review skipped", continue |
| State file missing | Create new, treat as first run |
| State file corrupt | Backup and create new |
| Edit failure | Log error, continue with next file, report at end |
| Playwright not installed | Report error, skip version check, continue with docs |

## Up-to-Date Detection

If Playwright version matches and last update was within 7 days:

```
## Self-Update Check

Already up to date!

**Playwright Version:** {VERSION}
**Last Updated:** {TIMESTAMP}
**Files Tracked:** 8
```

Skip steps 3-6, exit early.
