---
description: Run parallel Claude Code agents with mprocs after prompt refinement
argument-hint: <number_of_agents> <prompt>
model: opus
---

# Parallel Thread Orchestrator

Run multiple Claude Code agents in parallel using mprocs, with an initial prompt refinement step.

## Variables

NUM_AGENTS: $1
RAW_PROMPT: $2

## Instructions

- First validate inputs are provided
- Refine the prompt using claude-expert guidance to make it more effective
- Generate an mprocs YAML config with NUM_AGENTS processes
- Each process runs `claude --dangerously-skip-permissions -p "<refined_prompt>"`
- Launch mprocs with the generated config

## Workflow

### Step 1: Validate Inputs

If NUM_AGENTS is not provided or RAW_PROMPT is empty:
- STOP and ask user: "Please provide: /pthread <number_of_agents> <prompt>"
- Example: `/pthread 3 "Add unit tests for the auth module"`

Validate NUM_AGENTS is between 1 and 10.

### Step 2: Refine the Prompt

Before distributing work, improve the prompt for better agent performance.

Apply these refinements:
1. Add explicit context about the task scope
2. Include success criteria
3. Specify output format expectations
4. Add constraints to prevent overlap between parallel agents
5. Include instruction to work independently and report results

<refined-prompt-template>
You are one of {NUM_AGENTS} parallel agents working on the same codebase.

## Task
{RAW_PROMPT}

## Constraints
- Work independently - do not assume other agents have made changes
- Focus on a specific subset of the work if the task is divisible
- Document your changes clearly
- If you encounter conflicts or blocking issues, report them

## Output
When complete, provide:
1. Summary of changes made
2. Files modified
3. Any issues encountered
</refined-prompt-template>

### Step 3: Generate mprocs Configuration

Create a temporary mprocs YAML config file at `/tmp/pthread-{timestamp}.yaml`:

```yaml
procs:
  agent-1:
    shell: "claude --dangerously-skip-permissions -p '<REFINED_PROMPT>'"
    cwd: "{CURRENT_WORKING_DIR}"
  agent-2:
    shell: "claude --dangerously-skip-permissions -p '<REFINED_PROMPT>'"
    cwd: "{CURRENT_WORKING_DIR}"
  # ... repeat for NUM_AGENTS
```

Important:
- Escape single quotes in the prompt with '\''
- Use the current working directory for cwd
- Name agents sequentially: agent-1, agent-2, etc.

### Step 4: Launch mprocs

Execute:
```bash
mprocs -c /tmp/pthread-{timestamp}.yaml
```

This opens the mprocs TUI where you can:
- View each agent's output in separate panes
- Switch between agents with arrow keys
- Ctrl+C to stop all agents

## Example Execution

User: `/pthread 3 "Add error handling to API endpoints"`

1. Validate: 3 agents, prompt provided
2. Refine prompt with context and constraints
3. Generate `/tmp/pthread-1234567890.yaml` with 3 processes
4. Run `mprocs -c /tmp/pthread-1234567890.yaml`

## Report

After generating the config, tell the user:

```
Launching {NUM_AGENTS} parallel Claude agents with mprocs.

Refined prompt:
> {REFINED_PROMPT_SUMMARY}

Config: /tmp/pthread-{timestamp}.yaml

Use mprocs controls:
- Arrow keys: switch between agents
- q: quit mprocs
- Ctrl+C: stop current agent
```
