# Cross-Harness Workflow Recipes

Practical workflow implementations showing how to achieve the same orchestration patterns across different harnesses.

## Parallel Research Workflow

### Goal
Investigate a topic from 3 angles simultaneously, synthesize findings.

### Claude Code Approach (Agent Teams)
```
Create an agent team with 3 researchers:
- researcher-api: investigate the API surface and endpoints
- researcher-arch: analyze the architecture and data flow
- researcher-tests: review test coverage and gaps

Each researcher should:
1. Use Grep and Read to explore relevant code
2. Use WebSearch for external context
3. Report findings with confidence scores

After all complete, synthesize into a single report.
```

Or with subagents (no team needed):
```xml
<!-- Launch 3 agents in a SINGLE message -->
<invoke name="Agent">
<parameter name="description">Research API surface</parameter>
<parameter name="prompt">Investigate all API endpoints...</parameter>
<parameter name="subagent_type">Explore</parameter>
</invoke>

<invoke name="Agent">
<parameter name="description">Research architecture</parameter>
<parameter name="prompt">Analyze the architecture...</parameter>
<parameter name="subagent_type">Explore</parameter>
</invoke>

<invoke name="Agent">
<parameter name="description">Research test coverage</parameter>
<parameter name="prompt">Review test coverage...</parameter>
<parameter name="subagent_type">Explore</parameter>
</invoke>
```

### Pi Approach (tmux + extensions)
```bash
# Terminal 1: API researcher
pi --model anthropic/claude-haiku-4-5 -p "Investigate API endpoints in this codebase..."

# Terminal 2: Architecture researcher
pi --model anthropic/claude-haiku-4-5 -p "Analyze the architecture..."

# Terminal 3: Test researcher
pi --model anthropic/claude-haiku-4-5 -p "Review test coverage..."
```

Or with agent-team extension:
```
/team full
dispatch_agent scout "Investigate API endpoints"
dispatch_agent planner "Analyze the architecture"
dispatch_agent reviewer "Review test coverage"
```

### OpenCode Approach (Custom Subagents)
Create 3 agents in `.opencode/agents/` (researcher-api.md, researcher-arch.md, researcher-tests.md), then use `@researcher-api` mentions or the general agent to dispatch work.

## Code Review Pipeline

### Goal
Sequential review: lint -> security -> logic -> report.

### Claude Code Approach
```yaml
# .claude/agents/review-pipeline.md
---
name: review-pipeline
description: Sequential code review pipeline. Use for thorough PR reviews.
model: opus
---

## Pipeline Steps

1. **Lint Check**: Launch Agent with Bash tool to run linters
2. **Security Scan**: Launch security-reviewer Agent (read-only)
3. **Logic Review**: Launch code-reviewer Agent (read-only)
4. **Synthesize**: Combine all findings into final report

Execute steps sequentially. Each step builds on previous findings.
```

### Pi Approach (Agent Chain)
```
/chain plan-review-plan "Review the changes in the last 3 commits"
```

Pipeline defined in `.pi/agents/agent-chain.yaml`:
```yaml
plan-review-plan:
  - agent: scout
    model: anthropic/claude-haiku-4-5
  - agent: reviewer
    model: anthropic/claude-sonnet-4-6
  - agent: planner
    model: anthropic/claude-opus-4-6
```

### OpenCode Approach
Use Plan agent (Tab to switch) for analysis, then Build agent for fixes:
1. Tab to Plan mode -> review code
2. Tab to Build mode -> implement fixes
3. Tab to Plan mode -> verify fixes

## Migration Workflow (Moving Between Harnesses)

### From Claude Code to Pi

| CC Concept | Pi Equivalent |
|------------|---------------|
| CLAUDE.md | AGENTS.md |
| .claude/agents/ | .pi/agents/ (prompt templates) |
| .claude/skills/ | .pi/skills/ |
| .claude/commands/ | .pi/prompts/ |
| hooks in settings.json | Extension event handlers |
| MCP servers | CLI tools + skills (or MCP extension) |
| Agent teams | agent-team.ts extension |
| Plan mode | Extension or "write plan to file" |
| /compact | /compact (built-in) |

### From Claude Code to OpenCode

| CC Concept | OC Equivalent |
|------------|---------------|
| CLAUDE.md | AGENTS.md |
| .claude/agents/ | .opencode/agents/ (same format) |
| .claude/skills/ | .opencode/skills/ (compatible!) |
| .claude/commands/ | .opencode/commands/ |
| hooks in settings.json | Plugin hooks |
| MCP servers | mcp section in opencode.jsonc |
| Agent teams | Not supported (use subagents) |
| Plan mode | Tab key (built-in) |
| settings.json | opencode.jsonc |

### From Pi to Claude Code

| Pi Concept | CC Equivalent |
|------------|---------------|
| AGENTS.md | CLAUDE.md |
| Extensions | Hooks + MCP servers + plugins |
| .pi/extensions/ | hooks in settings.json + MCP |
| .pi/skills/ | .claude/skills/ |
| .pi/prompts/ | .claude/commands/ |
| pi.registerTool() | MCP server tool |
| Session trees | Not supported (linear) |
| /tree, /fork | Not supported |
| Ctrl+P model cycle | /model command |

## Build-Test-Deploy Workflow

### Goal
Implement feature, test it, deploy if tests pass.

### Claude Code (with TaskCreate orchestration)
```markdown
## Workflow

1. TaskCreate: "Implement feature X" (owner: builder)
2. TaskCreate: "Test feature X" (owner: validator, blocked by task 1)
3. TaskCreate: "Deploy if tests pass" (owner: deployer, blocked by task 2)

Launch builder agent -> auto-unblocks validator -> auto-unblocks deployer
```

### Pi (Sequential Chain)
```yaml
# .pi/agents/agent-chain.yaml
build-test-deploy:
  - agent: builder
    model: anthropic/claude-sonnet-4-6
  - agent: tester
    model: anthropic/claude-haiku-4-5
  - agent: deployer
    model: anthropic/claude-haiku-4-5
    prompt: "Only deploy if all tests passed. $INPUT contains test results."
```

### OpenCode
Use Build agent for implementation, then run tests via bash, then deploy. All within a single session — no multi-agent needed for sequential workflows.
