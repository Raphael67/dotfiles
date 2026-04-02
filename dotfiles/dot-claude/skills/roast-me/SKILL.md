---
name: roast-me
description: >
  Analyzes past Claude Code conversations to roast your prompting habits
  and compute efficiency. Reads user prompts, cross-references with tool
  errors and corrections, analyzes model/reasoning choices (Opus vs Sonnet
  vs Haiku), then generates dual scores (prompt quality + compute efficiency),
  worst habits, techniques, and a personalized model selection cheat sheet.
  Tracks scores over time so you can see improvement.
  Use when you want honest feedback on your prompting skills.
model: opus
user-invocable: true
argument-hint: [days=7]
allowed-tools: Bash, Read, Write, Glob, Agent, TaskCreate, TaskGet, TaskList, TaskOutput, TaskStop, TaskUpdate, TeamCreate, TeamDelete, SendMessage
---

# Roast Me Skill

You are running the prompt quality roast pipeline. Follow these phases exactly.

## Phase 1: Extract Prompts

Parse `$ARGUMENTS` for `days=N` (default 7). Accept bare numbers (e.g., `3` means `days=3`).

```bash
python3 "$(dirname "$0")/tools/extract_prompts.py" --days <N>
```

Wait for it to complete. Read `/tmp/roast-me-extracted.json` and report the metadata summary to the user. **Important**: Report the `effective_error_rate` (errors that actually hurt) not the raw `error_rate` (which includes auto-recovered exploration errors).

If there are 0 prompts, stop here and tell the user: "Not enough data to roast you. Try a longer time window."

## Phase 2: Analyze Prompt Quality

Read the prompts from `/tmp/roast-me-extracted.json`.

Batch the prompts into groups of ~30. For each batch, spawn a **parallel Task subagent** with the analysis prompt from `prompts/analyze.md`.

Each subagent receives:
- The analysis prompt (read from `prompts/analyze.md`)
- Its batch of prompt records as JSON

Collect all analysis results. Group flagged issues by category. Count occurrences per category and severity.

**Filter aggressively**: Only keep issues where the impact was real (agent went wrong direction, user had to correct, dangerous action, or significant wasted work). Discard issues where the agent recovered on its own.

Report category counts to the user as a progress update.

If there are 0 issues flagged, still proceed to Phase 3 — the roast should acknowledge good prompting.

## Phase 2.5: Analyze Compute Efficiency

Read the prompts from `/tmp/roast-me-extracted.json`. Also read the `compute_stats` from the extraction metadata and report a quick summary to the user:

```
Compute overview: $X.XX total spend | Y% on Opus | Z prompts flagged as potential overkill
```

Batch the prompts into groups of ~30 (same batching as Phase 2). For each batch, spawn a **parallel Task subagent** with the compute analysis prompt from `prompts/compute.md`.

Each subagent receives:
- The compute analysis prompt (read from `prompts/compute.md`)
- Its batch of prompt records as JSON (including the compute fields)

Collect all results. Aggregate across batches:
- All `overuse_cases` (deduplicated by index)
- All `thinking_overuse_cases`
- All `correctly_used_opus` examples
- Sum up `total_overuse_count`, `total_savings_usd`, `thinking_overuse_count`
- Find the `worst_category` (most frequent task_type in overuse_cases)

**Filter**: Only keep overuse cases with `confidence` of `high` or `medium`. Discard `low` confidence.

Report to the user:
```
Compute analysis complete: X confirmed overuse cases | $Y.YY potential savings | Z thinking overuse
```

## Phase 3: Generate Roast

Spawn a single Task subagent with the roast generation prompt from `prompts/roast.md`.

The subagent receives:
- The roast prompt (read from `prompts/roast.md`)
- Aggregated issue counts by category and severity
- The top ~15 worst prompt examples (highest severity + real impact, with their analysis including `impact` and `technique` fields)
- The stats metadata from the extraction (including `effective_error_rate`)
- A sample of ~10 good prompts (no issues flagged) for the "What You Do Well" section
- The `compute_stats` from the extraction metadata
- Aggregated compute analysis from Phase 2.5: overuse cases (top ~10 worst), thinking overuse cases, correctly used opus examples, and summary totals

**Tone instruction**: Be funny and use humor throughout. Comedy roast style — every joke should teach something. Pop culture references welcome.

Collect the roast report. Extract the computed score (0-100) and grade from the report.

## Phase 4: Score & Track

Save the score to `~/.claude/roast-me-history.json` (this file is NOT in the dotfiles repo — it lives directly in ~/.claude/ and is gitignored).

Read existing history (if any). Append a new entry:
```json
{
  "date": "YYYY-MM-DD",
  "days_analyzed": N,
  "score": 73,
  "grade": "C",
  "total_prompts": 300,
  "issues_flagged": 45,
  "effective_error_rate": 0.12,
  "correction_rate": 0.08,
  "focus_of_week": "The 3W Rule: What, Where, Why",
  "compute_score": 35,
  "compute_grade": "F",
  "compute_total_cost_usd": 47.10,
  "compute_wasted_cost_usd": 12.50,
  "compute_efficiency_pct": 0.73,
  "compute_overuse_count": 45,
  "compute_thinking_overuse_count": 12,
  "model_distribution": {"opus": 0.93, "sonnet": 0.05, "haiku": 0.02}
}
```

If there are previous entries, show a trend line after the report:

```
Score History:
  Date        Prompt Quality    Compute Efficiency    Focus
  2026-03-10  68/100 (D+)       --/-- (new)           Context anchoring
  2026-03-17  73/100 (C) +5↑    35/100 (F)            The 3W Rule
  2026-03-24  75/100 (C) +2↑    52/100 (F) +17↑       Model selection
```

Write the updated history back to `~/.claude/roast-me-history.json`.

## Phase 5: Present

Output the roast report as formatted markdown directly to the terminal.

If there is score history, append the trend line at the end.

Done.
