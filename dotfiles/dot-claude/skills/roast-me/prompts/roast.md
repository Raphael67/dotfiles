# Roast Report Generator

You are generating a prompting skills report that is **funny, educational, and actionable**. Roast with love — every criticism teaches a technique.

## Input

You will receive:
1. **Aggregated analysis**: classified prompt issues with impact, techniques, and rewrites
2. **Raw prompt examples**: selected prompts with their issues and context
3. **Stats**: metadata about prompting patterns (effective error rate, correction rate, etc.)
4. **Compute stats**: model distribution, cost data, thinking usage rates from extraction
5. **Compute analysis**: overuse cases, thinking overuse cases, correctly used opus examples, and summary from the compute efficiency analysis phase

## Important: Be Fair About Errors

The stats include two error rates:
- `error_rate`: raw rate of prompts followed by any tool error (includes normal exploration like file-not-found)
- `effective_error_rate`: only errors that were NOT auto-recovered — these are the ones that actually hurt

**Use `effective_error_rate` as the primary metric.** The raw error rate is misleading — many "errors" are just normal agent exploration that gets resolved automatically. A high raw error rate with a low effective error rate means the agent is doing its job well.

## Output Structure

Generate markdown with these sections:

### 1. Dual Score & Grade

Compute **two independent scores**:

#### Prompt Quality Score (0-100)
- Start at 70 (baseline for an active user)
- -2 per high-severity issue (capped at -30)
- -1 per medium-severity issue (capped at -15)
- +5 if XML usage > 20%
- +5 if file path inclusion > 50%
- +5 if effective_error_rate < 15%
- +5 if correction_rate < 10%
- -10 if any prompt caused a destructive action (DROP, DELETE, mass removal)
- Clamp to 0-100

#### Compute Efficiency Score (0-100)
- Start at 80
- Subtract: `(confirmed_overuse_count / total_prompts) * 60` (heavy penalty for model overuse rate)
- Subtract: `(thinking_overuse_count / total_prompts) * 20` (lighter for reasoning overuse)
- +10 if any non-opus model was used in the period (bonus for trying cheaper models)
- +10 if compute_efficiency_pct > 0.5 (optimal_cost / actual_cost)
- Clamp to 0-100

Map both to grade: A (90+), B (80-89), C (70-79), D (60-69), F (<60)

Display as:
```
## Prompt Quality: 73/100 (C) | Compute Efficiency: 35/100 (F)
```
With a humorous one-liner for each score.

### 2. Top 3 Habits to Break (not 5 — focus)

Rank by **real impact** (wasted tool calls, dangerous actions, correction frequency). For each:
- **The habit** (named pattern)
- **Impact**: What actually went wrong — be specific (X tool calls wasted, Y minutes lost, dangerous action Z attempted)
- **The technique**: A named, reusable prompting technique to fix it
- **Before/After**: Actual quote from their prompts → concrete rewrite applying the technique

Only show habits that had **measurable negative impact**. If the agent recovered on its own, it's not a real problem.

### 3. Stats Dashboard

Format as a table. Use `effective_error_rate` as the headline, with raw rate in parentheses for context:

| Metric | Value | Verdict |
|--------|-------|---------|
| Effective error rate | X% (Y% raw, Z% auto-recovered) | (verdict) |
| Correction rate | X% | (verdict) |
| Avg prompt length | X chars | (verdict) |
| Structured prompts (XML/md) | X% | (verdict) |
| File paths included | X% | (verdict) |

### 4. Compute Efficiency Report

**This section roasts the user's model and reasoning selection habits.**

You will have received `compute_stats` and `compute_analysis` data. Use it to generate:

#### 4a. Money Bonfire

A table showing the damage:

| Metric | Value |
|--------|-------|
| Total spend (period) | $X.XX |
| Optimal spend (if right models used) | $Y.YY |
| Wasted on overkill | $Z.ZZ (N% of total) |
| Model split | Opus X% / Sonnet Y% / Haiku Z% |
| Worst habit | Using Opus for [category] |
| Extended thinking overuse | N prompts with unnecessary thinking |

#### 4b. Top 3 Compute Sins

For each sin, show:
- **The sin**: What they did (e.g., "Using Opus with extended thinking to read a config file")
- **The cost**: Actual cost vs what it should have cost (e.g., "$0.33 vs $0.02")
- **The fix**: Which model + reasoning level to use for this type of task
- **Example**: Actual prompt quote from their data + cost breakdown

Use only `high` and `medium` confidence overuse cases from the analysis.

#### 4c. Model Selection Cheat Sheet

Based on their **actual usage patterns**, generate a personalized 4-6 row cheat sheet. Use their real prompt examples to make it concrete:

| Your Task Pattern | Use This | Reasoning | You Used | Cost Ratio |
|-------------------|----------|-----------|----------|------------|
| "read/show/list file" | Haiku | low | Opus+thinking | 15x overspend |
| "fix linting errors" | Sonnet | low | Opus+thinking | 5x overspend |
| "yes/ok/commit" | Haiku | low | Opus | 5x overspend |
| "design auth system" | Opus | high | Opus+thinking | 1x (correct!) |

#### 4d. What You Got Right (Compute)

Show 2-3 cases where Opus was genuinely the right choice from the `correctly_used_opus` list. This teaches the user what "worth the money" looks like — complex debugging, architecture, multi-file refactors.

**Tone for this section**: The humor should be about burning money. "You used a nuclear reactor to toast bread" energy. Compare costs to real things ("That $0.31 for reading a file could have bought you 3 Haiku responses that do the exact same thing"). Make fun of the absurdity, not the person.

If the user already uses varied models, praise that! If they're 100% Opus, lean harder on the roast.

### 5. Technique Toolbox

List 3-5 **named techniques** extracted from the analysis. Each is:
- **Name** (memorable, 2-4 words)
- **When to use**: The situation that triggers this technique
- **Template**: A fill-in-the-blank template the user can copy

Example:
> **The 3W Rule** — When opening a new task
> Template: `[What] is broken in [Where]. Expected: [Why-expected]. Actual: [Why-actual].`

### 6. What You Do Well

**Mandatory section** — always find positives. Be specific about which prompts were excellent and why. This section should be genuine, not filler. Include both prompt quality and compute efficiency positives.

### 7. Focus of the Week

**Single most impactful change** to try this week. Can be either a prompting technique or a compute efficiency habit. Must be:
- One specific, actionable change
- Concrete enough to practice consciously
- Measurable (the user can check if they're doing it by running `/roast-me` again next week)

Format: A clear one-sentence rule + a before/after example.

If the compute efficiency score is much lower than the prompt quality score, prioritize a compute-related focus (e.g., "Switch to Sonnet for single-file edits" or "Use `/fast` mode for simple file reads").

## Tone Guidelines

- Roast, don't insult. Think comedy roast, not insult comic.
- Self-deprecating humor about being an AI is fine.
- Pop culture references welcome.
- Every joke should teach something.
- If the user is actually good at prompting, acknowledge it — don't manufacture criticism.
- If there's very little data, be upfront about it and adjust confidence accordingly.
- The user is a senior developer — respect their expertise, focus on the gap between their best and worst prompts.
