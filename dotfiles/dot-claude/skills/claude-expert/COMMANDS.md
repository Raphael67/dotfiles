# Claude Code Commands Reference

## What Are Commands?

Commands are user-invocable prompts stored in `.claude/commands/`. They provide:
- Quick access to common workflows
- Reusable prompt templates
- Project-specific operations
- Shorthand for complex tasks

## Directory Structure

```
.claude/commands/
├── prime.md           # Orient agent on codebase
├── install.md         # Setup/installation workflow
├── build.md           # Build from a plan
├── test.md            # Run tests
└── deploy.md          # Deployment workflow
```

### Locations
- **Project**: `.claude/commands/` (shared via git)
- **Global**: `~/.claude/commands/` (personal across all projects)

## Command Format

```yaml
---
description: Brief description shown in /help
allowed-tools: Bash, Read, Glob    # Optional: restrict tools
model: opus                         # Optional: specify model
argument-hint: [arg1] [arg2]        # Optional: show expected args
---

# Command content in markdown
```

## Invocation

```bash
# Basic invocation
/command-name

# With arguments
/command-name arg1 arg2

# Skill-specific command
/skill-name:command arg1
```

## Commands and Skills Merge

Commands and skills are now unified:
- Files at `.claude/commands/review.md` and `.claude/skills/review/SKILL.md` both create `/review`
- Existing `.claude/commands/` files continue to work (backwards compatible)
- Skills add optional features: directory structure, supporting files, frontmatter control, auto-loading

## Argument Syntax (v2.1.19+)

```yaml
# Shorthand (preferred)
USER_PROMPT: $0
OUTPUT_PATH: $1

# Bracket syntax
USER_PROMPT: $ARGUMENTS[0]
OUTPUT_PATH: $ARGUMENTS[1]

# All arguments
ALL_ARGS: $ARGUMENTS
```

## Common Command Patterns

### Prime Command
Orients the agent on a codebase:

```yaml
---
description: Prime agent on the codebase
allowed-tools: Bash, Read, Glob
---

# Purpose

Get oriented on the codebase. Read-only exploration.

## Instructions

- Do NOT modify any files
- Summarize what you learn
- Focus on key architecture decisions

## Workflow

- `git ls-files`
- Read `README.md`
- Read `CLAUDE.md` (if exists)
- Read `.claude/skills/*/SKILL.md`
- Read `ai_docs/*.md` (if exists, max 3 files)

## Report

Tell the user you're primed and summarize:
- Project structure
- Key technologies
- Important patterns
```

### Build Command
Implements from a plan file:

```yaml
---
description: Build the codebase based on a plan
argument-hint: [path-to-plan]
---

# Build

Follow the `Workflow` to implement the plan then `Report`.

## Variables

PATH_TO_PLAN: $ARGUMENTS

## Instructions

- Implement top to bottom, in order
- Do NOT stop between steps
- Make best-guess judgments based on the plan
- End with validation commands
- Fix issues before stopping

## Workflow

- If no `PATH_TO_PLAN` provided, STOP and ask user
- Read the plan at `PATH_TO_PLAN`
- Implement the entire plan before stopping

## Report

- Summarize work in bullet points
- Show files changed: `git diff --stat`
```

### Test Command
Runs test suite with analysis:

```yaml
---
description: Run tests and analyze failures
allowed-tools: Bash, Read, Grep
model: haiku
---

# Test

Run the test suite and provide analysis.

## Workflow

1. Detect test framework
2. Run tests
3. Parse failures
4. Suggest fixes

## Report

### Pass
```
All X tests passed in Y seconds.
Coverage: Z%
```

### Fail
```
## Failed Tests (X/Y)

### test_name (file:line)
- Expected: value
- Received: value
- Likely cause: [analysis]
- Fix: [suggestion]
```
```

### Install Command
Interactive installation workflow:

```yaml
---
description: Install skill/tool to the system
model: opus
---

# Install

Interactive installation with user prompts.

## Variables

GLOBAL_DIR: ~/.claude/
PROJECT_DIR: .claude/

## Workflow

### Step 1: Choose Location
Use AskUserQuestion:
```
Question: "Where to install?"
Options:
- Global (all projects)
- Project (this project)
- Cancel
```

### Step 2: Check Existing
- If exists: ask merge/overwrite/cancel
- If new: proceed to Step 3

### Step 3: Copy Files
- Create directories
- Copy files
- Update configuration

### Step 4: Verify
- Check files exist
- Show configuration

## Report

Installation summary with next steps.
```

### All-Skills Command
Lists available skills:

```yaml
---
description: List all available skills
---

# All Skills

List all available skills from your system prompt.
```

## Advanced Patterns

### Workflow Orchestration
Chain multiple commands:

```yaml
---
description: Full workflow - plan, build, test, deploy
argument-hint: [user_prompt]
---

# Full Workflow

## Variables

USER_PROMPT: $1
WORKFLOW_ID: workflow-<timestamp>

## Workflow

> Execute ALL steps. DO NOT STOP between steps.

1. **Plan**
   - Run `/skill:plan [USER_PROMPT]`
   - Capture: `PLAN_PATH`

2. **Build**
   - Run `/skill:build [PLAN_PATH]`
   - Validate before proceeding

3. **Test**
   - Run `/skill:test`
   - All tests must pass

4. **Deploy**
   - Run `/skill:deploy`
   - Report final URL

## Report

Complete workflow summary.
```

### Argument Handling
Handle optional arguments:

```yaml
---
description: Command with optional args
argument-hint: [required] [optional]
---

## Variables

REQUIRED_ARG: $1
OPTIONAL_ARG: $2 default "default_value" if not provided
```

### Conditional Routing
Route based on arguments:

```yaml
---
description: Multi-mode command
argument-hint: [mode] [options]
---

## Workflow

### Determine Mode

If `$1` is "install":
- Run installation workflow

If `$1` is "update":
- Run update workflow

If `$1` is "remove":
- Run removal workflow

If no mode specified:
- Use AskUserQuestion to determine mode
```

### Fork Terminal Pattern
Launch new terminal with command:

```yaml
---
description: Fork terminal with agentic tool
argument-hint: [tool] [prompt]
---

# Fork Terminal

## Variables

TOOL: $1 default "claude-code" if not provided
PROMPT: $2

## Instructions

- Run the fork tool to open new terminal
- Pass the prompt to the chosen agentic tool

## Workflow

1. Read `tools/fork_terminal.py`
2. Determine tool based on TOOL variable
3. Execute fork with PROMPT
```

## Commands vs Skills

| Aspect | Commands | Skills |
|--------|----------|--------|
| Location | `.claude/commands/` | `.claude/skills/name/` |
| Invocation | `/command-name` | Auto-discovered or `/skill name` |
| Structure | Single file | Directory with multiple files |
| Discovery | Explicit only | Auto or explicit |
| Use case | Quick actions | Complex domains |

## Best Practices

1. **Keep commands focused**: One purpose per command
2. **Use allowed-tools**: Restrict to what's needed
3. **Provide argument hints**: Help users understand usage
4. **Include workflow**: Step-by-step for complex commands
5. **Report results**: Always summarize what was done
6. **Handle missing args**: Ask or fail gracefully
7. **Use models wisely**: haiku for simple, opus for complex

## Integration with Skills

Commands can invoke skill prompts:

```yaml
---
description: Invoke skill workflow
---

# Invoke Skill

## Workflow

1. Run `/skill-name:workflow-name [args]`
2. Process results
3. Report summary
```

Skills can define their own commands in `prompts/`:

```
.claude/skills/my-skill/
├── SKILL.md
└── prompts/
    ├── build.md      # \my-skill:build
    ├── test.md       # \my-skill:test
    └── deploy.md     # \my-skill:deploy
```
