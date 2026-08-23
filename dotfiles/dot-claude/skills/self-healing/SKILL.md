---
name: self-healing
description: >
  Learns from past Claude Code sessions AND maintains the auto-memory system.
  Three pipelines: learn (extract mistakes from transcripts → memory rules),
  hygiene (detect dead references, duplicates, and contradictions in project
  memories → propose deletions/merges), consolidate (detect facts recurring in
  ≥2 projects → propose promotion to global rules or CLAUDE.md). Nothing is
  deleted, merged, or promoted without explicit user approval. Use for:
  "self-healing", "learn from mistakes", "clean up memories", "memory hygiene",
  "consolidate memories".
model: opus
user-invocable: true
argument-hint: [days=7] [phase=all|learn|hygiene|consolidate]
allowed-tools: Bash, Read, Write, Edit, Agent, Glob, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskOutput, TaskStop, TaskUpdate, SendMessage
---

# Self-Healing Skill

You are running the self-healing pipeline. Parse `$ARGUMENTS` for `days=N`
(default 7) and `phase=` (default `all`).

- `phase=learn` → run Phases 1–4 only.
- `phase=hygiene` → run Phase 5 only.
- `phase=consolidate` → run Phase 6 only.
- `phase=all` → run everything in order.

Follow the selected phases exactly.

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

## Phase 5: Memory Hygiene

Goal: find memories that are dead, duplicated, or contradictory — and fix them
**only after user approval**.

1. **Inventory**: list every store `~/.claude/projects/*/memory/` with content.
   For each store, read `MEMORY.md` and every memory file.
2. **Detect, with evidence** (fan out one subagent per large store if needed):
   - **Dead references**: every concrete path, binary, flag, script, or project
     directory a memory cites — verify it exists (`ls`, `command -v`, Glob).
     A memory whose load-bearing reference is gone is a deletion candidate;
     cite the verified-absent path as proof. Also flag stores whose own project
     directory no longer exists (slug will never load again).
   - **Duplicates**: two files covering the same fact (within or across stores),
     or a memory duplicating what the repo/CLAUDE.md/global rules already
     record → propose a merge (say which file survives) or a deletion.
   - **Contradictions**: memories contradicting each other or the current
     config (global CLAUDE.md, rules, hooks) → propose which side is right,
     with evidence.
   - **Index drift**: MEMORY.md lines pointing to missing files, files missing
     from MEMORY.md, or content blocks inlined in MEMORY.md (index must be
     one pointer line per memory).
3. **Report**: write an actionable table to
   `/tmp/self-healing-hygiene.md` — one row per finding:
   `store | file | finding | evidence | proposed action (DELETE/MERGE/REWRITE/REINDEX)`.
   Show the user the summary counts and the table location.
4. **MANDATORY REVIEW GATE**: present the proposed actions via AskUserQuestion
   (group them sensibly, one question per turn, max 4 options; iterate if more
   groups). **Apply ONLY the actions the user approves. A refusal or an
   unselected group leaves every concerned file byte-identical — no partial
   application, no "harmless" cleanups on the side.** Before any deletion,
   verify an archive copy exists (e.g. a git-tracked archive or an explicit
   `cp` to a user-designated location) — if none exists, create one and say where.
5. After applying approved actions, regenerate the touched `MEMORY.md` indexes
   and re-verify 1:1 index ↔ directory.

## Phase 6: Consolidation (promote recurring facts)

Goal: a fact learned in ≥2 projects belongs in the global config, not in N
local memories — **promotion only with user approval**.

1. Across all stores (including `self-healing.md` rule files), collect facts
   and compare: same convention, same gotcha, same preference appearing in
   memories of **at least 2 different projects**, or marked `[GLOBAL]` in a
   project self-healing.md.
2. For each recurring fact, decide the correct home:
   - Conditional on a language/tool/path → a **path-scoped global rule**
     `~/.claude/rules/<topic>.md` (source of truth:
     `~/Projects/dotfiles/dotfiles/dot-claude/rules/`, stowed) with a
     `paths:` frontmatter glob. Draft the exact rule content.
   - Truly universal (true in every project, every session) → a one-line
     addition to the global CLAUDE.md — **only if it stays within the ≤60
     content-line budget** (`grep -vcE '^\s*$|^#|^<!--' <file>`); if the
     budget would overflow, propose which existing line moves out instead.
   - Already covered by the global config → propose deleting the redundant
     local memories only.
3. **Report**: append proposals to `/tmp/self-healing-consolidation.md`:
   `fact | seen in (stores) | proposed home | draft content | local memories to delete`.
4. **MANDATORY REVIEW GATE**: same contract as Phase 5 — AskUserQuestion,
   apply only what is approved, refusal changes nothing. A promotion is
   applied atomically: write the rule/line AND delete the now-redundant local
   memories (with archive) AND update their MEMORY.md indexes; never leave
   both copies alive silently.
5. Verify each new rule triggers: its `paths:` glob must match at least one
   real file on disk (test with Glob) before the local memories are removed.

## Final Summary

Report per pipeline that ran:
- learn: sessions/projects scanned, issues classified, rules written (list), unresolved handled
- hygiene: findings by type, actions approved vs refused, actions applied
- consolidate: recurring facts found, promotions approved vs refused, rules created

Done.
