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
| GitHub Releases (Code) | https://github.com/anthropics/claude-code/releases | All files |
| Skills Docs | https://code.claude.com/docs/en/skills | SKILLS.md |
| Hooks Docs | https://code.claude.com/docs/en/hooks | HOOKS.md |
| MCP Docs | https://code.claude.com/docs/en/mcp | MCP.md |
| Agent SDK | https://code.claude.com/docs/en/sub-agents | SUBAGENTS.md |
| Memory Docs | https://code.claude.com/docs/en/memory | MEMORY.md |
| Plugins Docs | https://code.claude.com/docs/en/plugins | SKILLS.md |
| Plugins Ref | https://code.claude.com/docs/en/plugins-reference | SKILLS.md |
| Agent Skills Spec | https://agentskills.io/specification | SKILLS.md |
| Anthropic Skills Repo | https://github.com/anthropics/skills | SKILLS.md |
| Anthropic Plugins Repo | https://github.com/anthropics/claude-plugins-official | SKILLS.md |
| Agent Skills Home | https://agentskills.io/home | SKILLS.md |
| Commands Docs | https://code.claude.com/docs/en/commands | COMMANDS.md, SKILLS.md |
| Workflows Docs | https://code.claude.com/docs/en/workflows | WORKFLOWS.md |
| Output Styles Docs | https://code.claude.com/docs/en/output-styles | OUTPUT-STYLES.md |
| Status Line Docs | https://code.claude.com/docs/en/statusline | STATUS-LINES.md |
| Settings Reference | https://code.claude.com/docs/en/settings-reference | All files |
| Hooks Guide | https://code.claude.com/docs/en/hooks-guide | HOOKS.md |
| **Docs index** | https://code.claude.com/docs/llms.txt | discover pages whose slug moved |
| Anthropic News | https://www.anthropic.com/news | All files (model updates, product launches) |
| Claude Desktop Docs (official, works via WebFetch) | https://code.claude.com/docs/en/desktop | DESKTOP.md |
| Claude Desktop Release Notes | https://www.anthropic.com/download | DESKTOP.md |
| Claude Desktop Changelog | https://claude.ai/changelog | DESKTOP.md |
| Claude Desktop Support | https://support.anthropic.com/en/collections/4560928-claude-desktop | DESKTOP.md |

### Claude Desktop Sources

Track Claude Desktop app features, updates, and new capabilities:
- https://claude.ai/changelog — official changelog for Claude.ai and Desktop.
  **Known broken for WebFetch**: returns HTTP 403 (needs an authenticated session).
  Last confirmed failing 2026-09-09. Use a browser or an authenticated tool instead.
- https://www.anthropic.com/news — product announcements (filter for Desktop-related posts)
- https://support.claude.com/en/collections/4560928-claude-desktop — help articles.
  The old `support.anthropic.com` URL 301-redirects here, and this URL returned
  **HTTP 404** again on 2026-09-09. Find the current collection via https://support.claude.com.
- https://code.claude.com/docs/en/desktop — **works via WebFetch** and is the best substitute
  for the two broken sources above: official Desktop feature reference (tabs, MCP config,
  keyboard shortcuts, permission modes, features not available in Desktop). Use this as the
  primary Desktop source; only fall back to the changelog/support pages if this page is also
  down.

When both Desktop sources fail, do **not** invent Desktop features: leave DESKTOP.md alone
apart from corrections other sources support, and record the failure in the report.

### Model-Specific Sources

For model updates and capabilities, also check:
Verified against https://www.anthropic.com/news on 2026-09-09:

- **Claude Opus 5** — announced **2026-07-24**, "a step change improvement for the Opus tier
  powering long-running agents". Still the top generally-available model.
- **Claude Sonnet 5** — announced **2026-06-30**.
- **Claude Fable 5.1** (`claude-fable-5-1`) — announced **2026-09-01**, now the **default Fable
  model** in `/model` (1M context, $10/$50 per MTok, $0.25/MTok cache reads). Fable 5 (the
  earlier 2026-06-30 release) is superseded but gateways not yet configured for 5.1 still
  resolve `fable`/`best` to Fable 5 until updated. The 2026-06-12 export-control suspension is
  long over; do not repeat it as current.
- Look for new model announcements on https://www.anthropic.com/news

> Pricing per MTok is not published on the news index. Do not assert a price you have not
> sourced — check https://code.claude.com/docs or the API pricing page instead.

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

Launch 7 parallel WebFetch calls:

| URL | Prompt |
|-----|--------|
| Skills Docs | Extract all information about Claude Code skills: file structure, YAML frontmatter options, cookbook patterns, auto-discovery behavior, and best practices. |
| Hooks Docs | Extract all information about Claude Code hooks: PreToolUse, PostToolUse, event types, exit codes, JSON output format, and configuration options. |
| MCP Docs | Extract all information about MCP in Claude Code: server configuration, transport types, tool definitions, resource handling, and troubleshooting. |
| Agent SDK Docs | Extract all information about sub-agents in Claude Code: agent definition files, YAML options, tool restrictions, **Agent** tool usage (renamed from `Task` in v2.1.63), forking, background execution, cross-session messaging, and parallel-execution limits. |
| Anthropic News | Extract recent announcements about Claude models and products: new model releases, capabilities, pricing, API changes, features, and Claude Desktop updates. Focus on model IDs, performance benchmarks, technical details, and any Desktop-specific features. |
| Claude Desktop Changelog | Extract all recent updates, new features, bug fixes, and improvements to the Claude Desktop app and claude.ai. Include feature names, dates, and descriptions. |
| Claude Desktop Support | Extract information about Claude Desktop features: scheduled tasks, cowork mode, MCP in Desktop, keyboard shortcuts, integrations, and any new capabilities documented in help articles. |

### Step 3: Launch Parallel Subagents

Launch **11 parallel Agent-tool subagents** (subagent_type: general-purpose, model: haiku) to review each reference file.

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
| 8 | MEMORY.md | Review against memory docs. Return: outdated_sections[], new_content[], corrections[]. |
| 9 | DESKTOP.md | Review against Desktop changelog, support docs, and Anthropic news. Return: outdated_sections[], new_content[], corrections[]. If file doesn't exist yet, return NEW_CONTENT with all Desktop features found. |
| 10 | OUTPUT-STYLES.md | Review against the output-styles docs. Return: outdated_sections[], new_content[], corrections[]. |
| 11 | STATUS-LINES.md | Review against the status-line docs. Return: outdated_sections[], new_content[], corrections[]. |

Also review **SKILL.md** itself and **this cookbook**: the skill's front page summarises every
topic and goes stale with them, and the cookbook's own model/source notes rot too. Neither is
covered by an agent above — handle them directly.
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
5. **Hunt for fabrications.** Do not only look for stale facts — look for facts that were
   never true. Every enumerated list presented as authoritative (built-in styles, event
   names, settings keys, payload fields, env vars, CLI flags) must be checked item by item
   against a page you actually fetched. Flag anything you cannot find in a source as a
   CORRECTION with `current:` set to the unfoundable claim.
6. Never state a fact you cannot source. An omission is a small cost; an invented setting
   name or payload field is a trap that costs someone a debugging session.

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

Wait for all 11 agents to complete. Consolidate findings:

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

Output a friendly, blog-post style summary. Write it as if you're briefing a colleague over coffee — highlight what matters, explain why it's useful, and keep it scannable.

```
## What's New in Claude — {CURRENT_DATE}

> Updated from **{PREVIOUS_VERSION}** to **{NEW_VERSION}**

### The Headlines

Write 2-4 sentences summarizing the most impactful changes across both Claude Code and Claude Desktop. Lead with what the user will actually notice or benefit from. Example tone: "Big week for Desktop users — scheduled tasks just landed, letting you set Claude to run prompts on a timer. On the Code side, hooks got a new event type for..."

### Claude Code Updates

For each notable Code change, write a short paragraph:

**{Feature Name}** — {1-2 sentence description of what it does and why you'd care}. {Optional: how it changes your workflow or what it replaces}.

### Claude Desktop Updates

For each notable Desktop change, write a short paragraph:

**{Feature Name}** — {1-2 sentence description}. {Practical tip on how to use it or where to find it in the app}.

If no Desktop updates were found, write: "No new Desktop updates detected this cycle."

### Under the Hood

Bullet list of smaller changes, fixes, and corrections that don't warrant full paragraphs:
- {change description}
- {change description}

### Skill Files Touched

| File | What Changed |
|------|-------------|
| SKILLS.md | +3 sections, ~2 corrections |
| DESKTOP.md | Created with initial content |
| ... | ... |

---
*11 files reviewed, {X} updated, {Y} changes applied.*
```

## Error Handling

| Error | Action |
|-------|--------|
| WebFetch failure | Continue with available sources, note in report |
| Subagent timeout | Mark file as "review skipped", continue |
| State file missing | Create new, treat as first run |
| State file corrupt | Backup and create new |
| Edit failure | Log error, continue with next file, report at end |

## Why the fabrication check exists

The 2026-08-23 cycle found two files containing content that was **never true**, not merely
stale, and that had survived several self-update cycles unchallenged:

- `OUTPUT-STYLES.md` listed `genui`, `table-based` and `yaml-structured` as **built-in**
  output styles. No such built-ins exist; the real set is Default, Proactive, Concise,
  Explanatory, Learning.
- `STATUS-LINES.md` documented a flat input schema with `model` as a string plus
  `conversation`, `duration` and `line_changes` fields. The real schema is nested
  (`model.id`, `model.display_name`, `workspace.*`, `cost.*`, `context_window.*`) and those
  three fields do not exist.

The same cycle also found this cookbook itself asserting that Fable 5 was suspended and that
Opus 4.8 was the top model, months after both had ceased to be true.

**The lesson: a self-updating skill fossilises its own errors.** Each cycle reads the file as
a baseline and only looks for what is *missing*, so an invented fact is never revisited.
Step 5 of the agent instructions exists to break that loop. Do not skip it, and apply it to
this cookbook too.

## Up-to-Date Detection

If changelog shows no new versions since `lastVersion`:

```
## Self-Update Check

Already up to date!

**Current Version:** {VERSION}
**Last Updated:** {TIMESTAMP}
**Files Tracked:** 11
```

Skip steps 3-6, exit early.
