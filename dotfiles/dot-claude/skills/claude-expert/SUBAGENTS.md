# Claude Code Sub-Agents Reference

## What Are Sub-Agents?

Sub-agents are specialized Claude instances that can be invoked via the Task tool for specific tasks. They run in isolation with their own context, tools, and instructions.

## Built-in Agent Types

Claude Code includes several built-in agent types:

| Agent Type | Model | Use Case |
|------------|-------|----------|
| `Explore` | Haiku | Fast read-only codebase exploration, file search |
| `Plan` | Inherit | Research for plan mode (read-only) |
| `general-purpose` | Inherit | Complex multi-step tasks, code modifications |
| `Bash` | Inherit | Command execution in separate context |
| `statusline-setup` | Sonnet | Configure status line via `/statusline` |
| `Claude Code Guide` | Haiku | Answer questions about Claude Code features |

## Using the Task Tool

### Basic Usage
```
Use the Task tool with subagent_type="Explore" to find all API endpoints.
```

### Task Tool Parameters

| Parameter | Description |
|-----------|-------------|
| `description` | Short (3-5 word) description of the task |
| `prompt` | Detailed task instructions |
| `subagent_type` | Agent type to use |
| `model` | Optional model override (`sonnet`, `opus`, `haiku`) |
| `run_in_background` | Run asynchronously |
| `resume` | Agent ID to resume previous execution |

### Examples

**Explore Agent:**
```xml
<invoke name="Task">
<parameter name="description">Find API endpoints</parameter>
<parameter name="prompt">Search the codebase for all REST API endpoint definitions. Look for route handlers, controller methods, and OpenAPI specs.</parameter>
<parameter name="subagent_type">Explore</parameter>
</invoke>
```

**Plan Agent:**
```xml
<invoke name="Task">
<parameter name="description">Plan auth implementation</parameter>
<parameter name="prompt">Design an implementation plan for adding JWT authentication to the API. Consider middleware, token refresh, and logout.</parameter>
<parameter name="subagent_type">Plan</parameter>
</invoke>
```

**Background Execution:**
```xml
<invoke name="Task">
<parameter name="description">Run test suite</parameter>
<parameter name="prompt">Run the full test suite and report failures.</parameter>
<parameter name="subagent_type">Bash</parameter>
<parameter name="run_in_background">true</parameter>
</invoke>
```

## Creating Custom Agents

Custom agents are defined as markdown files with YAML frontmatter.

### Agent Scopes (Priority Order)

| Location | Scope | Priority |
|----------|-------|----------|
| `--agents` CLI flag | Current session only | 1 (highest) |
| `.claude/agents/` | Current project | 2 |
| `~/.claude/agents/` | All your projects | 3 |
| Plugin `agents/` directory | Where plugin is enabled | 4 (lowest) |

When multiple agents share the same name, higher-priority location wins.

### /agents Command

Run `/agents` in Claude Code to interactively:
- View all available agents (built-in, user, project, plugin)
- Create new agents (guided setup or Claude generation)
- Edit existing agent configuration and tool access
- Delete custom agents

### CLI-Defined Agents

Pass JSON with `--agents` for session-only agents:
```bash
claude --agents '{
  "reviewer": {
    "description": "Code reviewer",
    "prompt": "Review code for quality",
    "tools": ["Read", "Grep"],
    "model": "sonnet"
  }
}'
```

### Directory Structure
```
.claude/agents/
└── agent-name.md
```

Or globally:
```
~/.claude/agents/
└── agent-name.md
```

### Agent File Format

```yaml
---
name: my-custom-agent
description: Description shown in Task tool agent list. Include when to use this agent.
model: sonnet
allowed-tools:
  - Read
  - Grep
  - Glob
  - WebFetch
---

# Agent Instructions

You are a specialized agent for [specific purpose].

## Your Capabilities
- Capability 1
- Capability 2

## Guidelines
- Guideline 1
- Guideline 2

## Output Format
Always respond with:
1. Summary
2. Details
3. Recommendations
```

### Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Unique agent identifier |
| `description` | Yes | What + when, used for discovery |
| `model` | No | Default model (`sonnet`, `opus`, `haiku`, `inherit`) |
| `allowed-tools` | No | Restrict available tools |
| `disallowedTools` | No | Tools to deny (removed from inherited list) |
| `permissionMode` | No | `default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, `plan` |
| `skills` | No | Preload skills into agent context |
| `hooks` | No | Lifecycle hooks: PreToolUse, PostToolUse, Stop (converted to SubagentStop) |
| `memory` | No | Persistent memory scope: `user`, `project`, or `local` |
| `max-turns` | No | Limit conversation turns |

### Permission Modes

| Mode | Behavior |
|------|----------|
| `default` | Standard permission prompts |
| `acceptEdits` | Auto-accept file edits |
| `dontAsk` | Auto-deny permission prompts |
| `bypassPermissions` | Skip all permission checks |
| `plan` | Read-only exploration mode |

### Skills Preloading

Inject skill content at startup:
```yaml
---
name: api-developer
skills:
  - api-conventions
  - error-handling-patterns
---
```

### Persistent Memory

Enable cross-session memory for agents:
```yaml
---
name: code-reviewer
memory: user    # Scope: user, project, or local
---
```

| Scope | Location | Use Case |
|-------|----------|----------|
| `user` | `~/.claude/agent-memory/<name>/` | Learnings across all projects |
| `project` | `.claude/agent-memory/<name>/` | Project-specific, shareable via git |
| `local` | `.claude/agent-memory-local/<name>/` | Project-specific, not committed |

When memory is enabled, agents can read/write to their memory directory and maintain `MEMORY.md` for persistent context.

### Hooks in Agent Frontmatter

```yaml
---
name: code-reviewer
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate.sh"
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "./scripts/lint.sh"
---
```

## Complete Agent Example

### Security Reviewer Agent

```yaml
---
name: security-reviewer
description: Review code for security vulnerabilities. Use for security audits, dependency checks, or when security concerns are raised.
model: sonnet
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
---

# Security Review Agent

You are a security expert specializing in code review and vulnerability detection.

## Focus Areas

1. **Injection Vulnerabilities**
   - SQL injection
   - Command injection
   - XSS (Cross-Site Scripting)

2. **Authentication/Authorization**
   - Weak credentials
   - Missing auth checks
   - Privilege escalation

3. **Data Exposure**
   - Hardcoded secrets
   - Sensitive data in logs
   - Insecure transmission

4. **Dependencies**
   - Known vulnerabilities
   - Outdated packages
   - Malicious dependencies

## Review Process

1. Scan for hardcoded secrets and credentials
2. Check input validation and sanitization
3. Review authentication flows
4. Analyze authorization logic
5. Check dependency versions
6. Review error handling and logging

## Output Format

```markdown
## Security Review Report

### Critical Issues
- Issue 1: [Description] at `file:line`

### High Priority
- Issue 1: [Description]

### Medium Priority
- Issue 1: [Description]

### Recommendations
1. Recommendation 1
2. Recommendation 2
```

## Commands to Use

```bash
# Find hardcoded secrets
grep -r "password\|secret\|api_key\|token" --include="*.{js,ts,py,env}"

# Check for vulnerable patterns
grep -r "eval\|exec\|shell\|system" --include="*.{js,ts,py}"

# Review dependencies
npm audit
pip-audit
```
```

### Test Runner Agent

```yaml
---
name: test-runner
description: Run tests and analyze failures. Use after code changes, for debugging test failures, or when asked to run tests.
model: haiku
allowed-tools:
  - Bash
  - Read
  - Grep
---

# Test Runner Agent

You run tests and provide clear analysis of failures.

## Process

1. Identify test framework (jest, pytest, vitest, etc.)
2. Run appropriate test command
3. Parse output for failures
4. Analyze failing tests
5. Suggest fixes

## Common Commands

```bash
# JavaScript/TypeScript
npm test
npm run test:coverage
npx jest --testPathPattern="pattern"

# Python
pytest
pytest -v --tb=short
pytest tests/test_file.py -k "test_name"

# Go
go test ./...
go test -v -run TestName
```

## Output Format

### All Tests Pass
```
All X tests passed in Y seconds.
Coverage: Z%
```

### Test Failures
```
## Failed Tests (X/Y)

### test_name (file:line)
- Expected: value
- Received: value
- Likely cause: [analysis]
- Suggested fix: [recommendation]
```
```

## Parallel Agent Execution

Launch multiple agents simultaneously in a SINGLE message:

```xml
<invoke name="Task">
<parameter name="description">Find components</parameter>
<parameter name="prompt">Find all React components in src/</parameter>
<parameter name="subagent_type">Explore</parameter>
</invoke>

<invoke name="Task">
<parameter name="description">Find API routes</parameter>
<parameter name="prompt">Find all API route definitions</parameter>
<parameter name="subagent_type">Explore</parameter>
</invoke>
```

### Advanced Parallel Patterns

#### Port Isolation for Parallel Agents
When running multiple agents that use network resources:

```markdown
### Port Validation (Primary Agent)

Assign ports BEFORE launching subagents:

```bash
# Assign deterministic ports based on index
# Agent 1 → port 9223
# Agent 2 → port 9224
# Agent 3 → port 9225

# Validate each port is available
for port in 9223 9224 9225; do
  lsof -i :$port 2>/dev/null && echo "Port $port: IN USE" || echo "Port $port: AVAILABLE"
done
```

If a port is in use, increment until available.
```

#### Subagent Prompt Template
Structure for parallel subagent prompts:

```markdown
<subagent-prompt>
You are executing a specific task.

**YOUR ASSIGNED PORT: [UNIQUE_PORT]**
This port is exclusively yours. No other agent will use it.

**Setup:**
1. cd to `[WORKING_DIR]`
2. Your port is: [UNIQUE_PORT] (pre-validated by parent)
3. Start service: `command --port [UNIQUE_PORT]`

**Task:**
[Specific instructions for this agent]

**CRITICAL - CLEANUP:**
- ONLY close YOUR service on YOUR port
- NEVER close without specifying your port
- NEVER touch ports other than [UNIQUE_PORT]

**Return this exact format:**
```
Task: [Name]
Port: [UNIQUE_PORT]
Status: PASSED or FAILED
Details: [summary]
```
</subagent-prompt>
```

#### Collecting Parallel Results
After launching parallel agents:

```markdown
### Collect Results (Primary Agent)

After all subagents complete:
1. Collect status from each
2. Count passed/failed
3. Generate consolidated report

| Task | Port | Status | Details |
|------|------|--------|---------|
| Task 1 | 9223 | PASSED | ... |
| Task 2 | 9224 | PASSED | ... |
| Task 3 | 9225 | FAILED | ... |
```

## Resuming Agents

Use the agent ID to resume:

```xml
<invoke name="Task">
<parameter name="description">Continue analysis</parameter>
<parameter name="prompt">Continue with the next step</parameter>
<parameter name="resume">a3840f8</parameter>
<parameter name="subagent_type">Explore</parameter>
</invoke>
```

### Auto-Resume with Agent Type (v2.1.32+)

When using `--resume`, the `--agent` value from the previous conversation is automatically re-used:

```bash
# Original invocation
claude --agent my-researcher "Find all database schemas"

# Later - agent type is automatically inherited
claude --resume a3840f8 "Continue from previous findings"
# Equivalent to: claude --agent my-researcher --resume a3840f8
```

## Best Practices

1. **Choose the right agent**: Use `Explore` for search, `Plan` for architecture, `Bash` for commands
2. **Be specific**: Give clear, detailed prompts
3. **Use background**: For long-running tasks that don't need immediate results
4. **Limit tools**: Restrict `allowed-tools` to what's needed for security
5. **Use haiku for simple tasks**: Faster and cheaper for straightforward operations
6. **Parallel when possible**: Launch independent agents simultaneously

## Agent Management

### /agents Command
Interactive agent management:
- List active agents
- Create new agents
- Edit agent configuration
- View agent status

### CLI Agent Configuration
```bash
claude --agents '{
  "reviewer": {
    "description": "Code reviewer",
    "prompt": "Review code for quality",
    "tools": ["Read", "Grep"],
    "model": "sonnet"
  }
}'
```

### Disabling Agents
Add to permissions deny list:
```json
{
  "permissions": {
    "deny": ["Task(Explore)", "Task(my-agent)"]
  }
}
```

## Foreground vs Background Execution

- **Foreground**: Blocks main conversation. Permission prompts and questions pass through to user.
- **Background**: Runs concurrently. Claude prompts for permissions before launching. Auto-denies anything not pre-approved. MCP tools not available. `AskUserQuestion` fails (but agent continues).

If a background agent fails due to missing permissions, resume it in foreground.

Controls:
- Ask Claude to "run this in the background"
- `Ctrl+B` to background a running task
- `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` to disable all background tasks

## Background Execution

### Auto-Compaction
Subagents compact at 95% capacity. Override with:
```bash
CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=85
```

### Transcript Storage
```
~/.claude/projects/{project}/{sessionId}/subagents/agent-{agentId}.jsonl
```

### Controls
- `Ctrl+B` - Background running task
- `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` - Disable background tasks

## Subagent Hook Events

In `settings.json`:
```json
{
  "hooks": {
    "SubagentStart": [{
      "matcher": "db-agent",
      "hooks": [{"type": "command", "command": "./setup-db.sh"}]
    }],
    "SubagentStop": [{
      "matcher": "db-agent",
      "hooks": [{"type": "command", "command": "./cleanup-db.sh"}]
    }]
  }
}
```

## When to Create Custom Agents

Create a custom agent when you have:
- Recurring specialized tasks
- Domain-specific expertise needs
- Complex multi-step workflows
- Need for tool restrictions
- Specific output format requirements

## Multi-Agent Safety Patterns

### ID Management
When working with resources that need tracking across operations:

```markdown
## Instructions

- **CAPTURE AND REMEMBER IDs** - Store in your context, not shell variables
- **Multi-agent safe** - Each agent tracks its own IDs independently
- **Never use shell variables** like `export ID=...` (conflicts with other agents)
- **Never rely on files** like `.sandbox_id` (gets overwritten by other agents)

**Example of proper ID handling:**
```bash
# When you run this:
uv run sbx init

# Capture the ID from output (e.g., "sbx_abc123def456")
# Store it in YOUR context/memory as: sandbox_id = "sbx_abc123def456"

# Then use it directly in all commands:
uv run sbx exec sbx_abc123def456 "python --version"
```
```

### Context Isolation
Each agent maintains its own state:

| What | Good | Bad |
|------|------|-----|
| Store IDs | In agent context/memory | In shell variables |
| Track URLs | Returned from commands | Constructed manually |
| Pass data | Through function returns | Through shared files |

### Conflict Prevention
When multiple agents might operate simultaneously:

```markdown
## Instructions

1. **Unique identifiers**: Always use workflow ID in resource names
2. **Port isolation**: Pre-assign unique ports per agent
3. **Directory isolation**: Use `temp/<WORKFLOW_ID>/` for working files
4. **Explicit cleanup**: Only clean up YOUR resources
```

## Agent Communication Patterns

### Parent-Child Communication
Pass context from orchestrating agent to subagents:

```markdown
### Launch Subagent

Use Task tool with full context:

<subagent-prompt>
**Context from parent:**
- Sandbox ID: [SANDBOX_ID]
- Plan path: [PLAN_PATH]
- Workflow ID: [WORKFLOW_ID]

**Your task:**
[Specific instructions]

**Return to parent:**
- Status: PASSED/FAILED
- Output path: [generated file]
- Errors: [if any]
</subagent-prompt>
```

### Result Aggregation
Parent agent collects and processes subagent results:

```markdown
### Process Results

After all subagents complete:

1. Parse each result for status
2. Aggregate metrics
3. Handle failures:
   - If any FAILED: report specific failures
   - If all PASSED: proceed to next phase
4. Generate consolidated report
```
