# Self-Update Workflow

Fetch upstream documentation for all configured tools, review all reference files with parallel subagents, and auto-apply updates.

## Variables

```
SKILL_DIR = .claude/skills/dotfiles
STATE_FILE = $SKILL_DIR/.self-update-state.json
```

### Documentation URLs

| Source | URL | Maps To |
|--------|-----|---------|
| Ghostty docs | https://ghostty.org/docs | GHOSTTY.md |
| Starship config | https://starship.rs/config/ | STARSHIP.md |
| Catppuccin releases | https://github.com/catppuccin/catppuccin/releases | TOOLS.md, GHOSTTY.md |
| Nushell config | https://www.nushell.sh/book/configuration.html | TOOLS.md |
| GNU Stow manual | https://www.gnu.org/software/stow/manual/stow.html | STOW.md |
| TPM releases | https://github.com/tmux-plugins/tpm/releases | TMUX.md |
| Neovim docs | https://neovim.io/doc/user/ | NEOVIM.md |

## Workflow

### Step 0: Read State File

Read `$STATE_FILE` to get last update timestamp.

- If file doesn't exist or is corrupt, treat as first run
- Extract `lastUpdateTimestamp` for comparison

### Step 1: Fetch Documentation (Parallel)

Launch 7 parallel WebFetch calls:

| URL | Prompt |
|-----|--------|
| Ghostty docs | Extract all configuration options, shell integration, keybindings, and theme format changes. Focus on breaking changes and new features. |
| Starship config | Extract all module options, format strings, palette syntax, and new modules. Focus on new features and changed defaults. |
| Catppuccin releases | Extract recent releases, theme naming changes, new ports, and migration guides. |
| Nushell config | Extract configuration syntax, environment setup, plugin system, shell integration, and vendor autoload patterns. |
| GNU Stow manual | Extract command options, conflict resolution, ignore lists, and new features. |
| TPM releases | Extract new features, changed plugin format, and compatibility notes. |
| Neovim docs | Extract new features, changed defaults, deprecated options, and Lua API changes. |

### Step 2: Launch Parallel Subagents

Launch **7 parallel Task agents** (subagent_type: general-purpose, model: haiku) to review each reference file.

Each agent receives:
- Combined documentation as context
- One assigned reference file to review
- Instructions to return structured findings

<parallel-agents>
| Agent | File | Instructions |
|-------|------|--------------|
| 1 | GHOSTTY.md | Review against Ghostty docs and Catppuccin releases. Return: outdated_sections[], new_content[], corrections[]. |
| 2 | STARSHIP.md | Review against Starship config docs. Return: outdated_sections[], new_content[], corrections[]. |
| 3 | TOOLS.md | Review against Catppuccin releases and Nushell config. Return: outdated_sections[], new_content[], corrections[]. |
| 4 | ZSH.md | Review against current dot-zshrc for drift. Return: outdated_sections[], new_content[], corrections[]. |
| 5 | TMUX.md | Review against TPM releases. Return: outdated_sections[], new_content[], corrections[]. |
| 6 | NEOVIM.md | Review against Neovim docs. Return: outdated_sections[], new_content[], corrections[]. |
| 7 | STOW.md | Review against GNU Stow manual. Return: outdated_sections[], new_content[], corrections[]. |
</parallel-agents>

**Agent Prompt Template:**

```
You are reviewing a dotfiles skill reference file for updates.

<context>
<documentation>
{RELEVANT_DOCS}
</documentation>
</context>

<file-to-review>
{FILE_CONTENT}
</file-to-review>

<instructions>
1. Compare the file content against the documentation
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

### Step 3: Collect and Consolidate Results

Wait for all 7 agents to complete. Consolidate findings:

- Group changes by file
- Deduplicate overlapping suggestions
- Prioritize corrections over additions
- Flag any conflicting recommendations

### Step 4: Apply Updates

For each file with changes:

1. Read current file content
2. Apply corrections first (highest priority)
3. Apply content updates
4. Add new content sections
5. Verify file still parses correctly

**Error Handling:**
- If Edit fails, log error and continue with next file
- Track which edits succeeded/failed for report

### Step 5: Update State File

Write updated state to `$STATE_FILE`:

```json
{
  "lastUpdateTimestamp": "{CURRENT_ISO_TIMESTAMP}",
  "updateHistory": [
    {
      "timestamp": "{CURRENT_ISO_TIMESTAMP}",
      "filesUpdated": ["{LIST_OF_FILES}"],
      "changesApplied": {COUNT}
    },
    ...previous_history
  ]
}
```

### Step 6: Generate Report

Output a human-readable summary:

```
## Self-Update Complete

**Date:** {CURRENT_DATE}

### Files Updated

| File | Changes | Status |
|------|---------|--------|
| GHOSTTY.md | +2 sections, ~1 correction | ✓ Updated |
| TOOLS.md | No changes needed | - Skipped |
| ... | ... | ... |

### Change Details

#### GHOSTTY.md
- Added: Nushell integration section
- Corrected: Theme naming format
- Updated: Shell integration options

#### ...

### Summary

- **Files reviewed:** 7
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

## Up-to-Date Detection

If no documentation has changed since `lastUpdateTimestamp`:

```
## Self-Update Check

Already up to date!

**Last Updated:** {TIMESTAMP}
**Files Tracked:** 7
```

Skip steps 2-5, exit early.
