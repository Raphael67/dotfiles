---
name: self-healing
description: >
  Analyzes past Claude Code conversation logs to learn from mistakes.
  Extracts tool errors, user corrections, and repeated failures,
  then writes actionable learnings to auto memory. Use when you want
  Claude to stop repeating the same mistakes across sessions.
model: opus
user-invocable: true
argument-hint: [days=7]
allowed-tools: Bash, Read, Write, Edit, Agent, Glob, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskOutput, TaskStop, TaskUpdate, TeamCreate, TeamDelete, SendMessage
---

# Self-Healing Skill

You are running the self-healing analysis pipeline. Follow these phases exactly.

## Phase 1: Extract Issues

Parse `$ARGUMENTS` for `days=N` (default 7).

```bash
python3 "$(dirname "$0")/tools/extract_issues.py" --days <N>
```

Wait for it to complete. Read `/tmp/self-healing-extracted.json` and report the metadata summary. If there are 0 extractions, stop here and tell the user.

## Phase 2: Classify Issues

Read the extractions from `/tmp/self-healing-extracted.json`.

Batch the extractions into groups of ~50. For each batch, spawn a **parallel Task subagent** (use `subagent_type: "task"`) with the classification prompt from `prompts/classify.md`.

Each subagent receives:
- The classification prompt
- Its batch of extractions as JSON

Collect all classification results. Filter to only `mistake` classifications. Group them by category.

Write the grouped results to `/tmp/self-healing-issues.md` in this format:

```markdown
# Self-Healing Issues Report
Generated: <timestamp>
Sessions scanned: N | Projects: N | Total mistakes: N

## FILE_PATH_ERROR (N issues)
- **Description**: <description>
  - Session: `<session_file>` line <line_number>
  - Timestamp: <timestamp>

## WRONG_TOOL (N issues)
...
```

Report the category counts to the user.

If there are 0 mistakes, stop here.

## Phase 3: Extract Solutions

For each mistake category that has issues, spawn a **parallel Task subagent** (use `subagent_type: "task"`) with the solution extraction prompt from `prompts/solve.md`.

Each subagent receives:
- The solution prompt
- All mistakes in its category
- For each mistake, read 50 lines of context from the session file around the `line_number` (use offset/limit) and include it

Collect all solution results. Separate into `learnings` (resolved) and `unresolved`.

### Write Solved Learnings to Memory

For each learning with confidence `high` or `medium`:

**Project-scoped** (`scope: "project"`):
- Write to `~/.claude/projects/<encoded-project-path>/memory/self-healing.md`
- The encoded project path uses dashes: `/Users/foo/bar` -> `-Users-foo-bar`
- Append the rule under a `## Self-Healing Rules` header
- Format: `- <rule> _(confidence: <level>, source: <source_description>)_`

**Global-scoped** (`scope: "global"`):
- Write to the current project's memory: `~/.claude/projects/<current-project>/memory/self-healing.md`
- Mark with `[GLOBAL]` prefix so it's recognized across projects
- Format: `- [GLOBAL] <rule> _(confidence: <level>, source: <source_description>)_`

Before writing, read any existing `self-healing.md` to avoid duplicating rules. If a rule already exists, skip it. If an existing rule contradicts a new one, replace the old rule.

## Phase 4: Unsolved Problems (Interactive)

If there are unresolved issues from Phase 3:

Present each to the user with:
- What happened (description + context summary)
- Which session/project it occurred in
- Why it wasn't resolved

For each, ask the user to choose:
1. **Add memory rule** - User provides a rule, you write it to memory
2. **Ignore** - Skip this issue
3. **Investigate** - Read more session context and analyze further

Apply the user's decisions.

## Final Summary

Report:
- Total sessions/projects scanned
- Issues found and classified
- Rules written to memory (list them)
- Unresolved issues handled

Done.
