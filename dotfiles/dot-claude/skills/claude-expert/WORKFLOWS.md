# Claude Code Workflows Reference

## What Are Workflows?

Workflows are structured sequences of actions that guide Claude through complex, multi-step tasks. They provide:
- Clear execution order
- Variable management
- Error handling
- Reporting templates

**Note**: everything below in this section describes a hand-authored markdown convention (YAML frontmatter + Variables/Instructions/Workflow/Report sections) for command/skill prompt files. It is a project authoring pattern, distinct from Claude Code's built-in **dynamic workflows** feature covered next.

## Bundled Dynamic Workflows (Claude Code v2.1.154+)

A **dynamic workflow** is a JavaScript script — written by Claude, not by you — that orchestrates many subagents in the background. Reach for one when a task needs more agents than a single conversation can coordinate (a codebase-wide audit, a large migration, a research question that needs sources cross-checked), or when the orchestration itself should be codified as a script you can read and rerun.

### [Skill] vs. [Workflow] vs. built-in command

Claude Code's bundled `/` commands are tagged by type:

| Type | What it is | Who decides what runs next | Where results live |
|---|---|---|---|
| **[Skill]** | A prompt Claude follows; some skills also auto-invoke when relevant, unless marked invocation-only | Claude, turn by turn | Claude's context window |
| **[Workflow]** | A JS script that fans work out across subagents and runs in the background | The script | Script variables |
| Built-in command | Core CLI behavior, not backed by a skill or workflow file | — | — |

### Bundled commands

| Command | Type | Purpose |
|---|---|---|
| `/deep-research <question>` | [Workflow] | Fans out web searches on a question across several angles, fetches and cross-checks sources, votes on each claim, and returns a cited report with claims that didn't survive cross-checking filtered out. Requires the WebSearch tool. **Runs only when explicitly invoked** (changed in v2.1.218 — before that Claude could also start it on its own). |
| `/batch <instruction>` | [Skill] | Orchestrates large-scale changes across a codebase: researches it, decomposes work into 5–30 independent units, presents a plan for approval, then spawns one background subagent per unit in its own isolated git worktree. Each subagent implements its unit, runs tests, and opens a PR. Requires a git repo. |
| `/loop [interval] [prompt]` | [Skill] | Runs a prompt repeatedly while the session stays open. Omit the interval to let Claude self-pace between iterations; omit the prompt to run an autonomous maintenance check or the prompt in `.claude/loop.md` (where available). Alias: `/proactive`. |
| `/goal [condition\|clear]` | Built-in command | Sets a completion condition Claude keeps working toward across turns, until it's met, a model judges it impossible, or an error occurs. No argument shows the current/most recent goal; `clear`/`stop`/`off`/`reset`/`none`/`cancel` removes it early. |

### Triggering an ad hoc dynamic workflow

Beyond `/deep-research`, you can have Claude write and run a one-off dynamic workflow for any task:
- Include the keyword `ultracode` in a prompt, or ask in plain language ("use a workflow", "run a workflow")
- Or set `/effort ultracode` so Claude plans a workflow for every substantive task in the session (requires a model that supports `xhigh` effort)

Mechanics worth knowing:
- The generated script is plain JavaScript with top-level `await`. Besides `agent()` (spawns one subagent) and `pipeline()` (runs one per item in a list), a script can call `parallel()` (runs a set of agent tasks at once and waits for all), `phase()` (groups the agents that follow under a title in the `/workflows` progress view), `log()` (shows a message above the phases), and read the `args` global (input passed to a saved workflow — see below)
- If an `agent()` call passes a `schema`, that subagent returns JSON matching the shape instead of prose; Claude Code validates the schema up front and fails fast on a self-contradicting one (e.g. a `required` key `additionalProperties: false` rules out); if the subagent's output still fails validation after 5 attempts (configurable via `MAX_STRUCTURED_OUTPUT_RETRIES`), the call fails with the last validation error
- Limits: up to 16 concurrent agents by default (fewer under CPU constraints; `CLAUDE_CODE_WORKFLOW_MAX_CONCURRENT_AGENTS` sets 1–256, v2.1.269+), up to 4,096 items in a single `parallel()`/`pipeline()` call (a longer list is rejected with an error, not silently truncated), 1,000 agents total per run
- **Usage limit (v2.1.271+)**: an agent that hits the claude.ai usage limit pauses the run instead of failing; waiting agents resume shortly after the reset. Only in interactive claude.ai-subscription sessions with `autoContinueAtUsageLimit` on, a reset within 24 hours, and at most two waits per run — otherwise (`-p`, SDK, background, Remote Control, teammate sessions) the agent fails
- Watch and manage runs with `/workflows` (pause/resume, drill into an agent, stop, restart)
- A good run can be saved as a reusable command by pressing `s` from `/workflows` — it lands in `.claude/workflows/` (project, shared) or `~/.claude/workflows/` (personal) and then runs as `/<name>` in future sessions. Saved scripts can accept input via `args` (e.g. `Run /triage-issues on issues 1024, 1025`), and editing a saved script requires running the bundled `/workflow-authoring` skill first (v2.1.248+) to load the script-writing reference — `Date.now()`, `Math.random()`, and a no-arg `new Date()` all throw inside a script, so a relaunched run repeats the same `agent()` calls deterministically
- A size guideline (`unrestricted`/`small` [<5 agents]/`medium` [<10; <15 before v2.1.271]/`large` [<50]) advises Claude on agent-count scale without hard-capping it (v2.1.202+; setting itself requires v2.1.219+). Default is `medium`, or `small` on a Pro plan (v2.1.271+). A run scheduling more than 25 agents or projecting over 1.5M tokens shows a `Large workflow` warning in the task panel (advisory only, doesn't pause the run); sessions with ultracode on skip the warning

Requires Claude Code v2.1.154+.

## Workflow Anatomy

A complete workflow file has these sections:

```yaml
---
description: What this workflow does
argument-hint: [required_arg] [optional_arg]
model: opus  # Optional: specify model
---

# Purpose
Brief description of the workflow's goal.

## Variables
Define constants and arguments.

## Instructions
Core rules and constraints.

## Workflow
Step-by-step execution flow.

## Report
Output format template.
```

## Variables Section

### Static Variables
Constants that don't change:
```markdown
## Variables

SKILL_DIR: .claude/skills/my-skill
CONFIG_FILE: SKILL_DIR/config.yaml
TIMEOUT_SECONDS: 43200
DEFAULT_PORT: 5173
DEFAULT_MODEL: sonnet
```

### Argument Variables (v2.1.19+)
Passed from user or parent workflow:

**Shorthand syntax (preferred):**
```markdown
## Variables

USER_PROMPT: $0
WORKFLOW_ID: $1 default "workflow-<timestamp>" if not provided
OPTIONS: $2 default "" if not provided
```

**Bracket syntax:**
```markdown
## Variables

USER_PROMPT: $ARGUMENTS[0]
WORKFLOW_ID: $ARGUMENTS[1] default "workflow-<timestamp>" if not provided
```

### Computed Variables
Derived during execution:
```markdown
## Variables

SANDBOX_ID: (captured from sbx init output)
PUBLIC_URL: (captured from get-host command)
PLAN_PATH: specs/<WORKFLOW_ID>/plan.md
```

## Instructions Patterns

### Critical Rules Pattern
Emphasize non-negotiable requirements:
```markdown
## Instructions

- **CRITICAL**: Capture the sandbox ID from output and remember it
- **IMPORTANT**: Do NOT stop between steps
- **NEVER**: Create files outside SKILL_DIR
- ALWAYS: Use --timeout TIMEOUT_SECONDS
```

### Conditional Behavior Pattern
```markdown
## Instructions

- IF `USER_PROMPT` is not provided, STOP and ask user
- IF configuration file exists, merge settings
- IF tests fail, fix issues before proceeding
```

### Multi-Agent Safety Pattern
```markdown
## Instructions

- **Capture the ID** from output and store in YOUR context
- **DO NOT use shell variables** like `export ID=...`
- **DO NOT rely on files** that may be overwritten by other agents
- **Track values yourself** and use them directly in commands
```

## Workflow Section Patterns

### Sequential Steps Pattern
```markdown
## Workflow

### Step 1: Validate Environment
1. Check for required configuration
2. Verify dependencies are installed
3. If missing, stop and request user action

### Step 2: Initialize
1. Create necessary directories
2. Copy template files
3. Update configuration

### Step 3: Execute
1. Run main operation
2. Capture output
3. Handle errors

### Step 4: Verify
1. Run validation commands
2. Confirm success
3. Report issues if any
```

### Decision Tree Pattern
Route based on user input:
```markdown
## Workflow

### Step 1: Determine Action
Use AskUserQuestion:
```
Question: "What would you like to do?"
Options:
- Install (fresh setup)
- Modify (update existing)
- Remove (uninstall)
```

### Step 2a: Install Path
If user chose Install:
1. Check for conflicts
2. Copy files
3. Configure settings

### Step 2b: Modify Path
If user chose Modify:
1. Read existing config
2. Apply changes
3. Preserve customizations
```

### Orchestrated Workflow Pattern
Chain multiple sub-workflows:
```markdown
## Workflow

> Run top to bottom. DO NOT STOP between steps.

1. **Initialize**
   - Run `sbx init --timeout 43200`
   - Capture sandbox ID: store as `SANDBOX_ID`

2. **Plan**
   - Run `\skill:plan [USER_PROMPT]`
   - Capture output path: store as `PLAN_PATH`

3. **Build**
   - Run `\skill:build [PLAN_PATH]`
   - Validate with test commands from plan

4. **Host**
   - Start server in background
   - Get public URL: `sbx sandbox get-host SANDBOX_ID --port 5173`
   - Store as `PUBLIC_URL`

5. **Test**
   - Run `\skill:test [SANDBOX_ID] [PUBLIC_URL]`
   - All tests must pass before proceeding

6. **Report**
   - Follow Report section format
```

### Task Tool Metrics (v2.1.30+)

Agent tool results now include metrics for monitoring:
- **Token count**: Input/output tokens used
- **Tool uses**: Number of tool invocations
- **Duration**: Execution time in milliseconds

Capture these in reports for workflow visibility.

### Parallel Execution Pattern
Launch multiple operations simultaneously:
```markdown
## Workflow

### Step 3: Execute Parallel Tasks

Launch ALL tasks in a SINGLE message with multiple Agent tool calls:

For EACH task, use Agent tool with `subagent_type="general-purpose"`:

<subagent-prompt>
**YOUR ASSIGNED PORT: [UNIQUE_PORT]**

This port is exclusively yours. No other agent will use it.

**Setup:**
1. cd to `[SKILL_DIR]`
2. Start service on port [UNIQUE_PORT]

**Task:**
[Specific task instructions]

**Cleanup:**
- Close only YOUR service on YOUR port
- NEVER close other ports

**Return format:**
```
Task: [Name]
Port: [UNIQUE_PORT]
Status: PASSED or FAILED
Details: [summary]
```
</subagent-prompt>

Wait for all subagents to complete.
```

### Error Recovery Pattern
```markdown
## Workflow

### Step 4: Execute with Recovery

1. Run the operation
2. **On SUCCESS**: Proceed to Step 5
3. **On FAILURE**:
   - Capture error details
   - Take diagnostic screenshot
   - Attempt fix based on error type
   - Re-run from beginning of this step
   - If fails 3 times, report failure and stop
```

## Report Section Patterns

### Simple Report
```markdown
## Report

Summarize the work:
- What was done
- Files modified: `git diff --stat`
- Next steps
```

### Structured Report
```markdown
## Report

### Task Complete

**Request**: [USER_PROMPT summary]
**Status**: [Success/Partial/Failed]

---

### Step 1: [Name]
**Result**: [what happened]
**Output**: [key details]

### Step 2: [Name]
**Result**: [what happened]
**Files**: [list]

---

### Summary

| Metric | Value |
|--------|-------|
| Steps Completed | X/Y |
| Files Modified | N |
| Tests Passed | M |

**Next Steps**:
1. [Recommendation 1]
2. [Recommendation 2]
```

### Validation Report
```markdown
## Report

### Validation Results

**Database**: OK - Tables verified
**Backend**: OK - All endpoints tested
**Frontend**: OK - Build succeeded
**Integration**: OK - End-to-end flow validated

---

### Test Summary

| Category | Status | Details |
|----------|--------|---------|
| Unit Tests | PASSED | 47/47 |
| Integration | PASSED | 12/12 |
| E2E | PASSED | 5/5 |

**All Tests Passed**: YES
```

## Complete Workflow Example

```yaml
---
description: Complete build-test-deploy workflow
argument-hint: [user_prompt] [workflow_id]
model: opus
---

# Full Stack Workflow

Orchestrates plan, build, host, and test in sequence.

## Variables

USER_PROMPT: $1
WORKFLOW_ID: $2 default "workflow-<hhmmss>" if not provided
SKILL_DIR: .claude/skills/my-skill
TIMEOUT: 43200
PORT: 5173

## Instructions

- Complete ALL steps before stopping
- Capture IDs and paths in YOUR context (not shell variables)
- If any step fails, report failure and stop
- Validate after each major step

## Workflow

> Execute top to bottom. DO NOT STOP between steps.

### Step 0: Read Documentation
- Read `SKILL_DIR/SKILL.md`
- Understand available commands

### Step 1: Initialize
- Run `uv run sbx init --timeout TIMEOUT`
- **Capture** sandbox ID from output (e.g., `sbx_abc123`)
- Store as: `sandbox_id = "sbx_abc123"`

### Step 2: Plan
- Run `\skill:plan [USER_PROMPT]`
- Capture generated plan path
- Store as: `plan_path = "specs/workflow-123/plan.md"`

### Step 3: Build
- Run `\skill:build [plan_path]`
- Verify with validation commands from plan
- Fix any errors before proceeding

### Step 4: Host
- Start server: `sbx exec [sandbox_id] "npm run dev" --background`
- Get URL: `sbx sandbox get-host [sandbox_id] --port PORT`
- Store as: `public_url`
- Verify with curl

### Step 5: Test
- Run `\skill:test [sandbox_id] [public_url] [plan_path]`
- All tests must pass
- If failures, fix and re-test

## Report

### Workflow Complete

**Request**: [USER_PROMPT]
**Stack**: [technologies used]

---

### Step 1: Initialize
**Sandbox ID**: [sandbox_id]
**Status**: Ready

### Step 2: Plan
**Plan File**: [plan_path]
**Components**: [list main components]

### Step 3: Build
**Files Modified**: [count]
**Validation**: All passed

### Step 4: Host
**URL**: [public_url]
**Port**: PORT

### Step 5: Test
**Database**: OK
**Backend**: OK
**Frontend**: OK

---

### Summary

| Metric | Value |
|--------|-------|
| Sandbox | [sandbox_id] |
| URL | [public_url] |
| Timeout | TIMEOUT seconds |

**Access your app at**: [public_url]
```

## Best Practices

1. **Variables at top**: Define all constants and arguments first
2. **Clear step numbering**: Use sequential numbers for order
3. **Capture outputs**: Explicitly state what to capture and store
4. **No shell variables**: Store values in agent context, not env vars
5. **Validation checkpoints**: Verify after each major step
6. **Error handling**: Define what to do on failure
7. **Complete before stopping**: Don't stop mid-workflow
8. **Report template**: Provide exact output format
9. **Multi-agent safety**: Unique ports/IDs for parallel execution
