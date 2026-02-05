# Self-Update Workflow

Fetch rclone and cloud provider documentation, review all reference files with parallel subagents, and auto-apply updates.

## Variables

```
SKILL_DIR = ~/.claude/skills/cloud-expert
STATE_FILE = $SKILL_DIR/.self-update-state.json
```

### Documentation URLs

| Source | URL | Maps To |
|--------|-----|---------|
| rclone commands | https://rclone.org/commands/ | RCLONE.md |
| rclone install | https://rclone.org/install/ | RCLONE.md |
| rclone docs | https://rclone.org/docs/ | RCLONE.md |
| rclone flags | https://rclone.org/flags/ | RCLONE.md |
| OneDrive backend | https://rclone.org/onedrive/ | ONEDRIVE.md |
| Google Drive backend | https://rclone.org/drive/ | GOOGLE-DRIVE.md |
| iCloud backend | https://rclone.org/iclouddrive/ | ICLOUD.md |
| OneDrive API | https://learn.microsoft.com/en-us/onedrive/developer/rest-api/ | ONEDRIVE.md |
| Google Drive API | https://developers.google.com/workspace/drive/api/guides/about-sdk | GOOGLE-DRIVE.md |

## Workflow

### Step 0: Read State File

Read `$STATE_FILE` to get last update timestamp and rclone version.

- If file doesn't exist or is corrupt, treat as first run
- Extract `lastUpdateTimestamp` and `rcloneVersion` for comparison

### Step 1: Check rclone Version

Run `rclone --version` to get current installed version.

- Compare with `rcloneVersion` in state file
- If same version and updated within last 7 days, report "up to date" and stop
- Otherwise continue with update

### Step 2: Fetch Documentation (Parallel)

Launch **9 parallel WebFetch calls** for all documentation URLs listed above.

| URL | Prompt |
|-----|--------|
| rclone commands | Extract all rclone commands with their descriptions, key flags, and usage examples. Focus on sync, copy, move, bisync, mount, nfsmount, serve, check, dedupe. |
| rclone install | Extract installation methods for all platforms, especially macOS Homebrew. Note any mount-related limitations. |
| rclone docs | Extract core rclone concepts: remotes, config file, encryption, VFS cache modes, filtering, logging levels. |
| rclone flags | Extract all global flags organized by category: performance, safety, filtering, logging, VFS cache tuning. |
| OneDrive backend | Extract OneDrive backend configuration: auth, Personal vs Business, SharePoint, delta queries, quirks, limits, Graph API usage. |
| Google Drive backend | Extract Google Drive backend configuration: auth, scopes, custom Client ID, rate limits, fast-list, dedup, Docs export, Shared Drives. |
| iCloud backend | Extract iCloud Drive backend configuration: auth requirements, trust token, ADP, limitations, experimental status. |
| OneDrive API | Extract Microsoft Graph API endpoints for OneDrive/SharePoint: sites, drives, files, permissions, rate limits. |
| Google Drive API | Extract Google Drive API overview: endpoints, scopes, quotas, best practices for file operations. |

### Step 3: Launch Parallel Subagents

Launch **5 parallel Task agents** (subagent_type: general-purpose, model: haiku) to review each reference file.

Each agent receives:
- Combined documentation from relevant URLs as context
- One assigned reference file to review
- Instructions to return structured findings

**Do NOT update MY-SETUP.md** — it documents user-specific infrastructure and should only be changed manually.

<parallel-agents>
| Agent | File | Documentation Sources |
|-------|------|----------------------|
| 1 | RCLONE.md | rclone commands + install + docs + flags |
| 2 | ONEDRIVE.md | OneDrive backend + OneDrive API |
| 3 | GOOGLE-DRIVE.md | Google Drive backend + Google Drive API |
| 4 | ICLOUD.md | iCloud backend |
| 5 | TROUBLESHOOTING.md | All sources (cross-cutting) |
</parallel-agents>

**Agent Prompt Template:**

```
You are reviewing a cloud storage reference file for updates.

<context>
<documentation>
{RELEVANT_DOCS}
</documentation>
</context>

<current-rclone-version>
{RCLONE_VERSION}
</current-rclone-version>

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

Wait for all 5 agents to complete. Consolidate findings:

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
  "rcloneVersion": "{CURRENT_RCLONE_VERSION}",
  "updateHistory": [
    {
      "timestamp": "{CURRENT_ISO_TIMESTAMP}",
      "rcloneVersion": "{RCLONE_VERSION}",
      "filesUpdated": ["{LIST_OF_FILES}"],
      "changesApplied": {COUNT}
    },
    ...previous_history
  ]
}
```

### Step 7: Generate Report

Output a human-readable summary:

```
## Self-Update Complete

**rclone Version:** {PREVIOUS_VERSION} → {NEW_VERSION}
**Date:** {CURRENT_DATE}

### Files Updated

| File | Changes | Status |
|------|---------|--------|
| RCLONE.md | +3 sections, ~2 corrections | Updated |
| ONEDRIVE.md | No changes needed | Skipped |
| ... | ... | ... |

### Change Details

#### RCLONE.md
- Added: New command documentation
- Corrected: VFS cache default values
- Updated: Flag descriptions

#### ...

### Summary

- **Files reviewed:** 5
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
| rclone not installed | Report error, skip version check, continue with docs |

## Up-to-Date Detection

If rclone version matches and last update was within 7 days:

```
## Self-Update Check

Already up to date!

**rclone Version:** {VERSION}
**Last Updated:** {TIMESTAMP}
**Files Tracked:** 5
```

Skip steps 3-6, exit early.
